resource "aws_key_pair" "boundary" {
  key_name   = "${var.prefix}-${random_pet.test.id}"
  public_key = tls_private_key.boundary.public_key_openssh
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "worker" {
  count                       = var.num_workers
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.boundary.name
  subnet_id                   = aws_subnet.public.*.id[count.index]
  key_name                    = aws_key_pair.boundary.key_name
  vpc_security_group_ids      = [aws_security_group.worker.id]
  associate_public_ip_address = true

  connection {
    type         = "ssh"
    user         = "ubuntu"
    private_key  = tls_private_key.boundary.private_key_pem
    host         = self.private_ip
    bastion_host = aws_instance.controller[count.index].public_ip
  }

  provisioner "file" {
    on_failure = continue
    content = templatefile("${path.module}/install/worker.hcl.tpl", {
      controller_ips         = aws_instance.controller.*.private_ip
      name_suffix            = count.index
      public_ip              = self.public_ip
      private_ip             = self.private_ip
      tls_disabled           = var.tls_disabled
      tls_key_path           = var.tls_key_path
      tls_cert_path          = var.tls_cert_path
      kms_type               = var.kms_type
      kms_worker_auth_key_id = aws_kms_key.worker_auth.id
    })
    destination = "~/boundary-worker.hcl"
  }

  provisioner "file" {
    on_failure = continue
    source      = "${path.module}/install/install.sh"
    destination = "~/install.sh"
  }
  provisioner "remote-exec" {
    on_failure = continue
    inline = [
      "sudo apt install unzip",
      "wget https://releases.hashicorp.com/boundary/0.7.1/boundary_0.7.1_linux_amd64.zip",
      "unzip boundary_0.7.1_linux_amd64.zip -d ~/boundary",
      "sudo mkdir -p /etc/pki/tls/boundary",
      "sudo mv ~/boundary/boundary /usr/local/bin/boundary",
      "sudo chmod 0755 /usr/local/bin/boundary",
      "echo '${tls_private_key.boundary.private_key_pem}' | sudo tee ${var.tls_key_path}",
      "echo '${tls_self_signed_cert.boundary.cert_pem}' | sudo tee ${var.tls_cert_path}",
      "sudo mv ~/boundary-controller.hcl /etc/boundary-controller.hcl",
      "sudo chmod 0755 ~/install.sh",
      "sudo ~/./install.sh worker"
    ]
  }

  depends_on = [aws_instance.controller]
}


resource "aws_instance" "controller" {
  count                       = var.num_controllers
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.boundary.name
  subnet_id                   = aws_subnet.public.*.id[count.index]
  key_name                    = aws_key_pair.boundary.key_name
  vpc_security_group_ids      = [aws_security_group.controller.id]
  associate_public_ip_address = true

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.boundary.private_key_pem
    host        = self.public_ip
  }
  provisioner "file" {
    on_failure = continue
    source      = "${path.module}/install/install.sh"
    destination = "~/install.sh"
  }

# aws_db_instance.boundary.endpoint
  provisioner "file" {
    on_failure = continue
    content = templatefile("${path.module}/install/controller.hcl.tpl", {
      name_suffix            = count.index
      db_endpoint            = "endpoint_variable"
      private_ip             = self.private_ip
      tls_disabled           = var.tls_disabled
      tls_key_path           = var.tls_key_path
      tls_cert_path          = var.tls_cert_path
      kms_type               = var.kms_type
      kms_worker_auth_key_id = aws_kms_key.worker_auth.id
      kms_recovery_key_id    = aws_kms_key.recovery.id
      kms_root_key_id        = aws_kms_key.root.id
    })
    destination = "~/boundary-controller.hcl"
  }
  
    provisioner "remote-exec" {
    on_failure = continue
    inline = [
      "sudo mkdir -p /etc/pki/tls/boundary",
      "echo '${tls_private_key.boundary.private_key_pem}' | sudo tee ${var.tls_key_path}",
      "echo '${tls_self_signed_cert.boundary.cert_pem}' | sudo tee ${var.tls_cert_path}",
    ]
  }
    provisioner "remote-exec" {
    on_failure = continue
    inline = [
      "sudo apt -y update",
      "sudo apt -y install postgresql-client",
      "sudo apt-get install ca-certificates curl gnupg lsb-release",
       "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get -y update",
      #setup docker
      "sudo apt-get -y install docker-ce docker-ce-cli containerd.io",
      "sudo docker network create bnet",
      #setup psql container
      "sudo docker create --name boundary_psql --network bnet -it -p 5432:5432 -e POSTGRES_PASSWORD=${var.psql_pw} -e POSTGRES_USER=${var.psql_user} postgres",
      "sudo docker start boundary_psql",
      "sleep 5",
      "psql \"postgresql://${var.psql_user}:${var.psql_pw}@localhost/postgres\" -c 'create database boundary';",
      #populate northwinds database
      "psql \"postgresql://${var.psql_user}:${var.psql_pw}@localhost/postgres\" -c 'create database northwind",
      "psql \"postgresql://${var.psql_user}:${var.psql_pw}@localhost/postgres/northwind\" -f northwind-database.sql --quiet",
      "psql \"postgresql://${var.psql_user}:${var.psql_pw}@localhost/postgres/northwind\" -f northwind-roles.sql --quiet",
      #install vault container
      "sudo docker create --name hcvault1 --net=bnet -p ${var.vault_port}:8200 -h hcvault1 -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN=${var.vault_token} hashicorp/vault-enterprise:1.7.1_ent server -dev -dev-root-token-id=${var.vault_token_id}",
      "docker start hcvault1",
      "sudo apt -y install unzip",
      "wget https://releases.hashicorp.com/boundary/0.7.1/boundary_0.7.1_linux_amd64.zip",
      "unzip boundary_0.7.1_linux_amd64.zip -d ~/boundary",
      "sudo mv ~/boundary/boundary /usr/local/bin/boundary",
      "sudo chmod 0755 /usr/local/bin/boundary",
      "sudo mv ~/boundary-controller.hcl /etc/boundary-controller.hcl",
      "sudo chmod 0755 ~/install.sh",
      "sudo ~/./install.sh controller"
    ]
  }
}

# Example resource for connecting to through boundary over SSH
resource "aws_instance" "target" {
  count                  = var.num_targets
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.*.id[count.index]
  key_name               = aws_key_pair.boundary.key_name
  vpc_security_group_ids = [aws_security_group.worker.id]
}
