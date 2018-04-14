/**
 * Defines IAM resources both to enable Terraform to be run in Travis CI from a read-only
 * perspective, and to enable Travis CI to perform tests and deployments.
 *
 * @author Tim Malone <tdmalone@gmail.com>
 */

/**
 * Create the IAM user that we'll use within Travis.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/iam_user.html
 */
resource "aws_iam_user" "travis_user" {
  name = "travis-ci-coffee-shop-message"
}

/**
 * As we'll be testing the function during the build, we'll need SNS publishing permissions.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/iam_user_policy.html
 */
resource "aws_iam_user_policy" "sns_publish" {
  user = "${aws_iam_user.travis_user.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sns:Publish",
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
 * Add permissions for Travis to deploy updates to our function.
 *
 * Most of these permissions are those documented by Travis, but we also add additional perms for us
 * to update aliases after deployment.
 *
 * @see https://docs.travis-ci.com/user/deployment/lambda/
 * @see https://www.terraform.io/docs/providers/aws/r/iam_user_policy.html
 */
resource "aws_iam_user_policy" "lambda_deployment" {
  user = "${aws_iam_user.travis_user.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:GetAlias",
        "lambda:GetFunction",
        "lambda:ListAliases",
        "lambda:ListFunctions",
        "lambda:ListVersionsByFunction",
        "lambda:PublishVersion",
        "lambda:UpdateAlias",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration"
      ],
      "Resource": "${aws_lambda_function.function.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "${aws_iam_role.role.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:ListRolePolicies",
        "iam:ListRoles"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

/**
 * Add permissions for read-only access to Terraform state and the resources it manages.
 *
 * @see https://www.terraform.io/docs/backends/types/s3.html
 * @see https://www.terraform.io/docs/providers/aws/r/iam_user_policy.html
 */
resource "aws_iam_user_policy" "read_only_state" {
  user = "${aws_iam_user.travis_user.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "${aws_s3_bucket.state.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "${aws_s3_bucket.state.arn}/tfstate"
    }
  ]
}
EOF
}
