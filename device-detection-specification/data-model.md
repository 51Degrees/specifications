# Data model

## Introduction

This document contains the details of the data values returned by 51Degrees
Device Detection.

## Overview

All Engines MUST populate data objects that
implement [Aspect Data](../pipeline-specification/conceptual-overview.md#aspect-data)
as defined in the Pipeline specification.

There are several different Engines for getting information about devices. Each
of these Engines MUST return data that is interface compatible with the others.

Given an interface `IDeviceData`, the following table shows what will be
populated by each Engine:

| Engine          | Result                   |
|-----------------|--------------------------|
| On-premise      | IDeviceData              |
| Cloud           | IDeviceData              |
| Hardware lookup | IList&lt;IDeviceData&gt; |

## Dynamic Property recommendations

The Properties that can be populated by Device Detection are defined within the
data file. As such, they are subject to change over time.

For weakly typed languages, this is usually less of an issue as developers in
these ecosystems are generally more used to the idea of discovering Properties
at runtime. However, there will need to be clear signposting to locations such as
the [Property dictionary](https://51degrees.com/developers/property-dictionary)
in order to help discover what Properties are available.

For strongly typed languages, this is partially handled by being able to access
Property values by name. For more details,
see [Element Data](../pipeline-specification/conceptual-overview.md#element-data)
in the Pipeline specification.

However, we also want to provide strongly-typed accessors. This could become a
significant maintenance burden, so a command line utility SHOULD be created that
can generate an interface definition and any necessary implementations from the
metadata embedded in the data files.

This can be used during development as well as within 51Degrees' CI/CD
infrastructure to automatically re-generate the code when changes occur, such as
a new Property being added.

Note that there are a few additional
[match metrics Properties](pipeline-elements/device-detection-on-premise.md#match-metric-properties)
that do not appear in the data file metadata, but will need to be included in
interfaces, etc.

## Property details

Each Property SHOULD return
an [Aspect Property value](../pipeline-specification/features/properties.md#null-values)
in order to support exposing the reason that a value is not set.

Beyond this, there are considerations unique to each Engine. Ensure to review
the details linked below:

- [on-premise](pipeline-elements/device-detection-on-premise.md#metadata)
- [cloud](pipeline-elements/device-detection-cloud.md#start-up-activity)
- [hardware lookup](part3/pipeline-elements/hardware-profile-lookup-cloud.md#start-up-activity)
