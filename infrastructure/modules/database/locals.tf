locals {
  json_data  = file("./initial_items.json")
  tf_data    = jsondecode(local.json_data)
}