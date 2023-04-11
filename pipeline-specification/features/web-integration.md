TODO - This has been copied from the old spec document. Needs review and refactor.


# Web application integration

A pipeline can be used by a web application without any additional changes, but
web application integration exists for two reasons:

1.  To make life easier for the web application developer.
2.  To leverage the ability to obtain data directly from the connecting web
    client.

When built as a web application, the pipeline contains helpers such as
**setHttpHeaders** and **setEvidenceFromRequest** which parse a languages native
request object or headers object into a correct format for **flowData** (for
example accessing cookies and IP addresses).

## Evidence helpers

By default, the integration can add the following values as evidence. In each
case, the evidence key can be checked against the pipeline’s EvidenceKeyFilter.
If the key is not included, then there is no need to add it to evidence:

-   All HTTP headers. Key must be ‘header.[header name]’
-   All cookies. Key must be ‘cookie.[cookie name]’
-   All query string parameters. Key must be ‘query.[parameter name]’
-   All form parameters from POST requests. Key must be ‘query.[parameter name]’
-   Where there is an HTTP session object, data stored in the session. Key must be ‘session.[value name]’
-   Client IP. Key must be ‘server.client-ip’
-   Request protocol. Can come from the request itself or headers such as
    X-Origin-Proto or X-Forwarded-Proto. Key must be ‘header.protocol’

## Default configuration

In order to provide its functionality, the web integration needs several
additional elements to be added to the Pipeline (detailed specs for these
elements are below). Where one or more of these are missing from configuration,
this integration should add them in with default settings.

1.  The SequenceElement should be added as the first element in the pipeline if it is not already present in the configuration.
2.  If JsonBuilderElement is not in the configuration then:
    1.  If there is a JavaScriptBuilderElement, then add the JsonBuilderElement immediately before it.
    2.  If there is no JavaScriptBuilderElement, add the JsonBuilderElement
        after all existing elements.
3.  If JavaScriptBuilderElement is not in the configuration then add it after all existing elements. Set the ‘EndPoint’ parameter to ‘/51dpipeline/json’
4.  If JavaScriptBuilderElement is already in the configuration, check for an ‘EndPoint’ parameter. If there isn’t one then set it to ‘/51dpipeline/json’

## JavaScript properties

Aspect engines can return properties with a category of “[javascript]”. For
these properties, the value of the property contains JavaScript code that is
intended to be added to the web page that is returned to a client. This
JavaScript include will usually obtain more details about a user’s device /
session that will be processed by the aspect engine to enhance the results.
Results are usually returned by post back, which results in an additional
query.[name] evidence value. In some cases, cookies can be used. The evidence
keys for request cookies are named **cookie.[name]**.

The web package should include three flow elements that produce a complete
JavaScript include.

-   SequenceElement – Generates a unique ‘session-id’ if one is not present in the evidence. If there is already a session-id, the ‘sequence’ number is incremented. These values are embedded in the data sent to the client-side in order to prevent infinite loops and aid in reducing unnecessary requests.
-   JsonBuilderElement – Converts the properties in the current flow data into a JSON data object.
-   JavaScriptBuilderElement – Takes the output from JsonBuilderElement and packages it within a JavaScript template. Sending the completed JavaScript to the client device will enable the developer to access pipeline results on the client-side. Additionally, any properties prefixed with ‘Javascript’ will automatically be executed and their results posted back in order to obtain more complete data.

The developer should have full control over how to include the JavaScript into
the page but by default, the package should include out-of-the-box functionality
that will allow the JavaScript to be executed on the client device with minimal
work from the third-party developer.

Generally, the recommended approach is to add a JavaScript include for
‘51Degrees.core.js’. When this file is requested, the request is intercepted and
the output from the JavaScriptBuilder is used to populate the response.

### SequenceElement

The sequence element does not have any configuration parameters.

The **ElementDataKey** is ‘sequence’

The **ElementData** contains no properties.

---
*EvidenceKeyFilter*

-   query.session-id

-   query.sequence

---
*Process*

If the evidence contains no session id, then create one and add it to the
evidence. This is usually the string representation of a Guid. However, it could
be any string that is (nearly) guaranteed to be unique.

If the evidence contains no sequence number, then add one to the evidence
initialized to 1. Otherwise, parse the value and increment it, assigning the new
value back to the evidence collection.

If the value cannot be parsed, then set it to 1 and log an error. “Failed to
increment usage sequence number”

---
### JsonBuilderElement

The json builder element creates a JSON representation with most of the values in the
flowdata.

The **ElementDataKey** is ‘json-builder’  
The **ElementData** contains a single string property called ‘Json’  
The **EvidenceKeyFilter** is empty

---
*Configuration Options*

| Builder method name | Type | Default | Description |
|---|---|---|------|
| SetProperties | List of strings | [Empty list] | A list of the properties to include in the JSON. By default, all properties will be included. Also note that some properties, such as JavaScript properties, will always be included, regardless of this setting. Property names must be fully qualified. (e.g. ‘device.ismobile’ or ‘devices.profiles.hardwarename’) |

Configuration Example:

**Incorrect**
```
"PipelineOptions": {
  "Elements": [
    {
      "BuilderName": "JsonBuilderElement",
      "BuildParameters": {
        "Properties": [ "ismobile", "city", "hardwarename" ]
      }
    }
  ]
}
```

**Correct**
```
"PipelineOptions": {
  "Elements": [
    {
      "BuilderName": "JsonBuilderElement",
      "BuildParameters": {
        "Properties": [ "device.ismobile", "location.city", "devices.profiles.hardwarename" ]
      }
    }
  ]
}
```

---
*Startup*

This element needs to build some helper collections when it first starts up:


1.  A list, DelayedExecutionProperties, of the complete names of all properties that have delay execution = true.
    1.  This can be determined by looking at the ‘DelayExecution’ flag on
        property meta data for each element in the pipeline.
    2.  Ensure that the complete name is stored. I.e. [element data
        key].[property name] For example, device.ismobile.
    3.  Ensure properties with nested sub-properties are handled correctly. For example, hardware.devices.ismobile.

2.  A collection, DelayedEvidenceProperties, of key value pairs when the key is the complete name of the property and the value is the list of complete property names that, when executed, can help determine the value of that property.  
This must be populated for all properties for which a value cannot be determined until the delayed execution properties are executed. For example, the location.javascript property must be executed before location.country can be populated. The key would be location.country and the value would be a list containing one element: location.javascript.
    1.  This can be determined by using the list of delayed execution properties generated above, in combination with the ‘EvidenceProperties’ list on property meta data.
        1.  EvidenceProperties contains only the property name. For example, ‘country’. These must be converted into complete names before they can be compared with the names in the list of delayed execution properties.
    2.  As above, complete names must be used, and sub-properties handled
        correctly.

---
*Process*

Get sequence number from evidence key ‘query.sequence’. If not present, throw an
error “Sequence number not present in evidence. This is mandatory. Check that
the SequenceElement exists in the pipeline before this JsonBuilderElement”

Create a nested collection C1 of string =\> object key value pairs to hold the
values that will end up in the JSON

For each property each element (except the json-builder element itself), perform
the following:


-   Get the complete name by combining the element name with the property name. Full stop separators are used and the result MUST be all lowercase. For example, the IsMobile property on the device detection engine becomes ‘device.ismobile’
-   Get the property value as a variable - V1.
-   If the V1 is **AspectPropertyValue** and it has a value, set V1 to the
    value. If it does not have a value, add two items to the nested collection C1:
    -   [complete name], null
    -   [complete name]+”nullreason”, [no value message from aspect property value]
-   If V1 is not null:
    -   If V1 is a list of other element data items, repeat this process for each item in the list. Set V1 = the result C1 from that call. Naming is important here, the current ‘complete name’ will become the ‘element name’ in the next level down. For example, when performing a TAC lookup, multiple profiles can be returned. In JSON, the ismobile property would then be represented as ‘hardware.profiles.ismobile’. ‘hardware’ is the **ElementDataKey** and ‘profiles’ is the name of the property, which contains the list of profile objects.
    -   Add to C1: [complete name], V1
    -   If DelayedExecutionProperties contains this property then Add to C1: [complete name]+”delayexecution”, true
-   If the complete name is in DelayedEvidenceProperties then add to C1:
    [complete name]+”evidenceproperties”, [value from DelayedEvidenceProperties]

If sequence number \< 10, get a list of the complete names of all JavaScript
properties. Add this to the result under the key ‘javascriptProperties’.

Add any errors from the flowdata Errors collection to the result. This must be a
simple string list of the error messages under the key ‘errors’.

---
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

---
### Client-side caching

Where possible, we want to prevent the client from evaluating JavaScript or
making requests unnecessarily. To achieve this, we use a mix of session storage
on the client and the client’s cache.

Below is a request/response diagram showing what happens when an initial request
is made (in brown) and the user then moves to another page on the same site (in
blue).

![JavaScript Properties Request Response](Images/JavascriptProperties-RequestResponse.png)

A client connecting to a web server that uses a Pipeline API with web
integration will typically be directed to download a script such as
51Degrees.core.js. The local cache will not have this as it is the first
request. Proxy and server caches must never cache this resource, so will also be
cache misses. The web integration code will intercept the request on the server
and serve the JavaScript that is produced by the JavaScriptBuilderElement in the
Pipeline.

The JavaScript in the response will then run on the client. If any JavaScript
properties are present, they will be executed. Any new pieces of evidence
produced because of processing these JavaScript properties will be added to the
parameters list. A request will then be sent to the callback URL. As this is the
first request, the response JSON payload will not be in the session storage and
no JavaScript properties will have been flagged as ‘run’. Proxy and server
caches must never cache this resource. On the server, the request to the JSON
endpoint will again be intercepted and handled. This time, by responding with
the output from the JsonBuilderElement.

The JavaScript code running on the client will update its JSON data with the one
from the response. In addition, the payload will be stored in session storage
using the Session ID as the key, the JavaScript properties that ran will be
flagged in session storage also and the sequence number sent in the call-back
request body will be incremented.

If the JSON payload still contains JavaScript properties, the process repeats.
This time, the sequence number in the request body will be 2 and new evidence
will have been provided. The session storage will be invalid as the parameters have
changed. The request to the call-back URL is made with the new evidence and any
existing evidence to get an updated JSON payload. The JavaScript will again
update its’ internal JSON data with the one from the response and store it in
session storage along with all the JavaScript properties that have been run.

We now assume that the user moves to another page on the same website. This page
also includes the directive to download 51Degrees.core.js. This time, the local
cache can serve the same JavaScript response that it used previously.

The script will be the original version that was obtained from the JavaScript
endpoint previously. As such, it will go through the same process of checking
session storage for existing results and executing JavaScript properties.

First, the session storage is checked to see if the JavaScript properties to be
run have been run already. If this is the case then the session storage is
checked to see if it contains a JSON payload using the cached Session ID as the
key. If the payload is found, then this is loaded into the JavaScript’s internal
JSON data and no requests to the call-back URL are made.

If any of the JavaScript properties to be run have not been run already or there
is no JSON payload in the session storage then the JavaScript will make the
requests to the call-back URL as before.

Note on correctness – This could lead to responses that are not strictly
correct. For example, if the user has moved and has different lat/lon
coordinates, the new coordinates will not be used, as the session storage will
contain the older location lookup response. In practice this seems unlikely to
cause any real issues, as long as the cache max-age is not too long.

GET requests can only send data to the server as part of the URI or as headers.
When passing parameters to the call-back URL, URL segments are not suitable as
the order or presence of parameters cannot be guaranteed. Query strings are also
not suitable as these are limited in length. For this reason, POST requests and
session storage is used. POST request can have a body with an arbitrary length
which allows for future growth in the amount of evidence that is sent to the
cloud service, but most browsers do not consider POST request to be cache-able (TO
BE VERIFIED), so results are stored in session storage if supported.

The HTTP response headers that must be set for the JSON and JavaScript endpoints
are:

| **Header**      | **Values**                                                                             | **Purpose**                                                                                      |
|-----------------|----------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|
| Cache-Control   | max-age=1800 private                                                                   | Cache item lifetime is 30 minutes. Only local client caches should cache this content.           |
| Vary            | [all headers in pipeline evidence key filter] (e.g. User-Agent)                        | Let the cache know that if one of these headers changes, the cached content must be re-fetched.  |
| ETag            | [Calculated hash of ALL the evidence values in evidence filter key for this pipeline]  | Assists caches in re-validating expired content                                                  |
| Content-Type    | application/x-javascript or application/json                                           | Indicate the type of content being returned                                                      |
| Content-Length  | [Content length in bytes]                                                              | Indicate the expected length of the content                                                      |

In order to validate the ETag, the json and JavaScript endpoints must check for
an ‘If-None-Match' header in the request. This will be sent when a cached item’s
lifetime has expired and the cache needs to check if what it holds is still
valid.

If the value in the ‘If-None-Match' header matches the calculated ETag value for
the current request, then the content in the cache is still valid and the
endpoint can just return a 304 status code. (Not modified)
