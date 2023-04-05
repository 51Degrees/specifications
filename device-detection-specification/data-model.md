# Introduction

This document contains the details of the data values returned by 51Degrees
device detection.

# Overview

All engines must populate data objects that
implement [Aspect Data](../pipeline-specification/conceptual-overview.md#aspect-data)
as defined in the pipeline specification.

There are several different engines for getting information about devices. Each
of these engines must return data that is interface compatible with the others.

Given an interface `IDeviceData`, the following table shows what should be
populated by each engine:

| Engine          | Result                   |
|-----------------|--------------------------|
| On-premise      | IDeviceData              |
| Cloud           | IDeviceData              |
| Hardware lookup | IList&lt;IDeviceData&gt; |

# Dynamic property recommendations

The properties that can be populated by device detection are defined within the
data file. As such, they are subject to change over time.

For weakly typed languages, this is usually less of an issue as developers in
these ecosystems are generally more used to the idea of discovering properties
at runtime. However, there should be clear signposting to locations such as
the [property dictionary](https://51degrees.com/developers/property-dictionary)
in order to help discover what properties are available.

For strongly typed languages, this is partially handled by being able to access
property values by name. For more details,
see [Element Data](../pipeline-specification/conceptual-overview.md#element-data)
in the pipeline specification.

However, we also want to provide strongly-typed accessors. This could become a
significant maintenance burden, so a command line utility should be created that
can generate an interface definition and any required implementations from the
metadata embedded in the data files.

This can be used during development as well as within 51Degrees' CI/CD
infrastructure to automatically re-generate the code when changes occur, such as
a new property being added.

Note that there are a few additional 
[match metrics properties](pipeline-elements/device-detection-on-premise.md#match-metric-properties)
that do not appear in the data file metadata, but will need to be included in
interfaces, etc.

# Property details

Each property should return
an [aspect property value](../pipeline-specification/features/properties.md#null-values)
in order to support exposing the reason that a value is not set.

TODO - finish links once content is available
Beyond this, there are considerations unique to each engine. Ensure to review
the details linked below:

- [on-premise](pipeline-elements/device-detection-on-premise.md#metadata)
- [cloud](pipeline-elements/device-detection-cloud.md#)
- [hardware lookup](pipeline-elements/hardware-profile-lookup-cloud.md#)

