TODO - Write up these points.

- Engines must support the addition of a cache. <span style="color:yellow">
  better put as "may" as for example on-premise DD throws an exception if you add a cache</span>
    - Keyed on one or more evidence key/value pairs. These must be just the
      evidence keys that will be used by the engine curing processing.
    - Value will be the aspect data instance that was returned when the evidence
      values that make up the key were processed.
      <span style="color:yellow">
      this reads as though it must be the same instance, but surely it should be "copy on read" if it's a complex value</span>
    - As the initial step in the engine's processing, check if the request has evidence
      values that match an entry already in the cache. If so, it should return
      the matching entry, rather than performing the usual processing.
    - Default cache implementation will need to ensure it does not use too much
      memory. LRU is recommended.
    - Default cache implementation must be efficient in highly concurrent
      scenarios. A 'sharded' approach is recommended.
      <span style="color:yellow">
      I think this should say that due consideration should be given to the usual caching concerns such as concurrency, speed and memory trade-off</span>
    - <span style="color:yellow">Caching is particularly important for "cloud" engines</span>