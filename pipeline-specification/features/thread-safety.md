# Thread safety

What thread safety a package needs depends on how its language is used.

- Where a package's supported setups run each request on one thread, with no
  other thread able to reach its Flow Data, such as PHP, no thread-safety
  strategy is needed, and the package does not offer
  [parallel processing](../advanced-features/parallel-processing.md).
- Where several threads can use the same Flow Data at once, Flow Data and the
  Element Data it holds MUST have a thread-safety strategy that keeps that use
  safe. Locking is one such strategy. Others include data that does not change
  once written, and collections built for concurrent use.
- Where the data is held in unmanaged memory, as an on-premise Engine's
  [results instance](#results-instances) is, multi-threaded access is not
  supported, for performance. That is a hard rule in every language.

## Flow Elements

The Pipeline API is designed to be used in highly concurrent environments
such as high traffic web servers.

Consequently, Pipeline and Flow Element implementations MUST be
capable of handling multiple concurrent requests to the `Process` function.

## Flow Data

The most common use is that a Flow Data is used only on the thread that
processes it, so a thread-safety strategy SHOULD cost nothing when no second
thread is involved.

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
has finished MUST therefore be safe from several threads at once, except
where it reads from a [results instance](#results-instances).

It is possible for a user to engineer a scenario where an instance is
written from several threads, or read while another thread writes it. It is
not worthwhile to cater for that scenario, given the decreased performance
and increased complexity that it would require.

Code comments and documentation MUST be clear that these instances are not
intended to be written from multiple threads simultaneously, nor read while
they are being written.

## Results instances

A results instance is the object an on-premise Engine's native code fills for
one request, which references unmanaged memory, such as the Device Detection
and IP Intelligence results. Multi-threaded access to a results instance is not
supported, for performance reasons. Reading a value from it writes into it, so it is not safe to use from
several threads at once, and neither is Element Data that reads its values
from one.

Implementations MUST NOT lock a results instance, or the reads that Element
Data makes from one, to make it safe for several threads. The caller can
almost always keep its use of a results instance on one thread, and a lock
would cost every request to protect the few that share one. The caller is
responsible for thread-safe access. A caller that needs to use a results
instance, or Element Data that reads from one, from several threads at once
MUST coordinate that itself, for example by wrapping its calls in a lock of
its own.

Where members of a parallel group read the same Element Data that reads from
a results instance, the Pipeline does not coordinate those reads. Whoever
builds the Pipeline coordinates them, or keeps one of those Flow Elements out
of the group.

Code comments and documentation MUST say plainly that a results instance, and
Element Data that reads from one, is not safe to use from several threads at
once, and that the caller is responsible for thread-safe access.

## Aspect data

Aspect Data is Element Data, so reading it once its Engine has finished is
safe from several threads at once, as [Element Data](#element-data) requires,
except where it reads from a results instance. The [caching](caching.md)
feature adds the same Aspect Data instance to the Flow Data of different
requests, which may run on different threads at once, so an Engine whose
Aspect Data reads from a results instance MUST NOT allow a cache to be added.
