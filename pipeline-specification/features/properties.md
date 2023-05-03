# Properties

## Overview

This document contains details on the features associated with the Properties that
are populated by Flow Elements.

In this case, a 'Property' refers to a specific, named data field that can be
set to different values.

The Property value will be determined during the 'process' step that is performed
by each Flow Element. This value will be stored within the Element Data,
which is in turn stored within Flow Data.

Each Flow Element may populate values for zero or more Properties.

## Value types

A Property may return values of any type. However, there are certain types that are
specifically expected and supported throughout the API.

The primary limitation is that these type values will need to be represented
in JSON data.

As such, the core types are:

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

The javascript type is a custom type that simply represents a string.
It is used to identify values that contain JavaScript snippets that are intended
to be executed on the client device.

See [web integration](web-integration.md) for more detail.

## Null values

Property values populated by Engines (as opposed to all Flow Elements)
MUST be capable of having 'no value'.

Where 'no value' is used, attempting to access the value should throw an
error/exception with a customizable message explaining why the value is not set.

This is similar to the [missing Property](#missing-properties) feature.
In that case, the Property is not present in the result dataset at all. In this
case, the Property is present in the result. However, the Flow Element has
chosen not to set its value for some reason.

## Property metadata

All [Flow Elements](../conceptual-overview.md#flow-element) MUST expose metadata
describing details of the Properties that they can populate.

In addition, it MUST be possible to get Property metadata at the Pipeline
level for all Properties that can be populated by all Flow Elements in the
Pipeline.

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

[Aspect Engines](../conceptual-overview.md#aspect-engine) are required to populate
some additional metadata values beyond those required for Flow Elements.

The table below describes the additional metadata that is available.

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

This may be any of the following reasons:

| Reason                                  | Notes           | Message                                                                                                                                                                                                                                                                                                            | Parameters                                                                                             |
|-----------------------------------------|-----------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| Not available in the current data file  | On-premise only | Property '{0}' not found in data for element '{1}'. This is because your license and/or data file does not include this Property. The Property is available with the {2} license/data.                                                                                                                             | 0. Property name<br/>1. element name<br/>2. comma-separated list of data file/license types            |
| Property excluded in configuration      | On-premise only | Property '{0}' not found in data for element '{1}'. This is because the Property has been excluded when configuring the Engine.                                                                                                                                                                                    | 0. Property name<br/>1. element name                                                                   |
| Product not included with Resource Key  | Cloud only      | Property '{0}' not found in data for element '{1}'. This is because your Resource Key does not include access to any Properties under '{2}'. For more details on Resource Keys, see our explainer: https://51degrees.com/documentation/_info__resource_keys.html                                                   | 0. Property name<br/>1. element name<br/>2. product name                                               |
| Property not included with Resource Key | Cloud only      | Property '{0}' not found in data for element '{1}'. This is because your Resource Key does not include access to this Property. Properties that are included for this key under '{2}' are {3}. For more details on Resource Keys, see our explainer: https://51degrees.com/documentation/_info__resource_keys.html | 0. Property name<br/>1. element name<br/>2. product name<br/>3. comma-separated list of Property names |

