# Lazy loading

This feature is specific to properties populated by **Engines** (rather than all 
**Flow Elements**).
It is currently only implemented in .NET and Java.

Lazy loading is a deferred execution feature that allows the user to specify 
that the engine's 'process' functionality should be executed as a background task.

This means that 'process' will return immediately. When the user attempts to access
the value of a property that is populated by this engine, the call must block until 
the background task is complete.

Note that there are many scenarios where lazy loading will be ineffective. This 
is because several core flow elements make use of properties populated by previous 
elements. (For example, cloud aspect engines, json builder, set response headers.)
If one of these elements is in a pipeline and the engine that is populating the 
value used by the element is configured for lazy loading, then the engine's 
process function will return immediately, but the element that makes use of its 
property value will just need to wait for the background task to finish anyway.
