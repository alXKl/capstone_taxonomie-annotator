terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "cap_backend_src" {
  bucket = "cap-backend-src-test"
  acl    = "private"
  tags = {
    Name = "cap-backend-src-test"
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




