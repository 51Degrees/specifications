# Thread safety

These rules decide how Pipelines, Flow Elements, Flow Data and Element Data
behave when more than one thread is involved. They aim to make every request
as fast as possible, and to leave as few ways as possible for threads to cause
faults.

## General rules for parallel operation

1. A Pipeline and its Flow Elements MUST be able to process many Flow Data at
   once, one for each request, as [Flow Elements](#flow-elements) describes.
2. Outside a parallel group, which rule 4 covers, a Flow Data is used by one
   thread at a time. It MAY pass from one thread to another, as an asynchronous continuation does, but it MUST NOT be used by
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
   own Element Data, and changes nothing else in the Flow Data apart from
   adding its own Element Data, errors and warnings.
5. Flow Elements MUST handle any multi-threaded or asynchronous work of their
   own internally, such as a call to another resource, lazy properties and
   sending usage data. Long-running work, such as a call to another resource,
   is a [lazy property](#lazy-properties) of the Flow Element's own Element
   Data, and an Engine does not run its processing in a background task,
   apart from the deprecated
   [lazy loading](../advanced-features/lazy-loading.md) option. A Flow Element
   that hands data to another thread MUST copy it during processing, and MUST
   NOT read the Flow Data from that thread afterwards.
6. A lazy property uses the lazy task pattern, as
   [lazy properties](#lazy-properties) describes.
7. Element Data MUST NOT be written once the Flow Element that provides it has
   finished processing, except by a lazy property's task, and a later write
   MUST fail, as [Element Data](#element-data) describes.
8. A results instance is never locked, as
   [results instances](#results-instances) describes.
9. A data refresh never affects a Flow Data created before it, as
   [data updates](data-updates.md) describes.
10. Disposing an Engine or a Pipeline waits for every call to process, every
    lazy task and every data refresh already running before it frees anything
    they use, as
    [resource cleanup](resource-cleanup.md#disposal-while-requests-are-running)
    describes.
11. Web integration examples and documentation say that a Flow Data cannot be
    used by two threads at once, and show it, as
    [web integration](web-integration.md#flow-data-and-threads) describes.

## How the language is used

What thread safety a package needs also depends on how its language is used.

- Where a package's supported setups run each request on one thread, with no
  other thread able to reach its Flow Data, such as PHP, no thread-safety
  strategy is needed, and the package does not offer
  [parallel processing](../advanced-features/parallel-processing.md).
- Where a package offers parallel processing, the rules for
  [parallel groups](../advanced-features/parallel-processing.md#how-a-group-uses-the-flow-data)
  and for [Flow Data](#flow-data) keep its Flow Data safe, with a lock only for
  the errors and warnings that members add.
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

A Flow Data MUST keep its Element Data in a linked list, not in a dictionary.
A Flow Element adds its Element Data while it processes, as a new node that
points at the current head of the list. Where a parallel group can add Element
Data at the same time, the new node MUST be put in place with one atomic
compare and swap of the head, being a single operation that replaces the head
only if it is still the node the add read. If another member added a node
first, the add points the new node at the new head and tries again. Readers
then read the head with the language's atomic or volatile read, so that they
see each node in full. Where no parallel group can add at the same time, a
plain write is enough. A node never changes once it is in the list, so a
reader follows the links with no lock and always sees a whole list. Finding
Element Data by its key is a search along the list, which is short because a
Flow Data holds one Element Data for each Flow Element. Anything that lists
the Element Data in Pipeline order, being the order the Flow Elements were
added to the Pipeline with the members of a parallel group in the order they
were added to the group, sorts it first, because the list holds the newest
first.

Errors and warnings that members of a parallel group add while the group runs
MUST be added under a lock. They are rare, so the lock costs nothing in the normal
case. At every other time, errors and warnings are added with no lock.

Once processing has finished, a Flow Data is read only, except for
[lazy properties](#lazy-properties), and its implementation MUST NOT take a
lock. Adding Evidence, Element Data, errors or warnings to a Flow Data that has
finished processing MUST fail with an error.

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
implementations do not check for it. A Flow Element that adds
Evidence for later Flow Elements to read runs outside any parallel group,
before the Flow Elements that read the value.

## Element Data

An Element Data instance is written only by the Flow Element that provides it,
or by the Flow Elements that share it, and only while they process. Each
Element Data records when a Flow Element that writes it finishes, and a Flow
Element that shares the instance opens it for writing again when it starts to
process. A write through its write methods while the instance is recorded as
finished MUST fail with an error, except by a
[lazy property's](#lazy-properties) task.

Values that Element Data reads from a [results instance](#results-instances),
and values it keeps once it has read them, are not writes for this rule. The
writes those reads make, into native memory or into the values kept, are
covered by the rules for results instances.

Each implementation MUST include a check, run by its automated tests, that
processes every Flow Element in the repository, then writes to its Element
Data and expects the error. See [automated testing](../automated-testing.md).

Code comments and documentation MUST be clear that Element Data is written
only by the Flow Element that provides it, or the Flow Elements that share it,
and only while they process.

## Lazy properties

A lazy property is one whose value is worked out when it is first asked for,
or by a task that the Flow Element starts while it processes, such as the
call to another resource that the
[Cloud Request Engine](../pipeline-elements/cloud-request-engine.md#processing)
starts. Apart from the reads from a results instance described below, lazy
properties are the only part of a Flow Data that changes once processing has
finished. Values that Element Data reads from a
[results instance](#results-instances) when they are asked for are not lazy
properties, and the rules for results instances cover them.

Where the language supports it, a lazy property MUST use the lazy task
pattern. One task works the value out, started by the first request for it,
or by the Flow Element while it processes. Every caller for the value,
including the first, waits for that task to finish and then reads its result.
No caller reads the value before the task has finished, and the work is never
done twice. If the task fails, every caller waiting for it gets its error.

Long-running work in a Flow Element, such as a call to another resource, is a
lazy property. The Flow Element builds what the work needs from the Flow Data
while it processes, starts the task, and adds the task to its own Element
Data. The task never reads the Flow Data.

The task is the Flow Element's own guard on its own value, not a lock on the
Flow Data. Where a package's setups run each request on one thread, as PHP's
do, the value is worked out on the first request for it.

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

Aspect Data is Element Data, so it is not written once its Engine has
finished, as [Element Data](#element-data) requires. The [caching](caching.md)
feature adds the same Aspect Data instance to the Flow Data of different
requests, which may run on different threads at once. Data that is not
written, apart from lazy properties handled as lazy tasks, is safe to share in
that way, except where it reads from a results instance. So an Engine whose
Aspect Data reads from a results instance MUST NOT allow a cache to be added.
