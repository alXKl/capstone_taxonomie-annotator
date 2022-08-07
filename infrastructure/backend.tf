module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name = "main-vpc"
  cidr = "10.0.0.0/16"

  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_launch_configuration" "cap_instance" {
  name_prefix           = "cap-instance-launch-"
  image_id              = "ami-0c956e207f9d113d5"
  instance_type         = "t2.small"
  key_name              = "ec2-key"
  security_groups       = [aws_security_group.cap_instance_sg.id]
  iam_instance_profile  = "${aws_iam_instance_profile.instance_profile.id}"
  user_data = <<EOF
    #!/bin/bash
    cd /home/ec2-user
    mkdir src
    cd src
    aws s3 cp s3://cap-backend-src-bucket/backend.zip backend.zip
    unzip backend.zip
    pip3 install -r requirements.txt
    python3 main.py
  EOF

  # depends_on = [
  #   aws_s3_bucket_object.src
  # ]
}

resource "aws_autoscaling_group" "cap_asg" {
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.cap_instance.name
  vpc_zone_identifier  = module.vpc.public_subnets
}

resource "aws_lb" "cap_lb" {
  name               = "cap-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.cap_lb_sg.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_listener" "cap_lb_listener" {
  load_balancer_arn = aws_lb.cap_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:eu-central-1:348555763414:certificate/c014867f-a8a0-4ea9-885f-a811c2c6ee01"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cap_tg.arn
  }
}

resource "aws_lb_listener" "cap_lb_listener_rd" {
  load_balancer_arn = aws_lb.cap_lb.arn
  port              = "8080"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "cap_tg" {
  name     = "cap-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_autoscaling_attachment" "cap_asg_attach" {
  autoscaling_group_name = aws_autoscaling_group.cap_asg.id
  alb_target_group_arn   = aws_lb_target_group.cap_tg.arn
}

resource "aws_security_group" "cap_instance_sg" {
  name = "cap-instance-sg"
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.cap_lb_sg.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.cap_lb_sg.id]
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "cap_lb_sg" {
  name = "cap-lb-sg"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = module.vpc.vpc_id
}

