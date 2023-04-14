# Overview

The web integration feature is intended to simplify usage of the Pipeline API
in web sites/applications that are built using a particular web framework.

The exact details may vary significantly based on the web framework that 
is being used. The capabilities and common usage of the target web framework 
should be fully understood so that the integration is in keeping with that
ecosystem, rather than simply repeating what worked for some other 
language/framework. 

Some common tasks that the web integration may perform are:

- Creation of **Pipeline** on startup.
- Manage **Flow Data** lifecycle
  - Create **Flow Data** when request comes in
  - Populate evidence values and call 'Process'
  - Make the processed **Flow Data** easily accessible to other parts of the 
    application so the results can be used.
  - Handle [resource cleanup](resource-cleanup.md) once request handling is 
    completed. 
- Handling requests for [client-side](TODO - add link) functionality.
- Set HTTP response headers to request additional information.

# Pipeline configuration

The web integration makes use of several **Flow Elements** in order to support
[client-side](#javascript-properties) functionality.

Where the web integration is responsible for creation of the **Pipeline**, it
must also ensure that these additional **Flow Elements** will be present.

- The [SequenceElement](../pipeline-elements/sequence-element.md) must be 
   present. If not, it should be added as the first element in the pipeline.
- The [JsonBuilderElement](../pipeline-elements/json-builder.md) must be 
   present. If not, it should be added as the penultimate element. 
   (Immediately before the JavaScriptBuilderElement).
- The [JavaScriptBuilderElement](../pipeline-elements/javascript-builder.md)
   must be present. If not, it should be added after all other elements.

Another **Flow Element** is needed to allow the web integration to automatically 
set HTTP response headers.

- The [SetHeadersElement](../pipeline-elements/set-headers-element.md) must
  be present. If not, it should be added after all other elements.

# Populating evidence

The web integration should automatically populate [evidence](evidence.md) from 
the web request.

It may use the Pipeline's [accepted evidence](advertise-accepted-evidence.md) 
feature to determine if individual values should be added to evidence or not.

An alternative approach would be to wrap the web request structure itself as 
evidence, and hence defer processing until the evidence is actually used.

In any case, the list below illustrates the type of data that should be used
and the evidence names they would be associated with.

- All HTTP headers. (Except cookies header) Key must be `header.[header name]`
- All cookies. Key must be `cookie.[cookie name]`
- All query string parameters. Key must be `query.[parameter name]`
- All form parameters from POST requests. Key must be `query.[parameter name]`
- Where there is an HTTP session object, data stored in the session. Key must 
  be `session.[value name]`
- Public client IP. Key must be `server.client-ip`
- Request protocol. Can come from the request itself or headers such as
  `X-Origin-Proto` or `X-Forwarded-Proto`. Key must be `header.protocol`

# Setting response headers

The [SetHeadersElement](../pipeline-elements/set-headers-element.md) will 
produce an output that describes which response headers should be set to which 
values.

However, it has no access to the web request itself. Consequently, the web 
integration logic must take this output and actually set the required response 
headers.

Where the required headers are already set to some value, the new value must 
be appended, rather than replacing the existing value.

# Client-side features

There are two major client-side features that the web integration must provide:
1. Enable the execution of JavaScript snippets which can be used to gather 
   additional evidence. Handle passing this data back to the **Pipeline** for 
   processing.
2. Allow the user to access results on **Pipeline** processing in client side 
   code.

## Access to results

Generally, this is achieved by adding a specific JavaScript include to the HTML 
page. The web integration intercepts the request to this URL and serves a 
JavaScript object that can be used to access the results from processing.

## JavaScript snippets 

Aspect engines can return properties with a type of 
[Javascript](properties.md#the-javascript-type). For these properties, 
the property value contains JavaScript code that is intended to be 
executed on the client device.

As these JavaScript property values are part of the result set, they will 
already be accessible in client-side code through the JavaScript include that 
is discussed in the section above.

Therefore, in order to meet this requirement, the JavaScript include must 
be enhanced to perform the following steps:
1. Identify these JavaScript property values
2. Execute the snippets 
3. Call back to the server, including the results from the execution of the 
   snippets
4. Use the result from the callback to update the result data set
5. Repeat if there are any JavaScript property values in the new result set. 
   (only repeat up to a configurable limit in order to avoid infinite loops)

## Flow Elements

These features are implemented using the web integration logic itself, along
with several **Flow Elements**:

- [SequenceElement](../pipeline-elements/sequence-element.md) - Used to 
  prevent the infinite loops described in the section above. 
- [JsonBuilderElement](../pipeline-elements/json-builder.md) - Converts the 
  property values in the current **Flow Data** into a JSON data object.
- [JavaScriptBuilderElement](../pipeline-elements/javascript-builder.md) - 
  Takes the output from JsonBuilderElement and packages it within a JavaScript 
  template.

## Intercepted Urls

In order for this to work, the web integration needs to intercept requests 
to two urls. These should be configurable, but the default values are:

- `/51Degrees.core.js` - Serves the JavaScript produced by JavaScriptBuilderElement.
- `/51dpipeline/json` - Serves the JSON produced by JsonBuilderElement.

### Client-side caching

Where possible, we want to prevent the client from evaluating JavaScript or
making requests unnecessarily. To achieve this, the web integration will
need to include logic to set HTTP cache control headers when responding to
requests to these intercepted endpoints.

#### Storing results of POST requests
<span style="color:yellow">TODO - move this detail to javascript builder. 
Just link to it from here</span>

Requests to the JSON endpoint will be be POST requests, as opposed to the GET 
requests made to the JavaScript endpoint.

This is a problem because most browsers do not consider POST requests to be 
cache-able and will not respect cache headers. 

The reference implementations work around this by using the session storage 
API. The JavaScript produced by the 
[JavaScriptBuilderElement](../pipeline-elements/javascript-builder.md) 
includes functionality to retain results of previous JSON endpoint requests
in session storage on the browser. These are stored using a key created 
by combining the session ID and sequence number generated by the 
[SequenceElement](../pipeline-elements/sequence-element.md).

Session ID is retained for the lifetime of the session, so when a future request 
would be made to the JSON endpoint with the same session ID and sequence number, 
we can simply pull the previous result from session storage instead.

Note that these session storage entries should use the same lifetime as the cache
max-age setting [described below](#cache-header-detail).

#### Caching example

Below is a request/response diagram showing what we want to happen when an 
initial request is made (in red) and the user then moves to another page on 
the same site (in blue).
See the descriptions below for a detailed walkthrough of what is happening 
on each line.

![JavaScript Properties Request Response](images/JavascriptProperties-RequestResponse.png)

##### Line 1 - First request to JavaScript endpoint:

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
parameters list. A request will then be sent to the callback URL. 

##### Line 2 - First request to JSON endpoint:

As this is the first request, there is nothing in the session storage. 
Proxy and server caches must never cache this resource. On the server, the 
request to the JSON endpoint will again be intercepted and handled. This time, 
by responding with the output from the JsonBuilderElement.

The JavaScript code running on the client will update its JSON data with the one
from the response. In addition, the payload will be stored in session storage
using the Session ID as the key, the JavaScript properties that ran will be
flagged in session storage also and the sequence number sent in the call-back
request body will be incremented.

If the JSON payload still contains JavaScript properties, the process repeats.

##### Line 3 - Second request to JSON endpoint (different parameters to 1st request):

This time, the sequence number in the request body will be 2 and new evidence
will have been provided. The session storage will be invalid as the parameters have
changed. The request to the call-back URL is made with the new evidence and any
existing evidence to get an updated JSON payload. The JavaScript will again
update its’ internal JSON data with the one from the response and store it in
session storage along with all the JavaScript properties that have been run.

##### Line 3 - Skipping second request to JavaScript endpoint:

We now assume that the user moves to another page on the same website. This page
also includes the directive to download 51Degrees.core.js. This time, the local
cache can serve the same JavaScript response that it used previously.

##### Line 5 + 6 - Skipping third and fourth requests to JSON endpoint:

The script will be the original version that was obtained from the JavaScript
endpoint previously. As such, it will go through the same process of checking
session storage for existing results and executing JavaScript properties.

First, the session storage is checked to see if the JavaScript properties to be
run have been run already. If this is the case then the session storage is
checked to see if it contains a JSON payload using the cached Session ID as the
key. If the payload is found, then this is loaded into the JavaScript’s internal
JSON data and no requests to the call-back URL need to be made.

This will then repeat as before for any JavaScript properties in the new payload.

#### Cache header detail

The HTTP response headers that must be set for the JSON and JavaScript endpoints
are:

| **Header**      | **Values**                                                                             | **Purpose**                                                                                      |
|-----------------|----------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|
| Cache-Control   | max-age=1800 private                                                                   | Cache item lifetime is 30 minutes. Only local client caches should cache this content.           |
| Vary            | [all headers in pipeline evidence key filter] (e.g. User-Agent)                        | Let the cache know that if one of these headers changes, the cached content must be re-fetched.  |
| ETag            | [Calculated hash of ALL the evidence values in evidence filter key for this pipeline]  | Assists caches in re-validating expired content                                                  |
| Content-Type    | application/x-javascript or application/json                                           | Indicate the type of content being returned                                                      |
| Content-Length  | [Content length in bytes]                                                              | Indicate the expected length of the content                                                      |

In order to validate the ETag, the JSON and JavaScript endpoints must check for
an ‘If-None-Match' header in the request. This will be sent when a cached item’s
lifetime has expired and the cache needs to check if what it holds is still
valid.

If the value in the ‘If-None-Match' header matches the calculated ETag value for
the current request, then the content in the cache is still valid and the
endpoint can just return a 304 status code. (Not modified)

Note on correctness – This process could lead to responses that are not strictly
correct if the JavaScript snippet is getting data values that might change over time. 
For example, if we're using JavaScript to get location and the user has moved then
session storage will still contain the previous location lookup response. 
In practice this seems unlikely to cause any real issues, as long as the cache 
max-age is not too long. Max-age should be configurable to allow this to be addressed 
if it is found to be an issue for a particular client.