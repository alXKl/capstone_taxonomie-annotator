resource "aws_launch_configuration" "instance_config" {
  name_prefix           = "instance-launch-"
  image_id              = "ami-0c956e207f9d113d5"
  instance_type         = "t2.medium"
  key_name              = "ec2-key"
  security_groups       = [aws_security_group.instance_sg.id]
  iam_instance_profile  = "${aws_iam_instance_profile.instance_profile.id}"
  user_data = <<EOF
    #!/bin/bash
    cd /home/ec2-user
    mkdir src
    cd src
    aws s3 cp s3://${local.src_bucket}/backend.zip backend.zip
    unzip backend.zip
    pip3 install -r requirements.txt
    python3 main.py
  EOF

  # depends_on = [
  #   aws_s3_bucket_object.src
  # ]
}

resource "aws_autoscaling_group" "asg" {
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.instance_config.name
  vpc_zone_identifier  = "${var.vpc_public_subnets}"
}

resource "aws_lb" "lb" {
  name               = "lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = "${var.vpc_public_subnets}"
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.lb_certificate.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }
}

resource "aws_lb_listener" "lb_listener_rd" {
  load_balancer_arn = aws_lb.lb.arn
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

resource "aws_lb_target_group" "lb_tg" {
  name     = "target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"
}

resource "aws_autoscaling_attachment" "asg_attach" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  alb_target_group_arn   = aws_lb_target_group.lb_tg.arn
}

data "aws_acm_certificate" "lb_certificate" {
  domain      = "*.annotator-capstone.ml"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}