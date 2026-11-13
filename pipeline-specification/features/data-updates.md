# Data update

## Overview

An On-Premise Aspect Engine can require data that is independent of the
logic of the Engine and that is periodically refreshed. For example,
when new phones or browser versions are released, the Device Detection
Engine will require new data in order to detect and populate
Property values for those new cases. The Data Update Service
provides functionality for this.

The Data Update Service assumes that the data is available from an HTTP
endpoint or that it can be provided by means of file store that is accessible
to an instance of the Aspect Engine.

A package whose processes last for one request, such as PHP's, has no Data
Update Service, as none of its processes lives long enough to poll or watch
for new data. The parts of this page about the service do not apply to such a
package, and the [Aspect Engine features](#aspect-engine-features) still do.

It is possible that an Aspect Engine requires more than one data source [^1] and
implementers can choose either to provide the data in a single unified way
or to implement the Data Update service to allow for multiple sources.

[^1]: This is not currently the case, but was required for a discontinued
Engine and may be needed again in the future.

### Aspect Engine features

In order to support this feature, Aspect Engines require
some additional abilities:

- At configuration time, there MUST be a mechanism for supplying details about
  the data sources that the Engine needs along with any information
  and configuration options associated with updating it.
- The Engine MUST provide a mechanism to allow it to refresh
  (use an updated data source) on demand.
  - This mechanism MUST be thread safe.
  - If the updated data source cannot be used, the refresh MUST fail with an
    error, and the Engine MUST go on using the data source it had, so that
    processing is unaffected.

The Pipeline that contains the Aspect Engine MUST still be capable of
processing Flow Data with minimal
performance impact while data refresh is happening.

## Data refresh availability

A data source might contain a timestamp that specifies when it was created and might
contain a timestamp that indicates when refreshed data will be available. This
information can be used to optimize polling, or to provide information as to
how up-to-date the current data is.

## Operational modes

From the point of view of the Data Update Service, Aspect Engines have several
operational modes:

- File data source, file based operation
- File data source, memory based operation
- Memory data source, memory based operation

Other operational modes are theoretically possible, such as an Aspect Engine's data residing
in a relational database.

### File data source, file based operation

In this operational mode an Aspect Engine uses data that
resides in the file system to support its operation. This might be because the
data is too extensive to be loaded into memory or because the benefit of
doing so is not considered worthwhile.

### File data source, memory based operation

In many cases, for reasons of access speed, it is desirable for the data, which
is provided in a file, to be loaded into memory on start-up and on refresh.

### Memory data source

In some cases, to provide for fully disk-less operation, it might be desirable
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

Implementations MAY choose to report an error when inconsistent configuration
options are chosen.

### Automatic update master switch

The **autoUpdate** option is the master switch for *Automatic update via
HTTP* (polling). When it is disabled, polling does not take place, however it
is configured.

*Automatic update from File* (file system watching) does not depend on
autoUpdate. The file system watcher runs on its own setting, whether autoUpdate
is enabled or disabled, because watching a file downloads nothing.

A License Key is needed only for the two mechanisms that download, which are
polling and the [update on start-up](#update-on-start-up). The file system
watcher needs no License Key.

This master switch does not disable *Programmatic update*, which remains
available for triggering an update manually (see
[Programmatic update](#programmatic-update)).

Configuration Groups:

- *General config*

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

This is an automatic update mechanism, so it only operates when the
[autoUpdate master switch](#automatic-update-master-switch) is enabled.

If the current data contains a *data update expected* timestamp, then polling
will not start until after that time. Options include the ability to control the remote
endpoint and the polling frequency.

As an optimization, the request for data MAY contain an `If-Modified-Since` HTTP
header, containing the date of the current data file.

If data is available that is newer than the current data, then it will be
downloaded and used to refresh the Aspect Engine. In the case of
file data source operation, the new data replaces
the existing data, at the location configured for data files.

51Degrees [download servers](https://51degrees.com/documentation/_info__distributor.html?utm_source=github&utm_medium=docs&utm_campaign=specifications&utm_content=pipeline-specification-features-data-updates.md&utm_term=automatic-update-via-http)
have a request rate limiting feature which provides
for a 429 HTTP Status (Too many requests) with a `Retry-After` HTTP header
whose value can be used to reset polling.

Rate limiting can be triggered
in the event that a single user has multiple servers, each of which is set to
auto update. It is expected that users with multiple servers do not use
this mechanism. Instead, they would obtain updated data once, distribute it
to their various servers by other means and then use the
[update from file](#automatic-update-from-file) functionality.

Configuration Groups:

- *General config*
- *HTTP config*
- *Polling config*
- *Operational file config*

### Automatic update from File

This option allows users to obtain new data files by whatever means they choose,
and have the Aspect Engine refresh by detection of a new file in the file system
at the location configured for the data file.

The file system watcher runs on its own setting, whether the
[autoUpdate master switch](#automatic-update-master-switch) is enabled or
disabled. Watching a file downloads nothing, so the watcher needs no License
Key. An application with no License Key, such as one running the free Lite data
file, can put a new file in place and the Aspect Engine refreshes from it.

Any timestamp contained in the data source is not taken into consideration,
operation depends on the operational environment reporting file system changes
and whatever file is found is used as the data source for the restarted
Aspect Engine.

If the operational environment does not support file system watching events,
implementors might need to use polling to determine changes and have
due regard to file system load when setting polling frequency.

Configuration Groups:

- *General config*
- *Operational file config*

### Programmatic update

The option allows for programmatic triggering of an update. The effect of a
programmatic update is to initiate
immediate polling of the remote HTTP server, where this option is enabled.

If automatic update via HTTP is not enabled and a file data source is specified
then it causes immediate refresh of the Engine using the file at the configured
location, irrespective of whether Automatic Update from File is enabled.

For memory data sources, programmatic update MUST allow provision of the new
memory data source.

Implementations MAY choose to provide options of Programmatic Update that
distinguish a request for HTTP update as opposed to file update.

Configuration Groups:

- *HTTP config*
- *Polling config*
- *Operational file config*

## Configuration groups

### General config

Configuration that governs update activity as a whole:

- **autoUpdate** - master switch for automatic update via HTTP (polling). When
  disabled, polling does not take place, regardless of its configuration.
  Automatic update from file (file system watching) and programmatic (manual)
  update are not affected. See
  [Automatic update master switch](#automatic-update-master-switch).
- **Automatic update from file** (the file system watcher) - whether the
  location of the data file is watched for a new file. It is its own setting,
  independent of autoUpdate. See
  [Automatic update from File](#automatic-update-from-file).

### HTTP config

Configuration of the remote endpoint for download:

- **dataUpdateUrl** - the remote URL
- **urlFormatter** - URL customization
- **useIfModifiedSince** - request data using `If-Modified-Since` HTTP header
- **decompressContent** - deprecated - always decompress content if it is compressed
- **verifyMD5** - deprecated - always verify MD5 if an MD5 value is provided

### Polling config

Configuration of the frequency for checking of new content:

- **pollingInterval** - frequency of polling of server
- **randomization** - provide a variation of polling frequency to avoid
  synchronized requests from more than one server

### Operational file config

Configuration of the locations that disk based operation is done from:

- **dataSourceFileLocation** - where to load the data source from
- **createOperationalDataCopy** - create a copy of the data source, for operation
- **operationalDataFileDirectory** - the directory for the data file copy

For disk based operation it is necessary to create an Operational Data Copy [^2]
if auto update via HTTP is enabled or if auto update from file is enabled. This is
to allow continued operation of the Aspect Engine with its present data file
while a new data file is made available.

[^2]: This is called *tempDataFile* in current reference implementations.

Since creating a data file copy is necessary for disk based operation,
implementations MAY choose not to provide control over
*createOperationalDataCopy* since disallowing it when either update option
is enabled and disk based operation is enabled is an error.

Implementations MAY choose to report an error if any item
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
- if autoUpdate is enabled (see [master switch](#automatic-update-master-switch)):
  - configure HTTP update polling, if requested
- continue

### Other start-up

- check operational data configuration consistency
- load data from memory or file
- if disk data source, configure file watcher, if requested
- if autoUpdate is enabled (see [master switch](#automatic-update-master-switch)):
  - configure HTTP update polling, if requested
- continue

### newBufferAvailable (from memory, via remote)

Probably can't compare dates so load whatever we have:

- load buffer
  - on fail, the Engine keeps the data it had. A failure with a buffer that
    update polling downloaded is reported and logged as for newFileAvailable.
    A failure with a buffer passed in by a programmatic update from memory
    fails that call with an error, which is not logged or reported to
    onUpdateCallbacks

### newFileAvailable (via remote or file watcher)

The file will be in *dataFilePath* from watcher or from download, if the
downloaded file is newer than the current file. A watched or downloaded file
that is not newer is not loaded, and the check is reported as not needed, as
[reporting each check](#reporting-each-check) says.

- pause file watcher, if any
- pause update polling, if any
- load file
  - on fail, the Engine keeps the data it had. Report the failure, not
    success, to onUpdateCallbacks, and log it as [errors](#errors) describes,
    apart from a programmatic check, which passes the error to its caller
    instead of logging it
- resume polling, if any, whether or not the file loaded
- resume file watcher, if any, whether or not the file loaded
- trigger onUpdateCallbacks with success, if the file loaded

### Programmatic update

- for a data file the Engine has no configuration for, return the no
  configuration status to the caller, report nothing and stop
- poll remote, if polling is configured
  - check if file is newer
    - if so, process as per newFile above
    - if not, report the check as not needed
  - return
- if newer file in *dataFilePath*
  - process as per newFile above
  - return
- otherwise, report the check as not needed
- on fail, report the failure to onUpdateCallbacks, then pass the error to
  the caller without logging it

### Reporting each check

A check for an update MUST be reported to onUpdateCallbacks once it ends,
including the checks made by update polling, by the file watcher, by the
update on start-up and by a programmatic call. A report names the data file
and gives one status. The status names are those of the .NET data update
service.

- Success (`AUTO_UPDATE_SUCCESS`), when the Engine was refreshed with new data.
- Not needed (`AUTO_UPDATE_NOT_NEEDED`), when no update was applied because
  none was needed, for example a 304 (Not modified) response, a downloaded or
  watched file that is not newer than the current file, or a check with no
  update URL set and no newer file.
- In progress (`AUTO_UPDATE_IN_PROGRESS`), for a file watcher event that
  found nothing left to do, being one that waited while another event for the
  same file was applied, or one from a watcher that does not belong to exactly
  one registered data file.
- A failure status naming its cause, when the check or the refresh failed, as
  [errors](#errors) lists.

Two calls report nothing to onUpdateCallbacks, and give their result to the
caller instead. A programmatic check for a data file the Engine has no
configuration for returns the no configuration status
(`AUTO_UPDATE_NO_CONFIGURATION`), and an update from memory returns success or
fails with an error.

## Defaults

The reference implementations start an On-premise Engine with these settings
when its configuration says nothing else, so a Pipeline built with a data file
keeps that file current without further configuration:

| Option | Default |
| --- | --- |
| autoUpdate | on |
| Automatic update from file (the file system watcher) | on |
| updateOnStartup | off |
| pollingInterval | 30 minutes |
| randomization | up to 10 minutes |
| dataUpdateUrl | `https://distributor.51degrees.com/api/v2/download`, with the URL formatter adding `LicenseKeys`, `Download=True` and `Type`, where the type is `HashV41` for a Device Detection Hash data file and `IPIV41` for an IP Intelligence data file |
| License key | required before the Engine builds with autoUpdate or updateOnStartup on, because the Distributor serves nothing without one. The build fails with a configuration error that names the option to turn off. A configuration may say that no key is required, for an update source that serves the file without one. The file system watcher downloads nothing and needs no key |

An application that cannot supply a license key, such as one running the free
Lite data file, turns autoUpdate off before it builds the Engine. Its file
system watcher still runs, because the watcher needs no License Key.

## Update polling

This section discusses making an HTTP request to check for
updated data and handling the response.

51Degrees Device Detection data files are supplied by the
[Distributor](https://51degrees.com/documentation/_info__distributor.html?utm_source=github&utm_medium=docs&utm_campaign=specifications&utm_content=pipeline-specification-features-data-updates.md&utm_term=update-polling)
web API. The capabilities of the data update service align with those of
the Distributor. However, the service MUST be capable of using other sources
as well. For example, a simple static URL that just supplies a file.

When sending a request to the *data update URL*, the `If-Modified-Since`
header SHOULD be set to the publication date of the existing data file.
If the data file does not have a publication date then the file system last modified
date/time can be used instead. This ensures that if a new data file has not
been published yet, we won't waste bandwidth downloading it.

There MUST be some mechanism for the update service to add query parameters
to the data update URL when needed.
The reference implementations use a 'URL formatter' class. Below are the
implementations used for calls made to the Distributor.

- [.NET FiftyOneUrlFormatter](https://github.com/51Degrees/51degrees-dotnet/blob/main/pipeline/Engines.FiftyOne/Data/FiftyOneUrlFormatter.cs)
- [Java FiftyOneUrlFormatter](https://github.com/51Degrees/51degrees-java/blob/main/pipeline/pipeline.engines.fiftyone/src/main/java/fiftyone/pipeline/engines/fiftyone/data/FiftyOneUrlFormatter.java)

If a new data file is downloaded, the date of the downloaded data is
compared with the current file data source, if file data source mode is active.
If the downloaded file is more recent, it replaces the current file data source.

If the data downloaded is more recent or if memory data source mode is in
operation the Aspect Engine is refreshed with the new data.

Once the refresh is complete, the data update service can start
checking for updates using the newly refreshed *next expected update*
date/time.

If no update was found then the check is reported as not needed, as
[reporting each check](#reporting-each-check) says, and the service will need
to repeat the same checks after the *polling interval* + a random time based on  
*update time maximum randomization* has passed.

## Logging

The data update service is a complex process. As such, it is
essential that detailed logging is
available to help diagnose issues that might arise.

All major actions SHOULD be logged at the appropriate level along with
relevant details (e.g. which Engine + data file the update is for)

The URL a data update request is sent to carries the license keys in its
query. Wherever a message below names the \<url\>, it is the URL with each
license key masked to its last 4 characters, because a license key MUST NOT
appear in full in a log entry or an error message (see
[logging](logging.md#license-keys)).

### Messages at start-up

| **Action**                             | **Message**                  |
|----------------------------------------|------------------------------|
| Running the update on start-up process | Updating on start-up         |
| File system watcher created            | Creating file system watcher |

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
A failure in a check started by update polling or by the file watcher MUST be
caught and logged, rather than being lost or ending the process, and is then
reported to onUpdateCallbacks. A failure MUST NOT stop later checks for
updates, so a later good data file is still applied. A programmatic check,
the update on start-up and an update from memory pass the error to their
caller instead of logging it.

These messages MUST also be consistent across languages to make life easier
for 51Degrees support. They are the messages and levels of the .NET data
update service, and each status is the one .NET reports.

A row at Error level is an error that carries the message shown. Where the
service logs it, the entry is at Error, reads `Error during check for data
update`, and has the error attached. An error of any other kind is logged at
Error with the message in the last row, also with the error attached. An
error raised by a callback in onUpdateCallbacks is logged in the same way on
update polling and the file watcher, as `Error during check for data update`
when it is of the same kind as the Error rows, and with the last row's message
otherwise. On a programmatic check and the update on start-up it passes to the
caller. Either way the callbacks after the one that raised the error are not
called, and on update polling any reports of the check not yet made are not
made. A row at Warning level is logged with the message shown, and the check
goes on.

| **Error**                                                                                     | **Log level**                    | **Status**                              | **Message**                                                                                                                                                                                   |
|-----------------------------------------------------------------------------------------------|----------------------------------|-----------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Connecting to the data update URL failed                                                      | Error                            | `AUTO_UPDATE_HTTPS_ERR`                 | Error accessing data update service at '\<url\>' for engine '\<Engine type name\>'                                                                                                            |
| The data update URL gave no response                                                          | Error                            | `AUTO_UPDATE_HTTPS_ERR`                 | No response from data update service at '\<url\>' for engine '\<Engine type name\>'                                                                                                           |
| A 429 (Too many requests) response                                                            | Error                            | `AUTO_UPDATE_ERR_429_TOO_MANY_ATTEMPTS` | Too many requests to '\<url\>' for engine '\<Engine type name\>'                                                                                                                              |
| A 403 (Forbidden) response                                                                    | Error                            | `AUTO_UPDATE_ERR_403_FORBIDDEN`         | Access denied to data update service at '\<url\>' for engine '\<Engine type name\>'                                                                                                           |
| Any other response that is not a success and not a 304 (Not modified)                         | Error                            | `AUTO_UPDATE_HTTPS_ERR`                 | HTTP status code '\<status code\>' from data update service at '\<url\>' for engine '\<Engine type name\>'                                                                                    |
| The response has no `Content-MD5` header                                                      | Warning                          | None, the check goes on                 | No MD5 hash included in data update response for '\<url\>'. Unable to verify data integrity                                                                                                   |
| The integrity check of the downloaded data failed                                             | Error                            | `AUTO_UPDATE_ERR_MD5_VALIDATION_FAILED` | Integrity check failed. MD5 hash in HTTP response '\<hash in response\>' for '\<Engine type name\>'data update does not match calculated hash for the downloaded file '\<calculated hash\>'.  |
| The data file has no temporary file path configured                                           | Error                            | `AUTO_UPDATE_TEMP_PATH_NOT_SET`         | The data file '\<data file identifier\>' is checking for updates but does not have a temporary file path configured.                                                                          |
| Copying the new data file over the existing one failed                                        | Error                            | `AUTO_UPDATE_NEW_FILE_CANT_RENAME`      | An error occurred when copying a data file to replace the existing one at '\<path\>'.                                                                                                         |
| Refreshing the Engine from the data file still failed after 10 tries                          | Error                            | `AUTO_UPDATE_REFRESH_FAILED`            | An error occurred when applying a data update to engine '\<Engine type name\>' after \<tries\> tries.                                                                                         |
| Refreshing the Engine from data held in memory failed                                         | Error                            | `AUTO_UPDATE_REFRESH_FAILED`            | An error occurred when applying a data update to engine '\<Engine type name\>'.                                                                                                               |
| Writing data passed in from memory to the data file failed                                    | Warning                          | None, the Engine is still refreshed     | An error occurred when writing to '\<path\>'. The engine will be updated to use the new data but the file on disk will still contain old data.                                                |
| A watched file could not be opened for reading within 10 minutes                              | Not logged                       | `AUTO_UPDATE_TIMEOUT`                   | None                                                                                                                                                                                          |
| The update on start-up ended with a status other than success or not needed, without an error | Not logged, passed to the caller | That status                             | Update on startup failed for \<data file identifier\> with status \<status\>. See log for details                                                                                             |
| An onUpdateCallbacks callback raised an error                                                 | Error, or passed to the caller   | None, already reported                  | An unhandled error occurred while checking for automatic updates for engine '\<Engine type name\>'                                                                                            |
| Any other error                                                                               | Error                            | `AUTO_UPDATE_UNKNOWN_ERROR`             | An unhandled error occurred while checking for automatic updates for engine '\<Engine type name\>'                                                                                            |
