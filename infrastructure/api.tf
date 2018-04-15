/**
 * Configures AWS infrastructure for an API Gateway API for invoking our Lambda function.
 *
 * @author Tim Malone <tdmalone@gmail.com>
 */

/**
 * Create the API itself.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/api_gateway_rest_api.html
 */
resource "aws_api_gateway_rest_api" "api" {
  name = "${var.api_name}"
}

/**
 * API stages, to separate dev/testing and production.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/api_gateway_stage.html
 */
resource "aws_api_gateway_stage" "dev" {
  stage_name    = "${var.dev_stage_alias_name}"
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  deployment_id = "${aws_api_gateway_deployment.dev.id}"

  variables = {
    lambdaAlias = "${var.dev_stage_alias_name}"
  }
}

resource "aws_api_gateway_stage" "prod" {
  stage_name    = "${var.prod_stage_alias_name}"
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  deployment_id = "${aws_api_gateway_deployment.prod.id}"

  variables = {
    lambdaAlias = "${var.prod_stage_alias_name}"
  }
}

/**
 * Switch on logging for the dev and prod stages.
 * As Terraform's AWS provider does not support this yet, we use a workaround.
 *
 * TODO: Need to add normal CloudWatch logs + metrics options to this too.
 *
 * @see https://github.com/terraform-providers/terraform-provider-aws/issues/2406#issuecomment-347645154
 * @see https://www.terraform.io/docs/provisioners/null_resource.html
 * @see https://www.terraform.io/docs/provisioners/local-exec.html
 * @see https://www.terraform.io/docs/providers/aws/r/cloudwatch_log_group.html
 */
resource "null_resource" "logging" {
  depends_on = ["aws_cloudwatch_log_group.default"]

  triggers {
    log_group = "${aws_cloudwatch_log_group.default.arn}"
  }

  provisioner "local-exec" {
    command = "aws apigateway update-stage --rest-api-id ${aws_api_gateway_deployment.dev.rest_api_id} --stage-name ${var.dev_stage_alias_name} --patch-operations op=replace,path=/accessLogSettings/destinationArn,value=${replace(aws_cloudwatch_log_group.default.arn, ":*", "")}"
  }

  provisioner "local-exec" {
    command = "aws apigateway update-stage --rest-api-id ${aws_api_gateway_deployment.dev.rest_api_id} --stage-name ${var.dev_stage_alias_name} --patch-operations 'op=replace,path=/accessLogSettings/format,value=${jsonencode("$context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength $context.requestId")}'"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "aws apigateway update-stage --rest-api-id ${aws_api_gateway_deployment.dev.rest_api_id} --stage-name ${var.dev_stage_alias_name} --patch-operations op=remove,path=/accessLogSettings,value="
  }
}

resource "aws_cloudwatch_log_group" "default" {
  retention_in_days = 7
}

/**
 * Deployments to get each stage started.
 *
 * Due to AWS API documentation confusion, the stage_name is intentionally blank here.
 * https://github.com/terraform-providers/terraform-provider-aws/issues/2918#issuecomment-356684239
 *
 * @see https://www.terraform.io/docs/providers/aws/r/api_gateway_deployment.html
 */
resource "aws_api_gateway_deployment" "dev" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = ""
  depends_on  = ["aws_api_gateway_integration.integration"]
}

resource "aws_api_gateway_deployment" "prod" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = ""
  depends_on  = ["aws_api_gateway_integration.integration"]
}

/**
 * Main endpoint for the API into the function.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/api_gateway_resource.html
 */
resource "aws_api_gateway_resource" "main_endpoint" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part   = "${var.rest_api_path}"
}

/**
 * Proxy endpoint, sitting under the main endpoint.
 *
 * This is so we can call eg. /closing/soon without having to define every path at the API level.
 * We can instead perform our 'routing' logic inside the function itself.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/api_gateway_resource.html
 */
resource "aws_api_gateway_resource" "proxy_endpoint" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id   = "${aws_api_gateway_resource.main_endpoint.id}"
  path_part   = "{proxy+}"
}

/**
 * Default endpoint HTTP method for calling.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/api_gateway_method.html
 */
resource "aws_api_gateway_method" "method" {
  rest_api_id      = "${aws_api_gateway_rest_api.api.id}"
  resource_id      = "${aws_api_gateway_resource.proxy_endpoint.id}"
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

/**
 * API Gateway Lambda proxy integration, supporting a stage variable so the appropriate function
 * alias can be called depending on the API stage.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/api_gateway_integration.html
 * @see https://github.com/hashicorp/terraform/issues/6463#issuecomment-293010256
 */
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api.id}"
  resource_id             = "${aws_api_gateway_resource.proxy_endpoint.id}"
  http_method             = "${aws_api_gateway_method.method.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.function.arn}:$${stageVariables.lambdaAlias}/invocations"
}

/**
 * Integration response.
 *
 * The need for this is a little confusing because API Gateway states it does not support
 * integration responses for Lambda proxy integrations. However, you still need to define it for the
 * method response to be set up properly.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/api_gateway_integration_response.html
 * @see https://github.com/hashicorp/terraform/issues/10157
 */
resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.proxy_endpoint.id}"
  http_method = "${aws_api_gateway_method.method.http_method}"
  status_code = 200
  depends_on  = ["aws_api_gateway_integration.integration"]

  response_templates = {
    "application/json" = ""
  }
}

/**
 * Method response.
 *
 * This resource type is not fully documented at the Terraform website, and its setup for a Lambda
 * proxy integration is a little confusing, but there's help available through the issue at
 * https://github.com/hashicorp/terraform/issues/10157.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/api_gateway_method_response.html
 */
resource "aws_api_gateway_method_response" "method_response" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.proxy_endpoint.id}"
  http_method = "${aws_api_gateway_method.method.http_method}"
  status_code = "${aws_api_gateway_integration_response.integration_response.status_code}"

  response_models = {
    "application/json" = "Empty"
  }
}

/**
 * API key and usage plans.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/api_gateway_api_key.html
 * @see https://www.terraform.io/docs/providers/aws/r/api_gateway_usage_plan.html
 * @see https://www.terraform.io/docs/providers/aws/r/api_gateway_usage_plan_key.html
 */
resource "aws_api_gateway_api_key" "default" {
  name = "coffee-shop-message-default"
}

resource "aws_api_gateway_usage_plan" "default" {
  name = "coffee-shop-message-default"

  api_stages {
    api_id = "${aws_api_gateway_rest_api.api.id}"
    stage  = "${var.dev_stage_alias_name}"
  }

  api_stages {
    api_id = "${aws_api_gateway_rest_api.api.id}"
    stage  = "${var.prod_stage_alias_name}"
  }

  quota_settings {
    limit  = "${var.quota_per_day}"
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 5
    rate_limit  = "${var.throttle_per_second}"
  }
}

resource "aws_api_gateway_usage_plan_key" "default" {
  key_id        = "${aws_api_gateway_api_key.default.id}"
  key_type      = "API_KEY"
  usage_plan_id = "${aws_api_gateway_usage_plan.default.id}"
}
