Where the language allows, the pipeline must support a mechanism for the 
caller to cancel processing. This will:
1. Stop any elements that are currently processing as soon as possible.
2. Skip processing for any subsequent elements.

Note that a flowdata instance that has had processing cancelled may be 
missing data that would normally have been populated. 