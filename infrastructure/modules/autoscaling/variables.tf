variable "vpc_id" {
  type = string 
}

variable "vpc_public_subnets" {
  type = list 
}

variable "dynamodb_arn" {
  type = string
}