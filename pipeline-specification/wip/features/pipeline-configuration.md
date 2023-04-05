# Summary

Many Flow Elements have numerous configuration options, it is also possible
to configure Pipelines in many different ways.

In order to make configuration as simple as possible for users, it is required 
that elements and pipelines can be configured and created using either a pure 
code approach, or a configuration file.

# Pipelines

- Pipelines must have the ability to add elements/engines. These will run in 
  sequence in the order they are added.
- Pipelines must have the ability to add multiple elements/engines that will run 
  in parallel (where the language supports this).

# Flow Elements 

- Elements/Engines may or may not have configuration options to customize the 
  processing that they perform.
- The configuration file definition must be as similar as possible to configuration 
  files for other languages.
- All configuration options should use the same names in the configuration file 
  as would be used when configuring in code.
- Where feasible, all configuration options available in code should be configurable 
  via a file. The exceptions are usually options that take complex objects, which 
  cannot easily be defined in a text-based file.

# Sample configuration files

TODO - these sample files are not yet publicly available, they are in 
internal `develop` branches.

[.NET](https://github.com/51Degrees/device-detection-dotnet/blob/master/Examples/sample-configuration.json)
[Java](https://github.com/51Degrees/device-detection-java/blob/master/device-detection.examples/console/src/main/resources/gettingStartedOnPrem.xml)
