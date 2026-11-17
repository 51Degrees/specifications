# Thread safety

These rules decide how Pipelines, Flow Elements, Flow Data and Element Data
behave when more than one thread is involved. They aim to make every request
as fast as possible, and to leave as few ways as possible for threads to cause
faults.

## General rules for parallel operation

1. A Pipeline and its Flow Elements MUST be able to process many Flow Data at
   once, one for each request, as [Flow Elements](#flow-elements) describes.
2. A Flow Data is used by one thread at a time. It MAY pass from one thread to
   another, as an asynchronous continuation does, but it MUST NOT be used by
   two threads at once. A caller that shares a Flow Data across threads is
   responsible for any locking.
3. Once processing has finished, a Flow Data is read only, except for
   [lazy properties](#lazy-properties), and its implementation MUST NOT take a
   lock. Being read only does not make a Flow Data safe to use from several
   threads at once, because the Element Data it holds may change when it is
   read, as Element Data that reads a [results instance](#results-instances)
   does, and the Flow Data cannot guard against that.
4. While a Flow Data is processed, only a
   [parallel group](../advanced-features/parallel-processing.md#how-a-group-uses-the-flow-data)
   puts more than one thread on it. Each member of the group writes only its
   own Element Data, and changes nothing else in the Flow Data.
5. Flow Elements MUST handle any multi-threaded or asynchronous work of their
   own internally, such as loading results in the background, lazy properties
   and sending usage data. A Flow Element that hands data to another thread
   copies it during processing, and never reads the Flow Data from that thread
   afterwards.
6. A lazy property uses the lazy task pattern, as
   [lazy properties](#lazy-properties) describes.
7. Element Data MUST be read only once the Flow Element that provides it has
   finished processing, except for lazy properties handled as lazy tasks, as
   [Element Data](#element-data) describes.
8. A results instance is never locked, as
   [results instances](#results-instances) describes.
9. A data refresh never affects a Flow Data created before it, as
   [data updates](data-updates.md) describes.
10. Disposing an Engine or a Pipeline waits for every request and every data
    refresh already running before it frees anything, as
    [resource cleanup](resource-cleanup.md#disposal-while-requests-are-running)
    describes.
11. Web integration examples and documentation say that a Flow Data cannot be
    shared across threads, and show it, as
    [web integration](web-integration.md#flow-data-and-threads) describes.

## How the language is used

What thread safety a package needs also depends on how its language is used.

- Where a package's supported setups run each request on one thread, with no
  other thread able to reach its Flow Data, such as PHP, no thread-safety
  strategy is needed, and the package does not offer
  [parallel processing](../advanced-features/parallel-processing.md).
- Where a package offers parallel processing, the rules for
  [parallel groups](../advanced-features/parallel-processing.md#how-a-group-uses-the-flow-data)
  keep its Flow Data safe without a lock.
- Where the data is held in unmanaged memory, as an on-premise Engine's
  [results instance](#results-instances) is, multi-threaded access is not
  supported, for performance. That is a hard rule in every language.

## Flow Elements

The Pipeline API is designed to be used in highly concurrent environments
such as high traffic web servers.

Consequently, Pipeline and Flow Element implementations MUST be
capable of handling multiple concurrent requests to the `Process` function.
Each request has its own Flow Data. State that a Flow Element shares between
requests, such as a cache, a queue or the data source it reads, MUST be safe
for that use.

## Flow Data

A Flow Data is created by the Pipeline that processes it, for one request.

During processing, a Flow Data is written by one thread at a time, except
within a parallel group, where the
[group's rules](../advanced-features/parallel-processing.md#how-a-group-uses-the-flow-data)
mean that no thread changes anything another thread uses. So a Flow Data needs
no lock at any time, and its implementation MUST NOT take one.

Once processing has finished, a Flow Data is read only, except for
[lazy properties](#lazy-properties). Adding Evidence, Element Data, errors or
warnings to a Flow Data that has finished processing MUST fail with an error.

A Flow Data is used by one thread at a time. A caller that needs to use one
from several threads at once is responsible for coordinating that, for
example by wrapping its calls in a lock of its own.

Code comments and documentation MUST say that a Flow Data is not safe to use
from several threads at once, and that the caller is responsible for any
locking.

### Evidence

Flow Elements MAY add values to the Evidence during processing, as described
in [adding Evidence values](evidence.md#adding-evidence-values).

A Flow Element that runs in a
[parallel](../advanced-features/parallel-processing.md) group MUST NOT add
values to the Evidence, because the other members of the group read the
Evidence at the same time. That is the Flow Element's responsibility, and
implementations are not required to check for it. A Flow Element that adds
Evidence for later Flow Elements to read runs outside any parallel group,
before the Flow Elements that read the value.

## Element Data

An Element Data instance is written only by the Flow Element that provides it,
while that Flow Element processes. Once that Flow Element has finished, the
instance MUST be read only, except for [lazy properties](#lazy-properties)
handled as lazy tasks.

Element Data that reads a [results instance](#results-instances) counts as
read only, because it offers no way to change a value. The writes that its
reads make into native memory are covered by the rules for results instances.

Each implementation MUST include a check, run by its automated tests, that
fails for a Flow Element whose Element Data does not meet this rule, so that
such a Flow Element cannot be added. See
[automated testing](../automated-testing.md).

Code comments and documentation MUST be clear that Element Data is written
only by the Flow Element that provides it.

## Lazy properties

A lazy property is one whose value is worked out when it is first asked for,
or by a task that runs after the Flow Element's process function has
returned, as in [lazy loading](../advanced-features/lazy-loading.md). Lazy
properties are the only part of a Flow Data that changes once processing has
finished.

Where the language supports it, a lazy property MUST use the lazy task
pattern. One task works the value out, started by the first request for it,
or by processing in the case of lazy loading. Every caller for the value,
including the first, waits for that task to finish and then reads its result.
No caller reads the value before the task has finished, and the work is never
done twice. If the task fails, every caller waiting for it gets its error.

The task is the Flow Element's own guard on its own value, not a lock on the
Flow Data. Where the language has no threads, as in PHP, the value is worked
out on the first request for it.

## Results instances

A results instance is the object an on-premise Engine's native code fills for
one request, which references unmanaged memory, such as the Device Detection
and IP Intelligence results. Multi-threaded access to a results instance is
not supported, for performance reasons. Reading a value from it writes into
it, so it is not safe to use from several threads at once, and neither is
Element Data that reads its values from one.

Implementations MUST NOT lock a results instance, or the reads that Element
Data makes from one, to make it safe for several threads. The caller can
almost always keep its use of a results instance on one thread, and a lock
would cost every request to protect the few that share one. The caller is
responsible for thread-safe access. A caller that needs to use a results
instance, or Element Data that reads from one, from several threads at once
MUST coordinate that itself, for example by wrapping its calls in a lock of
its own.

A member of a parallel group that reads Element Data that reads from a
results instance is responsible for the thread safety of those reads. For
example, where a Device Detection Engine runs before a parallel group, more
than one member of the group can read its values at the same time.

Code comments and documentation MUST say plainly that a results instance, and
Element Data that reads from one, is not safe to use from several threads at
once, and that the caller is responsible for thread-safe access.

## Aspect data

Aspect Data is Element Data, so it is read only once its Engine has finished,
as [Element Data](#element-data) requires. The [caching](caching.md) feature
adds the same Aspect Data instance to the Flow Data of different requests,
which may run on different threads at once. Data that is read only, apart from
lazy properties handled as lazy tasks, is safe to share in that way, except
where it reads from a results instance. So an Engine whose Aspect Data reads
from a results instance MUST NOT allow a cache to be added.
