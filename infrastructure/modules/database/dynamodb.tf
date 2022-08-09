resource "aws_dynamodb_table" "annotations_table" {
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

resource "aws_dynamodb_table_item" "fill_items" {
  for_each    = ["${local.tf_data}"]
  table_name  = aws_dynamodb_table.annotations_table.name
  hash_key    = aws_dynamodb_table.annotations_table.hash_key
  range_key   = aws_dynamodb_table.annotations_table.range_key
  item = jsonencode(each.value)
}

