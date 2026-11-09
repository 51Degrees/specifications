# Advertise accepted Evidence

## Summary

All Flow Elements and Pipelines MUST be capable of programmatically
describing the Evidence keys that they can make use of.

## Flow Elements

For the majority of Flow Elements, simply returning a list of Evidence
values they can use would be sufficient.
For example, the Device Detection Engine will accept `query.user-agent`,
`header.user-agent`, `query.sec-ch-ua`, `header.sec-ch-ua`, etc.

Where listing the keys is impractical, a Flow Element can use a filter
function that returns true if the supplied key is accepted by the Element and
false otherwise.

An Element MUST accept only the Evidence that can change its results, because
the Pipeline's accepted Evidence decides the cache keys, the ETag and the Vary
header. It is valid for an element not to make use of any Evidence values at
all. Cloud Aspect Engines, which use the output from the Cloud Request Engine,
accept none. The
[Usage Sharing Element](../pipeline-elements/usage-sharing-element.md#accepted-evidence)
accepts none either. It shares what it finds in the Flow Data and in the web
request, and none of that changes a result.

## Usage

This feature is used to enable or assist with other features.

- [caching](caching.md) - cache keys will be generated based on the values of
  the Evidence keys that the Engine accepts.
- [web integration](web-integration.md#populating-evidence) - Relevant data
  from a web request is automatically added to Evidence.
