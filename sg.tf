resource "aws_security_group" "controller" {
  name   = "controller_sg"
  vpc_id = aws_vpc.main.id
  egress {
    # allow all outbound
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # Allow inbound SSS from anywhere
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # Allow access to Boundary UI from anywhere
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # allow everyone access to psql. Do not do in production
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # Allow access to Boundary https from anywhere
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # allow all inbound traffic from private subnet
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [aws_subnet.private.cidr_block]
  }
}

resource "aws_security_group" "worker" {
  name   = "worker_sg"
  vpc_id = aws_vpc.main.id

  egress {
    # allow all outbound
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # Allow inbound SSH from anywhere
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9202
    to_port     = 9202
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # inbound webapp access for worker
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # allow all inbound traffic from private subnet
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [aws_subnet.private.cidr_block]
  }
}

resource "aws_security_group" "vault" {
  name   = "vault_sg"
  vpc_id = aws_vpc.main.id
  egress {
    # allow all outbound
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # inbound bastion access for provisioning. Can be disabled after provisoining.
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.controller.private_ip}/32"]
  }
  ingress {
    # inbound vault UI access through boundary worker
    from_port   = 8201
    to_port     = 8203
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.worker.private_ip}/32"]
  }
  ingress {
    # Allow inbound SSS from anywhere. Using bastion for provisioning. This can be disabled for production
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # allowing gloabl access for UI demo and build. Do not do this in production
    from_port   = 8200
    to_port     = 8205
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # allow all inbound traffic from private subnet
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [aws_subnet.private.cidr_block]
  }
}

resource "aws_security_group" "tfc_agent" {
  name   = "tfc_Agent_sg"
  vpc_id = aws_vpc.main.id
  egress {
    # allow all outbound
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # inbound bastion access for provisioning. Can be disabled after provisoining.
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.controller.private_ip}/32"]
  }

}

#resource "aws_security_group_rule" "allow_9201_controller" {
#  type              = "ingress"
#  from_port         = 9201
#  to_port           = 9201
#  protocol          = "tcp"
#  cidr_blocks       = ["0.0.0.0/0"]
#  security_group_id = aws_security_group.controller.id
#}


