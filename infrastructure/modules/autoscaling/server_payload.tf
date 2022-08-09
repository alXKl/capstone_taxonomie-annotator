resource "aws_s3_bucket" "cap_backend_src" {
  bucket = "${local.src_bucket}"
  acl    = "private"
  tags = {
    Name = "cap-backend-src-bucket"
  }
}

resource "aws_s3_bucket_object" "src" {
  for_each = fileset("../backend/", "**/*.zip")

  bucket = "${local.src_bucket}"
  key    = each.value
  source = "../backend/${each.value}"
  etag   = filemd5("../backend/${each.value}")
}