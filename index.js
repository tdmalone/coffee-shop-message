/**
 * Receives a custom 'coffee shop closing' event from an AWS API Gateway proxy endpoint.
 * Disseminates it to a custom Slack hook and SNS topic.
 *
 * Designed for use with a Flic button at The Good Food Collective, Canterbury VIC Australia.
 *
 * @author Tim Malone <tdmalone@gmail.com>
 */

'use strict';

const aws = require( 'aws-sdk' ),
      https = require( 'https' );

const HTTP_OK = 200,
      HTTP_SERVER_ERROR = 500,
      CI = process.env.CI; // eslint-disable-line no-process-env

// These will be like constants, but we can only set them once we have the context object.
let SLACK_HOOK, SNS_TOPIC;

exports.handler = function( event, context, callback ) {

  // Manage separate environment variables per stage.
  /* eslint-disable no-process-env */
  const environment = 'prod' === context.invokedFunctionArn.split( ':' ).pop() ? 'prod' : 'dev',
        envSuffix = '_' + environment.toUpperCase();
  SLACK_HOOK = process.env[ 'SLACK_HOOK' + envSuffix ];
  SNS_TOPIC = process.env[ 'SNS_TOPIC' + envSuffix ];
  console.info( 'Running in ' + environment + ' mode.' );
  /* eslint-enable no-process-env */

  let message = '';

  console.info( event.pathParameters.proxy );

  switch ( event.pathParameters.proxy ) {

    case 'closing/soon':
      message = 'Hey guys, just to let you know, we\'ll be closing soon.';
      break;

    case 'closing/now':
      message = 'We\'re closing! Get down here *now* if you want coffee!';
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

  Promise.all([ sendSnsMessage( message ), sendToSlack( message ) ])
    .then( ( response ) => {
      finishRequest( null, response, callback );
    })
    .catch( ( error ) => {
      finishRequest( error, null, callback );
    });

}; // Exports.handler.

/**
 * Finishes off the incoming API Gateway request by responding with a valid API Gateway response
 * object, depending on whether the request succeeded or an issue was encountered. Currently
 * assumes all issues are server issues (i.e. HTTP status code 500).
 *
 * @param {mixed}    error    The error encountered during processing of the request. Could be a
 *                            string, an object, or an Error - or null if no error occurred.
 * @param {mixed}    response The response received from external services while processing. Could
 *                            be a string, an object, an array... or null if an error occurred.
 * @param {function} callback Function to call to report completion.
 * @return {undefined}
 * @see https://docs.aws.amazon.com/apigateway/latest/developerguide/handle-errors-in-lambda-integration.html
 */
function finishRequest( error, response, callback ) {

  const apiResponse = {
    isBase64Encoded: false,
    headers:         {},
    statusCode:      error ? ( error.statusCode || HTTP_SERVER_ERROR ) : HTTP_OK,
    body:            error ? ( error.message || error ) : 'Message sent, thanks guys!'
  };

  const logFunction = error ? console.error : console.log;
  logFunction( error ? 'Error: ' + error : response );
  logFunction( apiResponse );
  callback( error && CI ? error : null, apiResponse );

} // Function finishRequest.

/**
 * Sends an SNS message to the topic provided by the environment.
 *
 * @param {string} message The message to send.
 * @return {Promise} A promise to send the message, funnily enough!
 */
function sendSnsMessage( message ) {
  return new Promise( ( resolve, reject ) => {

    if ( ! SNS_TOPIC ) {
      reject( 'No SNS_TOPIC provided.' );
      return;
    }

    const snsMessage = {
      Message:  JSON.stringify( message ),
      TopicArn: SNS_TOPIC
    };

    const sns = new aws.SNS();

    sns.publish( snsMessage, ( error, result ) => {

      if ( error ) {
        reject( error );
        return;
      }

      resolve( result );

    }); // Sns.publish.

  }); // Return Promise.
} // Function sendSnsMessage.

/**
 * Sends a message to the incoming Slack webhook provided by the environment.
 *
 * @param {string} message The message to send.
 * @return {Promise} A promise to send the message!
 */
function sendToSlack( message ) {
  return new Promise( ( resolve, reject ) => {

    if ( ! SLACK_HOOK ) {
      reject( 'No SLACK_HOOK provided.' );
      return;
    }

    const options = {
      method:   'POST',
      hostname: 'hooks.slack.com',
      port:     443,
      path:     '/services/' + SLACK_HOOK
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

        reject( body ? body : 'No response received from Slack.' );

      });
    });

    request.on( 'error', ( error ) => {
      reject( 'Error with Slack request: ' + error.message );
    });

    request.write( JSON.stringify( data ) );
    request.end();

  }); // Return Promise.
} // Function sendToSlack.
