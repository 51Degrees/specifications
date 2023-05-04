# Process cancellation

Where the language allows, the Pipeline MAY support a mechanism for the
caller to cancel processing. This will:

1. Where possible - cancel processing for any elements that are currently executing.
2. Skip processing for any elements that have not yet started.

Note that a Flow Data instance that has had processing cancelled might be
missing data that would normally have been populated.

The ability to cancel processing implies that the processing takes place
on some background thread. However, the call to `flowdata.Process` is blocking
unless a feature such as [lazy loading](lazy-loading.md) is being used.

To make it clear that the function is non-blocking when a cancellation token
is supplied, we suggest considering a differently named function for that scenario.
(For example, 'ProcessAsync').

A decision on whether to implement will need to consider: 
- The time required to implement the feature
- The impact on the API surface area 
- Impact on documentation 
- Impact on examples
- What alternatives exist to achieve a similar goal (For example, timeouts)