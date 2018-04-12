/**
 * Variables for Terraform infrastructure configuration.
 *
 * TODO: Some of these variables are defined twice - both here and in .travis.yml. Is it possible
 *       to read and use these from Travis, somehow? Even by turning this into JSON and
 *       programmatically pull from it? An alternative would be to deploy to Lambda using Terraform
 *       instead (if state was also stored remotely).
 *
 * @author Tim Malone <tdmalone@gmail.com>
 * @see https://www.terraform.io/intro/getting-started/variables.html
 */

variable "aws_region" {
  default = "ap-southeast-2"
}

variable "aws_account_id" {
  default = "873114526714"
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

variable "rest_api_path" {
  default = "coffee-test"
}

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

/**
 * Alternatively, the following hardcoding of an existing API could be removed and the API defined
 * from scratch in Terraform instead.
 */
variable "rest_api_id" {
  default = "78qkh1lhph"
}

variable "rest_api_parent_path_id" {
  default = "ignbcbt303"
}

/**
 * Alternatively, the following variables could be cut and the use of them in ./config.tf ommited,
 * so that they can be generated randomly.
 */
variable "role_name" {
  default = "coffeeShopMessageLambdaRole"
}

variable "policy_name" {
  default = "coffeeShopMessageLambdaPolicy"
}

/**
 * The following variables should be set elsewhere for security reasons, eg. on the command line,
 * in a .tfvars file, or as environment variables.
 *
 * @see https://www.terraform.io/intro/getting-started/variables.html#assigning-variables
 */

variable "slack_hook_dev" {}
variable "slack_hook_prod" {}
