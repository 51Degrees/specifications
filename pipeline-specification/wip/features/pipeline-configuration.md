It must be possible for elements and pipelines to be be configured and created using code.
It must also be possible to do this with a configuration file.

- Elements/Engines may have configuration options to customize the processing that they perform.
- Pipelines must have the ability to add elements/engines. These will run in sequence in the order they are added.
- Pipelines must have the ability to add multiple elements/engines that will run in parallel (where the language supports this).


- The configuration file definition must be as similar as possible to configuration files for other languages.
- All configuration options should use the same names in the configuration file as would be used when configuring in code.
- Where feasible, all configuration options available in code should be configurable via a file. The exceptions are usually options that take complex objects, which cannot easily be defined in a text file.

