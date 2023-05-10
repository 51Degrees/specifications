# Usage sharing header

Currently, the Usage Sharing Element duplicates
[several values](../pipeline-elements/usage-sharing-element.md#start-up-activity)
for every record in a message.

There is a proposal to reduce the size of the usage sharing payload
by moving these values to a `header` element rather than duplicating them in
every `device` element.

This is a possible future enhancement and it MUST NOT be implemented
in Pipeline APIs. Changes will first need to be made to 51Degrees' data
collection infrastructure.
