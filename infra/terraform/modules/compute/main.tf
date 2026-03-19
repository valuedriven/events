variable "order_table_name" {}
variable "billing_table_name" {}
variable "inventory_table_name" {}
variable "shipping_table_name" {}
variable "orders_topic_arn" {}
variable "billing_queue_arn" {}
variable "inventory_queue_arn" {}
variable "shipping_queue_arn" {}

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# -------------------------------------------------------------------------
# CreateOrder Lambda
# -------------------------------------------------------------------------
data "archive_file" "create_order_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../src/createOrder"
  output_path = "${path.root}/../src/createOrder.zip"
}

resource "aws_lambda_function" "create_order" {
  function_name    = "createOrder"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.create_order_zip.output_path
  source_code_hash = data.archive_file.create_order_zip.output_base64sha256

  environment {
    variables = {
      ORDER_TABLE   = var.order_table_name
      SNS_TOPIC_ARN = var.orders_topic_arn
    }
  }
}

# -------------------------------------------------------------------------
# BillingRegister Lambda
# -------------------------------------------------------------------------
data "archive_file" "billing_register_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../src/billingRegister"
  output_path = "${path.root}/../src/billingRegister.zip"
}

resource "aws_lambda_function" "billing_register" {
  function_name    = "billingRegister"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.billing_register_zip.output_path
  source_code_hash = data.archive_file.billing_register_zip.output_base64sha256

  environment {
    variables = {
      BILLING_TABLE = var.billing_table_name
    }
  }
}

resource "aws_lambda_event_source_mapping" "billing_sqs" {
  event_source_arn = var.billing_queue_arn
  function_name    = aws_lambda_function.billing_register.arn
  batch_size       = 10
}

# -------------------------------------------------------------------------
# InventoryRegister Lambda
# -------------------------------------------------------------------------
data "archive_file" "inventory_register_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../src/inventoryRegister"
  output_path = "${path.root}/../src/inventoryRegister.zip"
}

resource "aws_lambda_function" "inventory_register" {
  function_name    = "inventoryRegister"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.inventory_register_zip.output_path
  source_code_hash = data.archive_file.inventory_register_zip.output_base64sha256

  environment {
    variables = {
      INVENTORY_TABLE = var.inventory_table_name
    }
  }
}

resource "aws_lambda_event_source_mapping" "inventory_sqs" {
  event_source_arn = var.inventory_queue_arn
  function_name    = aws_lambda_function.inventory_register.arn
  batch_size       = 10
}

# -------------------------------------------------------------------------
# ShippingRegister Lambda
# -------------------------------------------------------------------------
data "archive_file" "shipping_register_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../src/shippingRegister"
  output_path = "${path.root}/../src/shippingRegister.zip"
}

resource "aws_lambda_function" "shipping_register" {
  function_name    = "shippingRegister"
  role             = data.aws_iam_role.lab_role.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.shipping_register_zip.output_path
  source_code_hash = data.archive_file.shipping_register_zip.output_base64sha256

  environment {
    variables = {
      SHIPPING_TABLE = var.shipping_table_name
    }
  }
}

resource "aws_lambda_event_source_mapping" "shipping_sqs" {
  event_source_arn = var.shipping_queue_arn
  function_name    = aws_lambda_function.shipping_register.arn
  batch_size       = 10
}

# Outputs
output "create_order_lambda_arn" {
  value = aws_lambda_function.create_order.arn
}
output "create_order_lambda_name" {
  value = aws_lambda_function.create_order.function_name
}
