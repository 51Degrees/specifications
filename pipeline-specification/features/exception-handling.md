# Exception handling

## Overview

Exceptions and errors can occur at many places within the Pipeline
API. It is vital that these are presented and handled consistently.

In general, we aim to follow these principles:

1. Exceptions and errors SHOULD be highly visible (e.g. display error message
   and stop the process) by default in order to highlight issues during
   development.
2. It MUST be possible for the user to configure the system to prioritize
   remaining operational over making failures visible. Many users will
   prefer this for production.

In all cases, standard language features SHOULD be used to
let IDEs and users know what exceptions/errors a particular function can
throw.

Below, we review the various points that errors might occur and bubble
up to the user.

## Process function

One of the key points that failures can occur is in the 'Process' function.
There can be any combination of Flow Elements, including custom
third-party ones in the Pipeline.

Consequently, exceptions and errors will need to be caught at the Pipeline
level.
These errors need to be added to the Flow Data errors
collection. Once all Flow Elements have completed processing, throw an
exception/error with all the stored errors included as sub-errors.

There MUST be an option to modify this behavior to just add these errors
to the errors collection and [log](logging.md) them (I.e. don't throw an
exception/error at the end of processing). This option will be available
when the [Pipeline is created](../conceptual-overview.md#pipeline-builder)
and be called `SuppressProcessExceptions` (**note the plural ending `s`**).

This property MUST be exposed as a public property as part of the `Pipeline` public interface as
`IsSuppressProcessExceptions` - for Pipeline wrappers such as `WebPipeline` to be able to use it
as well to make a decision on whether the exceptions should be suppressed and logged during processing.

### Flow Elements

Flow Elements can throw exceptions/errors freely, unless it makes
sense for an Element to handle a specific error internally.
In general, it is the responsibility of the Pipeline to handle these for
the user as described above. A Flow Element that meets a failed lazy property
while it processes handles it as [lazy properties](#lazy-properties)
describes.

### Parallel groups

A member of a
[parallel group](../advanced-features/parallel-processing.md#how-a-group-uses-the-flow-data)
adds the errors and warnings it records itself to the Flow Data under a lock
while the group runs, as [thread safety](thread-safety.md#flow-data)
describes. An exception or error that a member throws is not added by the
member. The parallel element sees it once every member has stopped, adds it
to the Flow Data's errors, and the Pipeline then handles it as described
above.

### Lazy properties

Work that a Flow Element starts as a
[lazy property](thread-safety.md#lazy-properties) can fail after that Flow
Element's process function has returned. The first reader to meet the
failure while the Flow Data is still being processed records it once in the
Flow Data's errors, as an error of the Flow Element whose Element Data holds
the lazy property, under the errors lock where the reader is a member of a
parallel group, and the Pipeline then handles it as described above. Where
the readers are members of a parallel group, finding whether the failure is
already recorded and recording it are one step under the errors lock, so two
members never both record it. A Flow Element that meets the failure while it
processes, whether it records the failure or finds it already recorded, MUST
NOT add an error of its own for it, and MUST NOT throw it or let the error
from the read leave its process function, because the Pipeline, or the
parallel element, would then add the failure to the Flow Data's errors a
second time. A failure met once processing has finished reaches only the
reader, as an error from the read, because writes to a finished Flow Data
fail, as [thread safety](thread-safety.md#flow-data) describes.

## Flow Data and derived accessors

Apart from the 'Process' function, almost all user interaction is handled
through Flow Data.
The general guidance is that these functions and accessors SHOULD only
throw errors/exceptions if the failure is likely due to something that
the API user has done wrong.

For example, passing a null parameter when a value is mandatory or
attempting to access result data before 'Process' has been called.

These are both things that the user will need to correct by making changes to
their code.

## Web integration

The [web integration](web-integration.md) feature will be hooking into
the web request handling logic of the target language/framework. As such,
it will be executing code outside easily handled areas.

The implementor MUST ensure that exceptions/errors that happen in these areas are
handled correctly in order to avoid the API taking down the customer's
production website.

## Data updates

The [data update](data-updates.md) process runs on a background thread.
Consequently, it is outside any other error handling mechanisms and
will need to handle all its errors internally.

When errors do occur, they will be [logged](logging.md) and MUST NOT
cause the process to crash.

## Custom exceptions/errors

There are several types of error that can be thrown by the Pipeline API.
The precise naming will be language-dependant, but in C#, these are:

### Property Missing Exception

A Property missing exception is thrown if an attempt is made to access a
Property that does not exist in the Flow Data.

See [missing Properties](properties.md#missing-properties) for more details.

### Pipeline Configuration Exception

Can be thrown by any Pipeline, Element or Pipeline/Element builder. This
exception is used to indicate that something in the provided configuration is
preventing the creation or execution of the Pipeline.

### Cloud Request Exception

Can be thrown by the [CloudRequestEngine](../pipeline-elements/cloud-request-engine.md)
following requests to a cloud service. MUST be populated with details
relevant to the failure (For example, when a 429 error occurs, include the
value of the 'Retry-After' header in the exception message so that
the user can act on it).  The underlying exceptions should be passed as part of it.  F.e. if there was an error 
parsing a JSON response from the server - that exception should be added into `CloudRequestException` and 
passed outwards for either logging or handling.
