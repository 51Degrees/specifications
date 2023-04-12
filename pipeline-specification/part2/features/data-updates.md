TODO - Write these points up properly. Consider migrating existing content from old document, 
including logic flow diagrams or some higher-level variation of them.

- Engines often have one or more associated data files.
- There must be a feature that allows these data files to be updated
  automatically.
- The engine should take all steps to minimize blocking of process requests
  during the data update process. (a small amount of blocking is generally
  unavoidable)
- Support Update on startup
- Allow randomization of update time
- Support MD5 <span style="color:yellow">validation of downloaded files</span>
- Support decompression of downloaded file
- Support if-modified-since header - using values from the data file that are
  exposed by the engine <span style="color:yellow">or some other mechanism if the data file doesn't contain its own update time</span>
- Support for customizable flat or parameterized URLs (where parameters based on
  values in the data file and exposed by the engine)
- Support for the user updating the file on disk, causing the engine to reload
  its in-memory data.
- Support for manually forcing a refresh of the data file from code.
- Support for filesystem-less environments. I.e. the file data only ever exists
  in memory.
- logging should be used to give users a clear picture of what is happening
  should they want it.
- Events, callbacks, etc should be used to allow users to act on updates
  starting/completing.
- Requirement for engines to support multiple data files (TODO - is this really needed? 
  Only engine that used this was geomprint cloud engine and it is no longer maintained.
  We could remove a bit of complexity by dropping the requirement)