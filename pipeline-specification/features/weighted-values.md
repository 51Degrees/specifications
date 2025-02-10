# Weighted Values

## Overview

Some Engines MAY return values which are weighted. This gives the user the
full picture of which are most likely when a single value is not certain.

For example, when returning a location based on IP address evidence, there
can be multiple locations with different probabilities.

## Accessing

Given an example `IElementData` implementation `IExampleData` which contains a property
`ExampleProperty`

1. Get the value in the standard way described in [access-to-results](./access-to-results.md):

```c#
IExampleData data;
IReadOnlyList<IWeightedValue<string>> values = data.ExampleProperty;
```

2. Fetch the most likely value. The values are ordered from highest to lowest probability:

```c#
IReadOnlyList<IWeightedValue<string>> values;
string mostLikelyValue = values[0].Value;
```

3. Get the probabilities of each value:

```c#
IReadOnlyList<IWeightedValue<string>> values;
foreach (var weightedValue in values)
{
    float weighting = weightedValue.Weighting();
    string value = weightedValue.Value;
}
```

## Serializing

When serializing weighted values, they are represented like:

```js
{
    "WeightedPropertyName": [
        { "RawWeighting": 32768, "Value": "value 1" },
        { "RawWeighting": 32767, "Value": "value 2" }
    ]
}
```

The raw weighting is stored as a 16-bit unsigned integer (aka [ushort](https://learn.microsoft.com/en-us/dotnet/api/system.uint16.maxvalue?view=netstandard-2.0)).

The sum of raw weightings for all values within any specific property should always add up to [UInt16.MaxValue](https://learn.microsoft.com/en-us/dotnet/api/system.uint16.maxvalue?view=netstandard-2.0) (that represents a `1.0` "likelyhood").

See [IWeightedValue.cs](https://github.com/51Degrees/pipeline-dotnet/blob/version/4.5/FiftyOne.Pipeline.Core/Data/IWeightedValue.cs) for more details.
