terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.app_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "ec2" {
  source = "./modules/ec2"

  app_name            = var.app_name
  environment         = var.environment
  instance_type       = var.instance_type
  github_repo         = var.github_repo
  vpc_id              = data.aws_vpc.default.id
  subnet_id           = data.aws_subnets.default.ids[0]
  allowed_cidr_blocks = var.allowed_cidr_blocks
}

module "s3" {
  source = "./modules/s3"

  app_name    = var.app_name
  environment = var.environment
}

module "cloudwatch" {
  source = "./modules/cloudwatch"

  app_name    = var.app_name
  environment = var.environment
  instance_id = module.ec2.instance_id
}
