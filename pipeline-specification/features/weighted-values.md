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
    float weighting = weightedValue.Weighting;
    string value = weightedValue.Value;
}
```

## Serializing 

When serializing weighted values, they are represented like:
```js
{
    "WeightedPropertyName": [
        { "Weighting": 0.9, "Value": "value 1" },
        { "Weighting": 0.1, "Value": "value 2" }
    ]
}
```