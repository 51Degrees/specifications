
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

<span style="color:yellow">
The README also mentions that "A Flow Data may only be processed 
once and belongs to exactly one Pipeline."  I think it makes sense to mention it here too, 
perhaps we also want implementers to enforce this with raising an error if `Process()` method was called multiple times on the same `Flow Data`.

Also is implementer able to retrieve the current `Flow Data` object from the pipeline after processing is complete if they somehow do not
hold on to the reference to this object?  If I understand correctly `Pipeline` holds on to an instance of `Flow Data` and just gives user
a reference to this object.  The user controls `Pipeline` thru the reference to `Flow Data`, but they can keep it in a temporary variable 
that might go out of scope, while they have to hold on to `Pipeline` object for the duration of processing at least.  Should they be able to get back
the reference to the existing `Flow Data` object that Pipeline is holding again without instantiating a new one? 

Also am I correct that users can instantiate new / multiple `Flow Data` objects from the existing pipeline?  (I am sure it is mentioned somewhere down the road, 
but I just haven't got there yet).
</span>

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

See [resource cleanup](features/resource-cleanup.md) for details on ensuring 
**Flow Element** resources are cleaned up correctly.

## Flow element builder

It is highly recommended that **Flow Elements** have some associated
builder/factory that is used to create **Flow Element** instances.

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

A **Pipeline** object is intended to be immutable. In other words, once created, it cannot be 
changed by adding new elements, removing old ones, etc.

## Pipeline builder

As with [Flow Elements](#flow-element-builder), we have found that the builder 
pattern is a good way to control the creation of **Pipeline** instances.

See [pipeline configuration](features/pipeline-configuration.md) for more information
on configuring and creating instances.

# Engines

The engines package adds features to **Flow Elements** that are common to
multiple different 51Degrees element implementations.

## Aspect engine

<span style="color:yellow">
I think the previous version of the conceptual overview also contained an explanation of an Aspect term and examples of it.
I think it was a useful concept and I can't seem to find it in the docs now.
</span>

**Aspect Engines** (often shortened to just '**Engines**') are a specific type 
of **Flow Element** with additional features and properties:

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

See [cloud request engine](pipeline-elements/cloud-request-engine.md) 
for the technical details.

## Cloud aspect engine

The cloud aspect engine is also a specialization of **Aspect Engine**.
It takes the JSON result from the cloud request engine and transforms 
it into an **Aspect Data** instance that is interface compatible with 
the data from the equivalent on-premise engine.

See [cloud aspect engine](pipeline-elements/cloud-aspect-engine.md) 
for the technical details.
