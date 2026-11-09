# Hardware profile lookup on-premise

## Overview

This On-premise Engine gives the results of the
[hardware profile lookup](hardware-profile-lookup-cloud.md) without a remote
server. Given a TAC or a native model name, it returns every hardware
[profile](device-detection-on-premise.md) in the data file whose TAC or
NativeModel Property holds that value.

It uses the data file of the
[Device Detection on-premise](device-detection-on-premise.md) Engine. It needs a
data file that holds the TAC and NativeModel Properties. The published
property list of the
[Lite data file](https://github.com/51Degrees/data#device-detection) has
neither.

## Native component

The lookup is part of the native component in
[51degrees-cxx/src/dd/hash](https://github.com/51Degrees/51degrees-cxx/tree/main/src/dd/hash),
added in 51degrees-cxx commit
[b4d2f268](https://github.com/51Degrees/51degrees-cxx/commit/b4d2f268).
The Device Detection on-premise Engine gives it as the
[profiles for a property value](device-detection-on-premise.md#profiles-for-a-property-value),
and this Engine is built on that.

### Index of profiles by value

When the native data set is initialized, it builds an index from each value of
the Properties the caller names to the profiles holding that value. The index
is part of the data set. No Property is indexed unless the caller names it,
whatever the performance profile. A named Property is indexed whether or not
it is a required Property, so a caller does not need to require a Property to
look up its values. A name that the data file has no Property of indexes
nothing.

When the data is refreshed, the new data set indexes the same Properties from
the new data file, and the index of the data set it replaces is freed with
that data set.

Without the index, or for a Property that was not named, the lookup reads
every profile and returns the same profiles more slowly.

### Results

A lookup MUST return every profile holding the value, each once, in the order
of the profiles in the data file, which is ascending profile id. A value that
no profile holds returns no profiles. The Property name and the value are
matched exactly, as the data file holds them, including their case, as the
[profiles for a property value](device-detection-on-premise.md#profiles-for-a-property-value)
require.

Choosing one of several profiles is left to the caller. A caller that wants a
single device MAY pass the id of one profile to the Device Detection
on-premise Engine as the `51D_ProfileIds` Evidence.

### What each language exposes

| **Language**                      | **Properties to index**                                                                                                          | **Lookup**                                                                                        | **Returns**                                                                |
|-----------------------------------|----------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------|
| C                                 | `fiftyoneDegreesHashInitManagerFromFileWithIndexedProperties` or `fiftyoneDegreesHashInitManagerFromMemoryWithIndexedProperties` | `fiftyoneDegreesHashGetProfileIdsForPropertyAndValue`                                             | The number of profiles, with their ids set in an array the caller provides |
| C                                 | As above                                                                                                                         | `fiftyoneDegreesHashIterateProfilesForPropertyAndValue`                                           | Each profile, passed to a callback                                         |
| C++                               | `ConfigHash::setIndexedProperties`                                                                                               | `EngineHash::getProfileIdsForPropertyValue`                                                       | A `std::vector<uint32_t>` of profile ids                                   |
| C#, Java, Node.js, Python and PHP | `setIndexedProperties` on `ConfigHashSwig`                                                                                       | `getProfileIdsForPropertyValue` on `EngineHashSwig`                                               | A `VectorUInt32Swig` of profile ids                                        |
| Go and Rust                       | The C init functions, called through their bindings to the C API                                                                 | `fiftyoneDegreesHashGetProfileIdsForPropertyAndValue`, called through their bindings to the C API | The profile ids, as for C                                                  |

The languages built on SWIG get these once their wrapper is generated again
from the interface in 51degrees-cxx. In .NET the `NativeEngine` and
`TacEngine` of `FiftyOne.DeviceDetection.PropertyKeyed` are On-premise
Engines of this kind. Since
[51degrees-dotnet#101](https://github.com/51Degrees/51degrees-dotnet/pull/101)
they use the native lookup for a Property that the Device Detection
on-premise Engine's builder names with
`SetIndexedProperties("NativeModel", "TAC")`. For a Property the builder does
not name, they still process every hardware profile at start-up to build an index
of their own, which
[51degrees-dotnet#30](https://github.com/51Degrees/51degrees-dotnet/issues/30)
tracks. Java has no such Engine yet, which
[51degrees-java#17](https://github.com/51Degrees/51degrees-java/issues/17)
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

The [JSON Builder](../../pipeline-specification/pipeline-elements/json-builder.md#process)
MUST write `profiles` as an empty list however many ids the Element Data
holds, because the profiles are read on demand, so building the JSON reads no
profile.

## Start-up activity

The Device Detection on-premise Engine whose data this Engine uses SHOULD be
created with the NativeModel and TAC Properties named to index, so that the
native index is built when its data set is initialized. An Engine of this
kind MUST find the profiles through the native lookup, as the
[profiles for a property value](device-detection-on-premise.md#profiles-for-a-property-value)
require, rather than build an index of its own by processing every hardware
profile at start-up.

## Process

1. Read the TAC or native model name from the Evidence.
2. Get the ids of the profiles holding it from the native lookup, with the
   Property name `TAC` or `NativeModel`.
3. Add the ids to the Element Data, in the order returned, without reading
   the profiles, so that a value many profiles hold costs only the lookup
   until `profiles` is read. There is no limit on the number of ids.
4. The first time `profiles` is read, populate an instance of the device
   data for each id, in the order the ids were added, with the Property
   values of that profile, for example by processing the id as
   `51D_ProfileIds` Evidence with the Device Detection on-premise Engine.
   A later read does not read the profiles again unless more ids have been
   added since.

## Refresh data

When the data of the Device Detection on-premise Engine is refreshed, the
native component indexes the same Properties again from the new data file.
Nothing more is needed from this Engine.

## Configuration options

There are no configuration options associated with this Engine beyond those
of the Device Detection on-premise Engine, where the Indexed Properties
[configuration option](device-detection-on-premise.md#configuration-options)
names the Properties to index.
