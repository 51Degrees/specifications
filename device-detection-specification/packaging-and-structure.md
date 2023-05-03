# Packaging

The structure of packages and dependencies is not rigidly enforced. The implementer
will need to choose the appropriate structure based on the norms of the language they are
working with and the architectural design they have produced.

This document contains recommendations to help inform these decisions.

1. Consider following the [recommendations](../pipeline-specification/packaging-and-structure.md)
   set out for Pipeline API packages in general.
2. Device Detection packages SHOULD all share a common prefix. For example
   'FiftyOne.DeviceDetection'
3. As on-premise Device Detection requires a native DLL, it is usually helpful to
   split this out into a package that is separate from the more lightweight
   Cloud Engine.
4. Examples and tests SHOULD NOT be included in any published packages.

For examples, see 51Degrees Device Detection packages on
[NuGet](https://www.nuget.org/packages?q=FiftyOne.DeviceDetection),
[Maven](https://central.sonatype.com/search?namespace=com.51degrees&q=device-detection)
or [NPM](https://www.npmjs.com/search?q=fiftyone.devicedetection)

