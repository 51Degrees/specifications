TODO - Taken from old spec. Needs review and refactor


### JavaScriptBuilderElement

The JavaScriptBuilderElement takes the JSON output from the JsonBuilderElement
and merges it into a pre-created template, containing JavaScript code.

The **ElementDataKey** is ‘javascriptbuilderelement’  
The **ElementData** contains a single string property called ‘JavaScript’.

---
*Configuration options*

| **Builder method name** | **Type** | **Default**    | **Description**                                                                                                                                                                                               |
|-------------------------|----------|----------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| SetProtocol             | String   | [Empty string] | The protocol used to make a request once additional evidence is available from client-side execution. Uses the value from the request by default                                                              |
| SetHost                 | String   | [Empty string] | The host used to make a request once additional evidence is available from client-side execution. Uses the value from the request by default.                                                                 |
| SetEndpoint             | string   | [Empty string] | The endpoint that a request will be sent to once additional evidence is available from client-side execution. This endpoint must return json data in the same form as the json embedded within the JavaScript |
| SetObjectName           | String   | fod            | The name of the global JavaScript object created on the client                                                                                                                                                |
| SetMinify               | Bool     | True           | Enable or disable minification of the Javascript that is produced                                                                                                                                             |
| SetEnableCookies        | Bool     | False          | True if results of client-side processing will be sent be in cookies, false otherwise                                                                                                                         |

----
*EvidenceKeyFilter*

-   header.host
-   header.protocol
-   query.fod-js-object-name

---
*Process*

First, determine several values to be passed to the template:

1.  If protocol was not specified in configuration, get it from the header.protocol evidence value. If that header is not present, then default to ‘HTTPS’.
2.  If host was not specified in the configuration, get it from the header.host evidence value.
3.  Get object name from the query.fod-js-object-name evidence value. If it’s not present or blank, use the value specified in the configuration.
4.  Get the JSON data that was created by JsonBuilderElement from the flow data.
5.  Get the Sequence and Session ID created by the sequence element from the flow data.
6.  Generate a string containing the query parameters from the evidence
    collection in url query format. I.e.
    -   Get all evidence values starting with ‘query.’
    -   Take the text after ‘query.’ As the key and the value for that key.
    -   Final string will be a list of all such values, formatted as
        [key]=[value] and separated by & characters
    -   Ensure keys and values are URL encoded.
7.  If protocol, host and endpoint are all set, then generate a URL in the following format: “[protocol]://[host][endpoint]”. Care must be taken to ensure variations with slashes in different places are handled correctly. Example URL:
    -   <https://cloud.51degrees.com/json>
    -   <https://cloud.51degrees.com/json-callback>
8.  If query parameters are set in the evidence then serialize these as a json object and pass to the JavaScript builder. The parameters get added to the POST body by the JavaScript include. E.g:
    -   Resource
    -   User-Agent

These parameters are then passed to the pre-created mustache template.
JavaScriptResource.mustache. (This template currently exists in the repository
for each language. The intention is to move this to a single shared repository
in future.)

The parameters to the template are:

| Parameter              | Populated from                                                                              | Description                                                                                                                              |
|------------------------|---------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------|
| \_objName              | Item 3 above                                                                                | The name of the global JavaScript object to create.                                                                                      |
| \_jsonObject           | Item 4 above                                                                                | The string containing the JSON data object.                                                                                              |
| \_sessionId            | Item 5 above                                                                                | The session id is used to deduplicate requests when using the JavaScript include                                                         |
| \_sequence             | Item 5 above                                                                                | The sequence is the number of calls made by the Session ID                                                                               |
| \_supportsPromises     | False. Unless device detection is in the pipeline and the ‘Promise’ property returns ‘Full’ | If true, the script will use Promises                                                                                                    |
| \_url                  | Item 7 above                                                                                | The callback url to use when javascript properties are executed on the client-side.                                                      |
| \_parameters           | Item 8 above                                                                                | Any query parameters in evidence, these should be replayed in call-backs to the cloud service.                                           |
| \_enableCookies        | From configuration                                                                          | If false, the script will automatically delete any cookies prefixed with ‘51D_’ after evaluating properties.                             |
| \_updateEnabled        | Should be true if \_url is set                                                              | If true, the JavaScript will include functionality to make callbacks to the server after evaluating JavaScript properties.               |
| \_hasDelayedProperties | True if the json contains the text ‘delayexecution’                                         | If true, the JavaScript will include functionality to support properties where execution of the JavaScript will be delayed until needed. |

Finally, the resulting JavaScript can optionally be minified, based on the
configuration provided. If minification is desired, a third-party library should
be used.

Performance tests MUST be in place to verify that this feature has minimal
performance impact. If it does have a significant impact, and no alternative
libraries offer better performance, a cut-down minification process should be
implemented in order to achieve the major benefits without a significant
performance cost.
