# Multi-Pipeline elements

This feature makes it possible for a Flow Element to be added to multiple
Pipelines once it has been created.

The intention is that this can be used to allow users to create Pipelines
that only do as much processing as they need for different use cases within
a single system.
Without this feature, new Flow Element instances, which may come with
a significant memory footprint, would be needed for each Pipeline.

This causes difficulties for any Flow Elements that maintain some
state information relating to the Pipeline they are added to (For
example, [JSON builder](../pipeline-elements/json-builder.md)).

If this feature is enabled, then all Flow Elements that maintain any
such state information MUST ensure that they have the means to keep track of
isolated instances of this state for each Pipeline to which they are
added and use the correct state information when processing.

Note that it may be preferable for some elements to throw an error if added
to a second Pipeline, rather than implement the logic that would be needed
to allow operation in multiple Pipelines. This approach can only
be used if the element has a very low memory footprint.
