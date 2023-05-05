# Sequence Element

The Sequence Element is used to keep track of the number of times that
the script produced by the [JavaScript Builder Element](javascript-builder.md)
makes callbacks to the server.

The generated 'session id' is also used as a key in various places.

Note that in this context, 'session' is not necessarily a one to one
mapping to an HTTP session.

## Accepted Evidence

- `query.session-id`
- `query.sequence`

## Element Data

| **Name**   | **Type** | **Description**                                                                       |
|------------|----------|---------------------------------------------------------------------------------------|
| session-id | string   | An identifier for this session.                                                       |
| sequence   | int      | A counter that records how many consecutive callbacks have been made in this session. |

## Process

If `query.session-id` is not present in Evidence then generate a new id and
add it to the output. The reference implementations use a GUID.

If `query.sequence` is present in Evidence then add one to it and add it to
the output. If it is not present, set the output value for sequence to one.

Note that the reference implementations currently write these output values
back to the Evidence collection as Evidence is not implemented as
immutable in the reference implementations.

## Configuration options

None
