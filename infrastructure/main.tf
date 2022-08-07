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

data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_s3_bucket" "cap_backend_src" {
  bucket = "cap-backend-src-bucket"
  acl    = "private"
  tags = {
    Name = "cap-backend-src-bucket"
  }
}

resource "aws_s3_bucket_object" "src" {
  for_each = fileset("../backend/", "**/*.zip")

  bucket = aws_s3_bucket.cap_backend_src.bucket
  key    = each.value
  source = "../backend/${each.value}"
  etag   = filemd5("../backend/${each.value}")
  # content_type = "text/html"
}

