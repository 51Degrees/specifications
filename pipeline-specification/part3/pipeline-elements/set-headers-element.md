# Set Headers Element

## Overview

The Set Headers Element constructs a list of all the HTTP response
header values that other Elements in the Pipeline want to be set.
Usually, this is done in order to request more Evidence from the
client (For example [User-Agent Client Hints](http://51degrees.com/documentation/_device_detection__features__u_a_c_h__headers.html)).

This relies on a Property naming convention whereby any Property
values containing data that should be sent in a response header
are named according to the following format:

`SetHeader[Identifier][HeaderName]`

- The `SetHeader` prefix indicates that this Property is intended
  for setting HTTP response headers.
- `[Identifier]` is some string that relates to what this value is for.
  It MUST NOT have upper-case characters after the first character.
- `[HeaderName]` is the name of the HTTP header to set in the response.

## Accepted Evidence

This element uses no Evidence, it works on Property values in Element Data
in the Flow Data.

## Start-up activity

For performance reasons, it is usually best to construct a list of
Properties with the `SetHeader` prefix on start-up, rather than doing
so for each request.

## Element Data

| **Name**                   | **Type**                              | **Description**                                                                                                                           |
|----------------------------|---------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| response-header-dictionary | `IReadOnlyDictionary<string, string>` | A collection of key value pairs where the key is the HTTP response header name and the value is the value to set that response header to. |

## Process

- Get all Properties in Flow Data with `SetHeader` at the start of the name.
- For each Property
  - If Property value is set and is not `Unknown`
    - Extract the header name from the Property name using the convention
      outlined [above](#overview). Use this as the key to the output key value
      pair collection.
    - Split the Property value using `,` and add each individual segment to
      the output collection if it has not yet been added for that key.

## Configuration options

None
