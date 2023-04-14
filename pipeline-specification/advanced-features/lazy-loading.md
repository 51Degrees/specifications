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

<span style="color:yellow">
If I understand correctly Process() still does start the background task in this case
so it is not exactly purely lazy.  Classic `lazy` computation would actually defer starting the task to the point when the 
property value is requested. So if this is still `eager` computation just happening in background - then perhaps
it is worth renaming it to background processing.

Alterantively some languages supporting syntactic concurrency via async/await keywords, or even supporting
it thru library features s.a. promises/futures - may benefit from defining yet another type of processing that would be
an eager but explicitly asynchronous computation - where Process() would return an awaitable/promise and that would 
allow the current thread to continue run loop execution while the results are awaited at the point of
call:

await flowData.Process();

So perhaps some languages/implementations can support 4 modes of execution:
- eager blocking call to Process()
- eager non-blocking call to Process(), but then value request blocks
- lazy non-blocking call to Process(), the computation starts at the point of requesting the value
- eager asynchronous call to Process(), that must be awaited (allowing the thread do run loop execution)

However the use cases must be carefully considered, perhaps eager blocking and eager non-blocking calls are all that are needed.  
The second plays nicely with the [Cancellable feature](process-cancellation.md). 

</span>