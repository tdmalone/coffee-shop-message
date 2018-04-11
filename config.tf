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
  region  = "ap-southeast-2"
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
 * TODO: Set up API Gateway to give us a way in to the function.
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
