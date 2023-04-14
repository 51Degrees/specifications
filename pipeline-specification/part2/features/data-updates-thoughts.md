## Operational Modes
There are three operational modes, with operational options as follows:
- **memoryDataSource**

  Provides for fully disk-less operation, and has operational options:
    - **updateOnStartup**
    - **autoUpdateEnabled**
- **diskDataSource - memory Operation**

   After start-up disk is not required other than for update, with the following options:
    - **dataFilePath**
    - **updateOnStartUp**
    - **autoUpdateEnabled**
    - **fileSystemWatcherEnabled**
- **diskDataSource - disk Operation**

  After start-up disk *is* required, with the following options:
    - **dataFilePath**
    - **updateOnStartUp**

      (must have tempDataCopy for the following)
    - **autoUpdateEnabled**
    - **fileSystemWatcherEnabled**

## Operational Options
  - **updateOnStartUp**

    On start up block and download new copy, using the following configuration:
    - *HTTP config*
  - **autoUpdateEnabled**

    Periodically poll for updated data, and install:
    - *HTTP config*
    - *Polling config*
    - *Temp file config*
  - **fileSystemWatcherEnabled**

    Install a newer file if found in the **dataFilePath**:
    - *Temp file config*

## Configuration Groups
- *HTTP config*

  Configuration of the remote endpoint for download:
  - **dataUpdateUrl**
  - **urlFormatter** 
  - **decompressContent**
  - **verifyMD5**
  - **useIfModifiedSince**

- *Polling config*

  Configuration of the frequency for checking of new content:
  - **pollingInterval** 
  - **randomization** 

- *Temp File config*
  
  Configuration of the location that disk based operation is done from:
  - **createTempDataCopy** 
  - **tempDirectory** 

# Update Process

## Update on Startup
- check temp data configuration consistency
- Check Remote for File
    - on fail, fall back to local file if any
        - no local file, fail
- Compare date with local 
    - if newer, load new file
    - else, load old file
- if disk operation, configure file watcher, if necessary
- if disk operation, configure update polling, if necessary
- continue

## Other Startup
- check temp data configuration consistency
- engine load configured data from memory or file
- if disk operation, configure file watcher, if necessary
- if disk operation, configure update polling, if necessary
- continue

## newBufferAvailable (from memory, via remote)

Probably can't compare dates so load whatever we have:
- engine load buffer

## newFileAvailable (via remote or file watcher)

The file will be in **dataFilePath** from watcher or from download
- pause file watcher, if any
- pause update polling, if any
- compare date with local
  - if newer, engine load file
- resume polling, if any
- resume file watcher, if any
- trigger onUpdateCallbacks

## manualTrigger

This could mean go and get remote or it could mean compare local file, or 
both, not clear.
- if newer file in **dataFilePath**
  - process as per newFile above
  - return
- poll remote
  - process as per newFile above