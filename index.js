
const https = require( 'https' );

exports.handler = function( event, context, callback ) {

  // Manage separate environment variables per stage.
  const environment = 'prod' === context.invokedFunctionArn.split( ':' ).pop() ? 'prod' : 'dev',
        envSuffix = '_' + environment.toUpperCase();
  process.env.SLACK_HOOK = process.env[ 'SLACK_HOOK' + envSuffix ];
  console.info( 'Running in ' + environment + ' mode.' );

  let message = '';

  console.info( event.pathParameters.proxy );

  switch ( event.pathParameters.proxy ) {

    case 'closing/soon':
      message = 'Hey guys, just to let you know, we\'ll be closing soon.';
      break;

    case 'closing/now':
      message = 'We\'re closing! Get down here *now* if you want coffee!'
      break;

    case 'closing/early':
      message = (
        'Hey guys, we\'ll be closing early today.. maybe 2, or 3 or something. I dunno. ' +
        'This thing doesn\'t let me put in a number.'
      );
      break;

    default:
      throw Error( 'Invalid path specified: ' + event.pathParameters.proxy );

  }

  sendToSlack( message, callback );

}; // Exports.handler.

function sendToSlack( message, callback ) {

  const options = {
    method:   'POST',
    hostname: 'hooks.slack.com',
    port:     443,
    path:     '/services/' + process.env.SLACK_HOOK
  };

  const data = {
    text: message
  };

  const apiResponse = {
    isBase64Encoded: false,
    headers:         {},
  };

  const request = https.request( options, ( response ) => {

    let body = '';
    response.setEncoding( 'utf8' );

    response.on( 'data', ( chunk ) => {
      body += chunk;
    }).on( 'end', () => {

      const logFunction = 'ok' === body ? console.log : console.error;
      logFunction( ( 'ok' === body ? 'Error' : 'Response' ) + ' from Slack: ' + body );

      apiResponse.statusCode = response.statusCode;
      apiResponse.body = 'ok' === body ? 'Message sent.' : body;

      callback( null, apiResponse );

    });
  });

  request.on( 'error', ( error ) => {
    throw Error( 'Problem with Slack request: ' + error.message );
  });

  request.write( JSON.stringify( data ) );
  request.end();

} // Function sendToSlack.
