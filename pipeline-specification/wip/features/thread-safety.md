- Engine implementations should be capable of handling multiple concurrent
  requests.
- In general user-facing data structures do not need to be thread-safe. 
- better performance, user can ensure that they handle the data in a thread safe way if
  they need to.
    - Where the pipeline contains elements running in parallel, some data
      structures will need to be updated in a thread safe manner.
- aspect data instances must be thread-safe. If this is not possible, the engine
  must not support [caching](caching.md)