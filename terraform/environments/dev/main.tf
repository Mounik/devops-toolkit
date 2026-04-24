# ══════════════════════════════════════════════════════════
# Dev Environment — Wire modules together
# ══════════════════════════════════════════════════════════

terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state (commented — use S3 backend for team work)
  # backend "s3" {
  #   bucket         = "devops-toolkit-tfstate"
  #   key            = "dev/terraform.tfstate"
  #   region         = "eu-west-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "devops-toolkit"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

module "vpc" {
  source               = "../../modules/vpc"
  region               = var.region
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["eu-west-1a", "eu-west-1b"]
}

module "compute" {
  source          = "../../modules/compute"
  instance_count  = 1
  instance_type   = "t3.micro"
  key_name        = var.ssh_key_name
  subnet_ids      = module.vpc.public_subnet_ids
  security_groups = [module.vpc.bastion_security_group_id]
  user_data       = file("${path.module}/../../scripts/server-init.sh")
}
