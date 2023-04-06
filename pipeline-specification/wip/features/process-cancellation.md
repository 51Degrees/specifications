# Overview

Where the language allows, the pipeline must support a mechanism for the 
caller to cancel processing. This will:
1. Skip processing for any elements that have not yet started.
2. Where possible - Cancel processing for any elements that are currently executing.

Note that a flowdata instance that has had processing cancelled may be 
missing data that would normally have been populated. 

The ability to cancel processing implies that the processing takes place 
on some background thread. However, the call to `flowdata.Process` is blocking
unless a feature such as lazy loading is being used.

To make it clear that the function is non-blocking when a cancellation token
is supplied, we suggest considering a differently named function for that scenario.
(For example, 'ProcessAsync').


