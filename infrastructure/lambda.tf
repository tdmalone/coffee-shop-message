/**
 * Configures AWS infrastructure for a Lambda function to run coffee-shop-message.
 *
 * @author Tim Malone <tdmalone@gmail.com>
 */

/**
 * Define the Lambda function itself.
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
  publish       = true
  filename      = "../function.zip"             # Created by running `yarn bootstrap`.

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
 * Lambda aliases, to allow us to test changes without modifying the production version.
 * These will be mapped to API stages by ./api.tf.
 *
 * Subsequent deployments should be managed through Travis CI, as our configuration for that will
 * deploy and link new versions as appropriate.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/lambda_alias.html
 */
resource "aws_lambda_alias" "alias_dev" {
  name             = "${var.dev_stage_alias_name}"
  function_name    = "${aws_lambda_function.function.arn}"
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "alias_prod" {
  name             = "${var.prod_stage_alias_name}"
  function_name    = "${aws_lambda_function.function.arn}"
  function_version = "${aws_lambda_function.function.version}"
}

/**
 * IAM role for the Lambda function.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/iam_role.html
 */
resource "aws_iam_role" "role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
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
  role = "${aws_iam_role.role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "sns:Publish",
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
 * Lambda execution perms for the API Gateway integration (for the dev stage -> dev alias and prod
 * stage -> prod alias).
 *
 * TODO: Although these seem to work, they might need the `source_arn` property defined as well,
 *       because at the moment Terraform is trying to re-create them each time it is run.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/lambda_permission.html
 */
resource "aws_lambda_permission" "permission_dev_stage" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.function.arn}:${var.dev_stage_alias_name}"
  principal     = "apigateway.amazonaws.com"
  depends_on    = ["aws_lambda_alias.alias_dev"]
}

resource "aws_lambda_permission" "permission_prod_stage" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.function.arn}:${var.prod_stage_alias_name}"
  principal     = "apigateway.amazonaws.com"
  depends_on    = ["aws_lambda_alias.alias_prod"]
}
