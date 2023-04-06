# Summary

There must be some mechanism for instances to clean up system resources 
associated with various instances:

| Type | Description |
|---|---|
| Element Data | If the instance contains any native (C/C++) resources, it must clean them up when triggered. |
| Flow Data    | Trigger cleanup of any contained Element Data instances that need it.                   |
| Flow Element | Cleanup of large in-memory data items, file handles, etc.                               |
| Pipeline     | Trigger cleanup of Flow Elements that it contains. This behavior is configurable.       |

Note that the [web integration](web-integration.md) feature should manage cleanup 
so the user doesn't need to worry about it.

# Detail

## Element data

In general, we have found that specific clean up of resources associated with 
**Element Data** instances is not needed as the garbage collector does a good 
enough job.
However, there are two caveats to this:

1. This will not be the case in all programming languages. Some profiling should
   be done to ensure that cleanup is being done effectively in the absence of
   specific cleanup logic.
2. Where the **Element Data** contains references to native (C/C++) resources
   the system needs assistance to tie the cleanup of the **Element Data** to 
   the cleanup of these native resources. We have found that without this 
   assistance, the system fails to cleanup resources fast enough, leading to 
   resource starvation and low level memory exceptions.

### Impact on caching

Where the [result caching](caching.md) feature is being used, **Element Data** 
instances will be stored in the cache.

If the instances are cleaned up after they are used, then the ones stored in
the cache become useless.

Consequently, the system must not allow a cache to be added to **Engines** 
where the **Element Data** they produce requires cleanup.

## Flow Data

Cleanup of **Flow Data** may include any resources that it holds. However,
the primary concern is to ensure that any **Element Data** instances that 
it holds that require cleanup are taken care of.

**Element Data** instances that do not require cleanup must be left alone
in order for [result caching](caching.md) to work correctly.

## Flow Element

**Flow Elements** can be very lightweight, but can also maintain significant 
internal resources.

Similar to **Element Data** we have found that the primary problem area 
when it comes to cleanup is native resources.

There must be some mechanism to ensure that such resources are cleaned up 
when the **Flow Element** is no longer needed. 

Wether or not other **Flow Elements** need any specific cleanup logic is 
left up to implementers.

## Pipeline

By default, **Pipeline** will cleanup the **Flow Elements** it contains. 
However, there must be an option to disable this behavior.

This is needed for scenarios where single elements are added to multiple
**Pipelines**.
In this case, the user must take responsibility for cleanup of 
**Flow Element** resources. This should be made clear in comments and 
documentation around the use of this option.