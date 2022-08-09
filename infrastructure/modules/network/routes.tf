resource "aws_route53_record" "cloudfront-record" {
  zone_id = "Z032039338M1X3L5AR4HT"
  name    = "www.annotator-capstone.ml"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.www_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.www_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "lb-record" {
  zone_id = "Z032039338M1X3L5AR4HT"
  name    = "api.annotator-capstone.ml"
  type    = "A"
  alias {
    name                   = "${var.lb_dns_name}"
    zone_id                = "${var.lb_zone_id}"
    evaluate_target_health = true
  }
}
