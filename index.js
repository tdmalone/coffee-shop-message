
const aws = require( 'aws-sdk' ),
      https = require( 'https' );

exports.handler = function( event, context, callback ) {

  // Manage separate environment variables per stage.
  const environment = 'prod' === context.invokedFunctionArn.split( ':' ).pop() ? 'prod' : 'dev',
        envSuffix = '_' + environment.toUpperCase();
  process.env.SLACK_HOOK = process.env[ 'SLACK_HOOK' + envSuffix ];
  process.env.SNS_TOPIC = process.env[ 'SNS_TOPIC' + envSuffix ];
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

  Promise.all([
    sendSnsMessage( message ),
    sendToSlack( message )
  ])
    .then( ( response ) => { finishRequest( null, response, callback ); })
    .catch( ( error ) => { finishRequest( error, null, callback ); });

}; // Exports.handler.

function finishRequest( error, response, callback ) {

  const apiResponse = {
    isBase64Encoded: false,
    headers:         {},
    statusCode:      error ? error : response,
    body:            error ? 500 : 200
  };

  const logFunction = error ? console.error : console.log;
  logFunction( error ? error : response );
  callback( null, apiResponse );

} // Function finishRequest.

function sendSnsMessage( message, callback ) {
  return new Promise( ( resolve, reject ) => {

    if ( ! process.env.SNS_TOPIC ) {
      reject( 'No SNS_TOPIC provided.' );
      return;
    }

    const snsMessage = {
      Message:  JSON.stringify( message ),
      TopicArn: process.env.SNS_TOPIC
    };

    const sns = new aws.SNS();

    sns.publish( snsMessage, ( error ) => {

      if ( error ) {
        reject( error );
        return;
      }

      resolve();

    }); // Sns.publish.

  }); // Return Promise.
} // Function sendSnsMessage.

function sendToSlack( message ) {
  return new Promise( ( resolve, reject ) => {

    if ( ! process.env.SLACK_HOOK ) {
      reject( 'No SLACK_HOOK provided.' );
      return;
    }

    const options = {
      method:   'POST',
      hostname: 'hooks.slack.com',
      port:     443,
      path:     '/services/' + process.env.SLACK_HOOK
    };

    const data = {
      text: message
    };

    const request = https.request( options, ( response ) => {

      let body = '';
      response.setEncoding( 'utf8' );

      response.on( 'data', ( chunk ) => {
        body += chunk;
      }).on( 'end', () => {

        if ( 'ok' === body ) {
          resolve( body );
          return;
        }

        reject( body );

      });
    });

    request.on( 'error', ( error ) => {
      reject( 'Error with Slack request: ' + error.message );
    });

    request.write( JSON.stringify( data ) );
    request.end();

  }); // Return Promise.
} // Function sendToSlack.
