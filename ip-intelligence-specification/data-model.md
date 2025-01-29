# Data model

## Introduction

This document contains the details of the data values returned by 51Degrees
IP Intelligence.

## Overview

All Engines MUST populate data objects that
implement [Aspect Data](../pipeline-specification/conceptual-overview.md#aspect-data)
as defined in the Pipeline specification.

## User Facing Structure

Element data returned by an IP Intelligence Engine MUST implement the
`IMultiWeightedAspectData` interface.
This interface extends `IAspectData` contains the following:

| Property | Type |
| -------- | ---- |
| Profiles | `IReadOnlyList<T> where T : IWeightedAspectData` |

Each property MUST also be exposed as a [weighted value](../pipeline-specification/features/weighted-values.md) 

This list of individual Aspect Data are weighted, by implementing the `IWeightedAspectData`
interface which has the following:

| Property | Type |
| -------- | ---- |
| Weighting | `float` |

The weightings of all Aspect Data for each component MUST add up to 1. So for 4 Components,
the total would be 4.

If there is only one profile for a component, then this just has a weighting of 1.

### Component Types

There are multiple components per data file, and the weightings for the profiles for
each are not necessarily the same across all component results.
Therefore the components are treated separately when getting values and their weightings.
This does not mean that the properties are not exposed in the same way.

The Aspect Data contained in the multi Aspect Data consists of the following 4 types:

#### Network

| Property | Type |
| -------- | ---- |
| IpRangeStart | `string` |
| IpRangeEnd | `string` |
| Name | `string` |
| Owner | `string` |
| Asn | `int` |

#### Location

| Property | Type |
| -------- | ---- |
| Latitude | `float` |
| Longitude | `float` |
| Areas | `WktString` |
| AccuracyRadius | `int` |

Location also includes all properties from the existing location results model.
This type will extend [`IGeoData`](https://github.com/51Degrees/location-dotnet/blob/main/FiftyOne.GeoLocation.Core/Data/IGeoData.cs).

The only properties from `IGeoData` which are populated are:
- Town
- County
- Region
- State
- ZipCode
- Country
- CountryCode
- CountryCode3
- TimeZoneOffset

The rest will return null values with an appropriate null value reason.

The `WktString` type is defined in `pipeline-core`, see [WKT Type](#wkt-type).

#### MCC

| Property | Type |
| -------- | ---- |
| MCC | `int` |

#### MNC

| Property | Type |
| -------- | ---- |
| MNC | `int` |

### Example

As an example, take the MCC component. The rough implementation would look like:

```{cs}
class MccData : IWeightedAspectData, IMccData
{
    // From IMccData
    int Mcc { get; }
    // From IWeightedAspectData
    float Weighting { get; }
}
```

And the engine would return a type of:

```{cs}
class IpIntelligenceData : IMultiWeightedAspectData IIpIntelligenceData
{
    // Contains all profiles
    // Defined in IMultiWeightedAspectData
    IReadOnlyList<IWeightedAspectData> Profiles { get; }

    // Gets the MCC values
    // This is the accessor that most callers will use
    // Defined in IIpIntelligenceData
    IReadOnlyList<IWeightedValue<int>> Mcc { get; }

    // Contains only the MCC profiles
    // Defined in IIpIntelligenceData
    IReadOnlyList<IMccData> MccProfiles { get; }
}
```

The same applies to the other 4 components.

## Internal Data File Structure

Data files follow the standard 51Degrees data file structure, with the addition
of profile groups. See [Hash dataset](https://github.com/51Degrees/device-detection-cxx/blob/main/src/hash/hash.h#L295). Meaning that collections and headers are common,
and logic from [common-cxx](https://github.com/51Degrees/common-cxx) should be used.
Collections shared with Hash are:
- values (named strings in Hash as only string values are used)
- properties
- profiles
- components

See [general data model](../data-model-specification/README.md) for more info.

### Profile Groups

A profile is pointed to by an integer offset. This is the same as existing data 
files. In the case where this offset is negative, it points to a group of
profiles instead. Profile groups exist in a separate collection, and a profile
group structure is an array of `WeightedProfile`, where `WeightedProfile` is:

| Property | Type |
| -------- | ---- |
| Profile Offset | `int` |
| Weighting | `float` |

The number of profiles which make up a group is not written. However, with
the axiom that weightings add up to 1 for a component, profiles are read until
the total weighting is 1, signifying that the array is complete.

## Property Metadata

For on-premise implementations, the metadata associated with properties is
contained within the data file. See [device-detection dotnet engine](https://github.com/51Degrees/device-detection-dotnet/blob/main/FiftyOne.DeviceDetection.Hash.Engine.OnPremise/FlowElements/DeviceDetectionHashEngine.cs) and [device-detection cxx metadata](https://github.com/51Degrees/device-detection-cxx/blob/main/src/hash/MetaDataHash.hpp)

For cloud implementations, the metadata associated with properties is
fetched from the cloud service. See [CloudAspectEngineBase](https://github.com/51Degrees/pipeline-dotnet/blob/main/FiftyOne.Pipeline.CloudRequestEngine/FlowElements/CloudAspectEngineBase.cs).

## WKT Type

A new property type for the IP Intelligence Engine is the `WktString` interface.
This uses a WKT/WKB shape (see https://en.wikipedia.org/wiki/Well-known_text_representation_of_geometry).

This comes from the data file in WKB format. And is interpreted to a more useable
form, as the interface `WktString` which extends string, and contains a WKT
format string.

Implementation adheres to the [OGC 06-103r4](https://www.ogc.org/publications/standard/sfa/) standard.

**TODO: Note that WKT is not yet implemented in core, but is part of a parallel project.**

## Property Details

Each Property SHOULD return
an [Aspect Property value](../pipeline-specification/features/properties.md#null-values)
in order to support exposing the reason that a value is not set.

Additionally, values MUST be returned along with their weights when fetched
from the `IMultiWeightedAspectData`. Meaning the introduction of the 
`IWeightedValue<T>` type, with the following properties:

| Property | Type |
| -------- | ---- |
| Value | `T` |
| Weighting | `float` |

For example:
```{cs}
// All weighted values for a property
IAspectPropertyValue<IWeightedValue<int>> allValues = flowData
    .Get<IpIntelligenceData>()
    .MCC;
// Compared to finding the highest weighted value for
// a property
IAspectPropertyValue<int> firstValue = flowData
    .Get<IpIntelligenceData>()
    .MccProfiles[0]
    .MCC;
```