# JavaScript Builder Element

The JavaScript Builder Element takes the JSON output from the
[JSON Builder Element](json-builder.md) and merges it into a
template which contains JavaScript.

The resulting JavaScript is provided to the client as part of an HTTP response.
At the client it provides the
following features:

- Allow access to Pipeline processing results in client-side JavaScript.
- Acquire additional Evidence that is only accessible to client-side
  JavaScript. This process is described in our
  [documentation](https://51degrees.com/documentation/_features__client_side_evidence.html?utm_source=github&utm_medium=docs&utm_campaign=specifications&utm_content=pipeline-specification-pipeline-elements-javascript-builder.md&utm_term=javascript-builder-element)

## Accepted Evidence

- `header.host`
- `header.protocol`
- `query.fod-js-object-name`
- `query.fod-js-enable-cookies`

## Start-up activity

On start-up, initialize the normal data structures, such as
accepted Evidence, and perform any set-up for the template system to
operate as efficiently as possible.

## Element Data

| **Name**   | **Type** | **Description**                              |
|------------|----------|----------------------------------------------|
| javascript | string   | The raw JavaScript produced by this Element. |

## Process

The [Mustache](https://mustache.github.io/) template used by all implementations is available at
[GitHub](https://github.com/51Degrees/javascript-templates/blob/main/JavaScriptResource.mustache).
There is no requirement that this template or Mustache is used. However,
any new variant would need to reproduce the capabilities of the existing script.

If the Mustache template is used, then several values it requires must
first be determined:

1. If protocol was not specified in configuration, get it from the
   `header.protocol` Evidence value. If that header is not present, then
   default to `HTTPS`.
2. If host was not specified in the configuration, get it from the
   `header.host` Evidence value.
3. Get object name from the `query.fod-js-object-name` Evidence value.
   If it’s not present or blank, use the value specified in the configuration.
   The name is written into the script as code, so it MUST be a valid
   object name, as defined under [Object name](#object-name). A requested
   name that is not valid MUST be ignored in favour of the configured name,
   and a warning SHOULD be logged that does not repeat the requested text.
4. Retrieve the Element Data for [JSON builder element](json-builder.md) from
   the Flow Data. This contains the JSON to be passed to the template.
5. Retrieve the Element Data for [Sequence Element](sequence-element.md) from
   the Flow Data. This contains the session id and sequence number to be
   passed to the template. Where there is no Sequence Element, the sequence
   MUST be rendered as `1` and the session id as an empty string, so the
   script always parses. A session id is written into the script inside
   quotes, so a session id that does not match `^[A-Za-z0-9-]{1,64}$` MUST
   be rendered as an empty string.
6. If protocol, host and endpoint are all set, meaning none of them is empty
   or only whitespace, then generate a URL in the following format:
   `[protocol]://[host][endpoint]`, adding a `/` between the host and the
   endpoint when neither has one and removing one when both do. The protocol
   and host can come from Evidence, and the template writes the URL inside a
   single-quoted JavaScript string, so the URL MUST be checked and encoded as
   described under [Callback URL](#callback-url) before it is passed to the
   template.
7. The JavaScript might need to make call backs to the server. A list of any
   query parameters that will be included in those calls needs to be created.
   This can be done by looking at the query entries in the existing Evidence:
   - Get all Evidence values starting with `query.`
   - Use the text after `query.` as the key.
   - Pass keys and values in the form needed by the template (don't forget
     URL encoding, etc. if needed).
8. If cookies are enabled from the `query.fod-js-enable-cookies` Evidence value.
   If it's not present or blank, use the value specified in the configuration.

The parameters to the existing template are:

| ***Parameter**         | **Populated from**                                                                          | **Description**                                                                                                                          |
|------------------------|---------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------|
| \_objName              | Item 3 above                                                                                | The name of the global JavaScript object to create.                                                                                      |
| \_jsonObject           | Item 4 above                                                                                | The string containing the JSON data object.                                                                                              |
| \_sessionId            | Item 5 above                                                                                | The session id is used to deduplicate requests when using the JavaScript include                                                         |
| \_sequence             | Item 5 above                                                                                | The sequence is the number of calls made by the Session ID                                                                               |
| \_supportsPromises     | False. Unless Device Detection is in the Pipeline and the ‘Promise’ Property returns ‘Full’ | If true, the script will use Promises                                                                                                    |
| \_url                  | Item 6 above                                                                                | The callback url to use when javascript Properties are executed on the client-side.                                                      |
| \_parameters           | Item 7 above                                                                                | Any query parameters in Evidence, these can be relayed in callbacks to the cloud service.                                                |
| \_enableCookies        | Item 8 above                                                                                | If false, the script will automatically use session storage instead of writing any cookies prefixed with `51D_` after evaluating Properties.                             |
| \_updateEnabled        | Will usually be true if \_url is set                                                        | If true, the JavaScript will include functionality to make callbacks to the server after evaluating JavaScript Properties.               |
| \_hasDelayedProperties | True if the JSON contains the text `delayexecution`                                         | If true, the JavaScript will include functionality to support Properties where execution of the JavaScript will be delayed until needed. |

Finally, the resulting JavaScript will be minified (or not, based on the
configuration provided). Minification SHOULD be performed using an existing
third-party library.

Performance tests MUST be in place to verify the performance impact of this
feature. (The Node JS implementation caused issues for a customer due to the
extremely poor performance of the minification library that was being used)
If it does have a significant impact, and no alternative libraries offer better
performance, a cut-down minification process MAY be implemented in order to
achieve the major benefits without a significant performance cost.

### JavaScript template functionality

The JavaScript snippet that is produced by this element MUST include the
following functionality:

- A new JavaScript object with a configurable name created in global
  scope. This is the mechanism through which the
  client-side functionality can be used.
- A way to access the results of processing in client-side JavaScript.
- A mechanism to execute any properties that contain JavaScript snippets,
  pass the output back to the server and allow the user (i.e. the third
  party developer, not the web site user) to act on the results.

#### Session storage caching

As explained in  
[web integration](../features/web-integration.md#client-side-caching),
caching SHOULD be used to reduce the need to resend data.

Since the response to the server is a POST request and
[is not cached](../features/web-integration.md#storing-results-of-post-requests),
the generated JavaScript SHOULD
include functionality to retain results of previous JSON endpoint requests
in session storage on the browser. These are stored using a key created
by combining the session ID and sequence number generated by the
[Sequence Element](sequence-element.md).

Session ID is retained for the lifetime of the session. A future request
to the JSON endpoint with the same session ID and sequence number
as a previous result can then be retrieved from session storage.

## Object name

A valid object name matches `^[A-Za-z_$][A-Za-z0-9_$]*$` and is none of
the following:

- a JavaScript reserved word, including those reserved in strict mode and
  `null`, `true` and `false`;
- `Infinity`, `NaN` or `undefined`, which a top level `var` cannot replace,
  so the object would never be created;
- `fiftyoneDegreesManager`, which is the constructor the script defines.

Where no name is configured, the name is `fod`. A configured name that is
not valid, including an empty one, MUST be refused when the element is
built, using the language's usual configuration error.

## Callback URL

The protocol and host of the callback URL come from the `header.protocol`
and `header.host` Evidence values unless they are configured, so whoever
makes the request supplies them. The URL MUST therefore meet the following
rules before it is passed to the template.

1. The protocol MUST be `http` or `https`, compared ignoring ASCII case
   only, so that a letter outside ASCII never matches one inside it. The
   script uses the URL only with `fetch` and `XMLHttpRequest`, and the Fetch
   Standard's [scheme fetch](https://fetch.spec.whatwg.org/#scheme-fetch)
   gives a network error for every scheme but `about`, `blob`, `data`,
   `file`, `http` and `https`, of which only `http` and `https` can reach a
   server. A configured protocol that is neither MUST be refused when the
   element is built, using the language's usual configuration error.
2. The authority is the host value up to its first `/`, `?` or `#`. Anything
   after that point is written after the authority and before the endpoint,
   encoded as rule 8 says.
3. The authority MAY start with user information, which ends at the first
   `@`. What follows the first `@` is the host and an optional port, so a
   second `@` fails rule 4.
4. The host MUST be one of the following.
   - An IPv6 address in square brackets, as
     [RFC 3986 section 3.2.2](https://www.rfc-editor.org/rfc/rfc3986#section-3.2.2)
     defines one, optionally followed inside the brackets by `%25` and a zone
     identifier of one or more unreserved characters
     ([RFC 3986 section 2.3](https://www.rfc-editor.org/rfc/rfc3986#section-2.3)).
     Nothing but a port may follow the closing bracket.
   - A name made of labels separated by `.`, optionally ending in `.`, where
     every label holds at least one character and only ASCII letters, digits,
     `-` and `_`. An IPv4 address in dotted decimal meets this rule. A host
     holding any character outside ASCII fails, because the Host header's
     syntax allows only ASCII
     ([RFC 9110 section 7.2](https://www.rfc-editor.org/rfc/rfc9110#section-7.2),
     [RFC 3986 section 3.2.2](https://www.rfc-editor.org/rfc/rfc3986#section-3.2.2))
     and RFC 3986 asks for an internationalized name in its IDNA form. A
     configured internationalized host MUST therefore be given as A-labels
     ([RFC 5890 section 2.3.2.1](https://www.rfc-editor.org/rfc/rfc5890#section-2.3.2.1)).
5. A port, where present, is `:` followed by nothing or by digits whose value
   is no more than 65535.
6. A URL that fails any of rules 1 to 5 MUST NOT be passed to the template,
   so the script is produced without callback functionality. An error SHOULD
   be logged the first time, written so that the URL cannot start a new log
   line.
7. ASCII letters in the protocol and the host MUST be written in lower case.
8. In the user information, in anything after the authority, and in the
   endpoint, every byte of the UTF-8 encoding that is a control character,
   is outside ASCII, is a space, or is one of `"`, `'`, `<`, `>`, `\`, `^`,
   `` ` ``, `{`, `|` and `}` MUST be percent-encoded, as MUST a `%` that is
   not followed by two hexadecimal digits.

These rules accept fewer hosts than RFC 3986 does, because the host is
written into a script rather than sent in an HTTP request.

## More than one script on a page

A page SHOULD carry one client script. Each script creates its own object,
runs its own round and creates its own identifier.

Where a page carries two, because they are built with different object names
and different resource keys, both hear an answer announced on the window and
both refresh, so the visitor's answer costs two rounds and produces two
identifiers. That is what independent scripts do, and a script does not check
which object an announcement names. A page that wants one identifier carries
one script.

## Configuration options

| **Name**         | **Type** | **Default**    | **Description**                                                                                                                                                                                               |
|------------------|----------|----------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| SetProtocol      | String   | [Empty string] | The protocol used to make a request once additional Evidence is available from client-side execution. Uses the value from Evidence by default                                                                 |
| SetHost          | String   | [Empty string] | The host used to make a request once additional Evidence is available from client-side execution. Uses the value from Evidence by default.                                                                    |
| SetEndpoint      | string   | [Empty string] | The endpoint that a request will be sent to once additional Evidence is available from client-side execution. This endpoint MUST return JSON data in the same form as the JSON embedded within the JavaScript |
| SetObjectName    | String   | fod            | The name of the JavaScript object created in the global scope on the client                                                                                                                                   |
| SetMinify        | Bool     | True           | Enable or disable minification of the Javascript that is produced                                                                                                                                             |
| SetEnableCookies | Bool     | True           | True if results of client-side processing can be retained in cookies so that they are sent by default in subsequent requests. If false, session storage will be used instead                                |
