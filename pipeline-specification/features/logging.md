# Logging

The Pipeline API MUST implement logging, ideally using a popular third-party
logging library. Whichever library is used, the system SHOULD be configurable
without rebuilding binaries and capable of outputting to a log target at a
configurable location.

Ideally, the solution will support logging at multiple levels. This will allow
the customer to configure logging at the level they require and allow an engineer
to easily obtain more detailed logs when needed.

An example of the types of messages to assign to different log levels is available
in [Microsoft's documentation](https://learn.microsoft.com/dotnet/api/microsoft.extensions.logging.loglevel)

Testing will be needed to ensure that detailed (e.g. debug level) logging does not
impact performance when it is not enabled.

## License keys

A license key MUST NOT appear in a log entry or in an error message, at any log
level. A license key is a paid credential, and logs and error messages
travel further than the server, to log services, to support tickets and,
through the [JSON Builder's](../pipeline-elements/json-builder.md) `errors`
list, to the browser.

Some URLs carry a license key in their query, such as the URL a
[data update](data-updates.md) request is sent to. A message that names such a
URL MUST name it with the key removed or replaced by a placeholder. The same
applies to the message of an error raised by an HTTP library, which often
includes the URL it requested.

There MUST be a test that a failed request carrying a license key produces log
entries and error messages that do not hold the key.
