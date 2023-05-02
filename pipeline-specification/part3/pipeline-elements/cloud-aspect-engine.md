# Cloud Aspect Engine

## Overview 

A Cloud Aspect Engine is a type of Engine that works with the 
[Cloud Request Engine](cloud-request-engine.md#overview) to enable users
to refer processing of Evidence to a remote server.

See the link above for an overview of how these Engines work together.
<span style="color:yellow">It would be good to enumerate the existing Cloud Aspect Engines.  
Although this is the description of the common abstraction for all of them - any implementation
still probably would contain at least Cloud Device Detection and Cloud Location Detection - 
as the most prominent examples of this.</span>

## Accepted Evidence

Cloud Aspect Engines do not use any Evidence values, they just consume 
the output from the Cloud Request Engine.

## Element Data

The Element Data definition will be different for each Cloud Aspect Engine.
The key requirement is that the Element Data for a Cloud Aspect Engine MUST
be interface compatible with the Element Data for the equivalent on-premise
engine.

For example, both cloud and on-premise device detection engines in C# 
produce an ElementData that implements `IDeviceData`.

## Start-up activity

Cloud Aspect Engines do not intrinsically contain Property metadata, they 
derive that from the Cloud Request Engine that precedes them in 
the Pipeline.

The Cloud Request Engine [requests](cloud-request-engine.md#start-up-activity) 
this information on start-up. Each Cloud Aspect Engine accesses that 
data to obtain Property metadata relating to the Properties that it populates. 

## Processing

The precise processing that occurs depends on the Aspect this 
Engine relates to.

In outline, the process is:

1. Get the portion of the raw JSON (provided by the Cloud Request Engine as its
   Element Data) that relates to this aspect by using a
   string data key. (For example, `device` for device detection)
2. Use that portion of the raw JSON to construct the Element Data result.

The primary difficulty with this process is usually converting from the JSON 
format to whatever structure is needed to support the 
[Null Values](../../features/properties.md#null-values) feature.

For example, in C#, this feature is implemented with the `AspectPropertyValue` 
type. Each value in the JSON is a simple raw string/numeric/boolean value, so
there needs to be logic to:

1. Determine the generic `AspectPropertyValue` type that is needed.
2. Create an instance of that type.
3. Populate the instance with the value from the raw JSON.
4. If there is no value in the JSON, Look for a JSON property with the same 
   name suffixed with `nullreason`. Use this value to set the `NoValueMessage` 
   on the instance.

## Configuration options

There are no configuration options for this Engine.