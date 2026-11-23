# Redeem specification

This section describes how a server **redeems** a sealed result from the
remote server, and what every package that redeems one MUST do, in every
language. It builds on the concepts defined in the
[Pipeline specification](../pipeline-specification/README.md) and, for the
51Did, the [51Did specification](../did-specification/README.md).

## Why results are sealed

Some answers are worth forging. Whether a 51Did is being presented from the
connection it was created on, and how confident the remote server is that a
person is using the browser, are both answers a bad actor would change if it
could. Both are worked out from a browser's own call to the remote server, so
the answer has to travel back through that browser, and the browser must be
assumed compromised.

The remote server therefore returns these answers **sealed**. A sealed
result is an opaque string. The browser can carry it, but can't read it,
change it, or make one. The page passes it to its own server, and that server
**redeems** it: it sends the sealed result back to the remote server with its
License Key and gets the answer.

Two sealed results are redeemed this way today:

| **Sealed result**                   | **Made by**                                                                   | **Redeemed at**    |
|-------------------------------------|-------------------------------------------------------------------------------|--------------------|
| A 51Did creator context result      | The `verify-context` and `verify-full` endpoints, as `result`                 | `/api/v4/id/redeem` |
| A human confidence level            | The JSON call, as the `HumanConfidence` Property when `HumanConfidenceSource` is `Active` | `/api/v4/hc/redeem` |

Both follow one set of rules, set out below. A rule that applies to only one
of them says so.

## The rules every redemption follows

### Once, and soon

A sealed result redeems once, within **10 seconds** of the remote server
making it. The age is counted in whole seconds by the remote server's clock.
A result older than the window answers `expired`, and one already redeemed
answers `replayed`.

The record of redemptions is kept by each instance of the remote server, not
across all of them. A caller that needs a sealed result to be used once
across every instance MUST apply its own once-only rule as well, for example
by refusing a sealed result it has already seen.

### The License Key decides who can redeem

A sealed result only redeems for the account it was made for.

- Where the account holds License Keys, a License Key of that account is
  REQUIRED, and it is enough on its own. The License Key never appears in a
  page, so requiring it keeps redemption to the account's own servers and
  away from the browser that carried the result.
- Only an account that holds no License Key redeems with a Resource Key
  alone.

### The challenge or transaction value must match

Where the page was given a single-use value when the result was made, the
result only redeems with the same value. For a 51Did this is the
**challenge** given to the verify call. For human confidence it is the
**transaction value** the publisher's server put in the page. The human
confidence endpoint also accepts it under the name `challenge`.

Where no such value was given, none is sent, and an empty value is the same
as none.

### One answer for every way the inputs are wrong

A sealed result that was changed, made for another account, made with
another challenge or transaction value, made for another 51Did, or made under
a key the remote server no longer holds, answers `unreadable`. These are
deliberately not told apart, so a caller probing the endpoint learns nothing
about which part of a guess was wrong.

For the same reason, every answer about a sealed result has HTTP status 200,
including a value that isn't even well formed. The only exception is
`unconfirmed`, below.

Lateness and reuse are not secrets, so `expired` and `replayed` are named
plainly.

### Never cached

Every redeem response carries `Cache-Control: no-store`. A response holds an
answer that was spent the moment it was given, so a stored copy would hand it
to the next caller.

## The redeem endpoints

Both endpoints accept `GET` and `POST`. A package MUST use `POST` with every
input in an `application/x-www-form-urlencoded` body, so that no key or
sealed result appears in a URL or an access log.

### 51Did creator context: `/api/v4/id/redeem`

| **Input**   | **Required**                                  | **Value**                                                                          |
|-------------|-----------------------------------------------|------------------------------------------------------------------------------------|
| `51did`     | Yes                                           | The 51Did the caller holds independently, base64url. The result only redeems for the 51Did it was made for. |
| `result`    | Yes                                           | The sealed result, exactly as the verify endpoint returned it.                     |
| `challenge` | Where one was given to the verify call        | The same challenge.                                                                |
| `license`   | Where the account holds License Keys          | A License Key of the account.                                                      |
| `resource`  | Only where the account holds no License Key   | The Resource Key.                                                                  |

The answers:

| **Outcome**   | **Status** | **Body**                                                                                                                 |
|---------------|------------|--------------------------------------------------------------------------------------------------------------------------|
| Redeemed      | 200        | `{ "signature", "context", "factors"?, "verifiedAt", "secondsSinceVerified" }`                                           |
| Expired       | 200        | `{ "context": "expired", "verifiedAt", "secondsSinceVerified" }`                                                         |
| Replayed      | 200        | `{ "context": "replayed" }`                                                                                              |
| Unreadable    | 200        | `{ "context": "unreadable" }`                                                                                            |
| Unconfirmed   | 503        | `{ "context": "unconfirmed" }`                                                                                           |

On a redeemed result, `signature`, `context` and `factors` are the
verification outcomes set out in
[Package surface](../did-specification/package-surface.md#what-the-verification-outcomes-are),
and a package exposes them as that page says. The `context` field also carries
the redemption outcome on every other answer, so a package MUST read `expired`,
`replayed`, `unreadable` and `unconfirmed` as outcomes of the redemption, not
as Context outcomes.

A `51did` that is not a valid identifier answers 400, because the caller
already knows whether it sent a well formed 51Did, so naming the mistake
gives nothing away.

### Human confidence: `/api/v4/hc/redeem`

| **Input**     | **Required**                                     | **Value**                                                                                |
|---------------|--------------------------------------------------|------------------------------------------------------------------------------------------|
| `value`       | Yes                                              | The sealed `HumanConfidence` value, exactly as the JSON call returned it.                |
| `transaction` | Where the publisher put one in the page          | The same transaction value. `challenge` is accepted in its place when `transaction` is empty. |
| `license`     | Where the account holds License Keys             | A License Key of the account.                                                            |
| `resource`    | Only where the account holds no License Key      | The Resource Key.                                                                        |

The answers:

| **Outcome**   | **Status** | **Body**                                                              |
|---------------|------------|-----------------------------------------------------------------------|
| Redeemed      | 200        | `{ "humanConfidence": "High"\|"Medium"\|"Low", "verifiedAt", "secondsSinceVerified" }` |
| Expired       | 200        | `{ "result": "expired", "verifiedAt", "secondsSinceVerified" }`       |
| Replayed      | 200        | `{ "result": "replayed" }`                                            |
| Unreadable    | 200        | `{ "result": "unreadable" }`                                          |
| Unconfirmed   | 503        | `{ "result": "unconfirmed" }`                                         |

A redeemed answer carries `humanConfidence` and no `result`. Nothing about
`value` answers 400: a missing or malformed value answers `unreadable`, like
every other way the inputs can be wrong.

### The two times

`verifiedAt` is when the remote server made the sealed result, as ISO 8601
UTC to the second, for example `2026-11-23T09:15:32Z`. `secondsSinceVerified`
is how long before this redemption that was, in whole seconds by the remote
server's clock. Both describe the redemption, not the identifier or the
visitor. A result whose time is too far in the future answers `expired` with
an age of 0.

A caller needs neither for the normal flow, because the remote server has
already refused anything outside its window. They are there for a caller that
wants a stricter window, for example two seconds, without running a
synchronized clock of its own.

## What a redeeming package does

A package that redeems on a caller's behalf, in any language, MUST follow
these rules, so that a caller who knows one package knows them all.

### Inputs

- A package MUST take the License Key from its own configuration, set by the
  caller in code or in the configuration file. It MUST NOT take it from
  Evidence, from a request, or from anything a page can supply.
- A package MUST send the sealed result exactly as it received it. It MUST
  NOT decode, trim, or re-encode it.
- A package MUST send the challenge or transaction value the caller's server
  issued and kept for that page, never one read from the browser's request. A
  value the browser can choose binds nothing. A package that reads the value
  from Flow Data MUST read it from an Evidence key that no web integration
  fills from a request, and MUST NOT fall back to one that is filled from a
  request.
- A package MUST NOT log, trace, or put in an error message the License Key,
  the Resource Key, the sealed result, or the challenge or transaction value.

### Calling

- A package MUST redeem each sealed result at most once. Where its result is
  read more than once, for example through a Property read twice in the same
  request, the second read MUST give the stored outcome without another call.
- A package MUST NOT redeem when there is nothing to redeem: no sealed result,
  or, for human confidence, a `HumanConfidenceSource` other than `Active`. It
  reports the No value outcome without calling the remote server.
- A package's timeout for the redeem call SHOULD be well inside the 10 second
  window.
- A package MAY retry once after `unconfirmed`, as the remote server could not
  record the redemption and so did not spend the result. It MUST NOT retry
  after any other outcome. After a call with no answer it MUST NOT retry,
  because it can't know whether the result was spent, and reports Unreachable.

### Outcomes

A package MUST expose the outcome as a named value, in the same way it
exposes other enumerations, and never as a bare string:

| **Outcome**   | **When**                                                                                       | **Answer carried**                     |
|---------------|------------------------------------------------------------------------------------------------|----------------------------------------|
| Redeemed      | The remote server redeemed the result                                                          | The level, or the 51Did verification outcomes, and both times |
| Expired       | The result was older than the window                                                           | Both times, never a level or a verdict |
| Replayed      | The result had already been redeemed                                                           | Nothing                                |
| Unreadable    | The remote server could not open the result for these inputs, or answered with a word or level this package doesn't know | Nothing                                |
| Unconfirmed   | The remote server could not record the redemption (503)                                         | Nothing                                |
| Unreachable   | No answer in time, or a status the package doesn't expect                                       | Nothing                                |
| No value      | Nothing to redeem, so the remote server was not called                                         | Nothing                                |

- A level or a verdict MUST be exposed only on Redeemed. Every other outcome
  MUST leave it absent, using whatever that language uses for absence, and
  never a default such as `Low` or `false`.
- An outcome word a package does not know MUST be reported as Unreadable,
  with the word as the remote server sent it kept beside the value, so a
  caller can still act on it. A human confidence level other than `High`,
  `Medium` or `Low` MUST be reported the same way. An answer a package can't
  interpret never reads as a pass.
- A package MUST expose `verifiedAt` and `secondsSinceVerified` where the
  remote server sent them. It MAY let a caller set a stricter window, and MUST
  NOT widen the remote server's window.
- Status 404 means the remote server does not offer that redeem endpoint. A
  package SHOULD report it as an error naming the endpoint, not as an
  outcome. Status 400 from `/api/v4/id/redeem` means the 51Did was not valid,
  and a package SHOULD report it as an error about that argument.

### Keeping the answer on the server

- A redeemed level or verdict is for the caller's server. A package MUST NOT
  put it, or the outcome, into anything a page receives.
- A package that adds the answer to Flow Data MUST keep it out of what the
  JSON and JavaScript builder elements serialize, and reading the Element Data
  as a whole MUST NOT make the redeem call. Only reading the named Property,
  or the typed accessor, redeems.
- It is recommended that the element that redeems runs in a Pipeline used
  only on the server, not in the Pipeline that serves the page.

## Redeeming human confidence through the JSON call

A server that already calls the remote server through a Cloud Request Engine
can redeem human confidence in the same call, in place of calling
`/api/v4/hc/redeem` directly. It sends:

| **Evidence**               | **Value**                                                        |
|----------------------------|------------------------------------------------------------------|
| `query.humanconfidence`    | The sealed value                                                 |
| `query.transaction`        | The transaction value, where one was used. `query.challenge` is accepted in its place |
| The License Key            | As for any call                                                  |

and reads the answer from the `humanconfidenceredeemed` Element Data:

| **Property**           | **Value**                                                                                       |
|------------------------|-------------------------------------------------------------------------------------------------|
| `Level`                | `High`, `Medium` or `Low` on Redeemed, and no value otherwise                                   |
| `Result`               | `redeemed`, `expired`, `replayed`, `unreadable`, `unconfirmed`, or `none` when no value was sent |
| `SecondsSinceVerified` | The age, on Redeemed and Expired                                                                |

The same window, single use, License Key rule and outcomes apply as for the
endpoint, and the response is never cached.

## Notes for implementers

- The .NET packages are the reference implementation. The 51Did client is
  `DidClient` in
  [51degrees-dotnet](https://github.com/51Degrees/51degrees-dotnet/tree/main/pipeline/Did/Client),
  with its equivalents in the Java, Node, Python, PHP and Rust packages listed
  in the [51Did specification](../did-specification/README.md#notes-for-implementers).
- Code comments SHOULD link to the sections here rather than repeat the
  rules, as set out in the
  [repository notes for implementers](../README.md#notes-for-implementers).
- A change to these rules is made in every language's package together, for
  the reasons given in
  [Package surface](../did-specification/package-surface.md#why-the-surface-is-the-same-in-every-language).
