# Device Detection Cloud

## Overview

Cloud Device Detection presents [Evidence](../../pipeline-specification/features/evidence.md) 
to the 51Degrees Cloud Detection server, which carries out the detection 
and returns a JSON data structure, from which device detection properties 
are populated in the **FlowData**.

This is implemented as a two-step process: a Cloud Request Engine
presents the Evidence to the 51Degrees server with an HTTP request
and copies the JSON response into ElementData in the FlowData.

This ElementData is passed using the standard Pipeline FlowData mechanism to
a Device Detection Cloud Engine, later in the Pipeline. Since the detection 
engine depends on the request having been processed in advance, it checks that
ElementData from the cloud request is present in Pipeline before processing.

![Cloud engine flow](../../../pipeline-specification/images/Device%20Detection%20Cloud%20Engine.png)

The majority of the logic that must be performed by the Device Detection Cloud
Engine is common to all cloud engines and is described in the 
[Cloud Aspect Engine](../../pipeline-specification/pipeline-elements/cloud-aspect-engine.md) 
document.

## Device Detection Cloud Engine Configuration

There are no configuration options associated with this engine.

## Device Detection Cloud Engine Processing

When it is added to a pipeline, Device Detection Cloud Engine initializes
itself from a Cloud Request Engine, which must have been added to the pipeline
before it. 

The Cloud Request Engine determines which properties are available
based on the resource key supplied on start-up. The Device Detection Cloud engine 
then takes the details of the subset of those properties that are relevant to 
device detection.

See [Cloud Request Engine](../../pipeline-specification/pipeline-elements/cloud-request-engine.md) 
for more details of this engine.
<span style="color:yellow">move the remainder of text here to pipeline spec 
to create that document</span>

## Resource Key

A Resource Key is a token that serves both to authenticate a request to the 
51Degrees server and to specify which properties are requested as part of the 
device detection. Resource Keys are created using the 
[51Degrees Configurator](https://51degrees.com/documentation/4.4/_concepts__configurator.html). Using Resource Keys the 51Degrees 
server populates responses with configured properties and implements service
level tiering (number of requests). 
See [Resource Keys Documentation](https://51degrees.com/documentation/4.4/_info__resource_keys.html)
for more information.

## Cloud Request Engine Processing

On creation, the Cloud Request Engine accesses the 51Degrees server to 
configure which evidence keys are needed and also retrieves a list of properties
that can be accessed following a request to the server. This list is 
available to downstream FlowElements, in particular to the Device Detection 
Cloud Engine (q.v.)

The engine processes FlowData by filtering the evidence and making an HTTP 
request to the server containing that evidence. The HTTP API used for access to 
the server is defined at https://cloud.51degrees.com/api-docs/index.html.

The JSON received from the server is added to the FlowData as ElementData 
for the Cloud Request Engine and hence is available to downstream Flow Elements.

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

## Cloud Request Engine Configuration

Aside from configuration of the ResourceKey, the engine may be additionally 
configured with:
- the server URL (by default https://cloud.51degrees.com/api/v4/)
- a timeout value for requests (by default 100 seconds)
- a cache - (by default, no cache, however it is strongly recommended that 
    the engine is configured with a cache)
- other values may be configured as discussed in <span style="color:yellow">if 
not here, where?</span>
