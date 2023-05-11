# Parallel processing

The reference implementations allow users to configure the Pipeline to
execute Elements in parallel.
For example, C# enables this by using an additional Element called
[ParallelElements](https://github.com/51Degrees/pipeline-dotnet/blob/master/FiftyOne.Pipeline.Core/FlowElements/ParallelElements.cs).

## Benefits

The intention is that this would allow a user to reduce the end-to-end time
needed to process a given request. Particularly when large numbers of
relatively slow engines are involved.

This can be particularly important for high-throughput web servers where
every ms matters.

## Drawbacks

Allowing Elements to be executed in parallel adds some complexity to the
implementation:

- Flow Data MUST be capable of enforcing thread-safe writes to data structures
  while also maintaining performance when it is not needed.
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
