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
resource "aws_api_gateway_stage" "stage_dev" {
  stage_name    = "${var.dev_stage_alias_name}"
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  deployment_id = "${aws_api_gateway_deployment.api_deployment_dev.id}"

  variables = {
    lambdaAlias = "${var.dev_stage_alias_name}"
  }
}

resource "aws_api_gateway_stage" "stage_prod" {
  stage_name    = "${var.prod_stage_alias_name}"
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  deployment_id = "${aws_api_gateway_deployment.api_deployment_prod.id}"

  variables = {
    lambdaAlias = "${var.prod_stage_alias_name}"
  }
}

/**
 * TODO: Switch on logging for the dev and prod stages.
 *       As Terraform's AWS provider does not support this yet, we may need a workaround:
 *       @see https://github.com/terraform-providers/terraform-provider-aws/issues/2406#issuecomment-347645154
 */

/**
 * Deployments to get each stage started.
 *
 * Due to AWS API documentation confusion, the stage_name is intentionally blank here.
 * https://github.com/terraform-providers/terraform-provider-aws/issues/2918#issuecomment-356684239
 *
 * @see https://www.terraform.io/docs/providers/aws/r/api_gateway_deployment.html
 */
resource "aws_api_gateway_deployment" "api_deployment_dev" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = ""
  depends_on  = ["aws_api_gateway_integration.integration"]
}

resource "aws_api_gateway_deployment" "api_deployment_prod" {
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
 * TODO: Configure an API key for this method.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/api_gateway_method.html
 */
resource "aws_api_gateway_method" "method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.proxy_endpoint.id}"
  http_method   = "POST"
  authorization = "NONE"
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
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.function.arn}:$${stageVariables.lambdaAlias}/invocations"
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
