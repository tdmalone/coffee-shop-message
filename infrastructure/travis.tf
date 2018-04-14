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
 * Attach each of our policies to the user.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/iam_user_policy_attachment.html
 */
resource "aws_iam_user_policy_attachment" "sns_publish" {
  user       = "${aws_iam_user.travis_user.name}"
  policy_arn = "${aws_iam_policy.sns_publish.arn}"
}

resource "aws_iam_user_policy_attachment" "lambda_deployment" {
  user       = "${aws_iam_user.travis_user.name}"
  policy_arn = "${aws_iam_policy.lambda_deployment.arn}"
}

resource "aws_iam_user_policy_attachment" "read_only_state" {
  user       = "${aws_iam_user.travis_user.name}"
  policy_arn = "${aws_iam_policy.read_only_state.arn}"
}

resource "aws_iam_user_policy_attachment" "read_only_resources" {
  user       = "${aws_iam_user.travis_user.name}"
  policy_arn = "${aws_iam_policy.read_only_resources.arn}"
}

/**
 * As we'll be testing the function during the build, we'll need SNS publishing permissions.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/iam_policy.html
 */
resource "aws_iam_policy" "sns_publish" {
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
 * @see https://www.terraform.io/docs/providers/aws/r/iam_policy.html
 */
resource "aws_iam_policy" "lambda_deployment" {
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
 * Add permissions for read-only access to Terraform state.
 *
 * @see https://www.terraform.io/docs/backends/types/s3.html
 * @see https://www.terraform.io/docs/providers/aws/r/iam_policy.html
 */
resource "aws_iam_policy" "read_only_state" {
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:List*",
        "s3:Get*"
      ],
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

/**
 * Add permissions for read-only access to resources managed by Terraform.
 * We also need to set a policy name so that we can self-reference it.
 *
 * @see https://www.terraform.io/docs/backends/types/s3.html
 * @see https://www.terraform.io/docs/providers/aws/r/iam_policy.html
 */
variable "iam_policy_name_read_only_resources" {
  default = "coffee_shop_message_read_only_resource_access"
}

resource "aws_iam_policy" "read_only_resources" {
  name = "${var.iam_policy_name_read_only_resources}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "SNS:GetTopicAttributes",
      "Resource": [
        "${aws_sns_topic.sns_topic_dev.arn}",
        "${aws_sns_topic.sns_topic_prod.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "apigateway:GET",
      "Resource": [
        "arn:aws:apigateway:${data.aws_region.current.name}::/restapis/${aws_api_gateway_rest_api.api.id}",
        "arn:aws:apigateway:${data.aws_region.current.name}::/restapis/${aws_api_gateway_rest_api.api.id}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:DescribeTable",
        "dynamodb:DescribeTimeToLive",
        "dynamodb:ListTagsOfResource"
      ],
      "Resource": "${aws_dynamodb_table.state.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetUser",
        "iam:ListAttachedUserPolicies"
      ],
      "Resource": "${aws_iam_user.travis_user.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetRole",
        "iam:GetRolePolicy"
      ],
      "Resource": "${aws_iam_role.role.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetPolicy",
        "iam:GetPolicyVersion"
      ],
      "Resource": [
        "${aws_iam_policy.read_only_state.arn}",
        "${aws_iam_policy.sns_publish.arn}",
        "${aws_iam_policy.lambda_deployment.arn}",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.iam_policy_name_read_only_resources}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "lambda:GetPolicy",
      "Resource": "${aws_lambda_function.function.arn}"
    }
  ]
}
EOF
}
