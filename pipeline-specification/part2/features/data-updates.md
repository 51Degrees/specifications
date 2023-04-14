TODO - Write these points up properly. Consider migrating existing content from old document, 
including logic flow diagrams or some higher-level variation of them.

- Engines often have one or more associated data files.
- There must be a feature that allows these data files to be updated
  automatically.
- The engine should take all steps to minimize blocking of process requests
  during the data update process. (a small amount of blocking is generally
  unavoidable)
- Support for filesystem-less environments. I.e. the file data only ever exists
  in memory.
- Requirement for engines to support multiple data files (TODO - is this really needed? 
  Only engine that used this was geomprint cloud engine and it is no longer maintained.
  We could remove a bit of complexity by dropping the requirement)

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
- logging should be used to give users a clear picture of what is happening
  should they want it.
- Events, callbacks, etc should be used to allow users to act on updates
  starting/completing.


# Overview

Automatic data updates is a feature for on-premise **Aspect Engines**
that use one or more data files.

By 'data file' we mean some external resource that is used as part of 
the processing that the engine performs.

Such data files are typically separated out from the actual processing 
logic of the engine because they need to change over time. For example, 
when new phones or browser versions are released, the device detection 
engine will require a new data file in order to detect and populate 
property values for those new cases.

The data updates feature provides various mechanisms to support and
simplify the refreshing of these data files as new ones become available.

Note that there are two primary mechanisms that support different use-cases:

1. Use the file system to store data file content. Each data file will 
   have two locations in the file system. One for the 'user-facing' data 
   file. Another for a temporary location that contains a copy of the file 
   for use during processing.
   This ensures that the user-facing location can be updated in various 
   ways without impacting the operation of the engine.
2. In order to support environments without a file system, we allow data 
   file content to be supplied entirely in memory.

# Aspect Engine logic

In order to support this feature, **Aspect Engines** need to have a 
couple of additional abilities:

1. At build time, there must be a mechanism for supplying details about 
   the data file(s) that the engine needs along with any information 
   and configuration options associated with updating it.
2. The engine must provide a mechanism to allow callers to tell it to
   refresh its internal data structures.

## Data file update configuration

The table below shows the parameters associated with data updates for each 
data file. Some come from the data file itself, others are configured by 
the user.

| **Parameter**                     | **User configurable** | **Optional**                                      | **Default**                             | **Notes**                                                                                                                                                                                                                                                                                            |
|-----------------------------------|-----------------------|---------------------------------------------------|-----------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Data publish date/time            | N                     | N/A                                               | Read from data file                     | The time that the current data file was created.                                                                                                                                                                                                                                                     |
| Next expected update date/time    | N                     | N/A                                               | Read from data file                     | The time that a new data file is expected to be available.                                                                                                                                                                                                                                           |
| Data file location                | Y                     | N (not required if engine is built from a byte[]) | N/A                                     | The location of the data file that the service will update and check for updates. The engine will copy this file to the temp data file location before using it.                                                                                                                                     |
| Temp data file location           | N                     | N/A                                               | Machine-specific temp location          | The location of the data file that the engine will actively read data from.                                                                                                                                                                                                                          |
| Auto update enabled flag          | Y                     | Y                                                 | True                                    | If false then the service should not do any checks for updates from the URL or to the file. Manually calling the update methods must still work though.                                                                                                                                              |
| Data update URL                   | Y                     | Y                                                 | Read from data file                     | Default will initially be hard coded in the engine rather than actually stored in the data file.                                                                                                                                                                                                     |
| Data update URL formatter         | Y                     | Y                                                 | null, or FiftyOneDataUpdateUrlFormatter | The default is automatically set for all 51Degrees engines that use the Distributor service for data file updates. Otherwise, it will default to 'null', which means the Data Update URL will be used un-modified when checking for updates.                                                         |
| Data update use URL formatter     | Y                     | Y                                                 | True                                    | If set to true, the URL formatter will be used to format the update URL. If set to false, the formatter will be ignored and the data update URL will be used un-modified. This is the same as setting URL formatter to null. This setting exists to allow this to be done from a configuration file. |
| File system watcher enabled flag  | Y                     | Y                                                 | True                                    | May not be available for all languages. If set to true then the update service will watch the data file location and notify the engine if the file changes. (The file system watcher should be disabled while downloading a new file, etc)                                                           |
| Polling interval                  | Y                     | Y                                                 | 30 minutes                              | If the expected time has passed with no update available then the polling interval gives the time to wait between checking for updates from the URL or to the file (if file system watcher is available then checking the file is not necessary).                                                    |
| Update time maximum randomization | Y                     | Y                                                 | 10 minutes                              | This setting is the maximum random additional time period that is added to the next expected update date/time and the polling interval. It should be specified in seconds or, if available, some TimeSpan object.                                                                                       |
| VerifyMd5                         | Y                     | Y                                                 | True                                    | If true then the service will expect a ‘content-md5’ HTTP header to be populated in the response. It will check this against the content to ensure its integrity.                                                                                                                                   |
| Decompress                        | Y                     | Y                                                 | True                                    | If true then the service will automatically decompress the content returned from the data update URL.        |                                                               

### Data file configuration builder

We have found that separating the data file configuration options into 
a builder that is separate from the 
[engine builder](../../conceptual-overview.md#flow-element-builder) is 
helpful.

Engines that only need one data file may have builders that hide this 
complexity from the user and just appear to have the options available 
on the engine builder directly.                                                  

## Engine data refresh

Data refresh is the process of loading data from an external source into 
the in-memory data structures that will be used during processing.

The Pipeline must still be capable of serving requests with minimal 
performance impact while data refresh is happening.

Each **Aspect Engine** will need to provide two data refresh functions:

1. Take some data file configuration identifier, access the associated 
   configuration object that was supplied at construction time to find
   the location of the file on disk.
   The temp data file will need to be updated with the new one from the 
   'real' data file location and in-memory data structures refreshed.
2. Take some sort of in-memory data structure containing a byte 
   representation of the data file. This could be something simple like 
   a `byte[]` or something more complex like a c\# `MemoryStream`.
   The engine's in-memory data structures must be refreshed from this 
   data.

# Checking for updates