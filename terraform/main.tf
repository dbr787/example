terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.22.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.3.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.2.3"
    }
  }
  required_version = ">= 1.1.4"
}

# vpc
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = "true"
  tags = {
    Name = "${var.project_id}-vpc"
  }
}

# public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.availability_zones.names[0]
  tags = {
    Name = "${var.project_id}-public-subnet"
  }
}

# internet gateway for newly created vpc
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.project_id}-internet-gateway"
  }
}

# route table for newly created vpc
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name = "${var.project_id}-public-route-table"
  }
}

# associate route table with newly created public subnet
resource "aws_route_table_association" "public_subnet_route_table_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# ssh key
resource "tls_private_key" "ssh_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# save private key to local file
resource "local_file" "ssh_private_key_file" {
  content         = tls_private_key.ssh_private_key.private_key_pem
  filename        = "${path.root}/keys/${var.project_id}-key.pem"
  file_permission = "0600"
}

# aws key pair
resource "aws_key_pair" "ssh_key_pair" {
  key_name   = "${var.project_id}-ssh-key-pair"
  public_key = tls_private_key.ssh_private_key.public_key_openssh
  tags = {
    Name = "${var.project_id}-ssh-key-pair"
  }
}

# security group
resource "aws_security_group" "buildkite_agent_sg" {
  vpc_id = aws_vpc.vpc.id
  name   = "${var.project_id}-sg"
  egress {
    description = "Outbound internet access"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Inbound ping from allowed ips and internal subnets"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = setunion(var.allowed_ip_cidrs, ["${aws_subnet.public_subnet.cidr_block}"])
  }
  ingress {
    description = "Inbound ssh from allowed ips and internal subnets"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = setunion(var.allowed_ip_cidrs, ["${aws_subnet.public_subnet.cidr_block}"])
  }
  tags = {
    Name = "${var.project_id}-sg"
  }
}

# # aws instance
# resource "aws_instance" "buildkite_agent" {
#   count                  = var.agent_instance_count
#   ami                    = data.aws_ami.buildkite_agent_ami.id
#   instance_type          = var.buildkite_agent_instance_type
#   subnet_id              = aws_subnet.public_subnet.id
#   vpc_security_group_ids = [aws_security_group.buildkite_agent_sg.id]
#   key_name               = aws_key_pair.ssh_key_pair.id
#   user_data = templatefile("${path.module}/files/buildkite_agent_bootstrap.tpl.sh", {
#     buildkite_agent_token = "${var.buildkite_agent_token}"
#     hostname              = "${var.project_id}-agent-${format("%02d", count.index + 1)}"
#   })
#   root_block_device {
#     volume_size = 30
#   }
#   tags = {
#     Name     = "${var.project_id}-agent-${format("%02d", count.index + 1)}"
#     hostname = "${var.project_id}-agent-${format("%02d", count.index + 1)}"
#   }
# }

# This module will be applied for every object in the buildkite_agents variable
module "buildkite-agents" {
  source                = "./modules/buildkite-agents"
  for_each              = { for agent in var.buildkite_agents : agent.id => agent }
  project_id            = var.project_id
  id                    = each.value.id
  subnet_id             = aws_subnet.public_subnet.id
  security_group_id     = aws_security_group.buildkite_agent_sg.id
  key_name              = aws_key_pair.ssh_key_pair.id
  buildkite_agent_token = var.buildkite_agent_token
  platform              = each.value.platform
  instance_count        = each.value.instance_count
  instance_type         = each.value.instance_type
  ssh_user              = each.value.ssh_user
  ami_owner             = each.value.ami_owner
  ami_name_filter       = each.value.ami_name_filter
  private_key_file      = local_file.ssh_private_key_file.filename
}
