
## Value Types

Values within a data file can be stored and returned in different formats.

Sometimes values can just be stored as strings, and are parsed before being returned as the intended type (e.g. integer). This enables having mixed types, like `"Unknown"` in an int property. See [values stored as strings](#values-stored-as-strings) for how a caller reads the stored value in that case.

Other times, values can be stored in space optimized formats so that the value being represented takes up less space in the data file, and is converted when being returned.



### Values stored as strings

A parsed value cannot always represent what the data holds. A stored string
that is not one of the declared type's values still has to be returned as
that type, so the accessor answers with something the data never said.

`"Unknown"` in a Boolean Property is the case that matters. A device
detection data file holds `"Unknown"` for the Properties the 51Degrees
JavaScript populates, meaning the JavaScript has not run, and the Boolean
accessor answers `false`. That `false` is indistinguishable from a `false`
the data really holds, so a caller cannot tell a measurement that was taken
from one that was never taken, and anything reading the Property draws a
conclusion the data does not support.

Where a Flow Element holds a Boolean or numeric Property's values as strings,
the typed accessor reads the stored string as the 51Degrees C library does. A
Boolean is true only for the text `True`, exactly as written, and false for
any other text. An integer is the decimal number at the start of the text,
after any white space and sign, as C's `atoi` reads it, and 0 when the text
does not start with one. A floating point number is what C's `strtod` reads
from the start of the text, and 0 when the text does not start with one. So
`"Unknown"` and `"N/A"` give `false` or 0. Where the Profile holds more than
one value for such a Property, the Property has no value.

Where a Flow Element holds values as strings, it MAY expose them. Where it
does:

- It MUST expose them through a capability a caller can test for at run
  time, such as an interface, rather than by changing what the typed
  accessor returns.
- The stored value MUST be returned as an Aspect Property Value of string,
  so that a Property which is absent, which has no value, or which the
  request is not entitled to is reported in exactly the way it is through
  every other accessor. See [null
  values](properties.md#null-values) and [missing
  Properties](properties.md#missing-properties).
- Offering the stored value MUST NOT change what any existing accessor
  returns for the same Property on the same request.
- It MUST return the value as it was stored, and MUST NOT compose a string
  from a parsed value. A caller asking for the stored value is asking what
  the data said, so a string built from the parsed type would answer the
  question the caller was trying to avoid.

Where a Flow Element does not hold values as strings, or holds them but
chooses not to expose them, it MUST NOT be required to offer this. A caller
MUST therefore test for the capability and MUST behave correctly where it
is absent, which for most callers means using the typed accessor as before.

A Property whose declared type is string is unaffected, since the stored
value and the parsed value are the same.

### Azimuth

Compressed form of a floating point longitude value.

Instead of storing a longitude value as a `double`, or `float`, an `int16` is used to represent the same value.

The stored value is converted back to the floating point value by dividing by the maximum value of `int16`, and multiplying by 180.

For example:

```{c}
int16_t storedValue;
double actualValue = 180.0 * ((double)storedValue / (double)int16_max);
// or
double actualValue = 180.0 * ((double)storedValue / 32767.0);
```

### Declination

Compressed form of a floating point latitude value.

Instead of storing a latitude value as a `double`, or `float`, an `int16` is used to represent the same value.

The stored value is converted back to the floating point value by dividing by the maximum value of `int16`, and multiplying by 90.

For example:

```{c}
int16_t storedValue;
double actualValue = 90.0 * ((double)storedValue / (double)int16_max);
// or
double actualValue = 90.0 * ((double)storedValue / 32767.0);
```

### Rounding of Azimuth and Declination values

A value converted from Azimuth or Declination MUST be given to the caller
rounded to 3 decimal places, whether it is given as a number, as a string or
as a point in a [WKT](#wkt) shape. For example, a stored Declination of 6751
converts to 18.542741172521133 and is given as 18.543. Where the number is a
binary floating point type, it is the value of that type nearest to the
rounded decimal.

The locations these types hold are rough, and a step of 0.001 degrees of
latitude is about 111 metres. More decimal places would make each string, and
each WKT shape with its many points, longer without making the location any
more accurate.

A package MAY offer a setting that changes the number of decimal places,
provided the default is 3.

### WKT

A new property type for the IP Intelligence Engine is the `WktString` interface
This uses a WKT/WKB shape (see <https://en.wikipedia.org/wiki/Well-known_text_representation_of_geometry>).

This comes from the data file in WKBR (R = reduced) format. And is interpreted
to a more useable form, as the interface `WktString` which extends string, and
contains a WKT format string.

Where a WKT value is written to JSON, for example by the
[JSON Builder Element](../pipeline-elements/json-builder.md) or in a response
from the remote server, it MUST be written as an object with one member,
`value`, holding the WKT text, for example `{"value": "POINT(2 4)"}`. This is
the form the .NET and Java implementations write, and their
[IP Intelligence Cloud Engines](../../ip-intelligence-specification/pipeline-elements/ip-intelligence-cloud.md)
read. A reader MUST accept this form. A reader MAY also accept the WKT text
alone as a string.

Implementation adapts the [OGC 06-103r4](https://www.ogc.org/publications/standard/sfa/) standard, by changing the size of fields to reduce the size.

The modified structures are:

```{c}
struct WKBRPolygon {
    byte byteOrder;
    byte wkbType;
    uint16_t numRings;
    WKBRLinearRing rings[numRings]
}
```
```{c}
struct WKBRLinearRing {
    uint16_t numPoints;
    WKBRPoint points[numPoints];
};
```
```{c}
struct WKBRPoint {
    int16_t x;
    int16_t y;
};
```

The modifications from the WKB spec are:
- the size of the `num` fields are halved,
- `x` and `y` coordinates in the `WKBRPoint` are stored as short integers, using the `Azimuth` and `Declination` format to represent lat/lon values.

Importantly, it should be noted that the convention for lat/lon coordinates is `x=longitude` and `y=latitude` (not the other way around). This is in line with WKB spec.

## Property Details

Each Property SHOULD return
an [Aspect Property value](properties.md#null-values)
in order to support exposing the reason that a value is not set.

Additionally, values MUST be returned along with their weights when fetched
from the `IAspectData`. Meaning the introduction of the
`IWeightedValue<T>` type, with the following properties:

| Property | Type |
| -------- | ---- |
| Value | `T` |
| Weighting | `float` |

For example:

```{cs}
// All weighted values for a property
IAspectPropertyValue<IWeightedValue<int>> allValues = flowData
    .Get<IpIntelligenceData>()
    .MCC;
// Compared to finding the highest weighted value for
// a property
IAspectPropertyValue<int> firstValue = flowData
    .Get<IpIntelligenceData>()
    .MccProfiles[0]
    .MCC;
```
