# Cloud Request Engine

## Overview

Cloud engines offload the processing to a remote system. This reduces 
resource requirements and avoids the complexities of some local 
engines (For example, 
[device detection on premise](../../device-detection-specification/pipeline-elements/device-detection-on-premise.md) 
has a native component that requires additional dependencies) 

The Pipeline API splits this cloud processing over two separate types of 
engine:
- Cloud Request Engine - (Specified in this document) Makes the HTTP 
  call to the remote service and  makes the raw JSON response available 
  by adding it to its Aspect Data.
- [Cloud Aspect Engine](cloud-aspect-engine.md) - Designed to be swapped 
  out with an equivalent on-premise engine. Takes the raw JSON response 
  from the Cloud Request Engine's Aspect Data and deserializes it to 
  populate its own Aspect Data instance, which is interface compatible 
  with the Aspect Data from the on-premise engine.

The following diagram illustrates this process with a device detection
cloud engine:

![Cloud engine flow](../../../pipeline-specification/images/Device%20Detection%20Cloud%20Engine.png)

A Pipeline should only have one Cloud Request Engine, but may have 
multiple Cloud Aspect Engines - For example, a location cloud engine, 
device detection cloud engine, etc.

This approach is taken in order to allow cloud engines to behave as 
similar as possible to on-premise engines from the user point of view, 
while limiting the number of HTTP requests to one per Flow Data, regardless
of the number of different aspects the user wishes to get information on.

### Resource Key

A Resource Key is a token that serves both to authenticate a request to the 
51Degrees server and to specify which property values are returned in the 
result. Resource Keys are created using the 
[51Degrees Configurator](https://51degrees.com/documentation/4.4/_concepts__configurator.html). 
See [Resource Keys Documentation](https://51degrees.com/documentation/4.4/_info__resource_keys.html)
for more information.

## Accepted evidence

Accepted evidence is dependent on the supplied Resource Key.

[On startup](#startup-activity), the engine must make a request to cloud 
to get this information.

## Element data

This engine populates a single property - json-response. This will contain 
the raw JSON response from the cloud HTTP request.

An example of the JSON response received from the server:

```json
{
  "device": {
    "hardwarevendor": "Apple",
    "hardwaremodel": "iPhone 14 Pro Max",
    "hardwarename": [
      "iPhone 14 Pro Max"
    ],
    "platformvendor": "Apple",
    "platformname": "macOS",
    "platformversion": "Unknown",
    "iscrawler": false,
    "javascripthardwareprofile": null,
    "javascripthardwareprofilenullreason": null,
    "devicetype": "SmartPhone",
    "setheaderbrowseraccept-ch": "Sec-CH-UA,Sec-CH-UA-Full-Version-List,Sec-CH-UA-Mobile,Sec-CH-UA-Platform",
    "setheaderhardwareaccept-ch": "Sec-CH-UA-Model,Sec-CH-UA-Mobile",
    "setheaderplatformaccept-ch": "Sec-CH-UA-Platform,Sec-CH-UA-Platform-Version"
  },
  "javascriptProperties": [
    "device.javascripthardwareprofile"
  ],
  "warnings": [
    "Low entropy client-hints were supplied in the evidence, but high-entropy client-hints were not.\nThis will lead to less accurate results, and indicates that permissions were not set correctly in the original response to the browser.\nFor more info on client-hint permissions, see http://51degrees.me/documentation/4.4/_device_detection__features__user_agent_client_hints.html."
  ]
}
```

## Startup activity

On startup, the engine must call the `accessibleproperties` and `evidencekeys` 
endpoints, using the configured Resource Key.

The result from `accessibleproperties` will be used to populate a publicly 
accessible (read only) dictionary containing details of the data and 
properties that are expected to be returned by the cloud service for this 
**resource key**.

This information will then be used by [Cloud Aspect Engines](cloud-aspect-engine.md) 
to populate their property meta data collections.

The result from `evidencekeys` will be used to populate the 
[accepted evidence](#accepted-evidence) for this engine.

If either of these requests fail, the engine should throw a critical 
error. as the Pipeline will be unable to function correctly.

See the [HTTP requests](#http-requests) section for details on general 
HTTP request handling.

## Processing

The engine processes FlowData by filtering the evidence and making an HTTP 
request to the server containing that evidence. The HTTP API used for access to 
the server is defined at https://cloud.51degrees.com/api-docs/index.html.

The cloud service can handle evidence in several different forms, but where 
possible, URL-encoded form data should be used. This should be constructed 
by adding the resource key value using the key `resource`, then adding
all the values from the Flow Data Evidence.

When evidence is added, the prefix MUST be removed. 
For example, `query.user-agent` becomes `user-agent`.
This means that conflicts can occur when there are evidence values for the same
key with different prefixes. Where there are conflicts, the precedence order 
defined in the [Evidence](../features/evidence.md) document must be used to
decide which value to use.

See the [HTTP requests](#http-requests) section for details on general 
HTTP request handling.

## HTTP requests

When making requests to the cloud service during startup or processing, some
common steps must be followed.

Firstly, the `Origin` HTTP Header must be set using the configured 
[CloudRequestOrigin](#configuration-options).

Second, there are several scenarios that must cause an error to be thrown:

- The response will usually be a json object, where this is the case, the 
  code must check for an array under a property called `errors` at the top 
  level. If this contains an entry then it must be extracted and the text 
  used as the message for the thrown error. (If there are multiple entries 
  then a language-appropriate structure, such as the c\# AggregateException 
  should be used)
- If the response is empty then the message must be 
  `No data in response from cloud service at '[url]'`
- If the HTTP status code indicates failure (i.e. not 2xx) AND there are no 
  error messages for the reasons mentioned above, the message must be 
  `Cloud service at '[url]' returned status code '[code]' with content [raw response]`

Similarly to the `errors` array, any entries in the `warnings` array in the 
response should be logged as warnings.

## Configuration options

These are the configuration options that are unique to this engine. They 
are in addition to all the configuration options defined for other features. 
For example,
[caching](../../../pipeline-specification/part2/features/caching.md)

| Name                 | Type    | Default                                                 | Description                                                                                                                                                                               |
|----------------------|---------|---------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| EndPoint             | string  | https://cloud.51degrees.com/api/v4/                     | The base URL for the cloud service. This will be suffixed with `json`, `accessibleproperties` or `evidencekeys` to form the complete URLs for the various endpoints called by the engine. |
| DataEndPoint         | string  | https://cloud.51degrees.com/api/v4/json                 | The URL for the cloud service data end point                                                                                                                                              |
| PropertiesEndPoint   | string  | https://cloud.51degrees.com/api/v4/accessibleproperties | The URL for the cloud service properties end point                                                                                                                                        |
| EvidenceKeysEndPoint | string  | https://cloud.51degrees.com/api/v4/evidencekeys         | The URL for the cloud service evidence keys end point                                                                                                                                     |
| ResourceKey          | string  | null                                                    | The Resource Key to use when making requests to the cloud service                                                                                                                         |
| TimeoutSeconds       | integer | 100                                                     | The timeout to use when making requests to the cloud service                                                                                                                              |
| CloudRequestOrigin   | string  | null                                                    | The value to set the 'Origin' header to when making requests to the cloud service                            

