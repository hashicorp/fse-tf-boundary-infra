resource "aws_security_group" "controller" {
  name   = "controller_sg"
  vpc_id = local.vpc_id
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
    # Allow access to Boundary UI from anywhere
    from_port   = 9201
    to_port     = 9201
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
    security_groups = local.private_sub_cidrs
  }
}

resource "aws_security_group" "worker" {
  name   = "worker_sg"
  vpc_id = local.vpc_id

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
    cidr_blocks = local.private_sub_cidrs
  }
}


resource "aws_security_group" "tfc_agent" {
  name   = "tfc_Agent_sg"
  vpc_id = local.vpc_id
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
    cidr_blocks = local.public_sub_cidrs
  }

}
