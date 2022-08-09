resource "aws_iam_role" "instance_iam_role" {
  name = "instance_iam_role"
  assume_role_policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "instance_profile" {
    name = "instance_profile"
    role = aws_iam_role.instance_iam_role.name
}


resource "aws_iam_role_policy" "src_bucket_access" {
  name = "src_bucket_access"
  role = aws_iam_role.instance_iam_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "s3:ListBucket"
        Resource = "arn:aws:s3:::${local.src_bucket}"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${local.src_bucket}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "dynamodb_access" {
  name = "dynamodb_access"
  role = aws_iam_role.instance_iam_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ScanAndPut"
        Effect = "Allow"
        Action = [
          "dynamodb:Get*",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:Delete*",
          "dynamodb:Update*",
          "dynamodb:PutItem"
        ]
        Resource = "${var.dynamodb_arn}"
        # Resource = "arn:aws:dynamodb:eu-central-1:348555763414:table/annotations"
      }
    ]
  })
}