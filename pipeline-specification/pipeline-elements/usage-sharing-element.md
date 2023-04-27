# Usage sharing element

## Overview

This **Flow Element** implements the [usage-sharing](../features/usage-sharing.md) 
feature.

## Accepted evidence 

The EvidenceKeyFilter for share usage is unusual as it cannot simply be a 
list of accepted keys like most **Flow Elements**.

Instead, it is a filter function that should return false (i.e. not shared) 
for any key where: 

- Prefix = ‘header’ and field is in a user-configurable block list 
  (by default, this block list must include the ‘cookies’ header). 
- Prefix = ‘cookie’ and field does not start with `51D_`
- Prefix = ‘query’ and field does not start with `51D_` and is not in a 
  user-configurable allow list of query string parameters that should be 
  shared.

Anything else should return true. (i.e. it will be shared) 

See [configuration options](#configuration-options) for more detail on the
configuration parameters that can affect this filter function.

## Element data

This **Flow Element** does not add an **Element Data** instance to **Flow Data**.

## Startup activity

A static XML snippet can be generated for values that will be invariant 
for the lifetime of the current **Pipeline**.

From the list of parameters in the processing section below, the invariant ones
are:
- Version
- Product
- Flow elements
- Language
- LanguageVersion
- ServerIP
- Platform

Note that there is a proposal to reduce the size of the usage sharing payload 
by moving these values to a `header` element rather than duplicating them in 
every `device` element. 
Implementing this will be a future enhancement as changes will first be required
to 51Degrees' data collection infrastructure.

## Processing

The process function must get the data it needs and complete as soon as 
possible.
We recommend implementing a producer/consumer approach where the process
function just adds the raw data to a shared queue.

A background thread can then be used to consume items from this queue, 
adding them to the XML payload and sending it once it contains the 
required quantity of data.

The complete XML document must contain a `<Devices>` root element with 
each `<Device>` element containing the details related to a request. 

Multiple `<Device>` elements will be batched up as part of each message.
The number of items per batch is configurable using the 
[minimum entries per message](#configuration-options) setting.

```xml
<Device>
  <SessionId>SESSION_ID</SessionId> 
  <Sequence>SEQUENCE</Sequence> 
  <DateSent>DATE_SENT</DateSent> 
  <Version>API_VERSION</Version> 
  <Product>API_NAME</Product>  
  <FlowElement>ELEMENT1</FlowElement> 
  <FlowElement>ELEMENT2</FlowElement>	 
  <Language>LANG</Language> 
  <LanguageVersion>LANG_VERSION</LanguageVersion> 
  <ClientIP>IP_ADDRESS</ClientIP> 
  <ServerIP>IP_ADDRESS</ServerIP> 
  <Platform>PLATFORM PLATFORM_VER SERVICE_PACK</Platform> 
Each evidence value is represented as an entry in the form: 
  <PREFIX [escaped=true] [truncated=true] Name=”FIELD”>VALUE</PREFIX> 
For example: 
  <Header Name=”User-Agent”>USER_AGENT</Header> 
  <Header Name=”Host”>HOST</Header>
  <Cookie Name=”51D_ScreenPixelsHeight”>1080</Cookie> 
  [<BadSchema>true</BadSchema>]
</Device> 
```

- **SessionId** – A GUID generated by the Share Usage element used to 
  identify a set of evidence originating from the same source where 
  multiple requests are initiated to resolve the json payload for 
  updated evidence, e.g. client-side overrides or geo location. 
- **Sequence** – An integer paired with the SessionId which is incremented 
  each time the sequence value is seen in evidence to identify the number 
  of requests in a session. 
- **DateSent** - The date that the xml was constructed in UTC and formatted 
  as: yyyy-mm-ddThh:nn:ss
- **Version** - The version of the pipeline that is being used to generate 
  the xml. E.g. “4.0” 
- **Product** - The name of the product that is generating the xml. For 
  example, “Pipeline” 
- **FlowElement** – An xml element exists for each FlowElement in the 
  pipeline. The text contains the fully qualified class name of the FlowElement.
- **Language** - The name of the language/framework within which the 
  pipeline is running. 
- **LanguageVersion** - The version number of the language/framework 
  within which the pipeline is running. 
- **ClientIP** - Public IP address of the client that sent the request to 
  this server. 
- **ServerIP** - IP address of the server where the xml is being generated. 
- **Platform** - The platform name, version and service pack if available.
- **Evidence** – The evidence that is shared will be determined by its 
  evidence key filter as defined below. 

Evidence values may be extremely long, or contain characters that are not 
permitted in XML. In order to handle this, a function should be implemented 
to sanitize the values before they are added to the XML.

Where changes need to be made, attributes should be added to the XML element
to let the reader know the value was modified.

See the [ReplacedString](https://github.com/51Degrees/pipeline-java/blob/master/pipeline.engines.fiftyone/src/main/java/fiftyone/pipeline/engines/fiftyone/flowelements/ShareUsageElement.java#L485) 
function in Java for an example of this.

### Request detail

When sending the data, use the following details:
- URL configurable using the [share usage URL](#configuration-options) option.
- POST request
- XML content written to the body of the request using GZip compression
- HTTP Headers:
  - content-encoding = gzip
  - content-type = text/xml 

Response will be a 200 on success. Anything else is a failure.
When failures occur, the status code and content of the response should be logged.

See the [BuildAndSendXml](https://github.com/51Degrees/pipeline-dotnet/blob/master/FiftyOne.Pipeline.Engines.FiftyOne/FlowElements/ShareUsageElement.cs#L104) method in c# for an example of this.

## Session tracking 

Note that this section is not concerned with actually identifying
the precise boundaries of user sessions. Just with reducing the volume 
of unnecessary data that is shared.

When a user is browsing a website, they may typically make many HTTP 
requests to access different resources, visit different pages, etc.

These requests will usually all generate exactly the same usage data.
We have no need for this duplicate data, so it should be discarded as 
early as possible.

The usage sharing element must maintain a data structure containing 
recently shared evidence values. If the data entry being processed 
already has a matching entry in this data structure, it should not 
be shared. For example, the c# implementation generates a hash of the 
evidence values using the same logic as the [caching](../features/caching.md)
feature.

By default, entries will have a lifetime of 20 minutes within this 
data structure. This is reset each time an entry with matching 
evidence values is processed.

See [configuration options](#configuration-options) for more detail 
on customizing this lifetime.

Note that certain evidence values should not be included in this check 
as they are designed to make a request unique.
Internally, this only applies to the sequence number generated by the 
[sequence element](sequence-element.md).

We also include various [configuration options](#configuration-options) 
for users to exclude any keys that may be identified to cause 
oversharing of data.

## Error handling 

As a general principle, share usage should be considered an expendable 
activity. If errors occur then they should be handled and 
[logged](../features/logging.md) without disrupting anything else.

For example, the queue of data to be sent has limited size. If this 
becomes full additional data should simply be discarded until there 
is room to add entries again. 
However, it is important that these actions are logged so that users
can identify potential issues with their usage sharing.

## Cleanup

As this element uses a producer/consumer queue and background processing,
it will need to handle cleanup a little more carefully than other elements.

1. If needed, block while the consumer sends data waiting in the queue.
2. Send a final message with any data remaining in the queue (even if it is 
   less than the configured minimum batch size)
3. Free any resources associated with the queue and background processing.

## Configuration options

| **Parameter**                     | **User configurable** | **Optional** | **Default**                                                                  | **Notes**                                                                                                                      |
|-----------------------------------|-----------------------|--------------|------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------|
| Included query string parameters  | yes                   | yes          | All query string and HTTP form parameters starting with `51D_` are shared.   | Allows the user to include specific query string or HTTP form parameters in the usage data that is shared.                     |
| Share all query string parameters | yes                   | yes          | false                                                                        | If this flag is set, all query string and HTTP form parameters will be shared.                                                 |
| Share all evidence                | yes                   | yes          | false                                                                        | If this flag is set, all evidence values will be shared.                                                                       |
| Blocked HTTP headers              | yes                   | yes          | All HTTP headers are shared except for cookies that do not start with `51D_` | Allows the user to exclude specific HTTP headers that they do not want to share.                                               |
| Ignore flow data evidence filter  | yes                   | yes          | not set                                                                      | Allows the user to block a request from being shared if the specified criteria are met.                                        |
| Share percentage                  | yes                   | yes          | 1.0                                                                          | Used to set the approximate proportion of requests that should be shared. A value of 1 means that 100% of requests are shared. |
| Minimum entries per message       | yes                   | yes          | 50                                                                           | The number of requests that must be added to a usage sharing payload before it is sent.                                        |
| Maximum queue size                | yes                   | yes          | 1000                                                                         | The size of the queue that is used to buffer requests to be added to a usage sharing payload.                                  |
| Add timeout milliseconds          | yes                   | yes          | 5                                                                            | The timeout to use when trying to add items to the usage sharing queue. If the request times out, the data should be discarded |
| Take timeout milliseconds         | yes                   | yes          | 100                                                                          | The timeout to use when getting items from the usage sharing queue to add to the next payload.                                 |
| Share usage URL                   | yes                   | yes          | https://devices-v4.51degrees.com/new.ashx                                    | The URL to send data to                                                                                                        |
| Repeat evidence interval minutes  | yes                   | yes          | 20                                                                           | The size of the sliding window during which identical usage data will not be sent if it is seen second or subsequent times.    |


