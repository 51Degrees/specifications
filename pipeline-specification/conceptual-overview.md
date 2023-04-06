
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
in the **Pipeline**. These are accessed using the string 'data key' of the
 **Flow Element** that created each entry.

**Flow Data** objects are created by the pipeline and can only be used within the 
pipeline they were created by. The Process method on **Flow Data** will use the 
pipeline that created the **Flow Data** to process it.

**Flow Data** must be capable of being thread safe. In other words, it must handle 
  being accessed and updated by multiple threads simultaneously. However, non-thread 
  aware data structures are preferred when possible for performance reasons. 
  The **Pipeline** can decide at creation time if a concurrent structure is required 
  or not. Also see [thread safety](features/thread-safety.md).

**Flow Data** must support various different ways of accessing the data it contains. 
See [access to results](features/access-to-results.md) for more information.

## Element data

**Element Data** is a container for property values. These values will be set by 
**Flow Elements** during processing.

As a minimum, **Element Data** must support a string keyed accessor for property 
values. Individual implementations for specific elements should also include 
specific accessors for each property. 
See [access to results](features/access-to-results.md) for more information.

See [resource cleanup](features/resource-cleanup.md) for details on ensuring 
**Element Data** resources are cleaned up correctly.

## Flow element

A **Flow Element** is a black box which takes a **Flow Data** and performs some 
operation. This processing may read evidence and/or **Element Data** instances that 
have been added by previous elements. It may add new evidence values and should add 
an instance of its own element data, which may or may not have properties populated.

See [resource cleanup](features/resource-cleanup.md) for details on ensuring 
**Flow Element** resources are cleaned up correctly.

## Flow element builder

It is highly recommended that **Flow Elements** have some associated builder/factory 
that is used to create **Flow Element** instances.

The exact specification of this component is less important than having a common 
mechanism for construction of elements. This provides consistency for users and 
will assist in the implementation of other parts of the specification.

In most languages, we have found the builder pattern to be the best approach.

See [pipeline configuration](features/pipeline-configuration.md) for more information.

## Pipeline

A **Pipeline** is a method of grouping multiple **Flow Elements** into a single 
process. By default, elements are always executed sequentially in the order 
that they are added. See [pipeline builder](#pipeline-builder) for more details.

A **Pipeline** object is immutable. In other words, once created, it cannot be 
changed by adding new elements, removing old ones, etc.

## Pipeline builder

As with [Flow Elements](#flow-element-builder), we have found that the builder 
pattern is a good way to control the creation of **pipeline** instances.

See [pipeline configuration](features/pipeline-configuration.md) for more information.

# Engines

**Aspect Engines** (often shortened to just '**Engines**') are a specific type 
of **Flow Element** with additional features and properties.

- [Results caching](features/caching.md)
- [Request trackers](features/trackers.md)
- [Data file automatic updates](features/data-updates.md)
- [Lazy loading](features/properties.md#lazy-loading)

## Aspect data

## Aspect engine

## Aspect engine builder

# Cloud engines

## Cloud request engine

## Cloud aspect engine




