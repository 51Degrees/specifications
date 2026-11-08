# UA-CH high entropy decoder

## Overview

This Element is part of the system that allows Device Detection to use
values from the User-Agent Client Hints (UA-CH) JavaScript API rather
that the UA-CH HTTP headers.

51Degrees has [blogs](https://51degrees.com/blog/implementing-user-agent-client-hints?utm_source=github&utm_medium=docs&utm_campaign=specifications&utm_content=device-detection-specification-pipeline-elements-uach-high-entropy-decoder.md&utm_term=overview)
and [documentation](https://51degrees.com/documentation/_device_detection__features__u_a_c_h__javascript.html?utm_source=github&utm_medium=docs&utm_campaign=specifications&utm_content=device-detection-specification-pipeline-elements-uach-high-entropy-decoder.md&utm_term=overview)
with more information on this.

The Device Detection Engines will only work if Evidence values are provided
in the same format as UA-CH HTTP headers. The Evidence values that are
collected from the UA-CH JavaScript API are in a different format and are
encoded using base-64 encoding. This element decodes and transforms this
Evidence into values that match the HTTP header format so that it can
be used by the Device Detection Engines.

An on-premise Device Detection Engine whose native code does this
conversion itself does not need this Element. See
[Engines that convert the values](#engines-that-convert-the-values).

## Accepted Evidence

- cookie.51d_gethighentropyvalues
- query.51d_gethighentropyvalues

## Element Data

The .NET and Java packages have no implementation of this Element, and the
native code their on-premise Engines use converts the values itself.
Writing the values directly to Evidence will not be possible if Evidence is
immutable.
Instead, the Element can output its values using Element Data as described
in the table below.
A Device Detection Engine MUST be capable of using these values if
available and falling back to Evidence values if they are not, unless it is
an on-premise Engine whose native code converts the values itself.
See [adding Evidence values](../../pipeline-specification/features/evidence.md#adding-evidence-values)
for more details.

| **Name**                    | **Type** | **Description**                                                                                                                                                                                                                                                            |
|-----------------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| sec-ch-ua                   | string   | The value of the `sec-ch-ua` HTTP header determined from the encoded Evidence                                                                                                                                                                                              |
| sec-ch-ua-full-version-list | string   | The value of the `sec-ch-ua-full-version-list` HTTP header determined from the encoded Evidence                                                                                                                                                                            |
| sec-ch-ua-model             | string   | The value of the `sec-ch-ua-model` HTTP header determined from the encoded Evidence                                                                                                                                                                                        |
| sec-ch-ua-mobile            | string   | The value of the `sec-ch-ua-mobile` HTTP header determined from the encoded Evidence. Note that this value is a boolean in the UA-CH specification. However, as an HTTP header, it is a string (usually with the value `?0` or `?1`) and must be treated as a string here. |
| sec-ch-ua-platform          | string   | The value of the `sec-ch-ua-platform` HTTP header determined from the encoded Evidence                                                                                                                                                                                     |
| sec-ch-ua-platform-version  | string   | The value of the `sec-ch-ua-platform-version` HTTP header determined from the encoded Evidence                                                                                                                                                                             |

It is worth highlighting that there are other client hints, such as
`sec-ch-ua-bitness` and `sec-ch-ua-architecture`. However, these are
not needed for device detection, so are not featured here.

## Process

- Get the encoded value from Evidence for the [relevant keys](#accepted-evidence)
  - Use the value with the `query` prefix if both are available
- Decode the value from base 64
- Convert the JSON representation into individual HTTP header values.
  - See [here](https://github.com/51Degrees/sua-uach-conversion/blob/main/src/convertSUAtoUACH.js)
    for an example of this using JavaScript.

## Engines that convert the values

The native code of the on-premise Device Detection Engine in
[51degrees-cxx](https://github.com/51Degrees/51degrees-cxx) converts the
`query.51d_gethighentropyvalues` and `cookie.51d_gethighentropyvalues`
Evidence itself, before it matches, into header values that include those in
the [Element Data](#element-data) table
([hash.c lines 3540 to 3556](https://github.com/51Degrees/51degrees-cxx/blob/e866f6d3cea936587790f87967eff7863778b30e/src/dd/hash/hash.c#L3540-L3556)
and the list of headers in
[transform.h lines 49 to 56](https://github.com/51Degrees/51degrees-cxx/blob/e866f6d3cea936587790f87967eff7863778b30e/src/dd/transform.h#L49-L56)).
It does so while special evidence processing is enabled, which is the default
([config-dd.h line 90](https://github.com/51Degrees/51degrees-cxx/blob/e866f6d3cea936587790f87967eff7863778b30e/src/dd/config-dd.h#L90)).

An on-premise Device Detection Engine whose native code converts the values
itself, and which accepts both keys and passes their values to that native
code unchanged, need not read this Element's data. A Pipeline built around
such an Engine does not need this Element.

The native code converts only one such value, being the first
`51d_gethighentropyvalues` or `51d_structureduseragent` value, from the query
or a cookie, that gives at least one header
([hash.c lines 3587 to 3596](https://github.com/51Degrees/51degrees-cxx/blob/e866f6d3cea936587790f87967eff7863778b30e/src/dd/hash/hash.c#L3587-L3596)).
So where the Evidence also holds a `51d_structureduseragent` value that the
native code reads first, the high entropy values are not converted, and the
header values come from the structured User-Agent alone, which gives no
`sec-ch-ua` value
([transformc.c lines 1105 to 1107](https://github.com/51Degrees/51degrees-cxx/blob/e866f6d3cea936587790f87967eff7863778b30e/src/dd/transformc.c#L1105-L1107)).

## Configuration options

This Element has no configuration options
