# Thread safety

## Flow elements

The Pipeline API is designed to be used in highly concurrent environments 
such as high traffic web servers.

Consequently, **Pipeline** and **Flow Element** implementations must be 
capable of handling multiple concurrent requests to the `Process` function.

## Flow data

In general user-facing data structures linked to **Flow Data** do not need to be 
thread-safe as the most common use-case is that they will be accessed and 
updated only on the current thread.
This ensures users get the best performance by default.

Where the **Pipeline** contains elements running in parallel, **Element Data** instances 
will be added to the **Flow Data** in parallel. However, it is a useful optimization
to allow **Flow Data** to be non-thread safe in contexts where no parallel execution 
is required.

**Flow Data** instances are created by the Pipeline instance on which they 
will be processed. The Pipeline can determine whether any Flow Elements are
to be processed in parallel and thus can determine whether to create thread-safe 
Flow Data or not.

### Evidence

Evidence collection stored within **Flow Data** needs to be thread safe for
concurrent read access and immutable once created. 

## Element data

In general, **Element Data** instances do not need to be thread safe, as they
should only be accessed and updated from a single thread.

While it is certainly possible for a user to engineer a scenario where an 
instance is accessed from multiple threads. We do not consider it worthwhile 
to cater for this scenario given the decreased performance and increased
complexity that it would require.

## Aspect data

In contrast to Element Data, Aspect Data instances must be thread-safe as the 
same instance may be used for multiple different calls to `Process` when
the [caching](caching.md) feature is enabled.
If this is not possible for some reason then the engine must not allow a cache 
to be added.