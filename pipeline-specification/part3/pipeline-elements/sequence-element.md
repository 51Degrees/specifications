# SequenceElement

## Overview

The sequence element is used to keep track of the number of times that 
the script produced by the [JavaScript builder](javascript-builder.md) 
makes callbacks to the server.

The generated 'session id' is also used as a key in various places.

Note that in this context, 'session' is not necessarily a one to one 
mapping to an HTTP session.   

## Accepted evidence

- query.session-id
- query.sequence

## Element data

| **Name**   | **Type** | **Description**                                                                       |
|------------|----------|---------------------------------------------------------------------------------------|
| session-id | string   | An identifier for this session.                                                       |
| sequence   | int      | A counter that records how many consecutive callbacks have been made in this session. |

## Process

If `query.session-id` is not present in Evidence then generate a new id and 
add it to the output. We generally use GUIDs, but this is up to the implementor.

If `query.sequence` is present in Evidence then add one to it and add it to
the output. If it is not present, the the output value for sequence to one.

Note that the reference implementations currently write these output values 
back to the Evidence collection as evidence was not originally implemented as 
immutable.

## Configuration options

None