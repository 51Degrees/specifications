# UA-CH high entropy decoder

## Overview

This Element is part of the system that allows Device Detection to use
values from the User-Agent Client Hints (UA-CH) JavaScript API rather
that the UA-CH HTTP headers.

51Degrees has [blogs](https://51degrees.com/blog/implementing-user-agent-client-hints)
and [documentation](https://51degrees.com/documentation/_device_detection__features__u_a_c_h__javascript.html)
with more information on this.

The Device Detection Engines will only work if Evidence values are provided
in the same format as UA-CH HTTP headers. The Evidence values that are
collected from the UA-CH JavaScript API are in a different format and are
encoded using base-64 encoding. This element decodes and transforms this
Evidence into values that match the HTTP header format so that it can
be used by the Device Detection Engines.

## Accepted Evidence

- cookie.51d_gethighentropyvalues
- query.51d_gethighentropyvalues

## Element Data

This Element is only implemented for
[.NET](https://github.com/51Degrees/device-detection-dotnet/blob/main/FiftyOne.DeviceDetection/Uach/UachJsConversionElement.cs)
at time of writing.
The reference implementation writes directly to Evidence, which will not
be possible if Evidence is immutable.
Instead, the Element can output its values using Element Data as described
in the table below.
The Device Detection Engines MUST be capable of using these values if
available and falling back to Evidence values if they are not.
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

## Configuration options

This Element has no configuration options
