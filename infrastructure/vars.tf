/**
 * Variables for Terraform infrastructure configuration.
 *
 * TODO: Add descriptions to many of these variables to assist with usage.
 *
 * @author Tim Malone <tdmalone@gmail.com>
 * @see https://www.terraform.io/intro/getting-started/variables.html
 */

variable "aws_region" {
  default = "ap-southeast-2"
}

variable "api_name" {
  default = "coffee-shop-message"
}

variable "function_name" {
  default = "coffee-shop-message"
}

variable "function_description" {
  default = "Sends Slack and SNS messages when The Good Food Collective is closing for the day."
}

variable "function_handler" {
  default = "index.handler"
}

variable "function_runtime" {
  default = "nodejs6.10"
}

variable "function_timeout" {
  default = "15"
}

variable "sns_queue_name_dev" {
  default = "coffee-shop-message-dev"
}

variable "sns_queue_name_prod" {
  default = "coffee-shop-message-prod"
}

variable "sns_queue_display_name_prod" {
  default = "GFC Coffee"
}

variable "rest_api_path" {
  default = "coffee"
}

/**
 * The following variables should be set elsewhere for security reasons, eg. on the command line,
 * in a .tfvars file, or as environment variables.
 *
 * For example:
 * $ export TF_VAR_slack_hook_dev="TXXXXXXXX/BXXXXXXXX/xxxxxxxxxxxxxxxxxxxxxxxx"
 * $ export TF_VAR_slack_hook_prod="TXXXXXXXX/BXXXXXXXX/xxxxxxxxxxxxxxxxxxxxxxxx"
 *
 * @see https://www.terraform.io/intro/getting-started/variables.html#assigning-variables
 */

variable "slack_hook_dev" {}
variable "slack_hook_prod" {}

/**
 * The following stage variables are used to refer both to the API stages and to the Lambda aliases
 * that are matched with them.
 *
 * WARNING: These aliases are also referred within the function code, where the environment variable
 *          to use is chosen depending on the alias the function was invoked with. The environment
 *          variable names themselves, therefore, are also partially dependent on these values.
 */

variable "dev_stage_alias_name" {
  default = "dev"
}

variable "prod_stage_alias_name" {
  default = "prod"
}
