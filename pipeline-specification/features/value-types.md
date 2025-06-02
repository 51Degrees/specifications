
## Value Types

Values within a data file can be stored and returned in different formats.

Sometimes values can just be stored as strings, and are parsed before being returned as the intended type (e.g. integer). This enables having mixed types, like `"Unknown"` in an int property.

Other times, values can be stored in space optimized formats so that the value being represented takes up less space in the data file, and is converted when being returned.



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

### WKT

A new property type for the IP Intelligence Engine is the `WktString` interface
This uses a WKT/WKB shape (see <https://en.wikipedia.org/wiki/Well-known_text_representation_of_geometry>).

This comes from the data file in WKBR (R = reduced) format. And is interpreted
to a more useable form, as the interface `WktString` which extends string, and
contains a WKT format string.

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
an [Aspect Property value](../pipeline-specification/features/properties.md#null-values)
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
