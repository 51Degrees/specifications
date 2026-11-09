# Device Detection on-premise

## Overview

This Engine provides Device Detection capabilities using a high performance
on-premise algorithm we refer to as the
[hash](https://51degrees.com/documentation/_device_detection__hash.html?utm_source=github&utm_medium=docs&utm_campaign=specifications&utm_content=device-detection-specification-pipeline-elements-device-detection-on-premise.md&utm_term=overview)
algorithm.

This Engine also requires a hash data file, which comes in three variations:

- **Lite** - Freely available from [GitHub](https://github.com/51Degrees/device-detection-data).
  Contains a highly restricted set of Properties and is updated
  around once per month.
- **Enterprise** - Downloaded from
  [Distributor](https://51degrees.com/documentation/_info__distributor.html?utm_source=github&utm_medium=docs&utm_campaign=specifications&utm_content=device-detection-specification-pipeline-elements-device-detection-on-premise.md&utm_term=overview).
  Requires a license key for download and is usually updated Monday-Thursday. Includes all
  Properties except TAC.
- **TAC** - Same as enterprise except that TAC is included in the result.

## Native component

In all languages, the on-premise Device Detection Engine passes the actual
detection processing to a native DLL/so library that is written in C/C++.

The intention was that this will ensure the best performance for the most
computationally complex part of the process and reduce maintenance overhead,
as well as the time needed to add support for Device Detection in a new
language.

The code for this component is available on GitHub:

- [51degrees-cxx/src/common](https://github.com/51Degrees/51degrees-cxx/tree/main/src/common)
- [51degrees-cxx/src/dd](https://github.com/51Degrees/51degrees-cxx/tree/main/src/dd)

Unfortunately, while calling a native library is possible in many languages, it
is often fiddly and can come with unexpected difficulties. As such, we generally
use [SWIG](https://www.swig.org/) to help produce a wrapper for the target
language. This takes care of the marshalling of data structures to and from
C data structures but represents a performance overhead - see
[Performance Guidance](#performance-guidance) below. The implementor will still
need to be familiar with the mechanisms that are used by the language to call
native code.

The C library is distributed in binary form for a restricted set of target
environments [tested versions](https://51degrees.com/documentation/_info__tested_versions.html?utm_source=github&utm_medium=docs&utm_campaign=specifications&utm_content=device-detection-specification-pipeline-elements-device-detection-on-premise.md&utm_term=native-component),
with a number of assumptions about the availability
of [dependencies](https://51degrees.com/documentation/_info__dependencies.html?utm_source=github&utm_medium=docs&utm_campaign=specifications&utm_content=device-detection-specification-pipeline-elements-device-detection-on-premise.md&utm_term=native-component).

### Selecting the correct binary

While the implementor is not expected to produce the CI/CD scripts that
will create the final packages, The final package MUST have some mechanism
to determine the correct native binary to use based on the current
operating system.

In some cases, this capability is built into the packaging infrastructure
For example, [.NET/NuGet](https://github.com/51Degrees/51degrees-dotnet/blob/main/device-detection/Hash.Engine.OnPremise/FiftyOne.DeviceDetection.Hash.Engine.OnPremise.csproj#L110).
Some require additional code to be written to determine the correct binary
at runtime (Java/Maven and Node/NPM). Others
do not allow native binaries in packages at all (PHP/Composer).

### Reference implementation notes

The reference implementations bundle the cxx code in with the Java/.NET
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
i.e. `header.user-agent` and `header.User-Agent` would both be
accepted.

## Element Data

The list of Properties that can be populated by this Engine is determined
on data refresh based on the Properties that are available in the data
source that is used.

In addition, several additional [match metrics](#match-metric-properties)
Properties MUST be added as well. The table below shows the native
function to call to get the value for each Property.

| Name         | Function on result object to call to get value [^1] |
|--------------|------------------------------------------------------|
| MatchedNodes | getMatchedNodes                                      |
| Difference   | getDifference                                        |
| Drift        | getDrift                                             |
| DeviceId     | getDeviceId                                          |
| UserAgents   | getUserAgents                                        |
| Iterations   | getIterations                                        |
| Method       | getMethod                                            |

It is essential that the Element Data instance populated by this
On-premise Engine is interface compatible with the Element Data
populated by the [cloud Device Detection Engine](device-detection-cloud.md)
as well as the individual devices populated in the Element Data from
the [hardware profile lookup Engine](hardware-profile-lookup-cloud.md) and
its [on-premise counterpart](hardware-profile-lookup-on-premise.md).

[^1]: The native implementations have some additional complexity
in their code because of a plan to split Device Detection into 4
separate Engines. This is obsolete and is not necessary in new
implementations.

## Start-up activity

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
  - First, create a new `EvidenceDeviceDetection` C++ instance.
  - Next, add items from the Flow Data Evidence to the C++ instance.
    - Only need to add entries that the Engine will make use of.
- Call the `process` function on the native Engine, passing the native
  Evidence instance.
- This will return a `ResultsHash` instance, which contains references to
  the resulting Property values.
- Create a new instance of the implementation of the `IDeviceData` interface
  that is being used for the On-premise Engine.
  - Pass the `ResultsHash` instance so it can be used when Property values
    are requested.
  - The Element Data MUST read a Property value from `ResultsHash` only when
    that Property is requested, and MUST NOT copy Property values out of
    `ResultsHash` while the Engine processes the Flow Data. By default,
    around 200 Properties will be populated, so copying them all means 200+
    calls to the native code marshalling values back and forth on every
    request, whether or not the caller reads them [^3].
  - The Element Data MAY keep a value once it has been read, so that a
    second request for the same Property does not call the native code
    again.

[^3]: Note the effect that
holding the "un-managed" memory references (i.e. memory references that
are not handled by language garbage collection) has on
[caching](../../pipeline-specification/features/caching.md) and
[resource cleanup](../../pipeline-specification/features/resource-cleanup.md).
The reference implementations don't allow a cache to be
added to this Engine because of the complexity this introduces, however
end-users might be tempted to create their own cache of results.

### Finding Properties

The Engine is created with the names of the Properties an implementation
reads, or with none to have every Property of the data file. The position of a
Property is the index of its name in the names the Engine was created with, so
it does not depend on the data file. A [data refresh](#refresh-data) keeps
every position, and a Property the new data file lacks keeps its position and
reads as a Property the data set does not have, with the invalid Property
reason, until a later data file has it again.

- An implementation that created the Engine with names MAY read a Property by
  its position, being the index of its name in the list it gave, or by its
  name. It MUST NOT keep a map of its own from names to positions, such as one
  built from the data set, as the native code gives each name its position.
- An Engine created with no names has no positions. Its methods that take a
  position return no value, with the invalid Property reason, so an
  implementation MUST read the Properties of such an Engine by name, through
  the `ResultsHash` methods that take a Property name.
- `getAvailableProperties`, `getPropertyName` and the Engine's
  `getRequiredProperties` follow the names the Engine was created with, in
  that order. `getProperties` lists the Properties the data set has, sorted by
  name, so its order is not the order of the positions.

### Reading graphs

When the Engine was created with names, `process` walks the graph of each
component the named Properties need, and no other, so no later read walks a
graph. A failure to read one of those graphs from the data file is reported by
`process`, which throws in C++ and the languages built on it.

When the Engine was created with no names, `process` walks no graph. The native
code walks the graph of a component when a Property of that component is first
read from a `ResultsHash` instance, against the data set that instance holds,
and walks it once for that instance, so a lookup that reads the Properties of
one component walks one graph. A failure to read a graph from the data file is
reported by the read that walked it, which throws in C++ and the languages
built on it. That component is not walked again for the instance, so its
Properties then read as if it had no profile.

Either way the values are the same whatever is read first, and a data refresh
between `process` and a read does not change the answer, as the instance keeps
the data set it was populated from. The match metrics, such as
`getMatchedNodes` and `getDeviceId`, describe every component, so reading one
walks every graph not yet walked.

### Results and threads

A `ResultsHash` instance is used by one thread at a time, because reading a
value writes into it, and when the Engine was created with no names the first
read of a Property of a component walks the component's graph. Different
`ResultsHash` instances can be used on different threads at once, and the
Engine can be shared.

Aspect Data SHOULD be thread safe, as
[thread safety](../../pipeline-specification/features/thread-safety.md)
describes, so Aspect Data that reads its values from a `ResultsHash` instance
SHOULD let one thread at a time read that instance, for example by holding a
lock for each read. An Engine whose Aspect Data lets several threads read
one instance at once MUST NOT allow a
[cache](../../pipeline-specification/features/caching.md) to be added.

### Performance guidance

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
  Positions need no such store, as each is the index of a Property in the
  names the Engine was created with, as
  [finding Properties](#finding-properties) describes.

## Refresh data

The [refresh data function](../../pipeline-specification/features/data-updates.md#aspect-engine-features)
for this Engine will perform the following tasks:

- Create a new instance of the C++ `EngineHashSwig` type using either the
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

On-premise Device Detection has two related metadata structures:

1. The Device Detection data file includes metadata relating to the structure of the
   values that are stored in the file. This is exposed by the Device Detection Engine
   in order to allow users to query the data. [^4]
2. All Flow Elements expose a list of metadata relating to Properties populated by
   that element. In the case of the Device Detection Engine, this list will include
   Property metadata derived from the data file metadata mentioned above.

[^4]: Due to the structure of the data, this is not intended to support
high-performance querying scenarios. For that use-case, customers are directed to our
'csv' data file, which can be consumed and stored in a database or whatever other form
is needed for querying.

For details on the additional metadata, see the
[data model specification](../../data-model-specification/README.md).

### Match metric Properties

In addition to the 'standard' Device Detection Properties, there are a set of
Properties that return details about the processing that was performed and
the match that was found. Metadata for these Properties MUST be added, as they
will not be included in the metadata exposed by the native code.

All these Properties have the following values:

- Category = "Device Metrics" (sic)
- Available With = "Lite", "Premium", "Enterprise", "TAC" - This
  list could be created dynamically from the lists of files included against
  all other Property metadata that is exposed by the native code.
- Component = "Metrics" - This component MUST also be added to the list of
  components returned by the Engine.

| Name             | Type   | Default value | Description                                                                                                                                                                                                                                                                | Possible values                                 |
|------------------|--------|---------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------|
| MatchedNodes     | int    | 0             | Indicates the number of hash nodes matched within the Evidence.                                                                                                                                                                                                            | n/a                                             |
| Difference       | int    | 0             | Used when detection method is not Exact or None. The larger the value the less confident the detector is in this result.                                                                                                                                                   | n/a                                             |
| Drift            | int    | 0             | The drift of every component's result added together, each result's drift being how far, in character positions, the substring's hashes were found from where they were expected. Never the largest or smallest result alone.                                              | n/a                                             |
| DeviceId         | string | "0-0-0-0"     | Contains the profile ids of the matching profiles, separated by a hyphen symbol. For example \[HardwareId\]-\[PlatformId\]-\[BrowserId\]-\[CrawlerId\]. By convention, these will be in component Id order. There will often be 4 ids present, but this is not guaranteed. | n/a                                             |
| UserAgents       | list of strings | []   | The User-Agent values that were matched, each listed once across every result. Populated when the Update Matched User Agent [configuration option](#configuration-options) is on, which it is by default.                                                                                        | n/a                                             |
| Iterations       | int    | 0             | The number of iterations carried out in order to find a match. This is the number of nodes in the graph which have been visited.                                                                                                                                           | n/a                                             |
| Method           | string | "NONE"        | The method used to determine the match result.                                                                                                                                                                                                                             | "NONE", "PERFORMANCE", "COMBINED", "PREDICTIVE" |

## Profiles for a property value

The Engine MUST be able to give the ids of the profiles that hold a given value
of a given Property, such as a TAC or a native model name, through the native
code's
[EngineHash::getProfileIdsForPropertyValue()](https://github.com/51Degrees/51degrees-cxx/blob/main/src/dd/hash/EngineHash.hpp#L181).
TAC and native model lookups on-premise are built on it.

- The Property name and the value MUST both be matched exactly, as the data
  file holds them. A value given in another case does not match, and where
  the data file holds two spellings of a value that differ only in case, each
  spelling gives only its own profiles.
- The ids are in ascending profile id, which is the order of the data file,
  and each id appears once.
- For a Property named with the Indexed Properties
  [configuration option](#configuration-options), the native code's index
  finds the profiles without reading every profile. For any other Property
  every profile is read, which gives the same ids more slowly.

A language MUST use this native function for such a lookup rather than keep an
index of its own, because an index of its own can match differently (the .NET
fallback index matches without regard to case), so that every language gives
the same answers.

## Configuration options

These are the configuration options that are unique to this Engine. They are in
addition to all the configuration options defined for other features. For example,
[data updates](../../pipeline-specification/features/data-updates.md#configuration-groups)

| **Parameter**             | **Native code location**                                                                                                                            | **Optional** | **Default**                                                                                                                      | **Notes**                                                                                                                                                                                                                                                                                                                                                                                                   |
|---------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|--------------|----------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Difference                | [ConfigHash::setDifference()](https://github.com/51Degrees/51degrees-cxx/blob/main/src/dd/hash/ConfigHash.hpp#L139)                             | Yes          | Native code [^2]                                                                                                                 | Used to set the maximum [difference](https://51degrees.com/documentation/_device_detection__hash.html?utm_source=github&utm_medium=docs&utm_campaign=specifications&utm_content=device-detection-specification-pipeline-elements-device-detection-on-premise.md&utm_term=configuration-options#difference) in hash value to allow when processing HTTP headers.                                                                                                                                                                                                                                  |
| Drift                     | [ConfigHash::setDrift()](https://github.com/51Degrees/51degrees-cxx/blob/main/src/dd/hash/ConfigHash.hpp#L147)                                  | Yes          | Native code [^2]                                                                                                                 | Used to set the maximum [drift](https://51degrees.com/documentation/_device_detection__hash.html?utm_source=github&utm_medium=docs&utm_campaign=specifications&utm_content=device-detection-specification-pipeline-elements-device-detection-on-premise.md&utm_term=configuration-options-2#drift) in hash position to allow when processing HTTP headers.                                                                                                                                                                                                                                         |
| Allow Unmatched           | [ConfigDeviceDetection::setAllowUnmatched()](https://github.com/51Degrees/51degrees-cxx/blob/main/src/dd/ConfigDeviceDetection.hpp#L108)        | Yes          | Native code [^2]                                                                                                                 | If no match is found for the Evidence value then this controls how the Property values will be populated in the result.</br>If set to false, Properties will not have set values.</br>If set to true, Property values will be set from the default [profile](../../data-model-specification/README.md#profile) for that component. This means that Properties will always have values (i.e. no need to check .HasValue) but some values might be inaccurate. |
| Reuse Operational File    | [ConfigBase=>setReuseTempFile()](https://github.com/51Degrees/51degrees-cxx/blob/main/src/common/ConfigBase.hpp#L104)                                             | Yes          | Native code [^2]                                                                                                                 | Set whether or not an existing operational file will be used if one is found in the temp directory.                                                                                                                                                                                                                                                                                                       |
| Update Matched User Agent | [ConfigDeviceDetection::setUpdateMatchedUserAgent()](https://github.com/51Degrees/51degrees-cxx/blob/main/src/dd/ConfigDeviceDetection.hpp#L90) | Yes          | `true`, from native code [^2]                                                                                                    | Set whether or not the result will include the characters from the Evidence values that were used to find a match. If set, this will be available from the 'UserAgents' [match metric](#match-metric-properties) Property. It is enabled by default, and it can be turned off when the 'UserAgents' Property is not needed, which saves recording the characters.                                                                                |
| Use Performance Graph     | [ConfigHash::setUsePerformanceGraph()](https://github.com/51Degrees/51degrees-cxx/blob/main/src/dd/hash/ConfigHash.hpp#L159)                    | Yes          | Native code [^2]                                                                                                                 | Set whether or not to use the [performance](https://51degrees.com/documentation/_device_detection__hash.html?utm_source=github&utm_medium=docs&utm_campaign=specifications&utm_content=device-detection-specification-pipeline-elements-device-detection-on-premise.md&utm_term=configuration-options-3#performance-graphs) graph when attempting to match Evidence values.                                                                                                                                                                                                                        |
| Use Predictive Graph      | [ConfigHash::setUsePredictiveGraph()](https://github.com/51Degrees/51degrees-cxx/blob/main/src/dd/hash/ConfigHash.hpp#L170)                     | Yes          | Native code [^2]                                                                                                                 | Set whether or not to use the [predictive](https://51degrees.com/documentation/_device_detection__hash.html?utm_source=github&utm_medium=docs&utm_campaign=specifications&utm_content=device-detection-specification-pipeline-elements-device-detection-on-premise.md&utm_term=configuration-options-4#predictive-graphs) graph when attempting to match Evidence values.                                                                                                                                                                                                                          |
| Indexed Properties        | [ConfigHash::setIndexedProperties()](https://github.com/51Degrees/51degrees-cxx/blob/main/src/dd/hash/ConfigHash.hpp#L202)                     | Yes          | None                                                                                                                             | Names the Properties, such as TAC and NativeModel, whose values are indexed to the profiles holding them when the data file loads, so that the [profiles for a value](#profiles-for-a-property-value) of one of them are found without reading every profile. Names are matched exactly. A refresh indexes the same Properties.                                                                                  |
| Performance Profile       | [ConfigHash=>set\[ProfileName\]()](https://github.com/51Degrees/51degrees-cxx/blob/main/src/dd/hash/ConfigHash.hpp#L104)                        | Yes          | Balanced, except for the Engine PHP builds at start-up [^php]. See [native code](https://github.com/51Degrees/51degrees-cxx/blob/main/src/dd/hash/hash.c#L175) for definitions. | Set the performance profile to use when creating the Engine. Each profile has default values for various internal configuration options, as well as things like the use of predictive/performance graphs.                                                                                                                                                                                                   |
| Concurrency               | [ConfigHash::setConcurrency()](https://github.com/51Degrees/51degrees-cxx/blob/main/src/dd/hash/ConfigHash.hpp#L180)                            | Yes          | System processor count | Set the expected number of operations that use the Engine at the same time. The native code uses it for every collection read from the file.</br>1. It sets the number of file handles in the pool, which is Concurrency up to a fixed maximum of 64, because a process can only have so many files open (512 through `fopen` by default on Windows). An operation that has to read from the file when every handle is in use MUST wait until another operation releases one.</br>2. It decides how each cache is split into parts, each with its own lock, which avoids excessive locking. An item in use cannot be removed from a cache, and any operation can need any part, so every part MUST hold at least Concurrency items. The number of parts is Concurrency, or fewer where needed so that every part holds at least Concurrency items, and a cache that holds fewer than Concurrency items in total MUST be made large enough to hold Concurrency items. No value of Concurrency stops the Engine building.</br>Concurrency has no effect when every collection is held in memory, for example with the 'MaxPerformance' profile. |

[^php]: In PHP the Engine built when PHP starts, from its configuration file,
always uses MaxPerformance, which holds the whole data file in memory, and a
package refuses any other profile for it. PHP usually serves requests from
worker processes forked from the process that built that Engine. A fork copies
the open file handles, which then share one read position between the workers,
so with a profile that reads from the file the workers would corrupt each
other's reads. Any other Engine, such as one a package builds after the
fork or in a process that never forks, opens its own file handles and may use
any profile.

[^2]: The default values for many configuration options come from the native
C/C++ code. You can find these defaults in
<https://github.com/51Degrees/51degrees-cxx/blob/main/src/common/config.h> and
<https://github.com/51Degrees/51degrees-cxx/blob/main/src/dd/config-dd.h>
