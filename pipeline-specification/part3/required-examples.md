<span style="color:yellow">TODO - Define the requirements for user-runnable examples that are 
included with the pipeline API.
Also list the individual examples that are required.</span>

# Required Examples

## General

It is recommended that the following features are demonstrated in examples:

- Pipeline build from Options
- Use of fluent builder
- Creation of a Flow Element, and On-Premise and Cloud Engines
- Determination of various metadata associated with a flow element, such as 
  evidence accepted and evidence data key 

## Suggested Examples

The examples in the reference implementations demonstrate determination of a 
star sign from a birthdate, and do so in a number of different ways:

- Using client side evidence, the example prompts the user for a date using a 
  JavaScript dialog box, in Java this is implemented using Spring MVC

- Using a cloud request engine - this needs a cloud endpoint which may be 
  built and run as a local server

- Using a FLow Element that returns star sign given a date of birth as
evidence.

- Using an opn-premise Engine that demonstrates getting a star sign from a date
  similarly to the Flow Element but using a disk data source 

Reference implementations also contain the following examples:

- Create a pipeline that shares usage with 51degrees from options file, 
  although this example is runnable you can't actually "see" that it is working.



