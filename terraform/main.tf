########################################
# Root – wires all modules together
########################################
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

########################################
# VPC
########################################
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = var.availability_zone
}

########################################
# ECR
########################################
module "ecr" {
  source = "./modules/ecr"

  repository_name = var.project_name
  environment     = var.environment
}

########################################
# CloudWatch
########################################
module "cloudwatch" {
  source = "./modules/cloudwatch"

  project_name       = var.project_name
  environment        = var.environment
  log_retention_days = var.log_retention_days
  instance_id        = module.ec2.instance_id
}

########################################
# EC2
########################################
module "ec2" {
  source = "./modules/ec2"

  project_name     = var.project_name
  environment      = var.environment
  instance_type    = var.instance_type
  ami_id           = var.ami_id
  key_name         = var.key_name
  subnet_id        = module.vpc.public_subnet_id
  vpc_id           = module.vpc.vpc_id
  aws_region       = var.aws_region
  ecr_registry_url = "${module.ecr.registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  image_name       = var.project_name
  log_group_name   = module.cloudwatch.log_group_name
}
