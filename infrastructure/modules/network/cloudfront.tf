resource "aws_cloudfront_distribution" "www_distribution" {
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    domain_name = "${var.website_endpoint}"
    origin_id   = "${local.www_domain}"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${local.www_domain}"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  aliases = ["${local.www_domain}"]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    # acm_certificate_arn = "arn:aws:acm:us-east-1:348555763414:certificate/963e4ab2-1fb9-4b68-b9d9-a13a7c772970"
    acm_certificate_arn = data.aws_acm_certificate.cf_certificate.arn
    ssl_support_method  = "sni-only"
  }
}

data "aws_acm_certificate" "cf_certificate" {
  domain      = "annotator-capstone.ml"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
  provider = aws.virginia
}

provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}