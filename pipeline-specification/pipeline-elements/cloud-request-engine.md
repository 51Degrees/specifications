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

The Engine will make a request to its remote server to get this information.  The Engine
resolves it when it is built, retrying on first use only after a transient failure, see the
[start-up activity](#start-up-activity).

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

There were design issues with a previous revision of this specification, and the
design of start-up activity has been revised. The implementation should follow
the revised design below for all APIs. The withdrawn fully lazy design and the
reasons it was wrong are kept at the end for context.

### Revised design (eager discovery at build time, transient-failure fallback)

On start-up the Engine resolves, for the configured Resource Key, the accessible
Properties (from the [configured](#configuration-options) `accessibleproperties`
endpoint) and the accepted Evidence keys (from `evidencekeys`). The Engine MUST
attempt both discovery requests when it is built (in its builder or constructor),
and MAY make them in parallel, so that in the normal case a built Engine is fully
initialised and immediately ready to process Flow Data.

The result from `accessibleproperties` populates a publicly accessible (read
only) collection describing the data and Properties expected from the cloud
service for this Resource Key. [Cloud Aspect Engines](cloud-aspect-engine.md) use
it to populate their Property metadata collections. The result from `evidencekeys`
populates the [accepted Evidence](#accepted-evidence) for the Engine.

How a discovery failure at build time is handled depends on its class:

- **Definitive configuration errors** - an HTTP 4xx response to a discovery
  request (for example an invalid Resource Key) - MUST fail the build with a
  critical error. Retrying with the same configuration can never succeed, so
  the Engine fails fast with a clear error at start-up instead of surfacing the
  misconfiguration on the first request.
- **Transient failures** - the service unreachable (DNS or connection failure),
  a timeout, or an HTTP 5xx response - MUST NOT fail the build. The Engine MUST
  log a warning, complete the build, and retry discovery on first use. Failures
  of those first-use retries are process-time failures, so
  [`SuppressProcessExceptions`](../features/exception-handling.md) applies to
  them as to any other processing error.

A temporary cloud outage at construction time therefore cannot prevent the
application from starting, while a misconfiguration surfaces immediately.

See [HTTP requests](#http-requests) for general details on HTTP request handling.

### Consequences for consumers of the Engine

When discovery succeeds at build time (the normal case), consumers that read the
Engine while the Pipeline is assembled - the pipeline-wide accepted-Evidence
filter (used for the web `Vary` header), the SetHeaders element (client-hints
`Accept-CH`), and Property-metadata introspection - see correct, complete data
before the first request.

After a transient discovery failure, the built Engine advertises empty accepted
Evidence and empty Property metadata until a first-use retry succeeds. Consumers
of this information therefore MUST tolerate it being temporarily absent and MUST
NOT permanently cache an empty result obtained before discovery has completed.

### Resilience

The concern that originally motivated lazy loading (an outage of the 51Degrees
cloud must not bring the customer service down) is met by the transient-failure
fallback above rather than by deferring all discovery.

In addition, implementations SHOULD allow an Engine to be built from a
previously obtained, persisted copy of the discovery results (the accepted
Evidence keys and the accessible Properties, which depend only on the Resource
Key). When supplied, the builder uses it and makes no cloud request, so the
Pipeline can be built offline and a short-lived or frequently-restarted host
(for example a serverless or edge / WebAssembly runtime) need not call the
cloud on every cold start. The persisted copy is read back from the builder
after a successful build. At the time of writing no implementation provides
this yet.

### Why the fully lazy design was withdrawn

A previous revision deferred the `accessibleproperties` and `evidencekeys`
requests to the first `Process` call ("lazy" discovery) unconditionally, so
that a [`SuppressProcessExceptions`](../features/exception-handling.md)
Pipeline could absorb a cloud outage at start-up rather than failing
construction.

That design has been withdrawn, because it left a "built" Engine that was not
ready to process Flow Data even when the cloud was perfectly healthy:

- Construction did not mean ready. A built Engine reported an empty
  accepted-Evidence filter and empty Property metadata until its first `Process`,
  which is a broken abstraction.
- Consumers that read the Engine when the Pipeline is assembled, before any
  `Process`, saw nothing. The pipeline-wide accepted-Evidence filter (used for the
  web `Vary` header) and the SetHeaders element read the Engine's advertised keys
  and Properties at Pipeline-build time, so under lazy loading they were empty, and
  features such as the client-hints `Accept-CH` headers did not work on the first
  request.
- Metadata introspection before the first `Process` returned wrong, empty answers.
- It hid configuration errors: an invalid Resource Key only surfaced on the
  first request, in whatever context happened to trigger it, instead of at
  start-up.

The revised design keeps first-use retry only as the fallback path for
transient outages; it is no longer the normal start-up behaviour.

### Impact on implementations

Every SDK that adopted the withdrawn lazy design MUST warm discovery at Engine
construction as described above: attempt both requests at build time, fail the
build on a definitive configuration error, and fall back to first-use retry
only after a transient failure. This is a small, localised change to the Cloud
Request Engine. Adding the optional persisted-state constructor described
above is recommended so a Pipeline can also be built entirely offline.

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
