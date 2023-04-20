# Overview

This engine provides device detection capabilities using a high performance 
on-premise algorithm we refer to as the 
[hash](http://51degrees.com/documentation/4.4/_device_detection__hash.html)
algorithm.

This engine also requires a hash data file, which comes in three variations:

- **Lite** - Freely available from [GitHub](https://github.com/51Degrees/device-detection-data).
  Contains a highly restricted set of properties and is updated 
  around once per month.
- **Enterprise** - Downloaded from 
  [Distributor](http://51degrees.com/documentation/4.4/_info__distributor.html). 
  Requires a license key for download and is usually updated Monday-Thursday. Includes all 
  properties except TAC.
- **TAC** - Same as enterprise except that TAC is included in the result.

# Native component

In all languages, the on-premise device detection engine passes the actual
detection processing to a native dll/so library that is written in C/C++.

The intention was that this will ensure the best performance for the most 
computationally complex part of the process and reduce maintenance overhead,
as well as the time required to add support for device detection in a new 
language.

The code for this component is available on GitHub:

- [common-cxx](https://github.com/51Degrees/common-cxx)
- [device-detection-cxx](https://github.com/51Degrees/device-detection-cxx)

Unfortunately, while calling a native library is possible in many languages, it
is often fiddly and may come with unexpected difficulties. As such, we generally 
use [SWIG](https://www.swig.org/) to help produce a wrapper for the target 
language. This takes care of the marshalling of data structures to and from 
C data structures but represents a performance overhead - see 
[Performance Guidance](#performance-guidance) below.

The C library is distributed in binary form for a restricted set of target
environments [tested versions](https://51degrees.com/documentation/4.4/_info__tested_versions.html), 
with a number of assumptions about the availability 
of [dependencies](https://51degrees.com/documentation/4.4/_info__dependencies.html).

## Selecting the correct binary

While the implementor is not expected to produce the CI/CD scripts that 
will create the final packages, attention must be given to how the final
package will determine the correct native binary to use based on the current
operating system.

In some cases, this capability is built into the packaging infrastructure 
(For example, .NET/NuGet). Some require additional code to be written to 
determine the correct binary at runtime (Java/Maven and Node/NPM). Others 
do not allow native binaries in packages at all (PHP/Composer).

## Reference implementation notes

The reference implementations bundle the cxx code in with the Java/.NET 
code and build it all together. This works well enough, but does come
with the downside of adding significant complexity to the build process 
for customers who may just be able to consume pre-built native binaries.

For future implementations, we recommend exploring the possibility of
moving the native binary and target language wrapper to a separate 
repository and package from the target language device detection engine 
logic.

# Accepted evidence 

This engine determines the accepted evidence keys on data refresh based
on values in the data source.

After loading the data source into the native code, call the `getKeys` 
function to return a list of the accepted evidence keys.
These values should then be stored to prevent repeated calls to the
native code.

This must be done at startup and any time the data is refreshed.

Note that the list of accepted evidence keys is not case-sensitive -
i.e. `header.user-agent` and `header.User-Agent` should both be 
accepted.

# Element data

The list of properties that can be populated by this engine is determined 
on data refresh based on the properties that are available in the data 
source that is used.

In addition, several additional [match metrics](#match-metric-properties) 
properties must be added as well. The table below shows the native 
function to call to get the value for each property.

| Name         | Function on result object to call to get value [^nb] |
|--------------|------------------------------------------------------|
| MatchedNodes | getMatchedNodes                                      |
| Difference   | getDifference                                        |
| Drift        | getDrift                                             |
| DeviceId     | getDeviceId                                          |
| UserAgents   | getUserAgents                                        |
| Iterations   | getIterations                                        |
| Method       | getMethod                                            |

[^nb] Note that the native implementations have some additional complexity
in their code because of a plan to split device detection into 4 
separate engines. This is not necessary in new implementations.

It is essential that the **Element Data** instance populated by this 
on-premise engine is interface compatible with the **Element Data** 
populated by the [cloud device detection engine](device-detection-cloud.md) 
as well as the individual devices populated in the **Element Data** from 
the [hardware profile lookup engine](hardware-profile-lookup-cloud.md).

# Startup activity

On startup, the native engine needs to be created using the data file.
Several functions must then be called to get the data that will be needed 
by other engine features.

See [refresh data](#refresh-data) for details on this process.

# Processing

This section describes the core steps this engine executes to process 
**Flow Data**. This is on top of any common processing defined for 
other Pipeline API features.

- Create and populate the native evidence object
  - The evidence values will typically need to be converted to a memory 
    format that can be used by the native Cxx code.
  - First, create a new `EvidenceDeviceDetection` C++ instance.
  - Next, add items from the **Flow Data** evidence to the C++ instance.
    - Only need to add entries that the engine will make use of.
- Call the `process` function on the native engine, passing the native
  evidence instance.
- This will return a `ResultsHash` instance, which contains references to
  the resulting property values.
- Create a new instance of the implementation of the `IDeviceData` interface
  that is being used for the on-premise engine.
  - Pass the `ResultsHash` instance so it can be used when property values 
    are requested.
  - Do not immediately copy all the property values from `ResultsHash`. By 
    default, around 200 properties will be populated, meaning 200+ calls to 
    the native code marshalling values back and forth [^caching]. 

[^caching] Note the effect that 
    holding the "unmanaged" memory references (i.e. memory references that
    are not handled by language garbage collection) has on 
    [caching](features/caching.md) and [resource cleanup](resource-cleanup.md). 
    The reference implementations don't allow a cache to be
    added to this engine because of the complexity this introduces, however
    end-users may be tempted to create their own cache of results.

## Performance guidance

We have found that the main performance bottleneck is usually the process
of marshalling data values to and from native representations.

As such, this should be minimized as much as possible:

- Languages often have many mechanisms for passing data in calls
  to native binaries, some more efficient than others. SWIG code will 
  sometimes use the most flexible approach, rather than the most performant.
  It is worth checking the generated code for relatively easy performance 
  wins.
- Whenever making a call to native code, be aware of the data that is being
  passed and check if there is anything that can be done to reduce it.  
- Finally, do not call native code at all if it can be avoided. For example, any 
  values that will only change after a [data refresh](#refresh-data) should 
  be stored in the engine instance to avoid native calls for that value until 
  a refresh occurs. Not the possible clean-up consequences that this implies.

# Refresh data

The [refresh data function](../../pipeline-specification/features/data-updates.md#aspect-engine-features)
for this engine must perform the following tasks:
- Create a new instance of the C++ `EngineHashSwig` type using either the 
  filename or byte[] constructor.
- Call `refreshData` on the C++ engine in order to load data into the 
  relevant data structures.
- Call the necessary functions on the C++ engine in order to acquire 
  metadata about the engine that is dependent on the data file:
  - [accepted evidence](#accepted-evidence)
  - [properties](#property)
  - [additional device detection metadata](#metadata)
  - data file publish date
  - expected publish date of next data file
  - data file type
  - data file temp path 

The following table lists the C++ engine functions to call to get the data 
mentioned above:

| Function name            | Notes                                                                                                                                                                                              |
|--------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `getKeys`                | Get a list of the evidence keys that the data file will make use of                                                                                                                                |
| `getMetaData`            | Get [meta data](#metadata) from the data file                                                                                                                                                      |
| `getPublishedTime`       | Get the date/time that the data file was created                                                                                                                                                   |
| `getUpdateAvailableTime` | Get the data/time that a new data file is expected to be available                                                                                                                                 |
| `getProduct`             | Get the string type of the data file. This is used by the [data update](../../pipeline-specification/features/data-updates.md) functionality when calling Distributor to check for a new data file |
| `getDataFileTempPath`    | Get the path to the temporary working copy of the data file (This is the full path to the copy of the data file that the C code makes before reading it.)                                          |

# Events

This engine should implement the following events/callbacks/hooks:

| Name             | Notes                                                                       |
|------------------|-----------------------------------------------------------------------------|
| Refresh complete | Used by client to perform some action after a new data file has been loaded |

# Metadata

## Overview

On-premise device detection has two related metadata structures:
1. The device detection data file includes metadata relating to the structure of the 
   values that are stored in the file. This is exposed by the device detection engine 
   in order to allow users to query the data. [^performance]
2. All flow elements expose a list of metadata relating to properties populated by 
   that element. In the case of the device detection engine, this list will include 
   property metadata derived from the data file metadata mentioned above. 

[^performance] Note that, due to the structure of the data, this is not intended to support 
high-performance querying scenarios. For that use-case, customers are directed to our 
'csv' data file, which can be consumed and stored in a database or whatever other form 
is required for querying. 

```mermaid
erDiagram
    Component ||--|{ Property : has
    Property ||--|{ Value : has
    Component ||--|{ Profile : has
    Profile ||--|{ Value : has
```

## Component

A **component** defines a group of **properties** that are related.

In a 51Degrees data set, each **property** can only be related to one **component**. 
For example, the `Browser Name` **property** is part of the `Software` **component**, 
whereas the `Model Name` **property** is part of the `Hardware` **component**.

The metadata associated with a **component** is:

| Metadata        | Description                                                                                                                                                                         |
|-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Id              | The unique id of the **component**. This is a number and will remain the same when a data file is updated.                                                                          |
| Name            | The name of the **component** that gives a more 'human' identifier than id. By convention, this is unique within the data file.                                                     |
| Default profile | The default **profile** for the **component**. This is used to provide **values** for the **component's** **properties** when a **profile** matching the @evidence cannot be found. |
| Properties      | The **properties** associated with this **component**.                                                                                                                              |

## Property

The **properties** exposed by the device detection engine contain more information 
than that which is defined by the standard **property metadata** interface.
In addition to the usual information, the following must be made available:

| Metadata      | Description                                                                                                                                                                                                                                                  |
|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Description   | A description of the **property** explaining what it refers to, and what significance its values have.                                                                                                                                                       |
| URL           | A URL where more information on the **property** can be found.                                                                                                                                                                                               |
| Component     | The **component** to which the **property** belongs. This is subtly different from the category, in that a **profile** defines the values for all the **properties** of a single **component**, which likely contains multiple categories of **properties**. |
| Values        | The **values** that the **property** can have. As a simple example, a **property** named ``'IsSmartPhone'`` might have three values: ``true``, ``false``, and ``unknown``.                                                                                   |
| Default Value | The default **value** for the **property** if it is not otherwise known. In the above example, the **property** named ``'IsSmartPhone'`` would probably have ``unknown`` as the default value.                                                               |
| List          | Whether or not the **property** may have multiple values. For example, the connectivity types a device supports would be a list, as a single device might support Bluetooth, HSDPA, LTE, Wi-Fi, etc.                                                         |
| Obsolete      | Whether the **property** is obsolete and only exists to maintain backward compatibility.                                                                                                                                                                     |
| Display Order | The suggested order in which to display the **property** when listing **properties**.                                                                                                                                                                        |
| Mandatory     | Whether the **property** is mandatory or not. If a **property** is mandatory, a **profile** must have a non-default value for it to be classed as valid.                                                                                                     |
| Show          | Whether the **property** should be displayed in situations such as a page listing **properties**. Less important **properties** may not be displayed.                                                                                                        |
| Show Values   | Whether values of the **property** should be displayed in situations such as a page listing the **property's** values. Showing all the values can make a very long list.                                                                                     |

## Profile

A **profile** defines a unique set of **values** for all **properties** of 
a single **component**. 

| Metadata  | Description                                                                                                                                                                           |
|-----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Id        | The unique id of the **profile**. This is usually a number and will remain the same when a data file is updated.                                                                      |
| Name      | The name of the **profile** that gives a more 'human' identifier than id, usually describing what the **values** it contains are. By convention, this is unique within the data file. |
| Component | The **component** to which the **profile** relates. This is the **component** which the **profile** contains **values** for.                                                          |
| Values    | The **values** that define the **profile**.                                                                                                                                           |

## Value

Each **property** has a set of possible **values** that it can return.
The metadata associated with a **value** is:

| Metadata    | Description                                                                                                                                                   |
|-------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Name        | The **value** as a string. This uniquely identifies the **value** only within the **values** relating to the same **property**.                               |
| Property    | The **property** to which the **value** relates. This, in combination with the name, uniquely identifies the **value** within the device detection data file. |
| Description | A description of the **value** explaining what it refers to, and what it means if a **profile** has this **value**.                                           |
| URL         | A URL where more information on the **value** can be found.                                                                                                   |

## Match metric properties

In addition to the 'standard' device detection properties, there are a set of 
properties that return details about the processing that was performed and 
the match that was found. Metadata for these properties must be added, as they 
will not be included in the metadata exposed by the native code.

All these properties have the following values:
- Category = "Device Metrics" (sic)
- Available With = "Lite", "Premium", "Enterprise", "TAC" - If possible, this 
  list should be created dynamically from the lists of files included against 
  all other property metadata that is exposed by the native code.
- Component = "Metrics" - This component must also be added to the list of 
  components returned by the engine.

| Name             | Type   | Default value | Description                                                                                                                                                                                                                                                                | Possible values                                 |
|------------------|--------|---------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------|
| MatchedNodes     | int    | 0             | Indicates the number of hash nodes matched within the evidence.                                                                                                                                                                                                            | n/a                                             |
| Difference       | int    | 0             | Used when detection method is not Exact or None. The larger the value the less confident the detector is in this result.                                                                                                                                                   | n/a                                             |
| Drift            | int    | 0             | Total difference in character positions between where the substring's hashes were found and where they were expected.                                                                                                                                                      | n/a                                             |
| DeviceId         | string | "0-0-0-0"     | Contains the profile ids of the matching profiles, separated by a hyphen symbol. For example \[HardwareId\]-\[PlatformId\]-\[BrowserId\]-\[CrawlerId\]. By convention, these will be in component Id order. There will often be 4 ids present, but this is not guaranteed. | n/a                                             |
| MatchingEvidence | string | "n/a"         | The matched User-Agents.                                                                                                                                                                                                                                                   | n/a                                             |
| Iterations       | int    | 0             | The number of iterations carried out in order to find a match. This is the number of nodes in the graph which have been visited.                                                                                                                                           | n/a                                             |
| Method           | string | "NONE"        | The method used to determine the match result.                                                                                                                                                                                                                             | "NONE", "PERFORMANCE", "COMBINED", "PREDICTIVE" |

# Configuration options

These are the configuration options that are unique to this engine. They are in 
addition to all the configuration options defined for other features. For example,
[data updates](../../../pipeline-specification/part2/features/data-updates.md#configuration-groups)

| **Parameter**             | **Optional** | **Default**                                                                                                                      | **Notes**                                                                                                                                                                                                                                                                                                                                                                                                   |
|---------------------------|--------------|----------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Difference                | Yes          | Native code [^1]                                                                                                                 | Used to set the maximum [difference](https://51degrees.com/documentation/4.4/_device_detection__hash.html#difference) in hash value to allow when processing HTTP headers.                                                                                                                                                                                                                                  |
| Drift                     | Yes          | Native code [^1]                                                                                                                 | Used to set the maximum [drift](https://51degrees.com/documentation/4.4/_device_detection__hash.html#drift) in hash position to allow when processing HTTP headers.                                                                                                                                                                                                                                         |
| Allow Unmatched           | Yes          | Native code [^1]                                                                                                                 | If no match is found for the evidence value then this controls how the property values will be populated in the result.</br>If set to false, properties will not have set values.</br>If set to true, property values will be set from the default [profile](#profile) for that component. This means that properties will always have values (i.e. no need to check .HasValue) but some may be inaccurate. |
| Reuse Operational File    | Yes          | Native code [^1]                                                                                                                 | Set whether or not an existing operational file should be used if one is found in the temp directory.                                                                                                                                                                                                                                                                                                       |
| Update Matched User Agent | Yes          | Native code [^1]                                                                                                                 | Set whether or not the result should include the characters from the evidence values that were used to find a match. If set, this will be available from the 'MatchingEvidence' [match metric](#match-metric-properties) property. This is optional because it adds some overhead that is not necessary in normal operation.                                                                                |
| Use Performance Graph     | Yes          | Native code [^1]                                                                                                                 | Set whether or not to use the [performance](https://51degrees.com/documentation/4.4/_device_detection__hash.html#performance-graphs) graph when attempting to match evidence values.                                                                                                                                                                                                                        |
| Use Predictive Graph      | Yes          | Native code [^1]                                                                                                                 | Set whether or not to use the [predictive](https://51degrees.com/documentation/4.4/_device_detection__hash.html#predictive-graphs) graph when attempting to match evidence values.                                                                                                                                                                                                                          |
| Performance Profile       | Yes          | Balanced. See [native code](https://github.com/51Degrees/device-detection-cxx/blob/master/src/hash/hash.c#L175) for definitions. | Set the performance profile to use when creating the engine. Each profile has default values for various internal configuration options, as well as things like the use of predictive/performance graphs.                                                                                                                                                                                                   |
| Concurrency               | Yes          | System processor count                                                                                                           | Set the expected number of concurrent operations using the engine. This is used to configure internal caches to avoid excessive locking. It has no effect if these internal caches are not used. (For example, when using the 'MaxPerformance' profile)                                                                                                                                                     |

[^1]: The default values for many configuration options comes from the native 
C/C++ code. You can find these defaults in the following files: 
- https://github.com/51Degrees/common-cxx/blob/master/config.h
- https://github.com/51Degrees/device-detection-cxx/blob/master/src/config-dd.h

