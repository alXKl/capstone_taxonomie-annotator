resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow http traffic"
  vpc_id      = aws_vpc.cap_vpc.id

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http"
  }
}

resource "aws_instance" "cap_backend_server" {
  ami                         = "ami-0a1ee2fb28fe05df3"
  instance_type               = "t2.small"
  key_name                    = "ec2-key"
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups             = [aws_security_group.allow_http.id]
  associate_public_ip_address = true
  # iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  iam_instance_profile        = "${aws_iam_instance_profile.instance_profile.id}"
  user_data                   = file("userdata.sh")
  # user_data = <<EOF
  # #!/bin/bash
  # mkdir src
  # cd src
  # aws s3 cp s3://cap-backend-src-test/backend.zip backend.zip
  # unzip backend.zip
  # pip3 install -r requirements.txt
  # EOF

  tags = {
    Name = "cap-backend-server-test"
  }
}


