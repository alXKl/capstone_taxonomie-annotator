# http://www.annotator-capstone.ml.s3-website.eu-central-1.amazonaws.com

resource "aws_s3_bucket" "cap_frontend_bucket" {
  bucket = "${var.www_domain_name}"
  acl    = "public-read"
  policy = <<POLICY
  {
    "Version":"2012-10-17",
    "Statement":[
      {
        "Sid":"AddPerm",
        "Effect":"Allow",
        "Principal": "*",
        "Action":["s3:GetObject"],
        "Resource":["arn:aws:s3:::${var.www_domain_name}/*"]
      }
    ]
  }
  POLICY

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_object" "html" {
  for_each = fileset("../frontend/", "**/*.html")

  bucket = aws_s3_bucket.cap_frontend_bucket.bucket
  key    = each.value
  source = "../frontend/${each.value}"
  etag   = filemd5("../frontend/${each.value}")
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "css" {
  for_each = fileset("../frontend/", "**/*.css")

  bucket = aws_s3_bucket.cap_frontend_bucket.bucket
  key    = each.value
  source = "../frontend/${each.value}"
  etag   = filemd5("../frontend/${each.value}")
  content_type = "text/css"
}

resource "aws_s3_bucket_object" "js" {
  for_each = fileset("../frontend/", "**/*.js")

  bucket = aws_s3_bucket.cap_frontend_bucket.bucket
  key    = each.value
  source = "../frontend/${each.value}"
  etag   = filemd5("../frontend/${each.value}")
  content_type = "application/javascript"
}




#------------------------------------- S3 second version ------------------------------------------

# resource "aws_s3_bucket" "mybucket" {
#   bucket = "capstone-frontend-bucket"
#   acl    = "public-read" #"private"
#   # Add specefic S3 policy in the s3-policy.json on the same directory
#   policy = file("s3-policy.json")

#   versioning {
#     enabled = false
#   }

#   website {
#     index_document = "index.html"
#     error_document = "error.html"
	
# 	# Add routing rules if required
#     #routing_rules = <<EOF
#     #                [{
#     #                    "Condition": {
#     #                        "KeyPrefixEquals": "docs/"
#     #                    },
#     #                    "Redirect": {
#     #                        "ReplaceKeyPrefixWith": "documents/"
#     #                    }
#     #                }]
#     #                EOF
#   }

#   tags = {
#     Environment = "development"
#     Name        = "my-tag"
#   }

# }


# #Upload files of your static website
# resource "aws_s3_bucket_object" "html" {
#   for_each = fileset("../frontend/", "**/*.html")

#   bucket = aws_s3_bucket.mybucket.bucket
#   key    = each.value
#   source = "../frontend/${each.value}"
#   etag   = filemd5("../frontend/${each.value}")
#   content_type = "text/html"
# }

# resource "aws_s3_bucket_object" "css" {
#   for_each = fileset("../frontend/", "**/*.css")

#   bucket = aws_s3_bucket.mybucket.bucket
#   key    = each.value
#   source = "../frontend/${each.value}"
#   etag   = filemd5("../frontend/${each.value}")
#   content_type = "text/css"
# }

# resource "aws_s3_bucket_object" "js" {
#   for_each = fileset("../frontend/", "**/*.js")

#   bucket = aws_s3_bucket.mybucket.bucket
#   key    = each.value
#   source = "../frontend/${each.value}"
#   etag   = filemd5("../frontend/${each.value}")
#   content_type = "application/javascript"
# }

# # resource "aws_s3_bucket_object" "json" {
# #   for_each = fileset("../../mywebsite/", "**/*.json")

# #   bucket = aws_s3_bucket.mybucket.bucket
# #   key    = each.value
# #   source = "../../mywebsite/${each.value}"
# #   etag   = filemd5("../../mywebsite/${each.value}")
# #   content_type = "application/json"
# # }


# # Add more aws_s3_bucket_object for the type of files you want to upload
# # The reason for having multiple aws_s3_bucket_object with file type is to make sure
# # we add the correct content_type for the file in S3. Otherwise website load may have issues

# # Print the files processed so far
# output "fileset-results" {
#   value = fileset("../frontend/", "**/*")
# }

# locals {
#   s3_origin_id = "capstone-frontend-bucket"
# }
