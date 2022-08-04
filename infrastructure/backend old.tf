# resource "aws_security_group" "allow_http" {
#   name        = "allow_http"
#   description = "Allow http traffic"
#   vpc_id      = aws_vpc.cap-vpc.id

#   ingress {
#     description = "ssh"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "http"
#     from_port   = 8080
#     to_port     = 8080
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "allow_http"
#   }
# }

# resource "aws_instance" "backend_server" {
#   ami                         = "ami-0a1ee2fb28fe05df3"
#   instance_type               = "t2.small"
#   key_name                    = "ec2-key"
#   subnet_id                   = aws_subnet.public_subnet.id
#   security_groups             = [aws_security_group.allow_http.id]
#   associate_public_ip_address = true
#   # user_data                   = file("userdata.sh")
#   tags = {
#     Name = "cap-backend-server"
#   }
# }

# resource "aws_eip" "eip" {
#   instance = aws_instance.backend_server.id
#   vpc      = true
# }