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
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.boundary.name
  subnet_id                   = aws_subnet.public.id
  key_name                    = aws_key_pair.boundary.key_name
  vpc_security_group_ids      = [aws_security_group.worker.id]
  associate_public_ip_address = true

  connection {
    type         = "ssh"
    user         = "ubuntu"
    private_key  = tls_private_key.boundary.private_key_pem
    host         = self.private_ip
    bastion_host = aws_instance.controller.public_ip
  }

  provisioner "file" {
    on_failure = continue
    content = templatefile("${path.module}/install/worker.hcl.tpl", {
      controller_ips         = aws_instance.controller.*.private_ip
      name_suffix            = ""
      region                 = "us-east-1"
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
    on_failure  = continue
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


resource "aws_instance" "vault" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  iam_instance_profile        = aws_iam_instance_profile.boundary.name
  subnet_id                   = aws_subnet.public[0].id
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
    on_failure  = continue
    source      = "${path.module}/install/vault_install.sh"
    destination = "~/vault_install.sh"
  }

  provisioner "file" {
    on_failure  = continue
    source      = "${path.module}/install/config.hcl"
    destination = "~/config.hcl"
  }

    provisioner "file" {
    on_failure  = continue
    source      = "${path.module}/install/pushvars.sh"
    destination = "~/pushvars.sh"
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
      "sudo apt update",
      "mkdir ~/vault",
      "mv ~/config.hcl ~/vault/config.hcl",
      #setup docker
      "sudo apt-get install ca-certificates curl gnupg lsb-release",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get -y update",
      "sudo apt-get -y install docker-ce docker-ce-cli containerd.io",
      #install vault CLI
      "curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -",
      "sudo apt-add-repository \"deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
      "sudo apt-get update && sudo apt-get install vault",
      #stand up cluster
      "sudo apt-get install -y jq curl",
      "sudo bash vault_install.sh",
      #install Terraform helper
      "sudo apt-get upgrade -y coreutils",
      "git clone https://github.com/hashicorp-community/tf-helper.git",
      "cd tf-helper/tfh/bin",
      "sudo ln -s $PWD/tfh /usr/local/bin/tfh",
    ]
  }

  provisioner "remote-exec" {
    on_failure = continue
    inline = [
      "sudo bash pushvars.sh ${var.tfc_token} ${var.psql_user} ${var.psql_pw}"
    ]
  }
  
 
}
resource "aws_instance" "controller" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.boundary.name
  subnet_id                   = aws_subnet.public.id
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
    on_failure  = continue
    source      = "${path.module}/install/install.sh"
    destination = "~/install.sh"
  }

  provisioner "file" {
    on_failure  = continue
    source      = "${path.module}/install/northwind-database.sql"
    destination = "~/northwind-database.sql"
  }

  provisioner "file" {
    on_failure  = continue
    source      = "${path.module}/install/northwind-roles.sql"
    destination = "~/northwind-roles.sql"
  }

  # aws_db_instance.boundary.endpoint
  provisioner "file" {
    on_failure = continue
    content = templatefile("${path.module}/install/controller.hcl.tpl", {
      name_suffix            = ""
      db_endpoint            = "postgresql://${var.psql_user}:${var.psql_pw}@localhost/boundary?sslmode=disable"
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
      #setup docker
      "sudo apt-get install ca-certificates curl gnupg lsb-release",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get -y update",
      "sudo apt-get -y install docker-ce docker-ce-cli containerd.io",
      "sudo docker network create bnet",
      #setup psql container
      "sudo docker create --name boundary_psql --network bnet -it -p 5432:5432 -e POSTGRES_PASSWORD=${var.psql_pw} -e POSTGRES_USER=${var.psql_user} postgres",
      "sudo docker start boundary_psql",
      "sleep 5",
      "psql \"postgresql://${var.psql_user}:${var.psql_pw}@localhost/postgres\" -c 'create database boundary';",
      #populate northwinds database
      "psql \"postgresql://${var.psql_user}:${var.psql_pw}@localhost/postgres\" -c 'create database northwind';",
      "psql \"postgresql://${var.psql_user}:${var.psql_pw}@localhost/northwind\" -f ~/northwind-database.sql --quiet",
      "psql \"postgresql://${var.psql_user}:${var.psql_pw}@localhost/northwind\" -f ~/northwind-roles.sql --quiet",
      #install boundary
      "sudo apt -y install unzip",
      "wget https://releases.hashicorp.com/boundary/0.7.1/boundary_0.7.1_linux_amd64.zip",
      "unzip boundary_0.7.1_linux_amd64.zip -d ~/boundary",
      "sudo mv ~/boundary/boundary /usr/local/bin/boundary",
      "sudo chmod 0755 /usr/local/bin/boundary",
      "sudo mv ~/boundary-controller.hcl /etc/boundary-controller.hcl",
      "sudo chmod 0755 ~/install.sh",
      "sudo ~/./install.sh controller",
    ]
  }
}

## Example resource for connecting to through boundary over SSH
#resource "aws_instance" "target" {
#  count                  = var.num_targets
#  ami                    = data.aws_ami.ubuntu.id
#  instance_type          = "t3.nano"
#  subnet_id              = aws_subnet.private.*.id[count.index]
#  key_name               = aws_key_pair.boundary.key_name
#  vpc_security_group_ids = [aws_security_group.worker.id]
#}

resource "aws_instance" "tfc_agent" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.boundary.name
  subnet_id                   = aws_subnet.private.id
  key_name                    = aws_key_pair.boundary.key_name
  vpc_security_group_ids      = [aws_security_group.tfc_agent.id]
  associate_public_ip_address = true

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.boundary.private_key_pem
    host        = self.private_ip
    bastion_host = aws_instance.worker.public_ip
  }
  provisioner "remote-exec" {
    on_failure = continue
    inline = [
      "sudo apt -y install unzip",
      "wget https://releases.hashicorp.com/tfc-agent/1.0.2/tfc-agent_1.0.2_linux_amd64.zip",
      "unzip tfc-agent_1.0.2_linux_amd64.zip",
      "export TFC_AGENT_TOKEN=${var.tfc_agent_token}",
      "export TFC_AGENT_NAME=atarc_aws_enclave_01",
      "./tfc-agent"
    ]
  }
}