/**
 * Configures AWS infrastructure for running the coffee-shop-message function.
 * To use, download Terraform and run `terraform init` followed by `terraform apply`.
 *
 * To set variables, edit ./vars.tf.
 *
 * @author Tim Malone <tdmalone@gmail.com>
 */

/**
 * AWS provider configuration, with version constraints.
 * Credentials are taken from the usual AWS environment variables.
 *
 * @see https://www.terraform.io/docs/providers/aws/index.html
 * @see https://www.terraform.io/docs/configuration/providers.html#provider-versions
 */
provider "aws" {
  region  = "${var.aws_region}"
  version = "~> 1.14"
}

/**
 * IAM role for the Lambda function.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/iam_role.html
 */
resource "aws_iam_role" "role" {
  name = "${var.role_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

/**
 * IAM policy to allow the Lambda function to write logs, and publish to our SNS topics.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/iam_role_policy.html
 */
resource "aws_iam_role_policy" "policy" {
  name = "${var.policy_name}"
  role = "${aws_iam_role.role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "sns:Publish"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_sns_topic.sns_topic_dev.arn}",
        "${aws_sns_topic.sns_topic_prod.arn}"
      ]
    }
  ]
}
EOF
}

/**
 * Define the Lambda function.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/lambda_function.html
 */
resource "aws_lambda_function" "function" {
  function_name = "${var.function_name}"
  description   = "${var.function_description}"
  role          = "${aws_iam_role.role.arn}"
  handler       = "${var.function_handler}"
  runtime       = "${var.function_runtime}"
  timeout       = "${var.function_timeout}"

  environment {
    variables = {
      SLACK_HOOK_DEV  = "${var.slack_hook_dev}"
      SLACK_HOOK_PROD = "${var.slack_hook_prod}"
      SNS_TOPIC_DEV   = "${aws_sns_topic.sns_topic_dev.arn}"
      SNS_TOPIC_PROD  = "${aws_sns_topic.sns_topic_prod.arn}"
    }
  }
}

/**
 * TODO: Add function aliases (and maybe a couple of other resources too?)
 */

/**
 * SNS topic for development purposes.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/sns_topic.html
 */
resource "aws_sns_topic" "sns_topic_dev" {
  name = "${var.sns_queue_name_dev}"
}

/**
 * SNS topic for customers subscriptions (prod).
 *
 * @see https://www.terraform.io/docs/providers/aws/r/sns_topic.html
 */
resource "aws_sns_topic" "sns_topic_prod" {
  name         = "${var.sns_queue_name_prod}"
  display_name = "${var.sns_queue_display_name_prod}"
}

/**
 * Main endpoint for the API into the function.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/api_gateway_resource.html
 */
resource "aws_api_gateway_resource" "main_endpoint" {
  rest_api_id = "${var.rest_api_id}"
  parent_id   = "${var.rest_api_parent_path_id}"
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
  rest_api_id = "${var.rest_api_id}"
  parent_id   = "${aws_api_gateway_resource.main_endpoint.id}"
  path_part   = "{proxy+}"
}

/**
 * Endpoint method.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/api_gateway_method.html
 */
resource "aws_api_gateway_method" "method" {
  rest_api_id   = "${var.rest_api_id}"
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
  rest_api_id             = "${var.rest_api_id}"
  resource_id             = "${aws_api_gateway_resource.proxy_endpoint.id}"
  http_method             = "${aws_api_gateway_method.method.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.function.arn}:$${stageVariables.lambdaAlias}/invocations"
}

/**
 * Add Lambda execution perms for the API Gateway integration (for the dev stage -> dev alias).
 *
 * TODO: Although this seems to work, it might need the source_arn property defined as well, because
 *       at the moment Terraform is trying to re-create it on each apply.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/lambda_permission.html
 */
resource "aws_lambda_permission" "permission_dev_stage" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.function.arn}:${var.dev_stage_alias_name}"
  principal     = "apigateway.amazonaws.com"
}

/**
 * Add Lambda execution perms for the API Gateway integration (for the prod stage -> prod alias).
 *
 * TODO: Although this seems to work, it might need the source_arn property defined as well, because
 *       at the moment Terraform is trying to re-create it on each apply.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/lambda_permission.html
 */
resource "aws_lambda_permission" "permission_prod_stage" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.function.arn}:${var.prod_stage_alias_name}"
  principal     = "apigateway.amazonaws.com"
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
  rest_api_id = "${var.rest_api_id}"
  resource_id = "${aws_api_gateway_resource.proxy_endpoint.id}"
  http_method = "${aws_api_gateway_method.method.http_method}"
  status_code = 200

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
  rest_api_id = "${var.rest_api_id}"
  resource_id = "${aws_api_gateway_resource.proxy_endpoint.id}"
  http_method = "${aws_api_gateway_method.method.http_method}"
  status_code = "${aws_api_gateway_integration_response.integration_response.status_code}"

  response_models = {
    "application/json" = "Empty"
  }
}

/**
 * TODO: Consider also adding...
 *       - aws_api_gateway_rest_api?
 *       - aws_api_gateway_stage?
 *       - aws_api_gateway_deployment?
 */

