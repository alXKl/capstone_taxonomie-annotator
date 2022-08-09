terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket = "capstone-terraform-state"
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = "eu-central-1"
}


module "autoscaling" {
	source              = "./modules/autoscaling"
  vpc_id              = module.network.vpc_id
  vpc_public_subnets  = module.network.vpc_public_subnets
  dynamodb_arn        = module.database.dynamodb_arn
}

module "network" {
	source            = "./modules/network"
  lb_dns_name       = module.autoscaling.lb_dns_name
  lb_zone_id        = module.autoscaling.lb_zone_id
  website_endpoint  = module.client.website_endpoint
}

module "client" {
	source            = "./modules/client"
}

module "database" {
	source            = "./modules/database"
}
