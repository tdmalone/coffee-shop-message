/**
 * Variables for Terraform infrastructure configuration.
 *
 * TODO: Some of these variables are defined twice - both here and in .travis.yml. Is it possible
 *       to read and use these from Travis, somehow? An alternative would be to deploy to Lambda
 *       using Terraform instead, if state was also stored remotely.
 *
 * @author Tim Malone <tdmalone@gmail.com>
 * @see https://www.terraform.io/intro/getting-started/variables.html
 */

variable "role_name" {
  default = "coffeeShopMessageLambdaRole"
}

variable "policy_name" {
  default = "coffeeShopMessageLambdaPolicy"
}

variable "function_name" {
  default = "coffeeShopMessage"
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
  default = "tim-dev-queue"
}

variable "sns_queue_name_prod" {
  default = "coffee-shop-message"
}

variable "sns_queue_display_name_prod" {
  default = "GFC Coffee"
}

/**
 * The following variables should be set elsewhere for security reasons, eg. on the command line,
 * in a .tfvars file, or as environment variables.
 *
 * @see https://www.terraform.io/intro/getting-started/variables.html#assigning-variables
 */

variable "slack_hook_dev" {}
variable "slack_hook_prod" {}
