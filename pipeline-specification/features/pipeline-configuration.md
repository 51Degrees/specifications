# Pipeline configuration

## Summary

Many Flow Elements have numerous configuration options. It is also possible
to configure Pipelines in many ways.

In order to make configuration as simple as possible for users, it is REQUIRED
that elements and Pipelines can be configured and created using either a pure
code approach, or a configuration file.

For consistency, configuration files need to be as similar as possible between
languages.

## Pipelines

- During construction, there MUST be the ability to add Elements/Engines
  to Pipelines. These will run in sequence in the order they are added.
- During construction, Pipelines MAY have the ability to add multiple
  elements/Engines that will run in parallel (where the language supports this -
  See [parallel processing](../advanced-features/parallel-processing.md) for a
  discussion of the complexities this adds).

For example:

```c#
var pipeline = pipelineBuilder.Add(s1).AddParallel([p1,p2]).Add(s2).Build()
```

This would create a Pipeline that performs the following processing:

- Execute s1.
- When s1 is finished, p1 and p2 are started in parallel.
- When both p1 and p2 are complete, s2 is started.

## Flow Elements

- Elements/Engines MAY have configuration options to customize the
  processing that they perform.
- The configuration file definition MUST be as similar as possible to configuration
  files for other languages.
- All configuration options SHOULD use the same names in the configuration file
  as would be used when configuring in code.
- Where feasible, all configuration options available in code SHOULD be configurable
  via a file. The exceptions are usually options that take complex objects, which
  cannot easily be represented in a text-based file format.

## Deserialization

Configuration files MUST be human-readable and consistent between languages.
Consequently, we don't want any type information or metadata appearing in
these files. This implies some limitations on the types that can be deserialized
from values in the files, as additional logic might need to be added for each type.

To date, the following types are supported in configuration files for all languages:

- string
- boolean
- numeric (integer or floating point)
- list of strings (represented as a comma-separated string)
- enumeration value (represented as the string name of the value)

## Sample configuration files

These sample files show all configuration options across many 51Degrees Elements
and include default values and links to descriptions of the options.

[.NET](https://github.com/51Degrees/device-detection-dotnet/blob/master/Examples/sample-configuration.json)
[Java](https://github.com/51Degrees/device-detection-java/blob/master/device-detection.examples/console/src/main/resources/gettingStartedOnPrem.xml)
