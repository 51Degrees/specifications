# Caching

## Overview

Aspect Engines MAY support the addition of a cache.
This is intended to improve performance when the Engine receives a process
request containing Evidence values that are sufficiently similar to a previous request.

As with any caching strategy, the implications for memory use and
performance will need to be investigated by profiling in the target environment.
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
At present, there are no plans to address this as most users only
query one product at once.

## Process flow

With a cache added, the logical execution of the process function within
the Engine will be something like this:

```pseudo-code
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

All Flow Elements MUST [advertize](advertize-accepted-evidence.md) the
Evidence keys that they make use of.
You will need to use this to build a list of the relevant Evidence keys
and values that are present in the Flow Data.

Other considerations when creating keys:

- Cache keys MUST always be generated deterministically. This means
  that the order that Evidence values are considered must be the same each
  time. See the [Evidence](evidence.md#overview) page for details on the
  defined order of Evidence keys.

- Comparison of Evidence keys MUST be case-insensitive. For example,
  the following keys are considered the same:

  ```json
  "query.user-agent": "abc"
  ```

  ```json
  "query.User-Agent": "abc"
  ```

- Comparison of Evidence values MUST be case-sensitive.

## Cache implementation

The system SHOULD allow any cache conforming to a simple interface to be
used.

In general, it has been observed that third-party caches such as Guava tend
to be too slow for this scenario. Instead, the reference implementations use
a custom sharded LRU cache. This ensures that memory use is always well-defined
and that the cache can cope with concurrent requests reasonably well. Most
importantly, it can be kept simple enough to be extremely performant.

Configuration options:

| Name        | Default             | Description                                                           |
|-------------|---------------------|-----------------------------------------------------------------------|
| Size        | 1000                | Number of items stored in the cache before it starts evicting things. |
| Concurrency | Number of CPU cores | Number of shards in the cache.                                        |

[This article](https://medium.com/@yewang2018/lru-cache-design-8257850a69fe)
describes the internals of such a cache. You can also review the
[Java](https://github.com/51Degrees/pipeline-java/blob/master/pipeline.caching/src/main/java/fiftyone/caching/LruCacheBase.java)
, [.NET](https://github.com/51Degrees/caching-dotnet/blob/master/FiftyOne.Caching/LruCacheBase.cs)
and [C](https://github.com/51Degrees/common-cxx/blob/main/cache.c)
reference implementations.

## Data lifetime and concurrency issues

The cache stores the instance of Aspect Data that was generated based
on the Evidence values in the key.

Where [resource cleanup](resource-cleanup.md) is needed, the lifetime
of such data objects is usually tied to the Flow Data that is generated
for that request.

However, cached Aspect Data instances can persist long after the original
Flow Data that resulted in their creation is gone.

Consequently, if the Aspect Data produced by an Engine requires
cleanup, then that Engine MUST NOT allow a cache to be added.

In addition, this functionality can result in a scenario where a single
instance is accessed by multiple threads simultaneously.
If access to the properties of an Aspect Data implementation cannot be
guaranteed to be thread-safe, then the corresponding Engine MUST NOT
allow a cache to be added.

Design note - There are various routes that could potentially be explored
to allow caches to still work in the scenarios described above. (Creating
a duplicate of the instance, reference counting to ensure cleanup happens,
etc.) 51Degrees has decided not to pursue these at present, so the current
implementations simply do not support adding a cache in these cases.
