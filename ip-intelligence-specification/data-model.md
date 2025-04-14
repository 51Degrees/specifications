# Data model

## Introduction

This document contains the details of the data values returned by 51Degrees
IP Intelligence.

## Overview

All Engines MUST populate data objects that
implement [Aspect Data](../pipeline-specification/conceptual-overview.md#aspect-data)
as defined in the Pipeline specification.

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

## Data Types

### Azimuth

Compressed form of a floating point longitude value.

Instead of storing a longitude value as a `double`, or `float`, an `int16` is used to represent the same value.

The stored value is converted back to the floating point value by dividing by the maximum value of `int16`, and multiplying by 180.

For example:

```{c}
int16_t storedValue;
double actualValue = 180.0 * ((double)storedValue / (double)int16_max);
// or
double actualValue = 180.0 * ((double)storedValue / 32767.0);
```

### Declination

Compressed form of a floating point latitude value.

Instead of storing a latitude value as a `double`, or `float`, an `int16` is used to represent the same value.

The stored value is converted back to the floating point value by dividing by the maximum value of `int16`, and multiplying by 90.

For example:

```{c}
int16_t storedValue;
double actualValue = 90.0 * ((double)storedValue / (double)int16_max);
// or
double actualValue = 90.0 * ((double)storedValue / 32767.0);
```

### WKT

A new property type for the IP Intelligence Engine is the `WktString` interface
This uses a WKT/WKB shape (see <https://en.wikipedia.org/wiki/Well-known_text_representation_of_geometry>).

This comes from the data file in WKBR (R = reduced) format. And is interpreted
to a more useable form, as the interface `WktString` which extends string, and
contains a WKT format string.

Implementation adapts the [OGC 06-103r4](https://www.ogc.org/publications/standard/sfa/) standard, by changing the size of fields to reduce the size.

The modified structures are:

```{c}
struct WKBRPolygon {
    byte byteOrder;
    byte wkbType;
    uint16_t numRings;
    WKBRLinearRing rings[numRings]
}
```
```{c}
struct WKBRLinearRing {
    uint16_t numPoints;
    WKBRPoint points[numPoints];
};
```
```{c}
struct WKBRPoint {
    int16_t x;
    int16_t y;
};
```

The modifications from the WKB spec are:
- the size of the `num` fields are halved,
- `x` and `y` coordinates in the `WKBRPoint` are stored as short integers, using the `Azimuth` and `Declination` format to represent lat/lon values.

Importantly, it should be noted that the convention for lat/lon coordinates is `x=longitude` and `y=latitude` (not the other way around). This is in line with WKB spec.

## Property Details

Each Property SHOULD return
an [Aspect Property value](../pipeline-specification/features/properties.md#null-values)
in order to support exposing the reason that a value is not set.

Additionally, values MUST be returned along with their weights when fetched
from the `IAspectData`. Meaning the introduction of the
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
| The value is less than the number of nodes in the nodes collection (`value < totalNodes`)| The node is not a leaf, so does not point to either a profile, or a profile group (see [ipi-graph](https://github.com/51degrees/ipi-graph-cxx)) | N/A |
| The value is greater than, or equal to, the number of nodes, but is less than the number of profiles after subtracting the number of nodes (`value >= totalNodes && value - totalNodes < totalProfiles`) | The value, minus the number of nodes in the nodes collection, is an index in the profile offsets collection | `offsetIndex = value - totalNodes`<br/>`offset = offsets[offsetIndex]`<br/>`profile = profiles[profileOffset]` |
| The value is greater than the number of nodes, and is greater than, or equal to, the number of profiles after subtracting the number of nodes (`value > totalNodes && value - totalNodes >= totalProfiles`) | The value, minus the number of nodes and profiles, is the index of the first weighted profile in the profile groups collection | `groupIndex = value - totalNodes - totalProfiles`<br/>`firstWeightedProfileOfGroup = profileGroups[groupIndex]` |

The number of profiles which make up a group is not written. However, with
the axiom that weightings add up to ushort.max for a component, profiles are read until the total raw weighting is ushort.max, signifying that the array is complete.


## Property Metadata

For on-premise implementations, the metadata associated with properties is
contained within the data file. See [device-detection dotnet engine](https://github.com/51Degrees/device-detection-dotnet/blob/main/FiftyOne.DeviceDetection.Hash.Engine.OnPremise/FlowElements/DeviceDetectionHashEngine.cs) and [device-detection cxx metadata](https://github.com/51Degrees/device-detection-cxx/blob/main/src/hash/MetaDataHash.hpp)

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
