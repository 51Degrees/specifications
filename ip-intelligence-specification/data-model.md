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
| Profiles | `IReadOnlyList<IWeightedAspectData>` |

This list of individual Aspect Data are weighted, by implementing the `IWeightedAspectData`
interface which has the following:

| Property | Type |
| -------- | ---- |
| Weighting | `float` |


The weightings of all Aspect Data for each component MUST add up to 1. So for 4 Components,
the total would be 4.

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
| Areas | `IReadOnlyList<WktArea>` |
| AccuracyRadius | `int` |

Location also includes all properties from the existing location results model.
This type will extend `IGeoData`.

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
    int Mcc { get; }
    float Weighting { get; }
}
```

And the engine would return a type of:

```{cs}
class IpIntelligenceData : IMultiWeightedAspectData IIpIntelligenceData
{
    // Contains all profiles
    IReadOnlyList<IWeightedAspectData> Profiles { get; }

    // Gets the MCC values
    IReadOnlyList<IWeightedValue<int>> Mcc { get; }

    // Contains only the MCC profiles
    IReadOnlyList<IMccData> MccProfiles { get; }
}
```

## Data File Structure

Data files follow the standard 51Degrees data file structure, with the addition
of profile groups.

### Profile Groups

A profile is pointed to by an integer offset. This is the same as existing data 
files. In the case where this offset is negative, it points to a group of
profiles instead. Profile groups exist in a separate collection, and a profile
group structure is as follows:

| Property | Type |
| -------- | ---- |
| Count | `short` |
| Profile Offset | `int` |
| Weighting | `float` |
| ... | ... |

where offset and weighting are repeated to form an array of size `Count`.

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