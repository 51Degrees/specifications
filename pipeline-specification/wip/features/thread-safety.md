# Flow Elements

The Pipeline API is designed to be used in highly concurrent environments 
such as high traffic web servers.

Consequently, **Pipeline** and **Flow Element** implementations must be 
capable of handling multiple concurrent requests to the `Process` function.

<span style="color:yellow">TODO - should this capability be included in the spec? It seems to rarely (never?) be used
and adds non-trivial complexity to several core elements.</span>
In addition, a **Flow Element** may be added to multiple **Pipelines** once it 
has been built. This means that the processing performed by a **Flow Element** 
should have no state information that is dependent on a **Pipeline** to which it has been added.
Where such state information is required, the element must maintain isolated instances 
of this state for each **Pipeline** to which it has been added.

# Flow Data

In general user-facing data structures linked to **Flow Data** do not need to be 
thread-safe as the most common use-case is that they will be accessed and 
updated only on the current thread.
This ensures users get the best performance by default.

Where the Pipeline contains elements running in parallel, Element Data instances 
will be added to the Pipeline in parallel. However, it is a useful optimization
to allow Flow Data to be non-thread safe in contexts where no parallel execution 
is required.

**Flow Data** instances are created by the Pipeline instance on which they 
will be processed. The Pipeline can determine whether any Flow Elements are
to be processed in parallel and thus can determine whether to create thread-safe 
Flow Data or not.

## Evidence

Evidence collection stored within **Flow Data** needs to be thread safe for
concurrent read access. (Note 
this is not technically true. It is valid for elements to write to the evidence 
collection, so a pipeline could be constructed with parallel elements that both 
write to evidence at the same time. Nevertheless, avoiding making the collection 
thread safe results in a performance gain and, given that there is currently only 
one element that writes to evidence, this is not seen as an area of concern).
<span style="color:yellow">hmmm, I think we should say that evidence should
be implemented as immutable and I think it should be a nit that we record,
which points out that we do write to it, somewhere? where, btw?
</span>

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
