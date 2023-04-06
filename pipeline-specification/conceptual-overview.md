
# Core 

The core package contains everything needed to construct a Pipeline and pass through 
a Flow Data object.

## Flow data

The **Flow Data** object is primarily a container for various data sets. It is the 
mechanism by which inputs are provided to the pipeline and outputs are returned to 
the user.

The input data, or 'evidence' is a set of key-value pairs. For more details, 
see the [evidence](features/evidence.md) section.

The output data consists of one **Element Data** instance for each **Flow Element** 
in the **Pipeline**. These are accessed using the 'data key' string of the
 **Flow Element** that created each entry.

**Flow Data** objects are created by the pipeline and can only be used within the 
pipeline by which they were created. The Process method on **Flow Data** 
initiates pipeline processing.

See [thread safety](features/thread-safety.md) for details on concurrent access requirements.

**Flow Data** must support various different ways of accessing the data it contains. 
See [access to results](features/access-to-results.md) for more information.

## Element data

**Element Data** is a container, within the **Flow Data**, for property values 
relating to a particular **Flow Element**. These values are set by 
**Flow Elements** during processing. **Element Data** is retrieved from 
**Flow Data** using the 'data key' associated with the **Flow Element**.

See [access to results](features/access-to-results.md) for more  
information on how this data should be accessed.

See [resource cleanup](features/resource-cleanup.md) for details on ensuring 
**Element Data** resources are cleaned up correctly.

## Flow element

A **Flow Element** is a black box which takes a **Flow Data** and performs some
processing. This processing may read evidence and/or **Element Data** instances
that have been added by previous elements. It may add new evidence values and
may add an instance of its own element data, which may or may not have 
properties populated.

A **Flow Element** can be added to multiple pipelines once it has been built.
This means that the processing performed by a flow element must be thread safe
and must either have no state that is dependent on a pipeline, or must maintain
this state internally for each pipeline it is added to.

See [resource cleanup](features/resource-cleanup.md) for details on ensuring 
**Flow Element** resources are cleaned up correctly.

## Flow element builder

It is highly recommended that **flow elements** have some associated
builder/factory that is used to create **flow element** instances.

The exact specification of this component is less important than having a common
mechanism for construction of elements. This provides consistency for users and
will assist in the implementation of other parts of the specification.

In most languages, we have found the builder pattern to be the best approach.
However, in some languages this pattern is less common. For ease of use, we want 
users to be familiar with whatever approach is used to create instances.

If the pattern to use is uncertain, we recommend looking at multiple high profile 
and highly regarded libraries for the target language and mirroring the approach 
used by them.

See [pipeline configuration](features/pipeline-configuration.md) for more 
information on configuring and creating elements.

Be aware that the way builders were implemented in the reference languages 
has caused some issues that could be avoided by making different design 
decisions in future implementations. These are discussed in more detail 
in [reference implementation notes](reference-implementation-notes.md#builders)

## Pipeline

A **Pipeline** is a method of grouping multiple **Flow Elements** into a single 
process. By default, elements are always executed sequentially in the order 
that they are added. See [pipeline builder](#pipeline-builder) for more details.

A **Pipeline** object is immutable. In other words, once created, it cannot be 
changed by adding new elements, removing old ones, etc.

## Pipeline builder

As with [Flow Elements](#flow-element-builder), we have found that the builder 
pattern is a good way to control the creation of **pipeline** instances.

See [pipeline configuration](features/pipeline-configuration.md) for more information
on configuring and creating instances.

# Engines

The engines package adds features to **Flow Elements** that are common to
multiple different 51Degrees element implementations.

## Aspect engine

**Aspect Engines** (often shortened to just '**Engines**') are a specific type 
of **Flow Element** with additional features and properties.

- [Results caching](features/caching.md)
- [Data file automatic updates](features/data-updates.md)
- [Lazy loading](features/properties.md#lazy-loading)
- [Missing properties](features/properties.md#missing-properties)

## Aspect data

In the same way that **Aspect Engines** are specific types of **Flow Element**. 
**Aspect Data** are specific types of **Element Data**.

See [Aspect engines](#aspect-engine) for details of the features that 
**Aspect Engines** / **Aspect Data** have on top of standard **Flow Element** / 
**Element Data**. 

# Cloud engines

The premise of cloud engines is to offload processing that might otherwise
be performed by an on-premise **Aspect Engine** to a remote service.

## Cloud request engine

The cloud request engine is a further specialization of **Aspect Engine** 
with the task of making requests to a remote service.

In theory, this could be an internally hosted service. In practice, it is
usually the [51Degrees cloud service](https://cloud.51degrees.com/api-docs/index.html).

This engine outputs a single property, the value of which is the JSON data 
that is returned by the remote service that it calls.

Note that calls will need to be made to the remote service at construction 
time in order to establish details the engine must expose, such as the 
accepted evidence keys.

## Cloud aspect engine

The cloud aspect engine is also a specialization of **Aspect Engine**.
It takes the JSON result from the cloud request engine and transforms 
it into an **Aspect Data** instance that is interface compatible with 
the data from the equivalent on-premise engine.

This engine must also expose the meta-data details for the properties
that it populates. We recommend having the cloud request engine 
request this data from the remote service when it is created. The data
can then be passed to the cloud aspect engine so that it can initialize 
it's internal data structures at creation time. 

