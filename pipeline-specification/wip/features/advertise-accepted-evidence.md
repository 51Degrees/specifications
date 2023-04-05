# Summary

All Flow Elements and Pipelines must be capable of programmatically describing 
the evidence keys that they can make use of.

# Flow Elements

For the majority of Flow Elements, simply returning a list of evidence values
they can use would be sufficient.
For example, the device detection engine will accept `query.user-agent`, 
`header.user-agent`, `query.sec-ch-ua`, `header.sec-ch-ua`, etc.

However, in some scenarios, a more complex approach is needed.
The main use-case is the share usage element. The data that this element
shares is configurable, but will typically include all HTTP headers (excluding 
those known to have personally identifiable information). Consequently, listing
all the header names it will accept is impractical. 

It is valid for an element not to make use of any evidence values at all 
(for example, cloud aspect engines - which use the output from the cloud 
request engine)

# Usage

This feature is used to enable or assist with other features.
- [caching]() - cache keys will be generated based on the values of the 
  evidence keys that the engine accepts.
- [web integration]() - Data from the web request is automatically added to
  evidence. Limiting this to only evidence that the pipeline will actually 
  make use of is preferable to adding everything.