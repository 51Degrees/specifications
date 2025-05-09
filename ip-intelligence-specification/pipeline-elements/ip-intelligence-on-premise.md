# IP Intelligence On-Premise

## Overview

This Engine provides IP Intelligence capabilities using a high performance
on-premise algorithm.

This Engine also requires an IPI data file, which comes in two variations:

- **Lite** - Freely available from [GitHub](https://github.com/51Degrees/ip-intelligence-data).
  Contains a highly restricted set of Properties and is updated
  around once per month.
- **Enterprise** - Downloaded from
  [Distributor](http://51degrees.com/documentation/_info__distributor.html).
  Requires a license key for download and is usually updated Monday-Thursday. Includes all Properties

## Native component

In all languages, the on-premise IP Intelligence Engine passes the actual
detection processing to a native DLL/so library that is written in C/C++.

The intention was that this will ensure the best performance for the most
computationally complex part of the process and reduce maintenance overhead,
as well as the time needed to add support for IP Intelligence in a new
language.

The code for this component is available on GitHub:

- [common-cxx](https://github.com/51Degrees/common-cxx)
- [ip-intelligence-cxx](https://github.com/51Degrees/ip-intelligence-cxx)
- [ip-graph-cxx](https://github.com/51Degrees/ip-graph-cxx)

Unfortunately, while calling a native library is possible in many languages, it
is often fiddly and can come with unexpected difficulties. As such, we generally
use [SWIG](https://www.swig.org/) to help produce a wrapper for the target
language. This takes care of the marshalling of data structures to and from
C data structures but represents a performance overhead - see
[Performance Guidance](#performance-guidance) below. The implementor will still
need to be familiar with the mechanisms that are used by the language to call
native code.

The C library is distributed in binary form for a restricted set of target
environments [tested versions](https://51degrees.com/documentation/_info__tested_versions.html),
with a number of assumptions about the availability
of [dependencies](https://51degrees.com/documentation/_info__dependencies.html).

### Selecting The Correct Binary

While the implementor is not expected to produce the CI/CD scripts that
will create the final packages, The final package MUST have some mechanism
to determine the correct native binary to use based on the current
operating system.

In some cases, this capability is built into the packaging infrastructure
For example, [.NET/NuGet](https://github.com/51Degrees/ip-intelligence-dotnet/blob/main/FiftyOne.IpIntelligence.Engine.OnPremise/FiftyOne.IpIntelligence.Engine.OnPremise.csproj).
Some require additional code to be written to determine the correct binary
at runtime (Java/Maven and Node/NPM). Others
do not allow native binaries in packages at all (PHP/Composer).

### Reference Implementation Notes

The reference implementations bundle the cxx code in with the .NET
code and build it all together. This works well enough, but does come
with the downside of adding significant complexity to the build process
for customers who would often prefer to be able to consume pre-built
native binaries (or not deal with native binaries at all).

For future implementations, we recommend exploring the possibility of
moving the native binary and target language wrapper to a separate
repository and package from the target language Device Detection Engine
logic.

## Accepted Evidence

This Engine determines the accepted Evidence keys on data refresh based
on values in the data source.

After loading the data source into the native code, call the `getKeys`
function to return a list of the accepted Evidence keys.
These values will then need to be stored to prevent repeated calls to the
native code.

This MUST be done at start-up and any time the data is refreshed.

Note that the list of accepted Evidence keys is not case-sensitive -
i.e. `server.client-ip` and `server.Client-IP` would both be
accepted.

## Element Data

The list of Properties that can be populated by this Engine is determined
on data refresh based on the Properties that are available in the data
source that is used.

It is essential that the Element Data instance populated by this
On-premise Engine is interface compatible with the Element Data
populated by the [cloud Device Detection Engine](device-detection-cloud.md)
as well as the individual devices populated in the Element Data from
the [hardware profile lookup Engine](hardware-profile-lookup-cloud.md).

## Start-Up Activity

On start-up, the native Engine needs to be created using the data file.
Several functions will then be called to get the data that is needed
by other Engine features.

See [refresh data](#refresh-data) for details on this process.

## Processing

This section describes the core steps this Engine executes to process
Flow Data. This is on top of any common processing defined for
other Pipeline API features.

- Create and populate the native Evidence object
  - The Evidence values will typically need to be converted to a memory
    format that can be used by the native Cxx code.
  - First, create a new `EvidenceIpi` C++ instance.
  - Next, add items from the Flow Data Evidence to the C++ instance.
    - Only need to add entries that the Engine will make use of.
- Call the `process` function on the native Engine, passing the native
  Evidence instance.
- This will return a `ResultsIpi` instance, which contains references to
  the resulting Property values.
- Create a new instance of the implementation of the `IIpIntelligenceData` interface
  that is being used for the On-premise Engine.
  - Pass the `ResultsIpi` instance so it can be used when Property values
    are requested.
  - Do not immediately copy all the Property values from `ResultsIpi`. By
    default, around 200 Properties will be populated, meaning 200+ calls to
    the native code marshalling values back and forth [^3].

[^3]: Note the effect that
holding the "un-managed" memory references (i.e. memory references that
are not handled by language garbage collection) has on
[caching](../../pipeline-specification/features/caching.md) and
[resource cleanup](../../pipeline-specification/features/resource-cleanup.md).
The reference implementations don't allow a cache to be
added to this Engine because of the complexity this introduces, however
end-users might be tempted to create their own cache of results.

### Value Retrieval

When retrieving values from the IPI native code, values always come with an
associated weighting. This should be reflected in the `Element Data` implementation returned by the implementation. For more details, see [data model](../data-model.md).

### Performance Guidance

We have found that the main performance bottleneck is usually the process
of marshalling data values to and from native representations.

As such, steps SHOULD be taken to minimize this as much as possible:

- Languages often have many mechanisms for passing data in calls
  to native binaries, some more efficient than others. SWIG code will
  sometimes use the most flexible approach, rather than the most performant.
  It is worth checking the generated code for relatively easy performance
  wins.
- Whenever making a call to native code, be aware of the data that is being
  passed and check if there is anything that can be done to reduce it.
- Some languages may be able to give/receive memory pointers directly.
  Implementors are advised to investigate the feasibility of this approach
  as it can be significantly faster. However, doing so requires a strong
  understanding of how memory allocation and access works in both the Pipeline
  language and native C code.
- Finally, do not call native code at all if it can be avoided. For example, any
  values that will only change after a [data refresh](#refresh-data) can
  be stored in the Engine instance to avoid native calls for that value until
  a refresh occurs. Note the possible clean-up consequences that this implies.

## Refresh Data

The [refresh data function](../../pipeline-specification/features/data-updates.md#aspect-engine-features)
for this Engine will perform the following tasks:

- Create a new instance of the C++ `EngineIpiSwig` type using either the
  filename or byte[] constructor.
- Call `refreshData` on the C++ Engine in order to load data into the
  relevant data structures.
- Call the necessary functions on the C++ Engine in order to acquire
  metadata about the Engine that is dependent on the data file:
  - [accepted Evidence](#accepted-evidence)
  - [Device Detection metadata](#metadata)
  - data file publish date
  - expected publish date of next data file
  - data file type
  - data file temp path

The following table lists the C++ Engine functions to call to get the data
mentioned above:

| Function name            | Notes                                                                                                                                                                                              |
|--------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `getKeys`                | Get a list of the Evidence keys that the data file will make use of                                                                                                                                |
| `getMetaData`            | Get [metadata](#metadata) from the data file                                                                                                                                                      |
| `getPublishedTime`       | Get the date/time that the data file was created                                                                                                                                                   |
| `getUpdateAvailableTime` | Get the data/time that a new data file is expected to be available                                                                                                                                 |
| `getProduct`             | Get the string type of the data file. This is used by the [data update](../../pipeline-specification/features/data-updates.md) functionality when calling Distributor to check for a new data file |
| `getDataFileTempPath`    | Get the path to the temporary working copy of the data file (This is the full path to the copy of the data file that the C code makes before reading it.)                                          |

## Events

This Engine implements the following events/callbacks/hooks:

| Name             | Notes                                                                       |
|------------------|-----------------------------------------------------------------------------|
| Refresh complete | Used by client to perform some action after a new data file has been loaded |

## Metadata

On-premise IP Intelligence has two related metadata structures:

1. The IP Intelligence data file includes metadata relating to the structure of the
   values that are stored in the file. This is exposed by the IP Intelligence Engine
   in order to allow users to query the data. [^4]
2. All Flow Elements expose a list of metadata relating to Properties populated by
   that element. In the case of the IP Intelligence Engine, this list will include
   Property metadata derived from the data file metadata mentioned above.

[^4]: Due to the structure of the data, this is not intended to support
high-performance querying scenarios. For that use-case, customers are directed to our
'csv' data file, which can be consumed and stored in a database or whatever other form
is needed for querying.

For details on the additional metadata, see the
[data model specification](../../data-model-specification/README.md).

## Configuration options

These are the configuration options that are unique to this Engine. They are in
addition to all the configuration options defined for other features. For example,
[data updates](../../pipeline-specification/features/data-updates.md#configuration-groups)

| **Parameter**             | **Native code location**                                                                                                                            | **Optional** | **Default**                                                                                                                      | **Notes**                                                                                                                                                                                                                                                                                                                                                                                                   |
|---------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|--------------|----------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Performance Profile       | [ConfigIpi=>set\[ProfileName\]()](https://github.com/51Degrees/ip-intelligence-cxx/blob/main/src/ConfigIpi.hpp#L104)                        | Yes          | Balanced. See [native code](https://github.com/51Degrees/ip-intelligence-cxx/blob/main/src/ipi.h#L429) for definitions. | Set the performance profile to use when creating the Engine. Each profile has default values for various internal configuration options, as well as things like the use of predictive/performance graphs.                                                                                                                                                                                                   |
| Concurrency               | [ConfigIpi::setConcurrency()](https://github.com/51Degrees/ip-intelligence-cxx/blob/main/src/ConfigIpi.hpp#L180)                            | Yes          | System processor count                                                                                                           | Set the expected number of concurrent operations using the Engine. This is used to configure internal caches to avoid excessive locking. It has no effect if these internal caches are not used. (For example, when using the 'MaxPerformance' profile)                                                                                                                                                     |

The default values for many configuration options come from the native
C/C++ code. You can find these defaults in
<https://github.com/51Degrees/common-cxx/blob/master/config.h>.
