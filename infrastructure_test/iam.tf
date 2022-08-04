resource "aws_iam_role" "instance_iam_role" {
    name = "instance_iam_role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "instance_profile" {
    name = "instance_profile"
    role = aws_iam_role.instance_iam_role.name
}

resource "aws_iam_role_policy" "instance_iam_role_policy" {
  name = "instance_iam_role_policy"
  role = "${aws_iam_role.instance_iam_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::cap-backend-src-test"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::cap-backend-src-test/*"]
    }
  ]
}
EOF
}