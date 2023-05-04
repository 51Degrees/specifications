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
and be called `SuppressProcessExceptions` or similar.

### Flow Elements

Flow Elements can throw exceptions/errors freely, unless it makes
sense for an element to handle a specific error internally.
In general, it is the responsibility of the Pipeline to handle these for
the user as described above.

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
the user can act on it)
