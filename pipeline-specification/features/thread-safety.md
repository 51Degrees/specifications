# Thread safety

## Flow Elements

The Pipeline API is designed to be used in highly concurrent environments
such as high traffic web servers.

Consequently, Pipeline and Flow Element implementations MUST be
capable of handling multiple concurrent requests to the `Process` function.

## Flow Data

In general user-facing data structures linked to Flow Data do not need to be
thread-safe as the most common use-case is that they will be accessed and
updated only on the current thread.
This ensures users get the best performance by default.

Where the Pipeline contains elements running in
[parallel](../advanced-features/parallel-processing.md), Element Data instances
will be added to the Flow Data in parallel. However, it is a useful optimization
to allow Flow Data to be non-thread safe in contexts where no parallel execution
is needed.

Flow Data instances are created by the Pipeline instance on which they
will be processed. The Pipeline can determine whether any Flow Elements are
to be processed in parallel and thus can determine whether to create thread-safe
Flow Data or not.

### Evidence

Evidence collection stored within Flow Data needs to be thread safe for
concurrent read access. Flow Elements MAY add values to the Evidence during
processing, as described in
[adding Evidence values](evidence.md#adding-evidence-values).

A Flow Element that runs in a
[parallel](../advanced-features/parallel-processing.md) group MUST NOT add
values to the Evidence. The other members of the group read the Evidence at
the same time, and the Evidence only needs to be safe for reading from several
threads at once, not for a write during those reads. A Flow Element that adds
Evidence for later Flow Elements to read runs outside any parallel group,
before the Flow Elements that read the value.

## Element Data

Element Data instances do not need to be safe for writing from several
threads at once, because an instance is written only by the Flow Element
that creates it, while that Flow Element processes.

They are read from several threads at once where the Pipeline contains
elements running in [parallel](../advanced-features/parallel-processing.md).
Every member of a parallel group processes the same Flow Data at the same
time, so Element Data written before the group is read by all of them
together, as the reference implementation's
[`ParallelElements`](https://github.com/51Degrees/51degrees-dotnet/blob/main/pipeline/Core/FlowElements/ParallelElements.cs)
does. Reading an Element Data instance once the Flow Element that writes it
has finished MUST therefore be safe from several threads at once.

It is possible for a user to engineer a scenario where an instance is
written from several threads, or read while another thread writes it. It is
not worthwhile to cater for that scenario, given the decreased performance
and increased complexity that it would require.

Code comments and documentation MUST be clear that these instances are not
intended to be written from multiple threads simultaneously, nor read while
they are being written.

## Aspect data

In contrast to Element Data, Aspect Data instances SHOULD be thread-safe. This
is because, if the [caching](caching.md) feature is enabled, the same instance
might be added to multiple different Flow Data from different calls to `Process`.
If the Aspect Data cannot be made thread safe for some reason then the
corresponding Engine MUST NOT allow a cache to be added.
