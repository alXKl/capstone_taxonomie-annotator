locals {
  json_data  = file("./modules/database/initial_items.json")
  tf_data    = jsondecode(local.json_data)
}