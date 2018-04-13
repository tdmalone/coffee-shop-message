# Infrastructure for Coffee Shop Message

Coffee Shop Message runs on AWS Lambda, invoked via an HTTP POST to an API Gateway endpoint.

All of the infrastructure is codified using [Terraform](https://www.terraform.io).

## Setup

If you don't have Terraform yet, [grab that first](https://www.terraform.io/downloads.html).

Then:

1. Edit any variables in [`vars.tf`](vars.tf) that you wish to change. Pay special attention to the Slack hook variables, which you'll need to set in a secure way, such as by exporting `TF_VAR_slack_hook_dev` and `TF_VAR_slack_hook_prod`.
1. Ensure that your AWS credentials are available. You can do this either by exporting `AWS_SECRET_ACCESS_KEY` and `AWS_ACCESS_KEY_ID`, by logging on via the [AWS CLI](https://aws.amazon.com/cli/), or by using [other options documented at Terraform](https://www.terraform.io/docs/providers/aws/#authentication).
1. Run `yarn bootstrap` to prepare a zip file of the function.
1. To prepare for the first run of the Terraform plan, it is neccessary to comment out the `terraform { }` block in [`config.tf`](config.tf). This is because on the first run, the resources used to store our state (an S3 bucket and DynamoDB table) will not yet exist.
1. Run `terraform init`, and wait for provider plugins to be downloaded.
1. Run `terraform apply`, and carefully read the list of infrastructure that Terraform will create (there'll be around 20 or so items). Ensure you are happy, and type `yes` to continue. *Although infrastructure created is minimal and shouldn't result in any immediate charges, you should still be aware of how the utilised infrastructure is priced as ongoing charges may apply.* See [AWS pricing documentation](https://aws.amazon.com/pricing/) for the most up-to-date information.
1. If the previous step errors, take note of the errors; you may need to run `terraform apply` again to retry if some actions have failed.
1. Next, uncomment the `terraform { }` block you commented out above, and run `terraform init` again. You will be prompted to copy your existing local state (`*.tfstate` files) into remote storage (in S3). Once this is done, you can safely delete your local `*.tfstate` files, and you can now manage your infrastructure from anywhere!
1. Finally, subscribe something to your new dev SNS topic - like your own e-mail address! You can do this from the [AWS SNS console](https://console.aws.amazon.com/sns/v2/home#/topics) or the AWS CLI (eg. `aws sns subscribe --topic-arn "$(terraform output sns_topic_dev)" --protocol email --notification-endpoint you@example.com`). Note that you'll need to approve the subscription through your e-mail account before it becomes active.

You should now be able to test your API. Send a CURL request like `curl -X POST "$( terraform output api_invoke_url_dev )"/closing/soon`. Check the response, and look out for a message in the e-mail address you subscribed to your dev SNS topic!
