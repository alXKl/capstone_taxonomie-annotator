
variable "www_domain_name" {
  default = "www.annotator-capstone.ml"
}

variable "root_domain_name" {
  default = "annotator-capstone.ml"
}

variable "backend_src" {
  default = "cap-backend-src-bucket"
}

# variable "cfd_certificate" {
#   default = "arn:aws:acm:us-east-1:348555763414:certificate/963e4ab2-1fb9-4b68-b9d9-a13a7c772970"
# }

# variable "lb_certificate" {
#   default = "arn:aws:acm:eu-central-1:348555763414:certificate/c014867f-a8a0-4ea9-885f-a811c2c6ee01"
# }