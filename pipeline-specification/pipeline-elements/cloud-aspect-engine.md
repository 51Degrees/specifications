# Cloud Aspect Engine

A Cloud Aspect Engine is a type of Engine that works with the
[Cloud Request Engine](cloud-request-engine.md#overview) to enable users
to refer processing of Evidence to a remote server.

See the link above for an overview of how these Engines work together.

At time of writing, there are 3 concrete Cloud Aspect Engine implementations:

- [Device Detection](../../device-detection-specification/pipeline-elements/device-detection-cloud.md)
- [Device Lookup (TAC and native key)](../../device-detection-specification/part3/pipeline-elements/hardware-profile-lookup-cloud.md)
- [Location](https://github.com/51Degrees/location-dotnet/blob/master/FiftyOne.GeoLocation.Cloud/FlowElements/GeoLocationCloudEngine.cs)
  (Location is not yet included in this specification repository)

## Accepted Evidence

Cloud Aspect Engines do not use any Evidence values, they just consume
the output from the Cloud Request Engine.

## Element Data

The Element Data definition will be different for each Cloud Aspect Engine.
The key requirement is that the Element Data for a Cloud Aspect Engine MUST
be interface compatible with the Element Data for the equivalent on-premise
Engine.

For example, both cloud and on-premise Device Detection Engines in C#
produce an Element Data that implements the interface `IDeviceData`.

## Start-up activity

Cloud Aspect Engines do not intrinsically contain Property metadata, they
derive that from the Cloud Request Engine that precedes them in
the Pipeline.

The Cloud Request Engine [requests](cloud-request-engine.md#start-up-activity)
this information on start-up. Each Cloud Aspect Engine accesses that
data to obtain Property metadata relating to the Properties that it populates.

## Processing

The precise processing that occurs depends on the Aspect this
Engine relates to. In essence though, it simply needs to filter and
deserialize the raw JSON from the Cloud Request Engine:

1. Get the portion of the raw JSON (provided by the Cloud Request Engine in its
   Element Data) that relates to this Aspect by using the appropriate
   string Data Key. (For example, `device` for Device Detection)
2. Deserialize that portion of the raw JSON to construct the Element Data result.

The primary difficulty with this process is usually converting from the JSON
format to whatever structure is needed to support the
[Null Values](../features/properties.md#null-values) feature.

For example, in C#, this feature is implemented with the `AspectPropertyValue`
type. Each value in the JSON is a simple raw string/numeric/boolean value, so
there needs to be logic to:

1. Determine the generic `AspectPropertyValue` type that is needed.
2. Create an instance of that type.
3. Populate the instance with the value from the raw JSON.
4. If there is no value in the JSON, Look for a JSON Property with the same
   name suffixed with `nullreason`. Use this value to set the `NoValueMessage`
   on the instance.

## Configuration options

There are no specific configuration options for this Engine.

The [caching](../features/caching.md) feature will not work
with this Engine because it does not use any Evidence, hence there
is no key to use in the cache.
It is recommended that caching is applied to the Cloud Request Engine instead
(Though this also becomes problematic if more than one Cloud Aspect Engine
is involved)

Implementors MAY chose to restrict the available configuration options accordingly.
