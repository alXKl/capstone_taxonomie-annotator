resource "aws_dynamodb_table" "annotations" {
  name           = "annotations"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "x"
  range_key      = "y"

  attribute {
    name = "x"
    type = "S"
  }

  attribute {
    name = "y"
    type = "S"
  }

}