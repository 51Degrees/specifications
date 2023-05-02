# Caching

## Overview

Aspect Engines may support the addition of a cache.
This is intended to improve performance when the Engine receives a process
request containing Evidence values that are sufficiently similar to a previous request.

As with any caching strategy, the implications for memory use and
performance should be investigated by profiling in the target environment.
Such concerns are the responsibility of the end
user of the Pipeline API, rather than the implementor of the API.
However, the implementor MUST ensure that there are tests to demonstrate that 
the caching system can provide some benefit in the limited scope of the 
testing environment. 

In practice, we have found that the primary use-case for caching is the
[Cloud Request Engine](../pipeline-elements/cloud-request-engine.md).
This works well when cloud requests are being made for one product.
(For example, Device Detection.) However, it becomes significantly less
effective when the cloud request is being made for multiple products.
At present, there are no plans to address this.

## Process flow

With a cache added, the logical execution of the process function within
the Engine will be something like this:

```
var result = null
var cacheKey = null

if(cache is enabled)
  cacheKey = createKey(getRelevantEvidence(flowData))
  result = cache.Get(cacheKey)
endif

if(result == null)
  result = doNormalProcessing()

  if(cache is enabled)
    cache.Add(cacheKey, result)
  endif
endif

flowData.Add(engineDataKey, result);
```

Warning - don't take the pseudo code above as a template. Real production code
is likely to vary significantly from this in order to account for concurrency
concerns, error handling, other features, etc.

## Generation of keys

All Flow Elements MUST [advertise](advertize-accepted-evidence.md) the
Evidence keys that they make use of.
You will need to use this to build a list of the relevant Evidence keys
and values that are present in the Flow Data.

Other considerations when creating keys:
- Evidence values MUST always be added in the same Evidence key order.
  For example, `query.user-agent` first, then `header.user-agent`, etc

- Comparison of Evidence keys MUST be case-insensitive. For example,
  the following keys are considered the same:

  ```
  "query.user-agent" = "abc"
  ```

  ```
  "query.User-Agent" = "abc"
  ```
- Comparison of Evidence values MUST be case-sensitive.

## Cache implementation

The system should allow any cache conforming to a simple interface to be
used.
However, the default implementation should be a sharded LRU cache.
This will ensure that memory use is always well-defined and that the cache
can cope with concurrent requests reasonably well.

The cache must be configurable:

| Configuration option | Default             | Description                                                           |
|----------------------|---------------------|-----------------------------------------------------------------------|
| Size                 | 1000                | Number of items stored in the cache before it starts evicting things. |
| Concurrency          | Number of CPU cores | Number of shards in the cache.                                        |

[This article](https://medium.com/@yewang2018/lru-cache-design-8257850a69fe)
describes the internals of such a cache. You can also review the
[Java](https://github.com/51Degrees/pipeline-java/blob/master/pipeline.caching/src/main/java/fiftyone/caching/LruCacheBase.java)
and [.NET](https://github.com/51Degrees/caching-dotnet/blob/master/FiftyOne.Caching/LruCacheBase.cs)
reference implementations.

## Data lifetime and concurrency issues

The cache stores the instance of Aspect Data that was generated based
on the Evidence values in the key.

Where [resource cleanup](resource-cleanup.md) is required, the lifetime
of such data objects is tied to the Flow Data that is generated for
that request.

However, cached instances can persist long after the original Flow Data
that resulted in their creation is gone.

Consequently, if the Element Data produced by an Engine requires
cleanup, then that Engine must not allow a cache to be added.

In addition, this functionality can result in a scenario where the
instance is accessed by multiple threads simultaneously.
If access to the Element Data cannot be guaranteed to be thread-safe,
then the Engine must not allow a cache to be added.

Design note - There are various routes we could potentially take to allow
caches to still work in the scenarios described above. (Creating a duplicate
of the instance, reference counting to ensure cleanup happens, etc.)
51Degrees has decided not to pursue these at present, so the current
implementations simply do not support adding a cache in these cases.
