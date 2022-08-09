# http://www.annotator-capstone.ml.s3-website.eu-central-1.amazonaws.com

resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "${local.frontend_bucket}"
  acl    = "public-read"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AddPerm"
        Effect = "Allow"
        Action = ["s3:GetObject"],
        Resource = "arn:aws:s3:::${local.frontend_bucket}/*"
      }
    ]
  })

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_object" "html" {
  for_each = fileset("../frontend/", "**/*.html")

  bucket = aws_s3_bucket.frontend_bucket.bucket
  key    = each.value
  source = "../frontend/${each.value}"
  etag   = filemd5("../frontend/${each.value}")
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "css" {
  for_each = fileset("../frontend/", "**/*.css")

  bucket = aws_s3_bucket.frontend_bucket.bucket
  key    = each.value
  source = "../frontend/${each.value}"
  etag   = filemd5("../frontend/${each.value}")
  content_type = "text/css"
}

resource "aws_s3_bucket_object" "js" {
  for_each = fileset("../frontend/", "**/*.js")

  bucket = aws_s3_bucket.frontend_bucket.bucket
  key    = each.value
  source = "../frontend/${each.value}"
  etag   = filemd5("../frontend/${each.value}")
  content_type = "application/javascript"
}