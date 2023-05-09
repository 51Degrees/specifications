# Resource cleanup

## Summary

There MUST be some mechanism to clean up system resources
associated with various instances:

| Type         | Description                                                                                          |
|--------------|------------------------------------------------------------------------------------------------------|
| Element Data | If the instance contains any native (C/C++) resources, it will need to clean them up when triggered. |
| Flow Data    | Trigger clean up of contained Element Data instances.                                                |
| Flow Element | Clean up large in-memory data items, file handles, etc.                                              |
| Pipeline     | Trigger clean up of Flow Elements that it contains.                                                  |

Note: In many scenarios the user application is responsible for creating
Flow Data from the Pipeline and for its later disposal.
However, see [web integration](web-integration.md) for further notes
on where this is not the case.

## Detail

### Pipeline

In general, the Pipeline is responsible for clean up of any Flow
Elements it contains.

However, if the [multi Pipeline Elements](../advanced-features/multi-pipeline-elements.md)
feature is implemented then there MUST be an option to disable
this behavior. In this case, the user will take responsibility
for cleanup of Flow Element resources. This can be made clear in
comments and documentation around the use of this option.

### Flow Element

Flow Elements might be very light-weight, but might also maintain
significant internal resources.

In general, we have found that specific clean up of resources associated with
Element Data instances is not needed as garbage collectors do a good enough
job for most languages.

However, there are two caveats to this:

1. This will not be the case in all programming languages or all workloads.
   Some profiling SHOULD be done to ensure that cleanup is being done effectively
   in the absence of specific cleanup logic.
2. Where the Element Data contains references to native (C/C++) resources
   the system needs assistance to tie the cleanup of the Element Data to
   the cleanup of these native resources. We have found that without this
   assistance, the system fails to clean resources up fast enough, leading to
   resource starvation and low level memory exceptions. There MUST be a
   mechanism to ensure such resources are cleaned up.

### Element Data

As with Flow Elements, we have found that the primary use case for
specific resource cleanup logic is for Element Data instances that
contain references to native C/C++ resources.

There MUST be some mechanism to ensure that such resources are cleaned up
when the Element Data is no longer needed.

Other Element Data implementations SHOULD be profiled to see if cleanup
logic is needed.

#### Impact on caching

Where the [result caching](caching.md) feature is being used, Element Data
instances will be stored in the cache.

If the instances are cleaned up after they are used, then the ones stored in
the cache become useless.

Consequently, the system MUST NOT allow a cache to be added to Engines
where the Element Data they produce requires cleanup beyond what normal
garbage collection will achieve.

### Flow Data

Cleanup of Flow Data might include any resources that it holds. However,
the primary concern is to ensure that any Element Data instances that
require cleanup are taken care of.

Element Data instances that do not require cleanup MUST be left alone
in order for [result caching](caching.md) to work correctly.

Note that Flow Data holds a reference to the Pipeline that created
it. However, Flow Data instances are not cleaned up when the Pipeline
is cleaned up. As such, it is possible to have active references to
Flow Data instances that reference disposed Pipeline instances and
would fail if processed.

Ideally, a helpful error message could be thrown in this scenario.
