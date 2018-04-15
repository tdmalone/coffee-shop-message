/**
 * Defines a small amount of outputs which are useful for quick user access.
 * To utilise, run eg. `terraform output sns_topic_dev_arn`.
 *
 * @author Tim Malone <tdmalone@gmail.com>
 * @see https://www.terraform.io/docs/configuration/outputs.html
 */

/**
 * Utilised in ./README.md for a quick way to subscribe to the dev SNS topic and in ../.travis.yml
 * for running integration tests.
 */
output "sns_topic_dev" {
  value = "${aws_sns_topic.sns_topic_dev.arn}"
}

/**
 * The following are utilised in ./README.md's instructions.
 */

output "api_invoke_url_dev" {
  value = "${aws_api_gateway_deployment.dev.invoke_url}${var.dev_stage_alias_name}/${var.rest_api_path}"
}

output "api_invoke_url_prod" {
  value = "${aws_api_gateway_deployment.prod.invoke_url}${var.prod_stage_alias_name}/${var.rest_api_path}"
}

output "api_key" {
  value = "${aws_api_gateway_api_key.default.value}"
}

output "access_key_id" {
  value = "${aws_iam_access_key.travis_user.id}"
}

output "secret_access_key" {
  value = "${aws_iam_access_key.travis_user.secret}"
}

/**
 * The following are utilised in ../.travis.yml so we don't have to redefine the variables again.
 */

output "function_name" {
  value = "${var.function_name}"
}

output "function_description" {
  value = "${var.function_description}"
}

output "function_timeout" {
  value = "${var.function_timeout}"
}

output "function_role" {
  value = "${aws_iam_role.role.arn}"
}

output "function_alias" {
  value = "${var.prod_stage_alias_name}"
}

output "function_runtime" {
  value = "${var.function_runtime}"
}

output "function_module" {
  value = "${var.function_module}"
}

output "function_handler" {
  value = "${var.function_handler}"
}
