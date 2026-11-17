# Parallel processing

The reference implementations allow users to configure the Pipeline to
execute Elements in parallel.
For example, C# enables this by using an additional Element called
[ParallelElements](https://github.com/51Degrees/51degrees-dotnet/blob/main/pipeline/Core/FlowElements/ParallelElements.cs).

A package whose supported setups run each request on one thread, with no
other thread able to reach its Flow Data, such as PHP under php-fpm or Apache in prefork
mode, MUST NOT offer parallel processing. It would add the cost of
running a group and give nothing back, because no request in those
setups has a second thread to run an Element on.

## How a group uses the Flow Data

A parallel group shares one Flow Data between its members. These rules keep
that safe with no lock, apart from the errors and warnings members add, as
[thread safety](../features/thread-safety.md#flow-data) describes.

1. Each member MUST add its Element Data to the Flow Data when it is ready,
   through the Flow Data's linked list, which puts each new node in place
   with one atomic compare and swap, so no lock is taken.
2. Each member MUST write only its own Element Data instance, and MUST NOT
   change anything else in the Flow Data apart from adding its own Element
   Data, errors and warnings.
3. A member's errors and warnings are added to the Flow Data under a lock
   while the group runs, in the order the members add them.
4. A member MAY read any Element Data in the Flow Data, but is responsible
   for making sure that the Element Data does not belong to another member of
   the same group, which may still be writing it.
5. A member that reads Element Data that reads from a
   [results instance](../features/thread-safety.md#results-instances) is
   responsible for the thread safety of those reads, because other members
   may read the same results at the same time.
6. Two Flow Elements that write one Element Data instance, such as two
   Engines with the same key or two
   [Derived Property Elements](../pipeline-elements/derived-property-element.md),
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
