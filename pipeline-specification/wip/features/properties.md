- Property metadata definition
- Nested properties
- Lazy loading
# Overview

This document contains details on the features associated with the properties that 
are populated by flow elements.

# Value types

A property may return values of any type. However, there are certain types that are 
specifically expected and supported throughout the API.

The primary limitation is that it must be possible for these types to be represented 
in json data.

As such, the core types are:

- string
- boolean
- numeric (integer or floating point)
- array of strings

In addition, there are a couple of types that are supported through additions in 
json encode/decode logic:

- javascript - See [the javascript type](#the-javascript-type) below
- array of key-value-pair collections - Used in scenarios where we want to return 
  multiple aspect data instances. (For example, TAC lookup)

## The javascript type

The javascript type is a custom type that simply represents a string.
It is used to identify values that contain JavaScript snippets that are intended 
to be executed on the client device.

# Null values

Property values must be capable of having 'no value'

Where 'no value' is used, attempting to access the value should throw an 
error/exception with a customizable message explaining why the value is not set. 

# Property metadata

# Missing properties

This feature is specific to properties populated by engines (rather than all flow 
elements).

When the user attempts to access a property that is defined for an engine, but 
does not exist in the result set for some reason, the system must throw an 
error/exception with a message explaining why the property is not available.

This may be any of the following reasons:

|Reason|Notes|Message|Parameters
|---|---|---|---|
| Not available in the current data file | On-premise only | Property '{0}' not found in data for element '{1}'. This is because your license and/or data file does not include this property. The property is available with the {2} license/data. | 0. property name<br/>1. element name<br/>2. comma-separated list of data file/license types |
| Property excluded in configuration | On-premise only | Property '{0}' not found in data for element '{1}'. This is because the property has been excluded when configuring the engine. | 0. property name<br/>1. element name |
| Product not included with resource key | Cloud only | Property '{0}' not found in data for element '{1}'. This is because your resource key does not include access to any properties under '{2}'. For more details on resource keys, see our explainer: https://51degrees.com/documentation/_info__resource_keys.html |  0. property name<br/>1. element name<br/>2. product name |
| Property not included with resource key | Cloud only | Property '{0}' not found in data for element '{1}'. This is because your resource key does not include access to this property. Properties that are included for this key under '{2}' are {3}. For more details on resource keys, see our explainer: https://51degrees.com/documentation/_info__resource_keys.html | 0. property name<br/>1. element name<br/>2. product name<br/>3. comma-separated list of property names |


# Lazy loading

This feature is specific to properties populated by engines (rather than all flow 
elements).