# Parallel processing

The reference implementations allow users to configure the Pipeline to
execute Elements in parallel.
For example, C# enables this by using an additional Element called
[ParallelElements](https://github.com/51Degrees/51degrees-dotnet/blob/main/pipeline/Core/FlowElements/ParallelElements.cs).

A package whose supported setups run each request on one thread, with no
other thread in the process, such as PHP under php-fpm or Apache in prefork
mode, MUST NOT offer parallel processing. It would add the cost of
thread-safe Flow Data and give nothing back, because no request in those
setups has a second thread to run an Element on.

## How a group uses the Flow Data

A parallel group shares one Flow Data between its members. These rules mean
that no member changes anything another member uses, so the Flow Data needs
no lock, as [thread safety](../features/thread-safety.md) requires.

1. Before any member runs, the Element Data of every member is added to the
   Flow Data, in Pipeline order, on the thread that runs the group. A member
   whose Element Data comes from a [cache](../features/caching.md) looks the
   cache up at that point.
2. Each member then writes only its own Element Data instance, and changes
   nothing else in the Flow Data. It adds no Evidence, no Element Data and no
   errors or warnings to the Flow Data.
3. The errors and warnings of each member are added to the Flow Data by the
   group once every member has finished, on the thread that runs the group,
   in Pipeline order.
4. A member MAY read any Element Data in the Flow Data, but is responsible
   for making sure that the Element Data does not belong to another member of
   the same group, which may still be writing it.
5. A member that reads Element Data that reads from a
   [results instance](../features/thread-safety.md#results-instances) is
   responsible for the thread safety of those reads, because other members
   may read the same results at the same time.
6. Two Engines that share one Element Data instance, because the second
   finds the instance the first added under the same key and writes into it,
   MUST NOT be members of the same group, because both would write that
   instance at once. Whoever builds the Pipeline keeps them apart.
   Implementations are not required to check for it.
7. The group finishes only when every member has finished. Waiting for them
   makes every member's writes visible to the thread that carries on.

A member MUST NOT add values to the Evidence, as
[thread safety](../features/thread-safety.md#evidence) describes. The
[usage sharing element](../pipeline-elements/usage-sharing-element.md#position-in-the-pipeline)
is never a member of a group.

## Benefits

The intention is that this would allow a user to reduce the end-to-end time
needed to process a given request. Particularly when large numbers of
relatively slow engines are involved.

This can be particularly important for high-throughput web servers where
every ms matters.

## Drawbacks

Allowing Elements to be executed in parallel adds some complexity to the
implementation:

- A group has to use the Flow Data as
  [how a group uses the Flow Data](#how-a-group-uses-the-flow-data)
  describes, so that no lock is needed.
- Additional options available during configuration.
- More features to document and test.

In addition, there are various factors that reduce the benefit from this feature:

- Many elements have dependencies on each other's output so cannot be executed
  in parallel anyway.
  - We have no mechanism for describing these dependencies, programmatically or
    otherwise. Consequently, it can be unclear to users which elements can safely
    be executed in parallel.
- The end-to-end processing time is still limited by the slowest Element. If
  one Element takes a significant proportion of the total processing time then
  the performance benefit could be marginal or possibly negative.
- If users want to improve performance through concurrent processing, they can
  do so more effectively by creating Flow Data instances on separate threads and
  calling process. This is exactly what web servers are doing and could easily
  be implemented for backend processing as well.
