# Hardware profile lookup

## Overview

This [Cloud Aspect Engine](../../pipeline-specification/conceptual-overview.md#cloud-aspect-engine)
enables the parsing of 'profile lookup' responses from the 51Degrees cloud service.

See [here](../../pipeline-specification/pipeline-elements/cloud-request-engine.md)
for an overview of the data flow for Cloud Engines.

Profile lookup allows the user to retrieve a list of property values for
[profiles](../pipeline-elements/device-detection-on-premise.md#profile)
where a given property has a value matching a supplied parameter.

Currently, this capability is used for two use-cases:

- Get hardware devices matching a given TAC. More background information on
  TACs can be found through various online sources such as
  [Wikipedia](https://en.wikipedia.org/wiki/Type_Allocation_Code).
- Get hardware devices matching a given native model name. Native model name
  is a string of characters that are returned from a query to the device's OS.
  There are different mechanisms to get native model names for
  [Android devices](https://developer.android.com/reference/android/os/Build#MODEL)
  and [iOS devices](https://gist.github.com/soapyigu/c99e1f45553070726f14c1bb0a54053b#file-machinename-swift)

## Accepted Evidence

None. This Engine uses the output from the Cloud Aspect Engine as input
rather than using Evidence.

## Start-up activity

When it is added to a Pipeline, this Engine initializes itself from a
Cloud Request Engine, which MUST have been added to the Pipeline
before it.

The Cloud Request Engine determines which Properties are available
based on the Resource Key supplied on start-up. The Hardware Profile Lookup Engine
then takes the details of the subset of those Properties that are relevant to
it.

Be aware that this engine also has sub-properties under the top level property
that MUST also be catered for.

## Element Data

| **Name**                   | **Type**                              | **Description**                                                                                                                           |
|----------------------------|---------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| profiles | `IReadOnlyList<IDeviceData>` | A list of instances that are interface compatible with the results from cloud and on-premise device detection engines. |

## Process

The majority of the processing SHOULD be handled by the shared
[Cloud Aspect Engine](../../pipeline-specification/pipeline-elements/cloud-aspect-engine.md#processing)
logic.

This will just need to filter and parse the JSON provided by the Cloud Aspect
Engine to the form that is needed for the Element Data output

## Configuration options

There are no configuration options associated with this Engine.
