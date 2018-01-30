# Coffee Shop Message

This is a little [AWS Lambda](https://aws.amazon.com/lambda/) function I've got hooked up to a [Flic button](https://flic.io) at [my work's](https://www.chromatix.com.au/) fave [coffee shop](https://www.instagram.com/tgfcollective/).

Like all good cafes they open early, and sometimes close early - particularly when they've sold out of salads, or it's a quiet afternoon. So the Flic sits on their wall, and when they're about to close they tap it... a few doors down our office gets a Slack message and we know to come get our last coffees of the day!

![The Flic button on the wall at The Good Food Collective](flic-button.png?raw=true "The Flic button on the wall at The Good Food Collective")

![The message as seen in our coffee-specific Slack channel](slack-screenshot.png?raw=true "The message as seen in our coffee-specific Slack channel")

## Tests

To run all tests at once:

    yarn test

### Unit Tests

To run:

    yarn unit-tests

Unit tests are yet to be written, and will currently just pass.

### Integration Tests

To run:

    yarn docker-tests

Integration tests require [Docker](https://docs.docker.com/install/). They run in `lambci/lambda:nodejs6.10` ([GitHub](https://github.com/lambci/docker-lambda) | [Docker Hub](https://hub.docker.com/r/lambci/lambda/)).

The following environment variables must be defined on your system:

* `SLACK_HOOK_DEV`
* `SNS_TOPIC_DEV`
* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`
* `AWS_DEFAULT_REGION`
* `CI` - optional

The final `CI` variable above is optional, but recommended. If set (which it is [by default on Travis CI](https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables), for instance), it will cause errors to be _thrown_ rather than returned as an [API Gateway style response](https://docs.aws.amazon.com/apigateway/latest/developerguide/handle-errors-in-lambda-integration.html). If not set, tests will still 'pass', as errors will be mapped to a HTTP status code rather than thrown.

## TODO

* Add basic unit tests
* Add integration tests (in progress)
* Clean up the code a little/add inline docs etc. (in progress)
* Add sending to an SNS topic, to support email/text subscribers (in progress, along with promisifying)
* Come up with an easy way (Lambda func with static frontend?) for the shop or customers themselves to subscribe e-mails and mobile numbers to the SNS topic

## License

[MIT](LICENSE).
