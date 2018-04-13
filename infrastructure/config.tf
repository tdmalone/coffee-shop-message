/**
 * Configures AWS infrastructure for running the coffee-shop-message function.
 *
 * To use, download Terraform and run `terraform init` followed by `terraform apply`.
 * To set variables, edit ./vars.tf.
 * For full instructions, see README.md.
 *
 * This file sets up Terraform, including remote state management. Infrastructure itself is managed
 * in other .tf files in this directory.
 *
 * @author Tim Malone <tdmalone@gmail.com>
 */

/**
 * S3 + DynamoDB backend for managing and locking Terraform remote state.
 *
 * Because these resources are managed by Terraform, they need to be created before the remote
 * backend is utilised. Therefore, when running `terraform plan` for the first time, you'll need
 * to comment out the `terraform` object below and allow the default, local backend to be used at
 * first.
 *
 * @see https://www.terraform.io/docs/backends/types/s3.html
 * @see https://www.terraform.io/docs/providers/aws/r/s3_bucket.html
 * @see https://www.terraform.io/docs/providers/aws/r/dynamodb_table.html
 */
terraform {
  backend "s3" {
    bucket         = "coffee-shop-message"
    key            = "tfstate"
    encrypt        = true
    dynamodb_table = "coffee-shop-message"
  }
}

resource "aws_s3_bucket" "state" {
  bucket = "coffee-shop-message"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "aws_dynamodb_table" "state" {
  name           = "coffee-shop-message"
  hash_key       = "LockID"
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "LockID"
    type = "S"
  }
}

/**
 * AWS provider configuration, with version constraints.
 * Credentials are taken from the usual AWS authentication methods such as environment variables.
 *
 * @see https://www.terraform.io/docs/providers/aws/index.html
 * @see https://www.terraform.io/docs/configuration/providers.html#provider-versions
 */
provider "aws" {
  version = "~> 1.14"
}

/**
 * Make the current AWS region accessible as a data attribute.
 *
 * @see https://www.terraform.io/docs/providers/aws/d/region.html
 * @see https://www.terraform.io/docs/configuration/data-sources.html
 */
data "aws_region" "current" {}
