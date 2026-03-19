variable "project_name" {
  type    = string
  default = "event-driven-arch"
}

resource "aws_dynamodb_table" "order" {
  name           = "Order"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "order_id"

  attribute {
    name = "order_id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "billing" {
  name           = "Billing"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "billing_id"

  attribute {
    name = "billing_id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "inventory" {
  name           = "Inventory"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "reservation_id"

  attribute {
    name = "reservation_id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "shipping" {
  name           = "Shipping"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "tracking_number"

  attribute {
    name = "tracking_number"
    type = "S"
  }
}

output "order_table_name" {
  value = aws_dynamodb_table.order.name
}

output "billing_table_name" {
  value = aws_dynamodb_table.billing.name
}

output "inventory_table_name" {
  value = aws_dynamodb_table.inventory.name
}

output "shipping_table_name" {
  value = aws_dynamodb_table.shipping.name
}
