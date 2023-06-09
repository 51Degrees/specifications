# Advertise accepted Evidence

## Summary

All Flow Elements and Pipelines MUST be capable of programmatically
describing the Evidence keys that they can make use of.

## Flow Elements

For the majority of Flow Elements, simply returning a list of Evidence
values they can use would be sufficient.
For example, the Device Detection Engine will accept `query.user-agent`,
`header.user-agent`, `query.sec-ch-ua`, `header.sec-ch-ua`, etc.

However, in some scenarios, a more complex approach is needed.
The main use-case is the
[Usage Sharing Element](../pipeline-elements/usage-sharing-element.md#accepted-evidence).
The data that this Element shares is configurable, but will typically include all
HTTP headers (excluding those known to have personally identifiable information).
Consequently, listing all the header names it will accept is impractical.

Instead, the reference implementations use a filter function that is set
up to return true if the supplied key is accepted by the Element and false
otherwise.

It is valid for an element not to make use of any Evidence values at all
(for example, Cloud Aspect Engines - which use the output from the cloud
request Engine)

## Usage

This feature is used to enable or assist with other features.

- [caching](caching.md) - cache keys will be generated based on the values of
  the Evidence keys that the Engine accepts.
- [web integration](web-integration.md#populating-evidence) - Relevant data
  from a web request is automatically added to Evidence.
