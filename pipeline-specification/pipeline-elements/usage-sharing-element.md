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
  session value of the web request, with its client IP address, its protocol and the method and path
  of its request line, when the web integration supplies the request as
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

The complete XML document MUST be written exactly as this section describes,
so that the same Evidence gives the same bytes in every language when run on
the same host. The only exceptions are `DateSent` and the values that name
the runtime, being `Version`, `Language`, `LanguageVersion`, `Platform` and
the `FlowElement` text.

### The document

1. The document is UTF-8 and starts with the byte order mark EF BB BF.
2. The XML declaration `<?xml version="1.0" encoding="utf-8"?>` follows, with
   no `standalone` attribute.
3. The root element is `<Devices>`, holding one `<Device>` element for each
   record.
4. Nothing is written between elements, so there is no indentation and no
   line break anywhere in the document.

Multiple `<Device>` elements are batched in each message. The number of items
per batch is set by the [minimum entries per message](#configuration-options)
option.

### The record

Each `<Device>` holds these elements in this order.

| **Element**       | **Content**                                                                                                                                                                                                                    |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `SessionId`       | The value of the `query.session-id` Evidence                                                                                                                                                                                   |
| `Sequence`        | The value of the `query.sequence` Evidence as a 32-bit integer in decimal, or `0` when it is absent or does not parse                                                                                                          |
| `DateSent`        | The time the record was written, in UTC, formatted `yyyy-MM-ddTHH:mm:ss` on a 24-hour clock, for example `2026-11-02T14:05:09`                                                                                                 |
| `ClientIP`        | The value of the `server.client-ip` Evidence                                                                                                                                                                                   |
| `Version`         | The version of the Pipeline core package                                                                                                                                                                                       |
| `Product`         | `Pipeline`                                                                                                                                                                                                                     |
| `FlowElement`     | One for each Flow Element in the Pipeline, in Pipeline order, holding the element's fully qualified type name                                                                                                                  |
| `Language`        | The name of the language, for example `dotnet`                                                                                                                                                                                 |
| `LanguageVersion` | The version of the language runtime                                                                                                                                                                                            |
| `ServerIP`        | The first address the server's host name resolves to that is IPv4 and is not `127.0.0.1`, otherwise the first that is neither `127.0.0.1` nor `::1`, otherwise empty. The usage sharing element works it out once and keeps it |
| `Platform`        | The name and version of the operating system                                                                                                                                                                                   |
| Evidence entries  | One for each shared Evidence entry, as described below. The [accepted Evidence](#accepted-evidence) decides which are shared                                                                                                   |
| `BadSchema`       | `true`, written only when a character was replaced in a name or value of this record                                                                                                                                           |

`SessionId`, `Sequence`, `DateSent` and `ClientIP` are always written. An
element with no content, such as `SessionId` when `query.session-id` is
absent, is written as `<SessionId />`, with a space before the slash. The
keys `query.session-id`, `query.sequence` and `server.client-ip` are matched
without regard to case and are not written again as Evidence entries.

### Evidence entries

1. Each shared Evidence key is split at its first `.` into a prefix and a
   field. The entry is an element named by the prefix exactly as the key has
   it, with a `Name` attribute holding the field exactly as the key has it,
   and the value in a CDATA section, for example
   `<header Name="User-Agent"><![CDATA[Mozilla/5.0]]></header>`.
2. A key that has no `.`, or that starts with `.`, is written as an element
   named by the whole key, with the value as element text rather than CDATA.
3. Entries are grouped by prefix. The prefixes come in the order each first
   appears in the Evidence, and the entries within a prefix in the order the
   Evidence holds them. Nothing is sorted.

### Names and values

1. A value longer than 10,000 characters, counted in UTF-16 code units, is
   replaced by the text `[TRUNCATED BY USAGE SHARING]` and a single space,
   followed by the value's first 10,000 code units.
2. After that, in each name and value, every character from U+0000 to U+001F
   other than tab (U+0009), line feed (U+000A) and carriage return (U+000D) is
   replaced by `\x` and the character's code as four lowercase hexadecimal
   digits, for example `\x001f`, and the record gains
   `<BadSchema>true</BadSchema>` after its Evidence entries.
3. Inside CDATA, `]]>` is written as `]]]]><![CDATA[>`, which closes the
   section after `]]` and opens another before `>`.
4. In an attribute value, `&`, `<`, `>` and `"` are written as `&amp;`,
   `&lt;`, `&gt;` and `&quot;`. In element text, `&`, `<` and `>` are written
   the same way. No other character is escaped, so tab, line feed and carriage
   return are written as they are.

### Example

With no session id, no client IP and these Evidence entries, in this order,

- `header.User-Agent` = `Mozilla/5.0`
- `header.X-Test` = `a]]>b`
- `query.51D_Test` = `x`, U+0001, `y`

the record is the following, shown on several lines here only for reading,
with `...` standing for the elements from `Version` to `Platform`.

```xml
<Device><SessionId /><Sequence>0</Sequence>
<DateSent>2026-11-02T14:05:09</DateSent><ClientIP />...
<header Name="User-Agent"><![CDATA[Mozilla/5.0]]></header>
<header Name="X-Test"><![CDATA[a]]]]><![CDATA[>b]]></header>
<query Name="51D_Test"><![CDATA[x\x0001y]]></query>
<BadSchema>true</BadSchema></Device>
```

### Request detail

When sending the data, use the following details.

- The URL is set by the [share usage URL](#configuration-options) option.
- A POST request.
- The whole document, compressed with GZip, as the body.
- The HTTP headers `content-encoding: gzip` and `content-type: text/xml`.

The response is a 200 on success, and anything else is a failure. When a
failure occurs, the status code and the content of the response MUST be logged
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
recently shared Evidence values. If the data entry being processed
already has a matching entry in this data structure, it MUST NOT
be shared. For example, the C# implementation generates a hash of the
Evidence values using the same logic as the [caching](../features/caching.md)
feature.

Entries will have a configurable lifetime within this data structure.
This is reset each time an entry with matching Evidence values is
processed.

See [configuration options](#configuration-options) for more detail
on customizing this lifetime.

The hash is of the values that would be shared, as the element accepts no
Evidence of its own for the caching logic to read.

Note that certain Evidence values MUST NOT be included in the generation
of this hash code as they are designed to make a request unique.
For example, the sequence number generated by the
[Sequence Element](sequence-element.md).

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
can identify potential issues with their usage sharing.

## Cleanup

As this element uses a producer/consumer queue and background processing,
it will need to handle cleanup a little more carefully than other elements.

1. If needed, block while the consumer sends data waiting in the queue.
2. Send a final message with any data remaining in the queue (even if it is
   less than the configured minimum batch size)
3. Free any resources associated with the queue and background processing.

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
| Maximum queue size                | yes                   | yes          | 1000                                                                         | The size of the queue that is used to buffer requests to be added to a usage sharing payload.                                |
| Add timeout milliseconds          | yes                   | yes          | 5                                                                            | The timeout to use when trying to add items to the usage sharing queue. If the request times out, the data will be discarded |
| Take timeout milliseconds         | yes                   | yes          | 100                                                                          | The timeout to use when getting items from the usage sharing queue to add to the next payload.                               |
| Share usage URL                   | yes                   | yes          | <https://devices-v4.51degrees.com/new.ashx>                                  | The URL to send data to                                                                                                      |
| Repeat Evidence interval minutes  | yes                   | yes          | 20                                                                           | The size of the sliding window during which identical usage data will not be sent if it is seen second or subsequent times.  |
