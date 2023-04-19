# Device Detection Cloud

## Overview

Cloud Device Detection presents Evidence <span style="color:yellow">link to 
discussion of detection evidence</span> to the 51Degrees Cloud Detection server, 
which carries out the detection and returns a JSON data structure, 
from which device detection properties are populated in the **FlowData**.

This process is implemented as a two-step process: a Cloud Request Engine
presents the Evidence to the 51Degrees server with an HTTP request
and copies the JSON response into ElementData in the FlowData.

This ElementData is passed using the standard Pipeline FlowData mechanism to
a Device Detection Cloud Engine, later in the Pipeline. Since the detection 
engine depends on the request having been processed in advance, it checks that
ElementData from the cloud request is present in Pipeline before processing.

This check takes place on processing of the FlowData, implementors may choose 
to implement checks at the point of pipeline construction, and report a
configuration error if it is determined that a Cloud Request Engine does not 
precede it in the pipeline. <span style="color:yellow">actually, this would be
difficult, probably</span>

## Resource Key

A Resource Key is a token that serves both to authenticate a request to the 
51Degrees server and to specify which properties are requested as part of the 
device detection. Resource Keys are created using the 
[51Degrees Configurator](todo reference). Using Resource Keys the 51Degrees 
server populates responses with configured properties and implements service
level tiering (number of requests).

<span style="color:yellow">We should discuss relationship between resource key 
and license key here. </span>

## Cloud Request Engine Processing

On creation, the Cloud Request Engine accesses the 51Degrees server to 
configure which evidence keys are needed and also retrieves a list of properties
that can be accessed following a request to the server. This list is 
available to downstream FlowElements.

The engine processes FlowData by filtering the evidence and making an HTTP 
request to the server. The HTTP API used for access to the server
is defined at https://cloud.51degrees.com/api-docs/index.html.

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
- properties of interest - note that it is the resource key that controls
   what the 51Degrees server populates in its response. Configuration
   restricts what is copied from the response into FlowData.
- other values may be configured a discussed in <span style="color:yellow">if 
- not here, where?</span>

## Device Detection Cloud Engine Configuration

There are no configuration options associated with this engine.


## Sample configuration

# Engine
