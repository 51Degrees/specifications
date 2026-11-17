# Lazy loading

Lazy loading is deprecated, and setting it has no effect. Every Engine
processes on the thread that processes the Flow Data, whether the option is
set or not. An implementation that offers the lazy loading option keeps
accepting it, with its timeout, as a deprecated public name, so that existing
code and configuration still build and run. Its code comments and
documentation MUST say that it is deprecated and has no effect, and point to
lazy properties.

The route for long-running work in a Flow Element is a
[lazy property](../features/thread-safety.md#lazy-properties) whose task the
Flow Element starts while it processes, as the
[Cloud Request Engine](../pipeline-elements/cloud-request-engine.md#processing)
does with its HTTP request. An Engine does not run its processing in a
background task.
