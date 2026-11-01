# Hardware profile lookup on-premise

## Overview

This On-premise Engine gives the results of the
[hardware profile lookup](hardware-profile-lookup-cloud.md) without a remote
server. Given a TAC or a native model name, it returns every hardware
[profile](device-detection-on-premise.md) in the data file whose TAC or
NativeModel Property holds that value.

It uses the data file of the
[Device Detection on-premise](device-detection-on-premise.md) Engine. The TAC
Property is only in the TAC data file, and the NativeModel Property is in the
Enterprise and TAC data files. The Lite data file has neither.

## Native component

The lookup is part of the native component in
[51degrees-cxx/src/dd/hash](https://github.com/51Degrees/51degrees-cxx/tree/main/src/dd/hash),
added by [51degrees-cxx#66](https://github.com/51Degrees/51degrees-cxx/pull/66).

### Index of profiles by value

When the native data set is initialized, it builds an index from each value of
the required Properties to the profiles holding that value. The index is part
of the data set. When the data is refreshed, the new data set builds its own
index from the new data file, and the index of the data set it replaces is
freed with that data set.

The index is built when the property value index option of the configuration
is enabled. This is the same option that controls the native index of
Property values for each profile, so the two indexes are built together. The
InMemory and HighPerformance performance profiles of the C API enable the
option. The C++ performance profiles leave it as it is, and it is disabled by
default, so an implementation that uses the C++ or SWIG interface MUST enable
it with `setPropertyValueIndex` for the lookup to use the index.

Without the index, or for a Property that is not required, the lookup reads
every profile and returns the same profiles more slowly.

### Results

A lookup MUST return every profile holding the value, in the order of the
profiles in the data file, which is ascending profile id. A value that no
profile holds returns no profiles. The Property name and the value are
matched exactly, including their case.

Choosing one of several profiles is left to the caller. A caller that wants a
single device MAY pass the id of one profile to the Device Detection
on-premise Engine as the `51D_ProfileIds` Evidence.

### What each language exposes

| **Language**                          | **Lookup**                                                                                                     | **Returns**                                                                  |
|---------------------------------------|----------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| C                                     | `fiftyoneDegreesHashGetProfileIdsForPropertyAndValue`                                                          | The number of profiles, with their ids set in an array the caller provides   |
| C                                     | `fiftyoneDegreesHashIterateProfilesForPropertyAndValue`                                                        | Each profile, passed to a callback                                           |
| C++                                   | `EngineHash::getProfileIdsForPropertyValue`                                                                    | A `std::vector<uint32_t>` of profile ids                                     |
| C#, Java, Node.js, Python and PHP     | `getProfileIdsForPropertyValue` on `EngineHashSwig`, with `setPropertyValueIndex` on `ConfigHashSwig`          | A `VectorUInt32Swig` of profile ids                                          |
| Go and Rust                           | `fiftyoneDegreesHashGetProfileIdsForPropertyAndValue`, called through their bindings to the C API              | The profile ids, as for C                                                    |

The languages built on SWIG get these once their wrapper is generated again
from the interface in 51degrees-cxx. In .NET the `NativeEngine` and
`TacEngine` of `FiftyOne.DeviceDetection.PropertyKeyed` are On-premise
Engines of this kind. Today they find the profiles by processing every
hardware profile at start-up, and
[device-detection-dotnet#915](https://github.com/51Degrees/device-detection-dotnet/issues/915)
moves them to the native lookup. Java has no such Engine yet, which
[device-detection-java#605](https://github.com/51Degrees/device-detection-java/issues/605)
proposes.

## Accepted Evidence

| **Key**             | **Description**                                    |
|---------------------|----------------------------------------------------|
| `query.tac`         | The TAC to look up, as for the remote server       |
| `query.nativemodel` | The native model name to look up                   |

## Element Data

| **Name** | **Type**                     | **Description**                                                                                                                                                                   |
|----------|------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| profiles | `IReadOnlyList<IDeviceData>` | Every hardware profile holding the value, in the order of the data file. Each is interface compatible with the results from the cloud and on-premise Device Detection Engines. |

## Start-up activity

The Device Detection on-premise Engine whose data this Engine uses SHOULD be
created with the property value index option enabled, so that the native
index is built when its data set is initialized. An Engine of this kind
SHOULD use the native lookup rather than processing every hardware profile
at start-up.

## Process

1. Read the TAC or native model name from the Evidence.
2. Get the ids of the profiles holding it from the native lookup, with the
   Property name `TAC` or `NativeModel`.
3. For each id, in the order returned, populate an instance of the device
   data with the Property values of that profile, for example by processing
   the id as `51D_ProfileIds` Evidence with the Device Detection on-premise
   Engine.
4. Set the instances as the `profiles` of the Element Data.

## Refresh data

When the data of the Device Detection on-premise Engine is refreshed, the
native component builds the index for the new data file. Nothing more is
needed from this Engine.

## Configuration options

There are no configuration options associated with this Engine beyond those
of the Device Detection on-premise Engine.
