# Data update

## Overview

An on-premise **Aspect Engine** may require data that is independent of the
logic of the Engine and that is periodically refreshed. For example,
when new phones or browser versions are released, the Device Detection
Engine will require a new data file in order to detect and populate
Property values for those new cases. The Data Update Service
provides functionality for this.

The Data Update Service assumes that the data is available from an HTTP
endpoint or that it can be provided by means of file store that is accessible
to an instance of the Aspect Engine.

It is possible that an Aspect Engine requires more than one data source [^1] and
implementers may choose either to provide the data in a single unified way
or to implement the Data Update service to allow for multiple file sources.

[^1] data sources are referred to as data files in the reference implementations

### Aspect Engine features

In order to support this feature, **Aspect Engines** must have
some additional abilities:

1. At configuration time, there must be a mechanism for supplying details about
   the data sources that the Engine needs along with any information
   and configuration options associated with updating it.
2. The Engine must provide a mechanism to allow it to refresh,
   (use an updated data source) on demand.
3. The mechanism must be thread safe.

The Pipeline that contains the Aspect Engine must still be capable of
processing Flow Data with minimal
performance impact while data refresh is happening.

## Data refresh availability

A data source may contain a timestamp that specifies when it was created and may
contain a timestamp that indicates when refreshed data will be available. This
information can be used to optimize polling, or to provide information as to
how up-to-date the current data is.

## Operational modes

From the point of view of the Data Update Service, Aspect Engines have several
operational modes:

- File Data Source, File Based Operation
- File Data Source, Memory Based Operation
- Memory Data Source, Memory Based Operation

Other operational modes may be possible, such as an Aspect Engine's data residing
in a relational database.

### File data source, file based operation

In this operational mode an Aspect Engine uses data that
resides in the file system to support its operation. This may be because the
data is too extensive to be loaded into memory or because of memory limitations
in the system.

### File data source, memory based operation

In many cases, for reasons of access speed, it is desirable for the data, which
is provided in a file, to be loaded into memory on start-up and on refresh.

### Memory data source

In some cases, to provide for fully disk-less operation, it may be desirable
for an Aspect Engine to obtain its data
as a memory buffer on start-up and on refresh.

## Operational options

A number of options control the operation of the Data Update Service. Not all
options are available in every mode and some combinations of options are
either mutually exclusive or unlikely to be useful. For example, it's unlikely
that an Aspect Engine will be configured with both the ability to update
from a disk based data file and update from HTTP.
Providing for both being active at the same time adds complexity to the
implementation.

Implementations may choose to report an error when inconsistent configuration
options are chosen.

### Update on start-up

This option provides for checking for data from an HTTP server on start-up
as a blocking operation.

This option is available both for memory data source mode and for file data
source modes. If the data source provides a timestamp then the remote timestamp
is compared with the local timestamp, and the remote data is used if it is more
recent than the current data.

This option can be used to bootstrap an Aspect Engine that does not yet have
any local data. In the case of file data source, the data is stored once
obtained via HTTP.

Configuration Groups:
- *HTTP config*

### Automatic update via HTTP

This option provides for periodic ongoing checking of an HTTP server
for the availability of an updated data source.

If the current data contains a *data update expected* timestamp, then polling
should start after that time. Options include the ability to control the remote
endpoint and the polling frequency.

As an optimization, the request for data may contain an *if modified since* HTTP
header, containing the date of the current data file.

If data is received that is newer than the current data, then the Aspect Engine
is refreshed with the newly available data. In the case of
file data source operation, the new data replaces
the existing data, at the location configured for data files.

51Degrees download servers have a request rate limiting feature which provides
for a 429 HTTP Status (Too many requests) with a *Retry After* HTTP header
whose value should be used to reset polling.

Rate limiting may be triggered
in the event that a single user has multiple servers each of which is set to
auto update. It is recommended that users with multiple servers do not use
this feature and that they obtain updated data once and distribute it to their
various servers by other means.

Configuration Groups:
- *HTTP config*
- *Polling config*
- *Operational file config*

### Automatic update from File

This option allows users to obtain new data files by whatever means they choose,
and have the Aspect Engine refresh by detection of a new file in the file system
at the location configured for the data file.

Any timestamp contained in the data source is not taken into consideration,
operation depends on the operational environment reporting file system changes
and whatever file is found is used as the data source for the restarted
Aspect Engine.

If the operational environment does not support file system watching events,
implementors may need to use polling to determine changes and should have
due regard to file system load when setting polling frequency.

### Programmatic update

The option allows for programmatic triggering of an update. The effect of a
programmatic update is to initiate
immediate polling of the remote HTTP server, where this option is enabled.

If it is automatic update via HTTP is not enabled, for file data sources
it causes immediate update, irrespective of whether Automatic Update
from File is enabled.

For memory data sources programmatic update must allow provision of the new memory data source.

Implementations may choose to provide options of Programmatic Update that
distinguish a request for HTTP update as opposed to file update.

Configuration Groups:
- *HTTP config*
- *Polling config*
- *Operational file config*

## Configuration groups

### HTTP config

Configuration of the remote endpoint for download:
- **dataUpdateUrl** - the remote URL
- **urlFormatter** - URL customization
- **useIfModifiedSince** - request data using if modified since HTTP header
- **decompressContent** - deprecated - always decompress content if it is compressed
- **verifyMD5** - deprecated - always verify MD5 if an MD5 value is provided

### Polling config

Configuration of the frequency for checking of new content:
- **pollingInterval** - frequency of polling of server
- **randomization** - provide a variation of polling frequency to avoid
  synchronized requests from more than one server

### Operational file config

Configuration of the locations that disk based operation is done from:
- **dataSourceFileLocation** - where to load the data source fom
- **createOperationalDataCopy** - create a copy of the data source, for operation
- **operationalDataFileDirectory** - the directory for the data file copy

For disk based operation it is necessary to create an Operational Data Copy [^1] if
auto update via HTTP is enabled or if auto update from file is enabled. This is
to allow continued operation of the Aspect Engine with its present data file
while a new data file is made available.

[^1] This is called *tempDataFile* in current reference implementations.

Since creating a data file copy is required for disk based operation
implementations may choose not to provide control over
**createOperationalDataCopy** since disallowing it when either update option
is enabled and disk based operation is enabled is an error.

Implementations may choose to report an error if any item
in this configuration is set for memory data source operation.

## Update processes

### Update on start-up

- for disk data source, check operational data configuration consistency
- check HTTP server for new file
  - on fail, fall back to local file if any
    - no local file, fail
- compare date with local
  - if newer or there is no local file,
    - save new file
  - load file
- if disk data source, configure file watcher, if requested
- configure HTTP update polling, if requested
- continue

### Other start-up

- check operational data configuration consistency
- load data from memory or file
- if disk data source, configure file watcher, if requested
- configure HTTP update polling, if requested
- continue

### newBufferAvailable (from memory, via remote)

Probably can't compare dates so load whatever we have:
- load buffer

### newFileAvailable (via remote or file watcher)

The file will be in **dataFilePath** from watcher or from download, if the
downloaded file is newer than the current file
- pause file watcher, if any
- pause update polling, if any
- load file
- resume polling, if any
- resume file watcher, if any
- trigger onUpdateCallbacks

### Programmatic update

- poll remote, if polling is configured
  - check if file is newer
    - if so, process as per newFile above
  - return
- if newer file in **dataFilePath**
  - process as per newFile above
  - return

## Update polling

This section making an HTTP request to check for
updated data and handling the response.

51Degrees Device Detection data files are supplied by the
[Distributor](http://51degrees.com/documentation/_info__distributor.html)
web API. The capabilities of the data update service align with those of
the Distributor. However, the service must be capable of using other sources
as well. For example, a simple static URL that just supplies a file.

When sending a request to the *data update URL*, the `If-Modified-Since`
header should be set to the publication date of the existing data file.
If the data file does not have a publication date then the file system last modified
date/time can be used instead. This ensures that if a new data file has not
been published yet, we won't waste bandwidth downloading it.

There must be some mechanism for the update service to add query parameters
to the data update URL when needed.
The reference implementations use a 'URL formatter' class. Below are the
implementations used for calls made to the Distributor.

- [.NET FiftyOneUrlFormatter](https://github.com/51Degrees/pipeline-dotnet/blob/master/FiftyOne.Pipeline.Engines.FiftyOne/Data/FiftyOneUrlFormatter.cs)
- [Java FiftyOneUrlFormatter](https://github.com/51Degrees/pipeline-java/blob/master/pipeline.engines.fiftyone/src/main/java/fiftyone/pipeline/engines/fiftyone/data/FiftyOneUrlFormatter.java)

If a new data file is downloaded, the date of the downloaded data must be
compared with the current file data source, if file data source mode is active.
If the downloaded file is more recent, it replaces the current file data source.

If the data downloaded is more recent or if memory data source mode is in
operation the **Aspect Engine** is refreshed with the new data.

Once the refresh is complete, the data update service can start
checking for updates using the newly refreshed *next expected update*
date/time.

If no update was found then the service should repeat the same checks
after the *polling interval* + a random time based on  
*update time maximum randomization* has passed.

## Logging

The data update service is a complex process. As such, it is
essential that detailed logging is
available to help diagnose issues that might arise.

All major actions should be logged at the appropriate level along with
relevant details (e.g. which Engine + data file the update is for)

### Messages at start-up

| **Action**                            | **Message**                  |
|---------------------------------------|------------------------------|
| Running the update on start-up process | Updating on start-up          |
| File system watcher created           | Creating file system watcher |

### Messages during operation

| **Action**                                           | **Message**                                                                     |
|------------------------------------------------------|---------------------------------------------------------------------------------|
| Starting the check for update process                | Checking for update                                                             |
| Call [refresh](#aspect-engine-features) on an Engine | Attempting to refresh Engine '\<Engine type\>' with new data                    |
| Send HTTP request to check for new data file         | Checking for update from '\<url\>' for Engine '\<Engine type\>'                 |
| Successfully downloaded new data file                | Downloaded new data from '\<url\>' for Engine '\<Engine type\>'                 |
| 304 (Not modified) response from HTTP request        | No data newer than \<datetime\> found at '\<url\>' for Engine '\<Engine type\>' |

### Errors

There are several possible causes of errors within the data update service.
As this is a background service, we must ensure that any failures are
caught and logged, rather than being lost or causing process failures.

These messages must also be consistent across languages to make life easier
for 51Degrees support.

[***Highlighted***] text should only be present if this is an automated update rather
than a procedural update.

| **Error**                                                                                                                       | **Log level** | **Message**                                                                                                                                                                                  |
|---------------------------------------------------------------------------------------------------------------------------------|---------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Could not connect to remote server for data file update                                                                         | Warning       | An error occurred when connecting to \<url\> in order to check for data file updates for \<Engine type name\>. [***Update will be attempted again later.***] Error detail: \<error message\> |
| Error downloading file                                                                                                          | Warning       | An error occurred while downloading a data file update for \<Engine name\> from \<url\>. [***Update will be attempted again later.***] Error detail: \<error from distributor\>             |
| Error validating data file                                                                                                      | Warning       | An error occurred during the integrity check of new data file for \<Engine name\>. [***Update will be attempted again later.***] Error detail: \<error\>                                     |
| Error writing to *data file location* or *temp file location*                                                               | Error         | An error occurred when writing to \<file path\>. Error detail: \<error\>                                                                                                                     |
| Engine was built from a file with the ‘use temp file’ flag disabled. And the file at *data file location* is currently locked | Error         | Unable to update data file. This is probably because the Engine was built with the ‘use temp file’ option disabled.                                                                          |
| Error when calling RefreshData on Engine                                                                                        | Error         | An error occurred while applying a data file update to \<Engine type name\>. Error detail: \<error\>                                                                                         |
| Attempting to update a data file that has no configured temporary file path                                                     | Error         | The data file '\<data file identifier\>' is checking for updates but does not have a temporary file path configured.                                                                         |
| Some file system error occurs while copying a new data file                                                                     | Error         | An error occurred when copying a data file to replace the existing one at '\<path\>'.                                                                                                        |
