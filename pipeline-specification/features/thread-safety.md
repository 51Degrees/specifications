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

Element Data instances are not thread-safe. An instance is written only by
the Flow Element that creates it, while that Flow Element processes, and it is
almost always read on the thread that processed the Flow Data.

Implementations MUST NOT lock reads or writes of an Element Data instance,
or of the native results it holds, to make it safe for several threads. The
caller can almost always keep its use of an instance on one thread, and a
lock would cost every request to protect the few that share an instance. The
caller is responsible for thread-safe access. A caller that needs to use an
instance from several threads at once MUST coordinate that itself, for
example by wrapping its calls in a lock of its own.

This matters most for Element Data that reads native results when its values
are read, such as an on-premise Engine's Aspect Data, where two reads at once
can corrupt the results.

Flow Elements in a [parallel](../advanced-features/parallel-processing.md)
group process the same Flow Data at the same time. The Pipeline does not
coordinate their reads of Element Data written before the group. Where two of
them read Element Data that reads native results, whoever builds the Pipeline
coordinates those reads, or keeps one of those Flow Elements out of the group.

Code comments and documentation MUST say plainly that Element Data instances
are not safe to read or write from several threads at once, and that a caller
who needs that coordinates its own calls.

## Aspect data

Aspect Data is Element Data, so the same holds. The [caching](caching.md)
feature adds the same Aspect Data instance to the Flow Data of different
requests, which may run on different threads at once, so an Engine whose
Aspect Data reads native results when its values are read MUST NOT allow a
cache to be added.
