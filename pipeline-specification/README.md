# Introduction

This folder structure contains a language agnostic specification for the 51Degrees 
v4 Pipeline API. 
We aim to avoid specific details of classes, interfaces, methods or the like. The 
focus is on the behaviour rather than the method by which that behaviour is achieved. 
This allows implementers to choose an architectural approach that is most appropriate 
for the target language.

# Structure

This specification is broken down into separate markdown files in multiple directories.
If you're not sure where to start, read through the primer section below before 
exploring further.

# Description

51Degrees `Pipeline` provides a framework within which input data is transformed
and enriched to create output data to be consumed by some application.

Note that more concrete details on the terms defined here can be found in the 
[conceptual overview](conceptual-overview.md).

## Flow
Processing is performed by a sequence of steps which consume the 
output of earlier steps and produce output of their own. The sequence of 
steps is called *flow*: the steps are called `Flow Elements` and the data 
transferred between them is called `Flow Data`.

Flow is unidirectional and does not provide for branching and looping. Parallel 
operation of steps or a sequence of steps is possible.

Flow Elements consume `Evidence` and may produce name-value pairs of `Properties`
which are stored in the Flow Data. Hence, Flow Elements may consume properties
generated earlier in the flow. Flow Elements "advertise" the evidence
that they consume, the properties that they produce, a key for accessing
those properties from the Flow Data and various information about the data types
within which those properties are found.

## Flow Data Lifecycle

Creation of Flow Data is carried out by an application requesting an instance 
from a pipeline. With a number of important exceptions, the creating 
application must destroy the Flow Data once it has completed its processing.

The application carries out the initial population of evidence
and then requests that the pipeline `process` it - i.e. present the Flow Data
to the various Flow Elements that comprise it, in sequence. Processing is 
synchronous by default and the application may consume properties produced
during processing once it is complete. A Flow Data may only be processed 
once and belongs to exactly one Pipeline.

Flow Data may also be used to report errors that occur during processing.

## Engine

An `Engine` is a specialization of a Flow Element, which builds on the basic 
functionality provided by Flow Element to provide higher level functions
in a consistent way. 

An `Aspect Engine` concerns itself with processing evidence to populate
properties related to some *aspect* related to the received evidence. For example,
*Device Detection* concerns itself with determining the aspects of *hardware*,
*browser* and *operating system* determined by analysis of evidence received 
in an HTTP request, such as HTTP Headers and Cookies.

Engines are classed as `Cloud` engines, which carry out their processing 
by delegation to a remote server, and `On-Premise` engines, which typically
carry out processing by reference to one or more data files, stored locally. 
Facilities are available for update and installation of such data files. 

Where both Cloud and On-Premise variants of an Engine are available, they should
arrange that the properties and values produced are compatible with each other
so that the engines may be substituted in the pipeline without alteration to
the consuming application.

Engines may be configured with caches and offer the ability to carry out lazy 
evaluation of property values. Engine instances may be shared between Pipelines.

