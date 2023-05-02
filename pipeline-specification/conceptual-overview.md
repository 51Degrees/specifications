# Conceptual overview

## Core

The core package contains everything needed to construct a Pipeline and pass through
a Flow Data object.

### Flow Data

The Flow Data object is the fundamental unit of work within the Pipeline API.
It is primarily a container for various data sets, and is the mechanism by which
inputs are provided to the Pipeline and outputs are returned to the user.

The input data, or 'Evidence' is a set of key-value pairs. For more details,
see the [Evidence](features/evidence.md) section.

The output data consists of one Element Data instance for each Flow Element
in the Pipeline. These are accessed using the 'data key' string of the
Flow Element that created each entry.

Flow Data objects are created by a Pipeline and can only be used within the
Pipeline by which they were created. The Process method on Flow Data
initiates Pipeline processing.

A Flow Data belongs to exactly one Pipeline.
While a Pipeline may have many Flow Data instances.
The standard usage pattern is to create a singleton Pipeline instance that will
be used in environments such as web servers. As such, it is expected that many
Flow Data instances will be created and processed in parallel from a single
Pipeline.

A Pipeline does not maintain references to Flow Data instances that it
has created, but they maintain references to it.

See [thread safety](features/thread-safety.md) for details on concurrent access requirements.

Flow Data must support various different ways of accessing the data it contains.
See [access to results](features/access-to-results.md) for more information.

### Element Data

Element Data is a container, within the Flow Data, for Property values
relating to a particular Flow Element. These values are set by
Flow Elements during processing. Element Data is retrieved from
Flow Data using the 'data key' associated with the Flow Element.

See [access to results](features/access-to-results.md) for more  
information on how this data should be accessed.

See [resource cleanup](features/resource-cleanup.md) for details on ensuring
Element Data resources are cleaned up correctly.

### Flow Element

A Flow Element is a black box which takes a Flow Data and performs some
processing. This processing may read Evidence and/or Element Data instances
that have been added by previous elements. It may add new Evidence values and
may add an instance of its own Element Data, which may or may not have
Properties populated.

See [resource cleanup](features/resource-cleanup.md) for details on ensuring
Flow Element resources are cleaned up correctly.

### Flow Element builder

It is highly recommended that Flow Elements have some associated
builder/factory that is used to create Flow Element instances.

The exact specification of this component is less important than having a common
mechanism for construction of elements. This provides consistency for users and
will assist in the implementation of other parts of the specification.

In most languages, we have found the builder pattern to be the best approach.
However, in some languages this pattern is less common. For ease of use, we want
users to be familiar with whatever approach is used to create instances.

If the pattern to use is uncertain, we recommend looking at multiple high profile
and highly regarded libraries for the target language and mirroring the approach
used by them.

See [Pipeline configuration](features/pipeline-configuration.md) for more
information on configuring and creating elements.

Be aware that the way builders were implemented in the reference languages
has caused some issues that could be avoided by making different design
decisions in future implementations. These are discussed in more detail
in [reference implementation notes](reference-implementation-notes.md#builders)

### Pipeline

A Pipeline is a method of grouping multiple Flow Elements into a single
process. By default, elements are always executed sequentially in the order
that they are added. See [Pipeline builder](#pipeline-builder) for more details.

A Pipeline object is intended to be immutable. In other words, once created, it cannot be
changed by adding new elements, removing old ones, etc.

### Pipeline builder

As with [Flow Elements](#flow-element-builder), we have found that the builder
pattern is a good way to control the creation of Pipeline instances.

See [Pipeline configuration](features/pipeline-configuration.md) for more information
on configuring and creating instances.

## Engines

The Engines package adds features to Flow Elements that are common to
multiple different 51Degrees element implementations.

### Aspect Engine

See the [readme](README.md#engine) for a definition of 'Aspect'.

Aspect Engines (often shortened to just 'Engines') are a specific type
of Flow Element with additional features and Properties:

- [Results caching](features/caching.md)
- [Data file automatic updates](features/data-updates.md)
- [Lazy loading](features/properties.md#lazy-loading)
- [Missing Properties](features/properties.md#missing-properties)

### Aspect data

In the same way that Aspect Engines are specific types of Flow Element.
Aspect Data are specific types of Element Data.

See [Aspect Engines](#aspect-engine) for details of the features that
Aspect Engines / Aspect Data have on top of standard Flow Element /
Element Data.

## Cloud Engines

The premise of Cloud Engines is to offload processing that might otherwise
be performed by an on-premise Aspect Engine to a remote service.

### Cloud Request Engine

The Cloud Request Engine is a further specialization of Aspect Engine
with the task of making requests to a remote service.

In theory, this could be an internally hosted service. In practice, it is
usually the [51Degrees cloud service](https://cloud.51degrees.com/api-docs/index.html).

This Engine outputs a single Property, the value of which is the JSON data
that is returned by the remote service that it calls.

See [Cloud Request Engine](pipeline-elements/cloud-request-engine.md)
for the technical details.

### Cloud Aspect Engine

The Cloud Aspect Engine is also a specialization of Aspect Engine.
It takes the JSON result from the Cloud Request Engine and transforms
it into an Aspect Data instance that is interface compatible with
the data from the equivalent On-premise Engine.

See [Cloud Aspect Engine](pipeline-elements/cloud-aspect-engine.md)
for the technical details.
