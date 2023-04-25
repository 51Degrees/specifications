# JavaScript builder element

## Overview

The JavaScript builder element takes the JSON output from the 
[JSON builder element](json-builder.md) and merges it into a pre-created 
template, containing JavaScript code.

This JavaScript can then be sent to the client, where it provides the 
following features:

- Allow access to Pipeline processing results in client-side code.
- Acquire additional evidence that is only accessible to client-side 
  scripts. This is described in more detail in our 
  [documentation](https://51degrees.com/documentation/4.4/_features__client_side_evidence.html)

## Accepted evidence

- header.host
- header.protocol
- query.fod-js-object-name

## Startup activity

On startup, just need to initialize the normal data structures, such as 
accepted evidence, and perform any set up for the template system to
operate as efficiently as possible.

## Element data

The output from this element is a single string property called 'JavaScript'.
This will be populated with the raw JavaScript that is generated.

## Process

First, determine several values to be passed to the template:

1. If protocol was not specified in configuration, get it from the 
   `header.protocol` evidence value. If that header is not present, then 
   default to `HTTPS`.
2. If host was not specified in the configuration, get it from the 
   `header.host` evidence value.
3. Get object name from the `query.fod-js-object-name` evidence value. 
   If it’s not present or blank, use the value specified in the configuration.
4. Retrieve the Element Data for [JSON builder element](json-builder.md) from 
   the Flow Data. This contains the JSON to be passed to the template.
5. Retrieve the Element Data for [sequence element](sequence-element.md) from 
   the Flow Data. This contains the session id and sequence number to be 
   passed to the template.
6. If protocol, host and endpoint are all set, then generate a URL in the 
   following format: `[protocol]://[host][endpoint]`. Ensure that values 
   with/without slashes are handled correctly.
7. The JavaScript may need to make call backs to the server. A list of any 
   query parameters that should be included in those calls needs to be created. 
   This can be done by looking at the query entries in the existing evidence:
   - Get all evidence values starting with `query.`
   - Use the text after `query.` as the key.
   - Pass keys and values in the form required by the template (don't forget 
     URL encoding, etc if needed).

These parameters are then passed to the pre-created template.
The mustache template used by .NET is available on 
[GitHub](https://github.com/51Degrees/pipeline-dotnet/blob/master/FiftyOne.Pipeline.Elements/FiftyOne.Pipeline.JavaScriptBuilderElement/Templates/JavaScriptResource.mustache) 
There is not requirement that this template or mustache is used. However, 
any new variant would need to reproduce the capabilities of the existing script. 

The parameters to the existing template are:

| ***Parameter**         | **Populated from**                                                                          | **Description**                                                                                                                          |
|------------------------|---------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------|
| \_objName              | Item 3 above                                                                                | The name of the global JavaScript object to create.                                                                                      |
| \_jsonObject           | Item 4 above                                                                                | The string containing the JSON data object.                                                                                              |
| \_sessionId            | Item 5 above                                                                                | The session id is used to deduplicate requests when using the JavaScript include                                                         |
| \_sequence             | Item 5 above                                                                                | The sequence is the number of calls made by the Session ID                                                                               |
| \_supportsPromises     | False. Unless device detection is in the pipeline and the ‘Promise’ property returns ‘Full’ | If true, the script will use Promises                                                                                                    |
| \_url                  | Item 6 above                                                                                | The callback url to use when javascript properties are executed on the client-side.                                                      |
| \_parameters           | Item 7 above                                                                                | Any query parameters in evidence, these should be relayed in call-backs to the cloud service.                                            |
| \_enableCookies        | From configuration                                                                          | If false, the script will automatically delete any cookies prefixed with `51D_` after evaluating properties.                             |
| \_updateEnabled        | Should be true if \_url is set                                                              | If true, the JavaScript will include functionality to make callbacks to the server after evaluating JavaScript properties.               |
| \_hasDelayedProperties | True if the json contains the text `delayexecution`                                         | If true, the JavaScript will include functionality to support properties where execution of the JavaScript will be delayed until needed. |

Finally, the resulting JavaScript can optionally be minified, based on the
configuration provided. If minification is desired, a third-party library should
be used.

Performance tests MUST be in place to verify that this feature has minimal
performance impact. If it does have a significant impact, and no alternative
libraries offer better performance, a cut-down minification process should be
implemented in order to achieve the major benefits without a significant
performance cost.

### JavaScript template functionality

The JavaScript snippet that is produced by this element must include the
following functionality:

- A new JavaScript object with a configurable name created in the the global 
  scope. This is the mechanism by which the engineer interacts with the 
  client-side functionality.
- A way to access the results of processing in client-side code.
- 

#### Session storage caching

As explained in the 
[web integration](../../part2/features/web-integration.md#client-side-caching) 
document, caching should be used to reduce the need to resend data.

Since the response to the server is a POST request and 
[is not cached](../../part2/features/web-integration.md#storing-results-of-post-requests), 
the generated JavaScript must
include functionality to retain results of previous JSON endpoint requests
in session storage on the browser. These are stored using a key created 
by combining the session ID and sequence number generated by the 
[SequenceElement](sequence-element.md).

Session ID is retained for the lifetime of the session, so when a future request 
would be made to the JSON endpoint with the same session ID and sequence number, 
we can simply pull the previous result from session storage instead.

## Configuration options

| **Name**         | **Type** | **Default**    | **Description**                                                                                                                                                                                               |
|------------------|----------|----------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| SetProtocol      | String   | [Empty string] | The protocol used to make a request once additional evidence is available from client-side execution. Uses the value from evidence by default                                                                 |
| SetHost          | String   | [Empty string] | The host used to make a request once additional evidence is available from client-side execution. Uses the value from evidence by default.                                                                    |
| SetEndpoint      | string   | [Empty string] | The endpoint that a request will be sent to once additional evidence is available from client-side execution. This endpoint must return json data in the same form as the json embedded within the JavaScript |
| SetObjectName    | String   | fod            | The name of the JavaScript object created in the global scope on the client                                                                                                                                   |
| SetMinify        | Bool     | True           | Enable or disable minification of the Javascript that is produced                                                                                                                                             |
| SetEnableCookies | Bool     | True           | True if results of client-side processing should be retained in cookies so that they are sent by default in subsequent requests                                                                               |