# Data model

## Introduction

This document contains the details of the data values returned by 51Degrees
IP Intelligence.

## Overview

All Engines MUST populate data objects that
implement [Aspect Data](../pipeline-specification/conceptual-overview.md#aspect-data)
as defined in the Pipeline specification.

## Element Data

Element data returned by an IP Intelligence Engine MUST implement the
`IMultiWeightedAspectData` interface.
This interface extends `IAspectData` contains the following:

| Property | Type |
| -------- | ---- |
| Profiles | `IReadOnlyList<T> where T : IWeightedAspectData` |

This list of individual Aspect Data are weighted, by implementing the `IWeightedAspectData`
interface which has the following:

| Property | Type |
| -------- | ---- |
| Weighting | `float` |


The weightings of all Aspect Data for each component MUST add up to 1. So for 4 Components,
the total would be 4.

If there is only one profile for a component, then this just has a weighting of 1.

### Component Types

The Aspect Data contained in the multi Aspect Data consists of the following 4 types:

#### Network

| Property | Type |
| -------- | ---- |
| Ip | `string` |
| IpV6 | `string ` |
| IpRangeStart | `string` |
| IpRangeEnd | `string` |
| Name | `string` |
| Owner | `string` |


#### Location

| Property | Type |
| -------- | ---- |
| Latitude | `float` |
| Longitude | `float` |
| Areas | `IReadOnlyList<IArea>` |
| AccuracyRadius | `int` |

Location also includes all properties from the existing location results model.
This type will extend [`IGeoData`](https://github.com/51Degrees/location-dotnet/blob/main/FiftyOne.GeoLocation.Core/Data/IGeoData.cs).

The `IArea` type is defined in `pipeline-core`, see [Area Type](#area-type).

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
    //  Defined in IMultiWeightedAspectData
    IReadOnlyList<IWeightedAspectData<IWeightedAspectData>> Profiles { get; }

    // Gets the MCC values
    // Defined in IIpIntelligenceData
    IReadOnlyList<IWeightedValue<int>> Mcc { get; }

    // Contains only the MCC profiles
    // Defined in IIpIntelligenceData
    IReadOnlyList<IMccData> MccProfiles { get; }
}
```

The same applies to the other 3 components.

## Data File Structure

Data files follow the standard 51Degrees data file structure, with the addition
of profile groups. See [Hash dataset](https://github.com/51Degrees/device-detection-cxx/blob/main/src/hash/hash.h#L295).

### Profile Groups

A profile is pointed to by an integer offset. This is the same as existing data 
files. In the case where this offset is negative, it points to a group of
profiles instead. Profile groups exist in a separate collection, and a profile
group structure is as follows:

| Property | Type |
| -------- | ---- |
| Count | `short` |
| Profiles | WeightedProfile[] |

Where `WeightedProfile` is 
| Property | Type |
| -------- | ---- |
| Profile Id | `int` |
| Profile Offset | `int` |
| Weighting | `float` |

Count is the number of profile offsets and weightings that follow.

## Property Metadata

For on-premise implementations, the metadata associated with properties is
contained within the data file. See [device-detection dotnet engine](https://github.com/51Degrees/device-detection-dotnet/blob/main/FiftyOne.DeviceDetection.Hash.Engine.OnPremise/FlowElements/DeviceDetectionHashEngine.cs) and [device-detection cxx metadata](https://github.com/51Degrees/device-detection-cxx/blob/main/src/hash/MetaDataHash.hpp)

For cloud implementations, the metadata associated with properties is
fetched from the cloud service. See [CloudAspectEngineBase](https://github.com/51Degrees/pipeline-dotnet/blob/main/FiftyOne.Pipeline.CloudRequestEngine/FlowElements/CloudAspectEngineBase.cs).

## Area Type

A new property type for the IP Intelligence Engine is the `IArea` interface.
This uses a WKT/WKB shape (see https://en.wikipedia.org/wiki/Well-known_text_representation_of_geometry).

This comes from the data file in WKB format. And is interpreted to a more useable
form, as the interface `IShape` which has the following properties:

| Property | Type |
| -------- | ---- |
| Points   | `IReadOnlyList<IPoint>` |

and `IPoint` is a coordinate (also represented in the WKB format) with the
properties:

| Property | Type |
| -------- | ---- |
| X | `float` |
| Y | `float` |

An `IArea` is one of many forms that an `IShape` can describe. For example,
a single line, or coordinate.

Implementation adheres to the [OGC 06-103r4](https://www.ogc.org/publications/standard/sfa/) standard.

**TODO: Note that WKT is not yet implemented in core, but is part of a parallel project.**

## Property Details

Each Property SHOULD return
an [Aspect Property value](../pipeline-specification/features/properties.md#null-values)
in order to support exposing the reason that a value is not set.

Additionally, values SHOULD be returned along with their weights. Meaning the
introduction of the `IWeightedValue<T>` type, with the following properties:

| Property | Type |
| -------- | ---- |
| Value | `T` |
| Weighting | `float` |

There are some cases where a weighting is not appropriate for a property.
For example, the Ip property.