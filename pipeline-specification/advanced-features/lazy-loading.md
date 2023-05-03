# Lazy loading

This feature is specific to Properties populated by Engines (rather than all
Flow Elements).
It is currently only implemented in .NET and Java.

There are several execution strategies one might consider for the Process function.
For example:

- Eager blocking, standard execution
- Eager non-blocking, but then request to get the result value blocks
- Lazy non-blocking, the computation starts at the point of requesting the result value
- Eager asynchronous, that is awaited (allowing the thread do run loop execution)

This feature, as currently implemented, corresponds with the eager, non-blocking
strategy from the list above. This may lead to renaming the feature in future. For
the time being, in order to be consistent, it will be called 'lazy loading'.

This means that 'process' will return immediately. When the user attempts to access
the value of a Property that is populated by this Engine, the call will block until
the background task is complete.

Some languages may have async/await features that may appear to be a good fit for
handling this type of execution in a neater way. There is no rule in this
specification against using such features. However, the implementation will need
to be carefully considered in order to avoid falling into the trap of adding
complexity for little real-world benefit.

Note that there are many scenarios where lazy loading as described here will be
ineffective. This is because several core Flow Elements make use of Properties
populated by previous elements. (For example, Cloud Aspect Engines, JSON builder,
set response headers.)
If one of these elements is in a Pipeline and the Engine that is populating the
value used by the element is configured for lazy loading, then the Engine's
process function will return immediately, but the element that makes use of its
Property value will just need to wait for the background task to finish anyway.

