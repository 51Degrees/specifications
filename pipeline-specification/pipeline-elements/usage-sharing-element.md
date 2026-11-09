# Usage sharing element

This Flow Element implements the [usage-sharing](../features/usage-sharing.md)
feature.

## Accepted Evidence

The Usage Sharing Element MUST NOT accept any Evidence. Its
[accepted Evidence](../features/advertize-accepted-evidence.md) is empty, so it
never adds a key to the Evidence a Pipeline accepts. The features that are
built from a Pipeline's accepted Evidence, being [caching](../features/caching.md)
and the ETag and Vary headers of the
[client-side endpoints](../features/web-integration.md#cache-header-detail),
therefore never depend on it. Usage sharing collects what it sees in order to
share it, and none of it changes a result, so none of it belongs in a cache key
or an ETag.

It shares instead what it finds, from two places:

- every Evidence value in the Flow Data, and
- every header other than Cookie, every cookie, query string parameter and
  session value of the web request, with its client IP address, its protocol
  and the method and path of its request line, when the web integration
  supplies the request as
  `server.http-request` (see
  [Populating Evidence](../features/web-integration.md#populating-evidence)).
  This is how a header that no other Flow Element accepts is still shared.

A key found in both places is shared once, with the value from the Evidence.

## Shared Evidence

Which of the keys it finds are shared is decided by a filter function. The
prefix of a key is everything before its first `.` and the field is everything
after it, so a field can itself contain a `.`. Keys are compared without regard
to case. A value from the web request is given the key it would have as
Evidence, for example `header.user-agent` for its User-Agent header,
`server.client-ip` for its client IP address and `header.protocol` for its
protocol.

The filter function MUST return false (i.e. not shared) for these keys,
matched as the whole key or after a `.`, whatever the configuration and even
when all Evidence is shared:

- `id.email`, which is a raw email address.
- `id.salt`, which is the salt used to make hashed email identifiers.
- `request-query`, which is the whole query string. Sharing it would undo the
  rules for query string parameters below.
- `request-path`, which is the path of the request. Sharing it makes each page
  a visitor opens look like a new session to the
  [session tracking](#session-tracking), and the path is the part of a URL most
  likely to carry a name or an identifier a site has put in it.
- `header.cookie`, which is the Cookie header of the request and carries every
  cookie ([RFC 6265 section 5.4](https://www.rfc-editor.org/rfc/rfc6265#section-5.4)).
  This holds for the Cookie header of the `server.http-request` view as well as
  for Evidence. The cookies starting `51D_` are shared as their own `cookie.`
  Evidence under the rules below, and no other cookie is shared through the
  header.

So `query.id.email`, `server.request-path` and `header.cookie` are never shared, while
`query.valid.email` is an ordinary query string parameter. The
`server.http-request` value itself is never shared, only the values read from
it.

Unless all Evidence is shared, it MUST also return false for any key where:

- Prefix = `header.` and field is in a user-configurable block list.
- Prefix = `cookie.` and field does not start with `51D_`
- Prefix = `session.` and field does not start with `51D_`
- Prefix = `query.` and field does not start with `51D_` and is not in a
  user-configurable allow list of query string parameters that will be
  shared.

Anything else MUST return true. (i.e. it will be shared)

The element accepts no Evidence, so it does not accept the session cookie
either. When the [track session](#configuration-options) option is on, the
element MUST read the cookie named by the
[session cookie name](#configuration-options) option from the same two places
as the values it shares, being the Evidence in the Flow Data and the web
request supplied as `server.http-request` (see
[Accepted Evidence](#accepted-evidence)), so that the
[session tracking](#session-tracking) can compare it. A cookie found in both
places is read once, with the value from the Evidence. The session cookie
MUST NOT be shared unless all Evidence is shared.

See [configuration options](#configuration-options) for more detail on the
configuration parameters that can affect this filter function.

## Element Data

This Flow Element does not add an Element Data instance to Flow Data.

## Start-up activity

A static XML snippet can be generated for values that will be invariant
for the lifetime of the current Pipeline.

From the list of parameters in the processing section below, the invariant ones
are:

- Version
- Product
- Flow Elements
- Language
- LanguageVersion
- ServerIP
- Platform

Note that there is a [proposal](../future-features/usage-sharing-header.md) to
avoid duplicating these values on every record.

## Processing

The process function SHOULD get the data it needs and complete as soon as
possible.
We recommend implementing a producer/consumer approach where the process
function just adds the raw data to a shared queue.

A background thread can then be used to consume items from this queue,
adding them to the XML payload and sending it once it contains the
configured quantity of data.

The complete XML document MUST contain a `<Devices>` root element with
each `<Device>` element containing the details related to a request.

Multiple `<Device>` elements will be batched up as part of each message.
The number of items per batch is configurable using the
[minimum entries per message](#configuration-options) setting.

In the snippet below:

- Text in CAPS represent variable values.
- Things in [square brackets] are optional

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
  <!--Each evidence value is represented as an entry in the form:--> 
  <PREFIX [escaped="true"] [truncated="true"] Name="FIELD">VALUE</PREFIX> 
  <!--For example:--> 
  <Header Name="user-agent">USER_AGENT</Header> 
  <Header Name="host">HOST</Header>
  <Cookie Name="51d_screenpixelsheight">SCREEN_HEIGHT</Cookie> 
</Device> 
```

- **SessionId** – A GUID generated by the [Sequence Element](sequence-element.md)
  used to identify a set of Evidence originating from the same source where
  multiple requests are initiated to resolve the JSON payload for
  updated Evidence, e.g. client-side overrides or geo location.
- **Sequence** – An integer paired with the SessionId which is incremented
  each time the sequence value is seen in Evidence to identify the number
  of requests in a session. (This incrementing is handled by the Sequence Element)
- **DateSent** - The date that the xml was constructed in UTC and formatted
  as: yyyy-mm-ddThh:nn:ss
- **Version** - The version of the Pipeline that is being used to generate
  the xml. E.g. “4.0”
- **Product** - The name of the product that is generating the xml. For
  example, “Pipeline”
- **FlowElement** – An xml element exists for each FlowElement in the
  Pipeline. The text contains the fully qualified class name of the FlowElement.
- **Language** - The name of the language/framework within which the
  Pipeline is running.
- **LanguageVersion** - The version number of the language/framework
  within which the Pipeline is running.
- **ClientIP** - Public IP address of the client that sent the request to
  this server.
- **ServerIP** - IP address of the server where the xml is being generated.
- **Platform** - The platform name, version and service pack if available.
- **Evidence** – The Evidence that is shared is what the element finds, as
  [accepted Evidence](#accepted-evidence) describes, less what the
  [shared Evidence](#shared-evidence) rules leave out.

Evidence values can be extremely long, or contain characters that are not
permitted in XML. In order to handle this, some mechanism MUST be implemented
to sanitize the values before they are added to the XML.

Where changes need to be made to the value, attributes are added to the XML
element for that Evidence entry to let the reader know the value was modified.

Currently, the defined attributes are:

- escaped - Indicates that the original evidence value included invalid
  characters, which have been replaced with escaped ones.
- truncated - Indicates that the original evidence value was too long. The
  value in the XML does not include all characters from the original.

A character that XML 1.0 does not allow is replaced by the text `\x` followed
by the code of the character as four lower-case hexadecimal digits, for
example `\x001f`, and the element for that Evidence entry is marked
`escaped="true"`.

A value longer than 10,000 characters is cut to 10,000 characters and the
element for that Evidence entry is marked `truncated="true"`. The limit counts
Unicode code points, and the cut never splits a character, so a character that
UTF-16 stores as two units (a surrogate pair, such as most emoji) is never
divided. The limit applies to the value as it was supplied, before any
character is replaced, so the `\x` escapes do not count towards it.

See the [ReplacedString](https://github.com/51Degrees/51degrees-java/blob/main/pipeline/pipeline.engines.fiftyone/src/main/java/fiftyone/pipeline/engines/fiftyone/flowelements/ShareUsageElement.java#L485)
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
When failures occur, the status code and content of the response MUST be logged
to aid troubleshooting.

See the [BuildAndSendXml](https://github.com/51Degrees/51degrees-dotnet/blob/main/pipeline/Engines.FiftyOne/FlowElements/ShareUsageElement.cs#L117) method in C# for an example of this.

## Session tracking

Note that this section is not concerned with actually identifying
the precise boundaries of user sessions. Just with reducing the volume
of unnecessary data that is shared.

When a user is browsing a website, they will typically make many HTTP
requests to access different resources, visit different pages, etc.

These requests will usually all generate exactly the same usage data.
We have no need for this duplicate data, so it MUST be discarded as
early as possible.

This can be achieved by maintaining a data structure containing
recently shared Evidence values, each with the time it was last shared.
For example, the C# implementation generates a hash of the Evidence
values using the same logic as the [caching](../features/caching.md)
feature.

The [repeat Evidence interval](#configuration-options) is a window that
starts when Evidence is shared and starts again only when the same Evidence is
next shared.

- Evidence with no matching entry MUST be shared, and an entry MUST be
  stored with the time it is shared.
- Evidence matching an entry shared less than the interval ago MUST NOT
  be shared, and the entry's time MUST NOT change.
- Evidence matching an entry shared the interval or more ago MUST be
  shared, and the entry's time MUST be set to the time it is shared.

So identical Evidence is shared at most once in each interval, however
often it is seen. The time MUST NOT be reset when matching Evidence is
seen but not shared, because Evidence seen continuously would then never
be shared again.

Entries MAY be removed once the interval has passed since they were
shared, and MAY be removed sooner to limit memory. Evidence matching no
entry is then shared as new.

The hash is of the values that would be shared, as the element accepts no
Evidence of its own for the caching logic to read, and also of the session
cookie when track session is on (see below).

Note that certain Evidence values MUST NOT be included in the generation
of this hash code as they are designed to make a request unique.
For example, the sequence number generated by the
[Sequence Element](sequence-element.md).

Unless all Evidence is shared, the session cookie is not compared, so
identical Evidence matches the same entry whichever session it comes from. When the [track session](#configuration-options)
option is on, the value of the session cookie named by the
[session cookie name](#configuration-options) option is compared as well.
Identical Evidence from a new session then makes a new entry and is shared,
while a repeat within the same session matches the existing entry and is not.
The session cookie itself is not shared.

The session cookie name has no effect unless track session is on. Track
session has no effect when all Evidence is shared, because every cookie is
then both shared and compared. In .NET the session cookie name defaults to
`asp.net_sessionid`, the ASP.NET session cookie.

We also include various [configuration options](#configuration-options)
for users to exclude any keys that might be identified to cause
oversharing of data.

## Error handling

As a general principle, share usage can be considered an important, but expendable
activity. If errors occur then they MUST be handled and
[logged](../features/logging.md) without disrupting anything else the Pipeline is doing.

For example, the queue of data to be sent has limited size. If this
becomes full, additional data can simply be discarded until there
is room to add entries again.
However, it is important that these actions are logged so that users
can identify potential issues with their usage sharing. A message MUST
NOT be logged for each entry discarded, as a busy server would flood its
log.

### Back-off after failed sends

Repeated failed sends MUST pause sending, so that a service that is down
or overloaded is not sent a message for every batch, and so that usage
data waits in the queue rather than being sent and lost. Only sending
pauses. Processing MUST NOT wait for, or be stopped by, the back-off.

A send fails when the request cannot be made, has no answer within the
time the implementation allows, or is answered with anything other than
200.
The batch that failed is dropped. It is not put back on the queue.

1. When the [failures to enter recovery](#configuration-options) number
   of sends have failed within the last
   [failures window seconds](#configuration-options), sending MUST pause
   for the [initial recovery delay](#configuration-options). Failures
   older than the window MUST NOT be counted. Successful sends between the
   failures do not reset the count, so a high rate of failures pauses
   sending even when some sends succeed.
2. The first send after a pause ends is a trial. If it fails, the delay
   MUST be multiplied by the [recovery multiplier](#configuration-options),
   up to the [maximum recovery delay](#configuration-options), and sending
   MUST pause again for the new delay. One failed trial is enough.
3. A successful send MUST end the back-off. The count of failures starts
   again from zero, and the next pause starts again from the initial
   delay.
4. During a pause, Evidence MUST still be added to the queue. New
   Evidence is discarded only when the queue is full.
5. When a pause ends and at least the
   [minimum entries per message](#configuration-options) are queued,
   sending MUST start again without waiting for more requests to be
   processed, and MUST continue until fewer than the minimum entries per
   message are queued, so a queue that filled during the pause drains at
   once.
6. A message SHOULD be logged as a warning when sending pauses or a pause
   is lengthened, giving the delay, and as information when sending
   resumes.

With the defaults, ten failed sends within 100 seconds pause sending for
2 seconds. While the trials keep failing the pauses grow to 4, 8, 16
seconds and so on, up to 300 seconds.

One message is sent at a time, so that while backing off a failing
service is sent one trial when each pause ends.

## Cleanup

As this element uses a producer/consumer queue and background processing,
it will need to handle cleanup a little more carefully than other elements.

1. If needed, block while the consumer sends data waiting in the queue.
2. Send a final message with any data remaining in the queue (even if it is
   less than the configured minimum batch size)
3. Free any resources associated with the queue and background processing.

While sending is paused by the [back-off](#back-off-after-failed-sends),
cleanup MUST NOT wait for the pause to end and MUST NOT send. The data
remaining in the queue is discarded, and the number of entries discarded
SHOULD be logged.

## Configuration options

| **Parameter**                     | **User configurable** | **Optional** | **Default**                                                                  | **Notes**                                                                                                                    |
|-----------------------------------|-----------------------|--------------|------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------|
| Included query string parameters  | yes                   | yes          | All query string and HTTP form parameters starting with `51D_` are shared.   | Allows the user to include specific query string or HTTP form parameters in the usage data that is shared.                   |
| Share all query string parameters | yes                   | yes          | false                                                                        | If this flag is set, all query string and HTTP form parameters will be shared.                                               |
| Share all Evidence                | yes                   | yes          | false                                                                        | If this flag is set, all Evidence values will be shared, apart from the keys that are never shared.                          |
| Blocked HTTP headers              | yes                   | yes          | All HTTP headers are shared except `Cookie`                                  | Allows the user to exclude specific HTTP headers that they do not want to share.                                             |
| Ignore Flow Data Evidence filter  | yes                   | yes          | not set                                                                      | Allows the user to block a request from being shared if the specified criteria are met.                                      |
| Share percentage                  | yes                   | yes          | 1.0                                                                          | Used to set the approximate proportion of requests that will be shared. A value of 1 means that 100% of requests are shared. |
| Minimum entries per message       | yes                   | yes          | 50                                                                           | The number of requests that will be added to a usage sharing payload before it is sent.                                      |
| Maximum queue size                | yes                   | yes          | 1000, or ten times the minimum entries per message if that is larger         | The size of the queue that is used to buffer requests to be added to a usage sharing payload.                                |
| Add timeout milliseconds          | yes                   | yes          | 5                                                                            | The timeout to use when trying to add items to the usage sharing queue. If the request times out, the data will be discarded |
| Take timeout milliseconds         | yes                   | yes          | 100                                                                          | The timeout to use when getting items from the usage sharing queue to add to the next payload.                               |
| Share usage URL                   | yes                   | yes          | <https://devices-v4.51degrees.com/new.ashx>                                  | The URL to send data to                                                                                                      |
| Repeat Evidence interval minutes  | yes                   | yes          | 20                                                                           | How long after Evidence is shared it is not shared again. A repeat after that is shared and starts a new interval.           |
| Track session                     | yes                   | yes          | false                                                                        | If this flag is set, the session cookie is compared along with the Evidence, so a repeat from a new session is shared.       |
| Session cookie name               | yes                   | yes          | `asp.net_sessionid` in .NET                                                  | The name of the cookie that holds the session id. It has no effect unless track session is on.                               |
| Failures to enter recovery        | yes                   | yes          | 10                                                                           | The number of failed sends within the failures window that pauses sending. From 1 to 100.                                    |
| Failures window seconds           | yes                   | yes          | 100                                                                          | The time over which failed sends are counted. 1 or more.                                                                     |
| Initial recovery delay seconds    | yes                   | yes          | 2.0                                                                          | The length of the first pause after failed sends. More than 0.                                                               |
| Maximum recovery delay seconds    | yes                   | yes          | 300.0                                                                        | The longest a pause can be. More than 0.                                                                                     |
| Recovery multiplier               | yes                   | yes          | 2.0                                                                          | What a pause is multiplied by each time the trial send when it ends fails. 1 or more.                                        |

The five recovery options set the
[back-off after failed sends](#back-off-after-failed-sends). An
implementation MUST reject a value outside the range given.
