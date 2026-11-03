# IP Intelligence On-Premise

## Overview

This Engine provides IP Intelligence capabilities using a high performance
on-premise algorithm.

This Engine also requires an IPI data file, which comes in two variations:

- **Lite** - Freely available from [GitHub](https://github.com/51Degrees/ip-intelligence-data).
  Contains a highly restricted set of Properties and is updated
  around once per month.
- **Enterprise** - Downloaded from
  [Distributor](https://51degrees.com/documentation/_info__distributor.html?utm_source=github&utm_medium=docs&utm_campaign=specifications&utm_content=ip-intelligence-specification-pipeline-elements-ip-intelligence-on-premise.md&utm_term=overview).
  Requires a license key for download and is usually updated Monday-Thursday. Includes all Properties

## Native component

In all languages, the on-premise IP Intelligence Engine passes the actual
detection processing to a native DLL/so library that is written in C/C++.

The intention was that this will ensure the best performance for the most
computationally complex part of the process and reduce maintenance overhead,
as well as the time needed to add support for IP Intelligence in a new
language.

The code for this component is available on GitHub:

- [51degrees-cxx/src/common](https://github.com/51Degrees/51degrees-cxx/tree/main/src/common)
- [51degrees-cxx/src/ipi](https://github.com/51Degrees/51degrees-cxx/tree/main/src/ipi)
- [51degrees-cxx/src/ipi/graph](https://github.com/51Degrees/51degrees-cxx/tree/main/src/ipi/graph)

Unfortunately, while calling a native library is possible in many languages, it
is often fiddly and can come with unexpected difficulties. As such, we generally
use [SWIG](https://www.swig.org/) to help produce a wrapper for the target
language. This takes care of the marshalling of data structures to and from
C data structures but represents a performance overhead - see
[Performance Guidance](#performance-guidance) below. The implementor will still
need to be familiar with the mechanisms that are used by the language to call
native code.

The C library is distributed in binary form for a restricted set of target
environments [tested versions](https://51degrees.com/documentation/_info__tested_versions.html?utm_source=github&utm_medium=docs&utm_campaign=specifications&utm_content=ip-intelligence-specification-pipeline-elements-ip-intelligence-on-premise.md&utm_term=native-component),
with a number of assumptions about the availability
of [dependencies](https://51degrees.com/documentation/_info__dependencies.html?utm_source=github&utm_medium=docs&utm_campaign=specifications&utm_content=ip-intelligence-specification-pipeline-elements-ip-intelligence-on-premise.md&utm_term=native-component).

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
repository and package from the target language IP Intelligence Engine
logic.

## Accepted Evidence

This Engine determines the accepted Evidence keys on data refresh based
on values in the data source.

After loading the data source into the native code, call the `getKeys`
function to return a list of the accepted Evidence keys, in the order the
native code tries them (see [choosing the IP address](#choosing-the-ip-address)).
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
populated by the IP Intelligence engine.

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
  - The Element Data MUST read a Property value from `ResultsIpi` only when
    that Property is requested, and MUST NOT copy Property values out of
    `ResultsIpi` while the Engine processes the Flow Data. Copying every
    Property means a call to the native code for each one, marshalling
    values back and forth, and conversions the caller may never need, such
    as writing a geometry value as text, on every request [^3].
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

### Choosing the IP address

The data file lists the client IP keys in priority order, for example
`true-client-ip-51d`, then `client-ip-51d`, then `client-ip`, and the Engine
accepts each of them under both the `query` and the `server` prefix. When the
Evidence holds more than one of these keys, the native code uses one value,
chosen in this order:

1. The `query` keys, in the data file's order.
2. Only when no `query` key supplied an address, the `server` keys, in the
   data file's order.

The prefix is decided first, as the
[Evidence precedence](../../pipeline-specification/features/evidence.md#overview)
requires, and the data file's order decides between keys under one prefix.
So `query.client-ip` is used ahead of `server.true-client-ip-51d`. The
Property values in the result describe that one address.

### Address forms

One IP address can be written in more than one form, and the form decides which
address it is. An IPv4 address and an ordinary IPv6 address are looked up as
written. The Engine MUST look up the three forms that hold an IPv4 address as
the following table says, so that one address gets the same Property values in
every language.

| **Form**             | **Example**        | **Defined by**                                                                          | **Looked up as**           |
|----------------------|--------------------|-----------------------------------------------------------------------------------------|----------------------------|
| IPv4-mapped IPv6     | `::ffff:8.8.8.8`   | [RFC 4291 section 2.5.5.2](https://www.rfc-editor.org/rfc/rfc4291.html#section-2.5.5.2) | The IPv4 address `8.8.8.8` |
| IPv4-compatible IPv6 | `::8.8.8.8`        | [RFC 4291 section 2.5.5.1](https://www.rfc-editor.org/rfc/rfc4291.html#section-2.5.5.1) | An IPv6 address            |
| IPv4-embedded IPv6   | `64:ff9b::8.8.8.8` | [RFC 6052](https://www.rfc-editor.org/rfc/rfc6052.html)                                 | An IPv6 address            |

#### IPv4-mapped addresses

[RFC 4291 section 2.5.5.2](https://www.rfc-editor.org/rfc/rfc4291.html#section-2.5.5.2)
says this form "is used to represent the addresses of IPv4 nodes as IPv6
addresses".
[RFC 4038 section 4.2](https://www.rfc-editor.org/rfc/rfc4038.html#section-4.2),
which RFC 4291 names as the background on its use, says "the IPv6 address
::FFFF:x.y.z.w represents the IPv4 address x.y.z.w." Servers report this form
because, under
[RFC 3493 section 3.7](https://www.rfc-editor.org/rfc/rfc3493.html#section-3.7),
an IPv6 socket that accepts a connection from an IPv4 node returns the address
of that node encoded this way.
[RFC 6890 section 2.2.3](https://www.rfc-editor.org/rfc/rfc6890.html#section-2.2.3)
and the current
[IANA registry](https://www.iana.org/assignments/iana-ipv6-special-registry/iana-ipv6-special-registry.xhtml)
list `::ffff:0:0/96` as not globally reachable, so the block is not a network
with Property values of its own.

So an IPv4-mapped address is its IPv4 address. Every way of giving the address,
such as `::ffff:808:808`, `0:0:0:0:0:ffff:808:808` and its 16 bytes, MUST get
the same Property values as `8.8.8.8`, including the Properties that report an
IP range. The native code does this on every lookup, so an implementation does
not need to change the address before passing it on.

Where an implementation reports the address of the client in the `Ip` and
`IpV6` Properties, `Ip` MUST report `8.8.8.8` and `IpV6` MUST have no value.

Language runtimes recognize this form, and an implementation that reads an
address for itself SHOULD use what its runtime provides rather than comparing
text.

| **Language** | **What the runtime does with `::ffff:8.8.8.8`**                                                                                                                             |
|--------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| .NET         | `IPAddress.IsIPv4MappedToIPv6` is true and `MapToIPv4()` gives `8.8.8.8`. Check `IsIPv4MappedToIPv6` first, as `MapToIPv4()` takes the last four bytes of any IPv6 address. |
| Java         | `InetAddress.getByName` returns an `Inet4Address` for `8.8.8.8`.                                                                                                            |
| Go           | `net.IP.To4()` and `netip.Addr.Unmap()` give `8.8.8.8`.                                                                                                                     |
| Rust         | `Ipv6Addr::to_ipv4_mapped()` and `IpAddr::to_canonical()` give `8.8.8.8`.                                                                                                   |
| Python       | `ipaddress.IPv6Address.ipv4_mapped` gives `8.8.8.8`.                                                                                                                        |
| Node.js      | `net.BlockList` matches the address against a rule for `8.8.8.8`.                                                                                                           |
| PHP          | `inet_pton` gives the 16 bytes and there is no call for the IPv4 address, so compare the first 12 bytes.                                                                    |

None of these treats `::8.8.8.8` or `64:ff9b::8.8.8.8` as an IPv4 address.

#### IPv4-compatible addresses

[RFC 4291 section 2.5.5.1](https://www.rfc-editor.org/rfc/rfc4291.html#section-2.5.5.1)
deprecates this form and says "New or updated implementations are not required
to support this address type". The Engine MUST NOT look up such an address as
the IPv4 address it holds.

#### IPv4-embedded addresses

[RFC 6052](https://www.rfc-editor.org/rfc/rfc6052.html) defines this form, and
the Engine follows RFC 6052 by treating these as IPv6 addresses.
[Section 1.3](https://www.rfc-editor.org/rfc/rfc6052.html#section-1.3) defines
an address translator as "any entity that has to derive an IPv4 address from an
IPv6 address or vice versa". The Engine has no need to derive one, so it is not
an address translator. The prefix can also be one that an organization chose for
itself, in any of the lengths that
[section 2.2](https://www.rfc-editor.org/rfc/rfc6052.html#section-2.2) allows,
so the form cannot in general be recognized from the address alone. The Engine
MUST NOT look up such an address as the IPv4 address it holds. The address gets
what the data file holds for that IPv6 address, which is no value where the file
holds nothing for it.

#### Addresses below the lowest key

An address below the lowest key in a graph has no profile for the component of
that graph, rather than the profile of an unrelated address. This is decided for
each graph, so an address can be below the lowest key of one graph and have a
profile in another. The result is what any address gets when the data file holds
nothing for it. A Property that is mandatory with a default value reads as that
default, any other Property has no value, with the null profile reason, and the
lookup raises no error.

A data file SHOULD hold a key at the bottom of each graph that leads to a
profile with no values, so that this case does not arise. The Property values
are the same with or without that key.

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
  - [IP Intelligence metadata](#metadata)
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
| Performance Profile       | [ConfigIpi=>set\[ProfileName\]()](https://github.com/51Degrees/51degrees-cxx/blob/main/src/ipi/ConfigIpi.hpp#L104)                        | Yes          | Balanced. See [native code](https://github.com/51Degrees/51degrees-cxx/blob/main/src/ipi/ipi.h#L429) for definitions. | Set the performance profile to use when creating the Engine. Each profile has default values for various internal configuration options, as well as things like the use of predictive/performance graphs.                                                                                                                                                                                                   |
| Concurrency               | [ConfigIpi::setConcurrency()](https://github.com/51Degrees/51degrees-cxx/blob/main/src/ipi/ConfigIpi.hpp#L180)                            | Yes          | System processor count                                                                                                           | Set the expected number of concurrent operations using the Engine. This is used to configure internal caches to avoid excessive locking. It has no effect if these internal caches are not used. (For example, when using the 'MaxPerformance' profile)                                                                                                                                                     |

The default values for many configuration options come from the native
C/C++ code. You can find these defaults in
<https://github.com/51Degrees/51degrees-cxx/blob/main/src/common/config.h>.
