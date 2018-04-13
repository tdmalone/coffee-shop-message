/**
 * Configures AWS SNS resources used by the coffee-shop-message function.
 *
 * @author Tim Malone <tdmalone@gmail.com>
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
