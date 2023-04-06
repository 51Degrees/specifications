
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

**Flow Data** must be capable of being thread safe. In other words, it must handle 
  being accessed and updated by multiple threads simultaneously. However, non-thread 
  aware data structures are preferred when possible for performance reasons. 
  The **Pipeline** can decide at creation time if a concurrent structure is required 
  or not. Also see [thread safety](features/thread-safety.md).

**Flow Data** must support various different ways of accessing the data it contains. 
See [access to results](features/access-to-results.md) for more information.

## Element data

**Element Data** is a container, within the **Flow Data**, for property values 
relating to a particular **Flow Element**. These values are set by 
**Flow Elements** during processing. **Element Data** is retrieved from 
**Flow Data** using the 'data key' associated with the **Flow Element**.

As a minimum, **Element Data** must support access to property 
values using a string denoting the property name. Individual implementations 
for specific elements should also include specific accessors for each 
property. <span style="color:yellow">not clear what the last sentence means</span>
See [access to results](features/access-to-results.md) for more information.

See [resource cleanup](features/resource-cleanup.md) for details on ensuring 
**Element Data** resources are cleaned up correctly.

## Flow element

A **Flow Element** is a black box which takes a **Flow Data** and performs some
processing. This processing may read evidence and/or **Element Data** instances
that have been added by previous elements. It may add new evidence values and
must <span style="color:yellow">"may", surely</span> add an instance of its own element data, which may 
or may not have properties populated.

A **Flow Element** can be added to multiple pipelines once it has been built.
This means that the processing performed by a flow element must be thread safe
and must either have no state that is dependent on a pipeline, or must maintain
this state internally for each pipeline it is added to.

See [resource cleanup](features/resource-cleanup.md) for details on ensuring 
**Flow Element** resources are cleaned up correctly.

## Flow element builder

<span style="color:yellow"> suggest rewriting this whole section in view of the reservations
expressed in [notes](reference-implementation-notes.md)</span>

It is highly recommended that **flow elements** have some associated
builder/factory that is used to create **flow element** instances.

The exact specification of this component is less important than having a common
mechanism for construction of elements. This provides consistency for users and
will assist in the implementation of other parts of the specification.

In most languages, we have found the builder pattern to be the best approach.

See [pipeline configuration](features/pipeline-configuration.md) for more information.

## Pipeline

## Pipeline builder

# Engines

## Aspect data

## Aspect engine

## Aspect engine builder

# Cloud engines

## Cloud request engine

## Cloud aspect engine