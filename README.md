# Coffee Shop Message

This is a little [AWS Lambda](https://aws.amazon.com/lambda/) function I've got hooked up to a [Flic button](https://flic.io) at [my work's](https://www.chromatix.com.au/) fave [coffee shop](https://www.instagram.com/tgfcollective/).

Like all good cafes they open early, and sometimes close early - particularly when they've sold out of salads, or it's a quiet afternoon. So the Flic sits on their wall, and when they're about to close they tap it... a few doors down our office gets a Slack message and we know to come get our last coffees of the day!

![The Flic button on the wall at The Good Food Collective](flic-button.png?raw=true "The Flic button on the wall at The Good Food Collective")

![The message as seen in our coffee-specific Slack channel](slack-screenshot.png?raw=true "The message as seen in our coffee-specific Slack channel")

## TODO

* Add basic tests
* Clean up the code a little
* Add sending to an SNS topic, to support email/text subscribers

## License

[MIT](LICENSE).
