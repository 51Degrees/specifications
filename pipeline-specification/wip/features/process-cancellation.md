Where the language allows, the pipeline must support a mechanism for the 
caller to cancel processing. This will:
1. Stop any elements that are currently processing as soon as possible.
2. Skip processing for any subsequent elements.

Note that a flowdata instance that has had processing cancelled may be 
missing data that would normally have been populated. 

The ability to cancel processing implies that the processing takes place 
on some background thread. However, the call to flowdata.process is blocking
unless a feature such as lazy loading is being used.

To get around this, we suggest the use of a differently named function 
(For example, 'ProcessAsync') when a cancellation token is supplied.


