# Required Examples

## General

It is RECOMMENDED that the following features are demonstrated in examples:

- Pipeline build from options
- Use of fluent builder
- Creation of a Flow Element, and On-Premise and Cloud Engines
- Determination of various metadata associated with a Flow Element, such as
  Evidence accepted and Flow Data key

See [Device Detection required examples](../device-detection-specification/part3/required-examples.md) for more detailed recommendations

## Suggested Examples

The examples in the reference implementations demonstrate determination of a
star sign from a birth date, and do so in a number of different ways:

- Using client side Evidence, the example prompts the user for a date using a
  JavaScript dialog box, in Java this is implemented using Spring MVC

- Using a Cloud Request Engine - this needs a cloud endpoint which can be
  built and run as a local server

- Using a Flow Element that returns star sign given a date of birth as
  Evidence.

- Using an On-premise Engine that demonstrates getting a star sign from a date
  similarly to the Flow Element but using a disk data source

Reference implementations also contain the following examples:

- Create a Pipeline that shares usage with 51degrees configured from options file,
  although this example is runnable you can't actually "see" that it is working.
