# Logging

The Pipeline API must implement logging, ideally using a popular third-party 
logging library. Whichever library is used, the system should be configurable
without rebuilding binaries and capable of outputting to a log target at a
configurable location.

Ideally, the solution should support logging at multiple levels. This will allow
the customer to configure logging at the level they require and allow 51Degrees
to easily obtain more detailed logs when needed.

An example of the types of messages to assign to different log levels is available
in [Microsoft's documentation](https://learn.microsoft.com/dotnet/api/microsoft.extensions.logging.loglevel)

Care should be taken to ensure that detailed (e.g. debug level) logging does not 
impact performance when it is not enabled.
