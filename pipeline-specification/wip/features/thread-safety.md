# Flow Elements

The Pipeline API is designed to be used in highly concurrent environments 
such as high traffic web servers.

Consequently, **Pipeline** and **Flow Element** implementations must be 
capable of handling multiple concurrent requests to the `Process` function.

TODO - should this capability be included in the spec? It seems to rarely (never?) be used
and adds non-trivial complexity to several core elements.
In addition, a **Flow Element** can be added to multiple **Pipelines** once it 
has been built. This means that the processing performed by a **Flow Element** 
must also have no state information that is dependent on the **Pipeline** or the 
**Flow Elements** it contains.
Where such state information is required, the element must maintain isolated instances 
of this state internally for each **Pipeline** it is added to and retrieve the correct 
state for the relevant **Pipeline** during processing.

# Flow Data

In general user-facing data structures linked to **Flow Data** do not need to be 
thread-safe as the most common use-case is that they will be accessed and 
updated only on the current thread.
This ensures users get the best performance by default.

Where the Pipeline contains elements running in parallel, element data instances 
will be added to the Pipeline in parallel.
We typically solve this by having the Pipeline be involved with **Flow Data** 
creation. Since the Pipeline knows whether it has any elements running in parallel,
we can decide at that point whether to create thread-safe or non thread-safe 
collection.

## Evidence

The evidence collection stored within **Flow Data** does not need to be thread safe, 
as it may be read concurrently but should not be written to concurrently. (Note 
this is not technically true. It is valid for elements to write to the evidence 
collection, so a pipeline could be constructed with parallel elements that both 
write to evidence at the same time. Nevertheless, avoiding making the collection 
thread safe results in a performance gain and, given that there is currently only 
one element that writes to evidence, this is not seen as an area of concern).

# Element Data

In general, Element Data instances do not need to be thread safe, as they
should only be accessed and updated from a single thread.

While it is certainly possible for a user to engineer a scenario where an 
instance is accessed from multiple threads. We do not consider it worthwhile 
to cater for this scenario given the decreased performance and increased
complexity that it would require.

# Aspect Data

In contrast to Element Data, Aspect Data instances must be thread-safe as the 
same instance may be used for multiple different calls to `Process` when
the [caching](caching.md) feature is enabled.
If this is not possible for some reason then the engine must not allow a cache 
to be added.
