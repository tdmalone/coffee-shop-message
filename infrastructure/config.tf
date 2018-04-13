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
