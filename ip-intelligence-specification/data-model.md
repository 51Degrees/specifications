# Data model

## Introduction

This document contains the details of the data values returned by 51Degrees
IP Intelligence.

## Overview

All Engines MUST populate data objects that
implement [Aspect Data](../pipeline-specification/conceptual-overview.md#aspect-data)
as defined in the Pipeline specification.

## Components

The IP Intelligence Engine contains multiple components, where the values for
each are resolved separately. This means that there are multiple graphs in the
data file, each linked to one or more components, and are evaluated to get the
values for the linked component.

The components in an IP Intelligence data file can include (but are not
limited to) the following:

| Component Name | Description |
| --- | --- |
| Network | Contains properties relating to the network the IP belongs to. For example, the start and end of the registered range, or the registered owner. |
| Location | Contains properties relating to the location the IP has been recorded in. For example, the latitude, longitude, or city. |

The benefit of separating components is that graphs can be optimized for the
IP ranges that apply to profiles for that component.

## User Facing Structure

Element data returned by an IP Intelligence Engine MUST extend
`IAspectData`.

Each property MUST also be exposed as a [weighted value](../pipeline-specification/features/weighted-values.md)

### Properties

| Property | Type |
| -------- | ---- |
| IpRangeStart | `string` |
| IpRangeEnd | `string` |
| Name | `string` |
| Owner | `string` |
| Asn | `int` |
| Latitude | `float` |
| Longitude | `float` |
| Areas | `WktString` |
| AccuracyRadius | `int` |

The `WktString` type is defined in `pipeline-core`, see [WKT Type](#wkt-type).

### Example

As an example, a rough interface  would look like:

```{cs}
interface IIpIntelligenceData
{
    IReadOnlyList<IWeightedValue<string>> Name { get; }
    ...
}
```

## Internal Data File Structure

Data files follow the standard 51Degrees data file structure, with the addition
of profile groups. Meaning that collections and headers are common,
and logic from [common-cxx](https://github.com/51Degrees/common-cxx) should be used.
Collections shared with [Hash dataset](https://github.com/51Degrees/device-detection-cxx/blob/main/src/hash/hash.h#L295) are:

- values (named strings in Hash as only string values are used)
- properties
- profiles
- components

See [general data model](../data-model-specification/README.md) for more info.

### Profile Groups

A profile is pointed to by an integer offset by going through the profile offsets collection. This is the same as existing data
files. For a profile group, the offsets collection is not required. Profile groups exist in a separate collection, and a profile
group structure is an array of `WeightedProfile`, where `WeightedProfile` is:

| Property | Type |
| -------- | ---- |
| Profile Offset | `int` |
| Weighting | `ushort` |

The value returned after evaluating the graph is a ulong. The possibilities for a returned value are:

| Scenario | Meaning | Access Path |
| -------- | ------- | ----------- |
| The value is less than the number of nodes in the nodes collection (`value < totalNodes`)| The node is not a leaf, so does not point to either a profile, or a profile group (see [ip-graph-cxx](https://github.com/51degrees/ip-graph-cxx)) | N/A |
| The value is greater than, or equal to, the number of nodes, but is less than the number of profiles after subtracting the number of nodes (`value >= totalNodes && value - totalNodes < totalProfiles`) | The value, minus the number of nodes in the nodes collection, is an index in the profile offsets collection | `offsetIndex = value - totalNodes`<br/>`offset = offsets[offsetIndex]`<br/>`profile = profiles[profileOffset]` |
| The value is greater than the number of nodes, and is greater than, or equal to, the number of profiles after subtracting the number of nodes (`value > totalNodes && value - totalNodes >= totalProfiles`) | The value, minus the number of nodes and profiles, is the index of the first weighted profile in the profile groups collection | `groupIndex = value - totalNodes - totalProfiles`<br/>`firstWeightedProfileOfGroup = profileGroups[groupIndex]` |

The number of profiles which make up a group is not written. However, with
the axiom that weightings add up to ushort.max for a component, profiles are read until the total raw weighting is ushort.max, signifying that the array is complete.


## Property Metadata

For on-premise implementations, the metadata associated with properties is
contained within the data file. See [ip-intelligence dotnet engine](https://github.com/51Degrees/ip-intelligence-dotnet/blob/main/FiftyOne.IpIntelligence.Engine.OnPremise/FlowElements/IpiOnPremiseEngine.cs) and [ip-intelligence cxx metadata](https://github.com/51Degrees/ip-intelligence-cxx/blob/main/src/MetaDataIpi.hpp)

For cloud implementations, the metadata associated with properties is
fetched from the cloud service. See [CloudAspectEngineBase](https://github.com/51Degrees/pipeline-dotnet/blob/main/FiftyOne.Pipeline.CloudRequestEngine/FlowElements/CloudAspectEngineBase.cs).

### Component Types

There are multiple components per data file, and the weightings for the profiles for
each are not necessarily the same across all component results.
Therefore the components are treated separately when getting values and their weightings.
This does not mean that the properties are not exposed in the same way.

The results contained in the combined result consists of the following 2 types:

- [Network](https://github.com/51Degrees/common-metadata/tree/main/Properties/Network)
- [Location](https://github.com/51Degrees/common-metadata/tree/main/Properties/Location)
