# Set headers element

## Overview

The set headers element constructs a list of all the HTTP response 
header values that other elements in the pipeline would like to set.
Usually, this is done in order to request more evidence from the 
client (For example [User-Agent Client Hints](http://51degrees.com/documentation/4.4/_device_detection__features__u_a_c_h__headers.html)).

This relies on a property naming convention whereby any property 
values containing data that should be sent in a response header
are named according to the following format:

`SetHeader[Identifier][HeaderName]`

- The `SetHeader` prefix indicates that this property is intended
  to be used to set response headers.
- `[Identifier]` is some string that relates to what this value is for. 
  It MUST have no upper-case characters after the first character.
- `[HeaderName]` is the name of the HTTP header to set in the response.

## Accepted evidence

This element uses no evidence, it works the the property values that have 
been set by other elements.

## Startup activity

For performance reasons, it is usually best to construct a list of 
properties with the `SetHeader` prefix on startup, rather than doing
so for each request.

## Element data

| **Name**                   | **Type**                              | **Description**                                                                                                                           |
|----------------------------|---------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| response-header-dictionary | `IReadOnlyDictionary<string, string>` | A collection of key value pairs where the key is the HTTP response header name and the value is the value to set that response header to. |

## Process

- Get all properties in Flow Data with `SetHeader` at the start of the name.
- For each property
  - If property value is set and is not `Unknown`
    - Extract the header name from the property name using the convention 
      outlined [above](#overview). Use this as the key to the output key value
      pair collection.
    - Split the property value using `,` and add each individual segment to 
      the output collection if it has not yet been added for that key.

## Configuration options

None