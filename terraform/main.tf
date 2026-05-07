########################################
# Root – wires all modules together
########################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment to use S3 remote state (recommended for production)
  # backend "s3" {
  #   bucket         = "your-tfstate-bucket"
  #   key            = "html-app/terraform.tfstate"
  #   region         = var.aws_region
  #   dynamodb_table = "terraform-lock"
  #   encrypt        = true
  # }
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
# Networking
########################################
module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = var.availability_zone
}

########################################
# Security
########################################
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

########################################
# IAM
########################################
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

########################################
# EC2
########################################
module "ec2" {
  source = "./modules/ec2"

  project_name          = var.project_name
  environment           = var.environment
  instance_type         = var.instance_type
  ami_id                = var.ami_id
  key_name              = var.key_name
  subnet_id             = module.networking.public_subnet_id
  security_group_id     = module.security.app_sg_id
  iam_instance_profile  = module.iam.instance_profile_name
  cloudwatch_log_group  = module.iam.cloudwatch_log_group_name
  aws_region            = var.aws_region
}

