# Properties

## Overview

This document contains details on the features associated with the Properties that
are populated by Flow Elements.

In this case, a 'Property' refers to a specific, named data field that can be
set to different values. This is the same conceptually as the
[Property](../../data-model-specification/README.md#property) that is defined in
the data model specification. (Although they have some different metadata values)

The Property value will be determined during the 'process' step that is performed
by each Flow Element. This value will be stored within the Element Data,
which is in turn stored within Flow Data.

Each Flow Element MAY populate values for zero or more Properties.

## Value types

A Property can return values of any type. However, there are certain types that are
specifically expected and supported throughout the API.

The primary limitation is that these type values will need to be represented
in JSON data.

The core types are:

- string
- boolean
- numeric (integer or floating point)
- array of strings

In addition, there are a couple of types that are supported through additions in
JSON encode/decode logic:

- javascript - See [the javascript type](#the-javascript-type) below
- array of key-value-pair collections - Used in scenarios where we want to return
  multiple Aspect data instances. (For example, TAC lookup)

### The javascript type

The javascript type is a custom type that is used to identify values which contain
JavaScript snippets that are intended to be executed on the client device.

In JSON, this type is represented as a string.

See [web integration](web-integration.md#javascript-snippets) for more detail.

## Null values

Property values populated by Engines (as opposed to Flow Elements in general)
MUST be capable of having 'no value'.

Where 'no value' has been assigned, attempting to access the value MUST throw an
error/exception with a customizable message explaining why the value is not set.

This is similar to the [missing Property](#missing-properties) feature.
In that case, the Property is not present in the result dataset at all. In this
case, the Property is present in the result, but the Flow Element has
chosen not to set its value for some reason.

## Property metadata

All [Flow Elements](../conceptual-overview.md#flow-element) MUST expose metadata
describing details of the Properties that they can populate.

In addition, it MUST be possible to get Property metadata at the Pipeline
level for all Properties that can be populated by all Flow Elements in the
Pipeline.

In the reference implementations, the Elements and Pipeline expose a property
that returns a list of metadata for all properties. The user can then filter
and store values as they need to.

see reference implementations:

- [C#](https://github.com/51Degrees/51degrees-dotnet/blob/main/pipeline/Core/FlowElements/FlowElementBase.cs#L111)
- [Java](https://github.com/51Degrees/51degrees-java/blob/main/pipeline/pipeline.core/src/main/java/fiftyone/pipeline/core/flowelements/FlowElementBase.java#L108)
  (Java also provides a `getProperty` method that takes the string name of a
  property, but this is not a required part of the spec)

The table below describes the metadata that is available.

| Property                 | Type                                    | Description                                                                                                                                                                                                                                                                                                          |
|--------------------------|-----------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Name                     | string                                  | The name of the Property. This is the string name used to access the Property value in the [Element Data](../conceptual-overview.md#element-data)                                                                                                                                                                    |
| Element                  | IFlowElement                            | The Flow Element that will populate the value for this Property.                                                                                                                                                                                                                                                 |
| Category                 | string                                  | A string name of the category that this Property belongs to. This is used to help organize Properties for elements that populate large numbers of them.                                                                                                                                                              |
| Type                     | Type                                    | The type of the value returned by the Property                                                                                                                                                                                                                                                                       |
| Available                | bool                                    | Flag used to store whether this Property is currently available to the caller or not. If not, then the Property value will not be present in Element Data                                                                                                                                                        |
| Delay Execution          | bool                                    | Flag used to control execution of [JavaScript](#the-javascript-type) Properties. See [web integration](web-integration.md) for more detail.                                                                                                                                                                          |
| Evidence Properties      | List\<string\>                          | A list of the string names of any [JavaScript](#the-javascript-type) Properties that can be executed to help determine the value of this Property. See [web integration](web-integration.md) for more detail.                                                                                                        |
| Item Properties          | List\<IPropertyMetaData\>               | Some Property values will be a collection of complex objects. In that scenario, this contains the metadata for the Properties on that complex object. Currently, this is only used by the [Hardware profile lookup Engine](../../device-detection-specification/pipeline-elements/hardware-profile-lookup-cloud.md) |
| Item Property Dictionary | Dictionary\<string, IPropertyMetaData\> | The same data returned by 'Item Properties', but keyed on Property name.                                                                                                                                                                                                                                             |

### Aspect Property metadata

[Aspect Engines](../conceptual-overview.md#aspect-engine) are REQUIRED to populate
some additional metadata values beyond those described for Flow Elements.

The table below outlines the additional metadata that is available.

| Property                 | Type           | Description                                                                                                                                                                         |
|--------------------------|----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Description              | string         | A description of the Property                                                                                                                                                       |
| Data tiers where present | List\<string\> | A list of the string names of the data tiers/files that can be used to populate the value for this Property. This is used by the [missing Properties](#missing-properties) feature. |

## Missing Properties

This feature is specific to Properties populated by Engines (rather than all
Flow Elements).

When the user attempts to access a Property that is defined for an Engine, but
does not exist in the result set for some reason, the system MUST throw an
error/exception with a message explaining why the Property is not available.

This could be any of the following reasons, named in the second line of each
row as the reference implementation names them.

| **Reason**                                                                         | **Message**                                                                                                                                                                                                                                                                | **Parameters**                                                                                                                                                                                              |
|------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Not available in the current data file<br/>`DataFileUpgradeRequired`               | Property '{0}' not found in data for element '{1}'. This is because your license or data file does not include this property. It is available with the {2} license/data for the {3}. To upgrade, see https://51degrees.com/pricing.                                        | 0. Property name<br/>1. Data Key of the Engine<br/>2. data tiers where the Property is present, from its metadata, or `Unknown` when the metadata does not list the Property<br/>3. type name of the Engine |
| Property excluded in configuration<br/>`PropertyExcludedFromEngineConfiguration`   | Property '{0}' not found in data for element '{1}'. This is because the property has been excluded when configuring the engine.                                                                                                                                            | 0. Property name<br/>1. Data Key of the Engine                                                                                                                                                              |
| Product not included with Resource Key<br/>`ProductNotAccessibleWithResourceKey`   | Property '{0}' not found in data for element '{1}'. This is because your resource key does not include access to any properties under '{1}'. Check or create a resource key with the properties you need in the configurator at https://configure.51degrees.com.           | 0. Property name<br/>1. Data Key of the Engine                                                                                                                                                              |
| Property not included with Resource Key<br/>`PropertyNotAccessibleWithResourceKey` | Property '{0}' not found in data for element '{1}'. This is because your resource key does not include access to this property. The properties included for your key under '{1}' are {2}. Check or change your key in the configurator at https://configure.51degrees.com. | 0. Property name<br/>1. Data Key of the Engine<br/>2. names of the Properties in the Engine's metadata                                                                                                      |
| Request to the remote server failed<br/>`CloudRequestFailed`                       | Property '{0}' not found in data for element '{1}'. This is because an upstream cloud request failed, so no data was available to populate the property.                                                                                                                   | 0. Property name<br/>1. Data Key of the first Engine, or `Unknown` when there is none                                                                                                                       |
| Unknown<br/>`Unknown`                                                              | Property '{0}' not found in data for element '{1}'. The reason for this is unknown. Please check that the aspect and property name are correct.                                                                                                                            | 0. Property name<br/>1. Data Key of the Engine                                                                                                                                                              |

Lists in a message are joined with a comma and no space, for example
`Premium,Enterprise`. The messages are those the reference implementation
gives. An implementation SHOULD give the same text, and MAY add to each link
the campaign parameters its own repository requires.

### Deciding the reason

An implementation SHOULD decide the reason as the reference implementation
does, in this order, using the first that applies.

1. When a Cloud Aspect Engine populated the Element Data, and the Cloud
   Request Engine has no response for this Flow Data because its request to
   the remote server failed, the reason is `CloudRequestFailed`. The message
   names the Data Key of the first Engine that populates the Element Data, or
   `Unknown` when there is none.
2. Otherwise each Engine that populates the Element Data is checked in turn,
   as step 3 describes. The first Engine to give a reason other than
   `Unknown` decides the reason and the message. When every Engine gives
   `Unknown`, the message names the last Engine checked.
3. For one Engine, the reason is the first of these that applies.
   1. The Engine has loaded its Property metadata, and the metadata lists a
      Property whose name is exactly the requested name, including case. An
      On-premise Engine whose data file tier is not among the Property's data
      tiers where present gives `DataFileUpgradeRequired`. Otherwise a
      Property that is not available gives
      `PropertyExcludedFromEngineConfiguration`.
   2. The Engine is a Cloud Engine that has loaded its Property metadata. It
      gives `ProductNotAccessibleWithResourceKey` when the metadata lists no
      Properties, and `PropertyNotAccessibleWithResourceKey` otherwise.
   3. The Engine's Element Data has a typed accessor for a Property of the
      requested name, compared ignoring case. It gives
      `DataFileUpgradeRequired`, with `Unknown` as the data tiers when the
      metadata does not list the Property.
   4. Otherwise the reason is `Unknown`.

The reference implementation is
[`MissingPropertyService`](https://github.com/51Degrees/51degrees-dotnet/blob/main/pipeline/Engines/Services/MissingPropertyService.cs)
and, for Cloud Engines,
[`MissingPropertyServiceCloud`](https://github.com/51Degrees/51degrees-dotnet/blob/main/pipeline/CloudRequestEngine/Services/MissingPropertyServiceCloud.cs),
with the text in [`Messages.resx`](https://github.com/51Degrees/51degrees-dotnet/blob/main/pipeline/Engines/Messages.resx).
