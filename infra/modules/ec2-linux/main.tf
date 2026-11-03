# One EC2 instance, Linux or Windows, attached to the existing environment.
# No VPC, subnet or security group IDs are passed in: platform-lookup finds them.

terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

module "platform" {
  source      = "../platform-lookup"
  project     = var.project
  environment = var.environment
}

locals {
  subnet_ids = var.subnet_tier == "public" ? module.platform.public_subnet_ids : module.platform.private_subnet_ids
  # Public SSM parameters. No AMI ID is written in this repo.
  ami_parameter = var.os == "windows" ? "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base" : "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  # Windows Server 2022 needs at least 30 GB. Linux keeps the requested size.
  root_volume_gb = var.os == "windows" ? max(var.root_volume_gb, 30) : var.root_volume_gb
}

data "aws_ssm_parameter" "ami" {
  name = local.ami_parameter
}

resource "aws_instance" "this" {
  ami                    = data.aws_ssm_parameter.ami.value
  instance_type          = var.instance_type
  subnet_id              = local.subnet_ids[0]
  vpc_security_group_ids = concat([module.platform.app_security_group_id], var.extra_security_group_ids)

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = local.root_volume_gb
  }

  tags = merge(module.platform.common_tags, var.tags, {
    Name = "${module.platform.name_prefix}-${var.name}"
  })
}
