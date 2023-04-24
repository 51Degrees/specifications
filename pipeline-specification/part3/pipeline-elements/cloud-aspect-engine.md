# Cloud Aspect Engine

## Overview 

The Cloud Aspect Engine is a type of engine that works with the 
[Cloud Request Engine](cloud-request-engine.md#overview) to enable users
to offload processing to a remote service.

See the link above for an overview of how these engines work together.

## Accepted evidence

Cloud Aspect Engines do not use any evidence values, they just consume 
the output from the Cloud Request Engine.

## Element data

The Element Data definition will be different for each Cloud Aspect Engine.
The key requirement is that the Element Data for a Cloud Aspect Engine MUST
be interface compatible with the Element Data for the equivalent on-premise
engine.

For example, both cloud and on-premise device detection engines in c# 
produce an ElementData that implements `IDeviceData`.

## Startup activity

The property meta-data for Cloud Aspect Engines must be retrieved from the 
remote service.

The Cloud Request Engine [requests](cloud-request-engine.md#startup-activity) 
this information on startup. Each Cloud Aspect Engines can then access that 
data to obtain property meta data relating to the properties that it populates. 

## Processing

The precise processing that occurs will depend slightly on the aspect this 
Engine relates to.

However, in general, the process will be something like:

1. Get the portion of the raw JSON that relates to this aspect by using the
   string data key. (For example, `device` for device detection)
2. Use the raw JSON to construct the Element Data result.

The primary difficulty with this process is usually converting from the JSON 
format to whatever structure is needed to support the 
[Null Values](../../features/properties.md#null-values) feature.

For example, in c#, this feature is implemented with the `AspectPropertyValue` 
type. Each value in the JSON is a simple raw string/numeric/boolean value, so
there needs to be logic to:

1. Determine the generic `AspectPropertyValue` type that is needed.
2. Create an instance of that type.
3. Populate the instance with the value from the raw JSON
4. If there is no value in the JSON, Look for a JSON property with the same 
   name suffixed with 'nullreason'. Use this value to set the `NoValueMessage` 
   on the instance.

## Configuration options

There are no configuration options for this engine.