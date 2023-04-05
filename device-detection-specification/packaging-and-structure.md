# Packaging

The structure of packages and dependencies is not rigidly enforced. The implementer should choose the appropriate structure based on the norms of the language they are working with and the architectural design they have produced.

This document contains recommendations to help inform these decisions.

1. Consider following the [recommendations](../pipeline-specification/packaging-and-structure.md) set out for pipeline API packages in general.
2. Device detection packages should all share a common prefix. For example 'FiftyOne.DeviceDetection'
3. As on-premise device detection requires a native dll, it is usually helpful to split this out into a package that is separate from the more lightweight cloud engine.
4. Examples and tests should not be included in any published packages.

For examples, see 51Degrees device detection packages on [NuGet](https://www.nuget.org/packages?q=FiftyOne.DeviceDetection), [Maven](https://central.sonatype.com/search?namespace=com.51degrees&q=device-detection) or [NPM](https://www.npmjs.com/search?q=fiftyone.devicedetection)

