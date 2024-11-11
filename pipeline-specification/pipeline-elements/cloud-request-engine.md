# Cloud Request Engine

Cloud Engines offload their processing to a remote system. This reduces
resource requirements and avoids the complexities of some local
Engines (For example,
[Device Detection on premise](../../device-detection-specification/pipeline-elements/device-detection-on-premise.md)
has a native component that requires additional dependencies that
can be difficult to get running in some environments)

The Pipeline API splits this cloud processing over two separate types of
Engine:

- Cloud Request Engine - The subject of this section, makes an HTTP
  call to a remote service and makes the raw JSON response available
  by adding it to its Aspect Data.
- [Cloud Aspect Engine](cloud-aspect-engine.md) - Designed to be swapped
  out with an equivalent On-premise Engine. Takes the raw JSON response
  from the Cloud Request Engine's Aspect Data and deserializes it to
  populate its own Aspect Data, which is interface compatible
  with the Aspect Data from the On-premise Engine.

The following diagram illustrates this process with a Device Detection
Cloud Engine:

![Cloud Engine flow](../images/Device%20Detection%20Cloud%20Engine.png)

A Pipeline will usually have a single Cloud Request Engine, but might have
multiple Cloud Aspect Engines - for example, a Location Cloud Engine,
Device Detection Cloud Engine, etc.

This approach is taken in order to allow Cloud Engines to behave as
similarly as possible to On-premise Engines from the user point of view,
while limiting the number of HTTP requests to the remote
server to one per Flow Data, regardless
of the number of different Aspects that are involved. This is important
for performance as the HTTP request time is the majority of the time
taken in many scenarios.

## Resource Key

A Resource Key is a token that serves both to authenticate a request to the
remote server and to specify which Property values are returned in the
result. Resource Keys are created using the
[51Degrees Configurator](https://51degrees.com/documentation/_concepts__configurator.html).
See [Resource Key documentation](https://51degrees.com/documentation/_info__resource_keys.html)
for more information.

## Accepted Evidence

Accepted Evidence is dependent on the supplied Resource Key.

The Engine will make a request to its remote server to get this information.  This should be
treated is failable lazy loaded data, see the [redesigned start-up activity](#updated-design).

## Element Data

| **Name**      | **Type** | **Description**                                   |
|---------------|----------|---------------------------------------------------|
| json-response | string   | The raw JSON response body from the HTTP request. |

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
    "Low entropy client-hints were supplied in the evidence, but high-entropy client-hints were not.\nThis will lead to less accurate results, and indicates that permissions were not set correctly in the original response to the browser.\nFor more info on client-hint permissions, see http://51degrees.me/documentation/_device_detection__features__user_agent_client_hints.html."
  ]
}
```

## Start-up activity

There were design issues discovered and the design of start-up activity has been updated.
The implementation should follow the updated design for all APIs.  For historical purposes the previous design
is left as is below, and then changes explanations follow.

### Previous Design

On start-up, the Engine will call its [configured](#configuration-options)
`accessibleproperties` and `evidencekeys` endpoints, using the configured Resource Key.

The result from `accessibleproperties` will be used to populate a publicly
accessible (read only) dictionary containing details of the data and
Properties that are expected to be returned by the cloud service for this
Resource Key.

This information will then be used by [Cloud Aspect Engines](cloud-aspect-engine.md)
to populate their Property metadata collections.

The result from `evidencekeys` will be used to populate the
[accepted Evidence](#accepted-evidence) for this Engine.

If either of these requests fails, the Engine MUST throw a critical
error as the Pipeline will be unable to function correctly.

See [HTTP requests](#http-requests) for general details on
HTTP request handling.

### Updated Design

#### Motivation for change

There was a problem with the old design.

We have discovered that customers encounter severe problems in case 51d cloud service, server machine or domain (cloud.51degrees.com)
are down or unavailable.  In this case the `CloudRequestEngine`  constructor would not be able to obtain `eviddencekeys` or `accessibleproperties`
and would throw an exception.  This can bring the whole customer service down especially in the [web integrations](../features/web-integration.md) where Pipeline functions as part of a request processing module/plugin (f.e. .NET Cloud/Framework-Web integration) - and the integration code does not even have an opportunity to properly catch the exceptions.

Of course construction should happen once, but there are service restarts and/or starts that might occur f.e. due to auto-scaling - so construction can happen undeterministically and
the customer can end up with an unitializable pipeline under the above circumstance.

However there is already a feature [`SuppressProcessExceptions`](../features/exception-handling.md) - this is a configuration flag that tells Pipeline
to not throw exceptions during processing.  We wanted to use this flag and extend its effect on this scenario when `evidencekeys` or `accessibleproperties` can
not be obtained due to host being down or due to other reasons.  

### Changes

The above motivation led to the following design decision.  `evidencekeys`, `accessibleproperties` or any future dependence on cloud.51degrees.com
(or any other external service) - must be made **lazy** and obtained (once and then cached) only at the point of first use!  In particular they must be made initialized
within the scope of a (Web)Pipeline.Process method call.  

That way if the host is down and any exception is thrown - the `SuppressProcessExceptions`, if it was specified
in the Pipeline configuration, would take effect and the exceptions would be suppressed and logged rather than throwing and bringing the customer service down.
**Thus, there is no particular start up activity, but any "start-up" properties should be made lazy for this element.**
Throwing exceptions if either of these lazy properties fails to initialize still holds, however they now will be thrown in the context of Process() and not constructor.  

## Processing

The Engine processes Flow Data by filtering the full list of Evidence down
to just Evidence keys needed by the server, and makes an HTTP
request to the server using the filtered Evidence. The HTTP API used for access to
51Degrees servers is defined at <https://cloud.51degrees.com/api-docs/index.html>.

The server can handle Evidence in a number of different forms, but where
possible, URL-encoded form data will be used. This is constructed
by adding the Resource Key value using the key `resource`, then adding
all the values from the Flow Data Evidence.

When Evidence is added, its prefix MUST be removed.
For example, `query.user-agent` becomes `user-agent`.
This means that conflicts can occur when there are Evidence values for the same
key with different prefixes. Where there are conflicts, the precedence order
defined in [Evidence](../features/evidence.md) MUST be used to
determine which value to send to the remote server.

See [HTTP requests](#http-requests) for general details on
HTTP request handling.

## HTTP requests

When making requests to the remote server during start-up or processing, some
common steps MUST be followed.

Firstly, the `Origin` HTTP Header MUST be set using the configured
[CloudRequestOrigin](#configuration-options).

Second, there are several scenarios that SHOULD cause an error to be thrown:

- If the top-level `errors` Property in the JSON response
  contains an entry, then it will need to be parsed and the text
  used as the message for the thrown error. (If there are multiple entries
  then a language-appropriate structure, such as the C# AggregateException
  SHOULD be used)
- If the HTTP response body is empty then the message will be
  `No data in response from cloud service at '[url]'`
- If neither of the above scenarios apply but the HTTP status code indicates
- failure (i.e. not 200), the message will be
  `Cloud service at '[url]' returned status code '[code]' with content [raw response]`
  (truncate raw response as needed)

Similarly to the `errors` array, any entries in the `warnings` array in the
response MUST be logged as warnings.

### Recovery Mode
**Note:** currently supported by .NET implementation only.

If responses from the cloud server become slow due to issues like network disruptions or potential attacks, this could result in timeouts, causing consumer requests to stall (e.g., waiting on a lock to access evidencekeys). Such a situation could degrade user experience and potentially deplete server resources (e.g., RAM or socket connections).

To mitigate this risk, if a significant number of request failures occur within a brief period, the engine can enter a "recovery period." During this phase, requests are bypassed, and a direct signal is sent indicating the temporary unavailability of the element (and the entire pipeline), preventing further strain on the system.

In case of ASP.NET Core / ASP.NET Framework integrations such errors will be suppressed -- as though under the effect of [`SuppressProcessExceptions`](../features/exception-handling.md) -- making the FlowData available, but without any usable data (except errors).

## Configuration options

These are the configuration options that are unique to this Engine. They
are in addition to all the configuration options defined for other features.
For example,
[caching](../../pipeline-specification/features/caching.md)

| **Name**                | **Type** | **Default**                                               | **Description**                                                                                                                                                                           |
|-------------------------|----------|-----------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| EndPoint                | string   | <https://cloud.51degrees.com/api/v4/>                     | The base URL for the cloud service. This will be suffixed with `json`, `accessibleproperties` or `evidencekeys` to form the complete URLs for the various endpoints called by the Engine. |
| DataEndPoint            | string   | <https://cloud.51degrees.com/api/v4/JSON>                 | The URL for the cloud service data end point                                                                                                                                              |
| PropertiesEndPoint      | string   | <https://cloud.51degrees.com/api/v4/accessibleProperties> | The URL for the cloud service Properties end point                                                                                                                                        |
| EvidenceKeysEndPoint    | string   | <https://cloud.51degrees.com/api/v4/Evidencekeys>         | The URL for the cloud service Evidence keys end point                                                                                                                                     |
| ResourceKey             | string   | null                                                      | The Resource Key to use when making requests to the cloud service                                                                                                                         |
| TimeoutSeconds          | integer  | 2                                                         | The timeout to use when making requests to the cloud service                                                                                                                              |
| CloudRequestOrigin      | string   | null                                                      | The value to set the 'Origin' header to when making requests to the cloud service                                                                                                         |
| FailuresToEnterRecovery | integer  | 10                                                        | The number of request failures that must occur within the timeframe defined by `FailuresWindowSeconds` for the engine to transition into a "recovery period."                             |
| FailuresWindowSeconds   | integer  | 100                                                       | The time frame in seconds within which the number of failed requests must reach the threshold set by FailuresToEnterRecovery for the engine to enter a "recovery period."                 |
| RecoverySeconds         | double   | 60.0                                                      | The duration of the recovery period in seconds. Set this to zero or a negative value to disable the recovery period.                                                                      | 
