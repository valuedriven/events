variable "create_order_lambda_arn" {}
variable "create_order_lambda_name" {}

resource "aws_apigatewayv2_api" "order_api" {
  name          = "order-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "create_order" {
  api_id           = aws_apigatewayv2_api.order_api.id
  integration_type = "AWS_PROXY"

  integration_uri    = var.create_order_lambda_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "create_order" {
  api_id    = aws_apigatewayv2_api.order_api.id
  route_key = "POST /orders"
  target    = "integrations/${aws_apigatewayv2_integration.create_order.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.order_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_create_order" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.create_order_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.order_api.execution_arn}/*/*"
}

output "api_endpoint" {
  value = aws_apigatewayv2_api.order_api.api_endpoint
}
