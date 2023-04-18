# Data Update

## Overview

An on-premise **Aspect Engine** may require data that is independent of the 
logic of the engine and that is periodically refreshed. The Data Update service 
provides functionality for this.

The Data Update Service assumes that the data is available from an HTTP
endpoint or that it can be provided by means of file store that is accessible
to an instance of the Aspect Engine.

It is possible that an Aspect Engine requires more than one data source and
implementers may choose either to provide the data in a single unified way
or to implement the Data Update service to allow for multiple file sources.

## Data Refresh Availability

A data source may contain a timestamp that specifies when it was created and may
contain a timestamp that indicates when refreshed data will be available. This
information can be used to optimise polling, or to provide information as to 
how up-to-date the current data is.

## Operational Modes

From the point of view of the Data Update Service, Aspect Engines have several 
operational modes:

- File Data Source, File Based Operation
- File Data Source, Memory Based Operation
- Memory Data Source, Memory Based Operation

Other operational modes may be possible, such as an Aspect Engine's data residing
in a relational database.

### File Data Source, File Based Operation
In this operational mode an Aspect Engine the Aspect Engine uses data that
resides in the file system to support its operation. This may be because the 
data is too extensive to be loaded into memory or because of memory limitations
in the system.

### File Data Source, Memory Based Operation

In many cases, for reasons of access speed, it is desirable for the data, which
is provided in a file, to be loaded into memory on start-up and on refresh.

### Memory Data Source

In some cases, to provide for fully diskless operation,  it may be desirable 
for an Aspect Engine to obtain its data 
as a memory buffer on start-up and on refresh.

## Operational Options

A number of options control the operation of the Data Update Service. Not all
options are available in every mode and some combinations of options are
either mutually exclusive or unlikely to be useful. For example, it's unlikely
that an Aspect Engine will be deployed with both the ability to reload on
disk based data file update as well as updating with HTTP based remote access. 
Providing for both being active at the same time adds complexity to the 
implementation.

Implementations may choose to report an error when inconsistent configuration 
options are chosen.

### Update on Startup

This option provides for checking for data from an HTTP server on startup 
as a blocking operation. 

This option is available both for memory data source mode and for file data
source modes. If the data source provides a timestamp then the remote timestamp
is compared with the local timestamp, and the remote data is used if it is more
recent than the current data.

This option can be used to bootstrap an aspect engine that does not yet have
any local data. In the case of file data source, the data is stored once
obtained via HTTP. 

The current reference implementation requires that local 
data is provided on start-up - in other words it doesn't allow for bootstrap
via HTTP.

Configuration Groups:
- *HTTP config*


### Automatic Update via HTTP

This option provides for periodic ongoing checking of an HTTP server
for the availability of an updated data source.

If the current data contains a *data update expected* timestamp, then polling 
should start after that time. Options include the ability to control the remote
endpoint and the polling frequency.

As an optimisation, the request for data may contain an "if modified since" HTTP
header, containing the date of the current data file.

If data is received that is newer than the current data, then the aspect engine
is restarted with the newly available data. The newly available data replaces
the existing data, at the location configured for data files, in the case of 
file data source operation.

51Degrees download servers have a request rate limiting feature which provides
for a 429 HTTP Status (Too many requests). This feature may be triggered
in the event that a single user has multiple servers each of which is set to
auto update. It is recommended that users with multiple servers do not use
this feature and that they obtain updated data once and distribute it to their
various servers by other means.

Configuration Groups:
- *HTTP config*
- *Polling config*
- *Operational file config*

### Automatic Update from File

This option allows users to obtain new data files by whatever means they choose,
and have the Aspect Engine update by detection of a new file in the file system
at the location configured for the data file.

<span style="color: yellow">Any timestamp contained in the data source is not taken into consideration, 
</span>operation depends on the operational environment reporting file system changes
and whatever file is found is used as the data source for the restarted 
Aspect Engine.

### Programmatic Update

The option allows for programmatic triggering of an update. The effect of a 
programmatic update is to initiate
immediate polling of the remote HTTP server, where this option is enabled.

If it is automatic update via HTTP is not enabled, 
it causes immediate update from local disk, irrespective of whether Automatic Update
from File is enabled.

Implementations may choose to provide options of Programmatic Update that 
distinguish a request for HTTP update as opposed to file update

Configuration Groups:
- *HTTP config*
- *Polling config*
- *Operational file config*

## Configuration Groups
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
  - **randomization** - provide a variation of polling frequency to avoid synchronised requests from more than one server

### Operational File config
  
  Configuration of the locations that disk based operation is done from:
  - **dataSourceFileLocation** - where to load the data source fom
  - **createOperationalDataCopy** - create a copy of the the data source, for operation
  - **operationalDataFileDirectory** - the directory for the data file copy

For disk based operation it is necessary to create an Operational Data Copy if
auto update via HTTP is enabled or if auto update from file is enabled. This is 
to allow continued operation of the Aspect Engine with its present data file
while a new data file is made available.

Since creating a data file copy is required for disk based operation 
implementations may choose not to provide control over 
**createOperationalDataCopy** since disallowing it when either update option
is enabled and disk based operation is enabled is an error.

Implementations may choose to report an error if any item
in this configuration is set for memory data source operation.

## Update Processes

### Update on Startup
- for disk data source, check operational data configuration consistency
- check HTTP server for new file
    - on fail, fall back to local file if any
        - no local file, fail
- compare date with local 
    - if newer, 
      - save new file
    - load file
- if disk data source, configure file watcher, if requested
- configure HTTP update polling, if requested
- continue

### Other Startup
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

### Programmatic Update

This could mean go and get remote or it could mean compare local file, or 
both, not clear.
- if newer file in **dataFilePath**
  - process as per newFile above
  - return
- poll remote
  - process as per newFile above