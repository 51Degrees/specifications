# Human Confidence

Human Confidence is how confident the remote server is that a person is
using the browser. This page says what a consumer reads, what the language
package does when the Value reaches the publisher's server sealed, how the
remote server answers a redemption, and what a 51Did carries.

A sealed result is one the browser carries exactly as the remote server made
it. Redemption takes a sealed result and gives the unsealed result. For Human
Confidence the unsealed result is the Value, being `High`, `Medium`, or
`Low`.

## What a consumer reads

A consumer reads two Properties of the `derived` Element Data, as set out in
[Derived Property Element](../pipeline-elements/derived-property-element.md),
and nothing more. A consumer never reads a Value from a sealed result and
never redeems one, because the package does both.

| **Property**            | **Values**                 |
|-------------------------|----------------------------|
| `HumanConfidence`       | `High`, `Medium`, or `Low` |
| `HumanConfidenceSource` | `Active` or `Passive`      |

HumanConfidence can also be `Unknown`, which the built-in script in
[Derived Property Element](../pipeline-elements/derived-property-element.md)
returns. A sealed result always redeems to `High`, `Medium`, or `Low`.

HumanConfidenceSource says how HumanConfidence was worked out for the
request. `Passive` means HumanConfidence was worked out from the request
alone. `Active` means the browser also ran the 51Degrees browser tests, and
HumanConfidence then reaches the publisher's server sealed, as
[When HumanConfidence arrives sealed](#when-humanconfidence-arrives-sealed)
sets out. On a request that carries no sealed result, the two Properties are
the ones the Pipeline gives without this page, which where the Pipeline uses
the cloud are the ones in the `derived` member of the remote server's
response.

Where the credential does not carry HumanConfidence or HumanConfidenceSource,
and the request carries no sealed result, that Property has no value, and a
read of it gives a message that says why, as for any other Property the
credential does not carry. The message is the remote server's null reason
where the response holds the Property as null, as the
[Cloud Aspect Engine](../pipeline-elements/cloud-aspect-engine.md#processing)
describes, and the reason from
[Missing Properties](properties.md#missing-properties) where the response
leaves the Property out. A test that reads either Property with such a
credential MUST expect no value and that message, and an example shows that
message as it shows any other Property with no value.

## When HumanConfidence arrives sealed

Where the page uses the 51Degrees client script with the remote server and
HumanConfidenceSource is `Active`, HumanConfidence reaches the publisher's
server as a sealed result. A `Passive` HumanConfidence is never sealed. The
page sends the sealed result to the publisher's server as the parameter
`humanconfidence`, which the
[web integration](web-integration.md#populating-evidence) adds as the
Evidence `query.humanconfidence`.

A request carries a sealed result where its Evidence holds
`query.humanconfidence` with a value that is not empty. On every such
request the language package's server-side Pipeline MUST redeem the sealed
result itself, as
[Redeeming through the JSON call](#redeeming-through-the-json-call) sets
out, and MUST give the two Properties as this table says.

| **Case**                           | **HumanConfidenceSource** | **HumanConfidence**                   |
|------------------------------------|---------------------------|---------------------------------------|
| The sealed result was redeemed     | `Active`                  | The Value, `High`, `Medium`, or `Low` |
| The sealed result was not redeemed | `Active`                  | `Medium`                              |

The Value is `Medium` whenever a sealed result was not redeemed, because
Human Confidence can't be worked out from a sealed result that didn't
redeem. The remote server gives the same Value for a sealed result it does
not redeem. A package MUST NOT give `High` or `Low` for a sealed result it
has not redeemed.

A package MUST give HumanConfidenceSource `Active` on every request that
carries a sealed result, whether or not it was redeemed. The package sets
`Active` itself, because the remote server seals only an `Active` Value, so
it does not ask the remote server for HumanConfidenceSource in order to
redeem.

A package MUST redeem a sealed result once for a request. Every read of
HumanConfidence for that request gives the same Value and makes no further
request to the remote server.

On a request that carries no sealed result, nothing on this page changes
what the Pipeline does.

Redemption belongs to the package. An example MUST NOT redeem a sealed
result itself, and only shows the two Properties being read.

## The transaction

Each sealed result is bound to the page that asked for it by a
**transaction**, a value used for one page only. The name is the one a
[sealed 51Did creator context result](../../did-specification/package-surface.md#a-sealed-creator-context-result)
uses. For Human Confidence the package issues the transaction, so a
transaction is REQUIRED for every sealed result the package redeems. For
51Did the caller issues it, and it is OPTIONAL.

In this specification a challenge is only a type of browser test, and never
this value. The transaction was once called a challenge, and 51Did keeps
`challenge` as an obsolete name for it.

1. The package MUST give each page it serves a new transaction, and MUST
   keep the transaction on the server.
2. The page sends the transaction to the remote server when it asks for
   Human Confidence, and the remote server binds the sealed result to that
   transaction.
3. The package MUST send the transaction it kept when it redeems the sealed
   result, so the sealed result redeems only for the page it was made for.

A package MUST NOT use one transaction for two pages, and MUST NOT take the
transaction it redeems with from the request. The package issues and checks
the transaction itself, so a consumer never sees it.

## Redeeming through the JSON call

The JSON call is the request that the
[Cloud Request Engine](../pipeline-elements/cloud-request-engine.md) makes to
the `json` endpoint for each Flow Data, as its
[processing](../pipeline-elements/cloud-request-engine.md#processing)
describes. The package redeems through that call. It MUST NOT make another
request to redeem, and it uses no other endpoint. The call holds this
Evidence.

| **Evidence**            | **Value**                                |
|-------------------------|------------------------------------------|
| `query.humanconfidence` | The sealed result, exactly as it arrived |
| `query.transaction`     | The transaction the package kept         |

The transaction the package kept MUST be the only transaction in the call.
Evidence under any prefix whose key strips to `transaction` or `challenge`,
in any letter case, MUST therefore be left out of the call, as the Engine's
[processing](../pipeline-elements/cloud-request-engine.md#processing) does
for `values`, `resource`, `license`, and `licence`, and the package's own
transaction sent as `transaction` in its place. `challenge` is left out as
well, because it is the older name for the same value.

The call carries the
[License Key](../pipeline-elements/cloud-request-engine.md#license-key) from
the package's own configuration, and a package MUST NOT take the License Key
from Evidence. On a request that carries a sealed result, its
[Requested Properties](../pipeline-elements/cloud-request-engine.md#requested-properties)
MUST name `derived.HumanConfidence`, which the package adds where the
configured list does not hold it. A name the package adds MUST be left out
of the comparison and the report that
[Properties the remote server did not return](../pipeline-elements/cloud-request-engine.md#properties-the-remote-server-did-not-return)
describes, so the report is made for the configured list alone and stays
the same from one request to the next. The Engine removes the prefixes as
it does for all Evidence, so the remote server receives `humanconfidence` and
`transaction`, beside `license`.

The call is the Engine's one request for the Flow Data, so the Engine's
`TimeoutSeconds` applies to it, and redemption has no timeout of its own.

The response gives the Value as `humanconfidence` in its `derived` member,
being `High`, `Medium`, or `Low`, which the package exposes as
HumanConfidence. The package reads no other Property. That member answers
for the sealed result alone, as
[How the remote server redeems a sealed result](#how-the-remote-server-redeems-a-sealed-result)
sets out.

### Where the sealed result is not redeemed

On a request that carries a sealed result, a package MUST give
HumanConfidence `Medium` and HumanConfidenceSource `Active` where any of
these is true:

- The Pipeline has no Cloud Request Engine
- The Cloud Request Engine has no License Key
- The package holds no transaction it kept for the page the request came
  from, as when the transaction was used before
- The Cloud Request Engine made no request for the Flow Data, as in a
  [recovery period](../pipeline-elements/cloud-request-engine.md#recovery-mode)
- The request failed, or did not complete within `TimeoutSeconds`
- The response's top-level `errors` list says that HumanConfidence is not
  covered by the credential
- The `derived` member of the response is absent, or holds no
  `humanconfidence`
- The `humanconfidence` in the response is null, or is any value other than
  `High`, `Medium`, or `Low`, `Unknown` included

A read of HumanConfidence or HumanConfidenceSource MUST NOT throw for any of
these, and MUST NOT add an error of its own to the Flow Data. A failed
request is still recorded once as the Cloud Request Engine's error, as its
[processing](../pipeline-elements/cloud-request-engine.md#processing)
describes, and [exception handling](exception-handling.md#process-function)
applies to that error as it does on any other request. A failure met once
processing has finished would otherwise reach the reader as an error from
the read, as that processing describes. For these two Properties on a
request that carries a sealed result, the read gives `Medium` and `Active`
in its place.

## How the remote server redeems a sealed result

The remote server redeems sealed Human Confidence results and sealed 51Did
creator context results under the same rules.

- A sealed result redeems once.
- A sealed result redeems within 10 seconds of being made.
- A sealed result redeems only for the account it was made for.
- A sealed result made with a transaction redeems only with that
  transaction, and one made with none only with none.
- A response that carries an unsealed result is never cached.

### The redeem endpoints

The remote server has two redeem endpoints, and both answer in the same
shape. `id/redeem` redeems a sealed 51Did creator context result, as
[Package surface](../../did-specification/package-surface.md#a-sealed-creator-context-result)
sets out for a package. `hc/redeem` redeems a sealed Human Confidence result
for a server that does not use a package. A package redeems through the
JSON call instead, and makes no request to `hc/redeem`.

Both endpoints take the sealed result as `sealedResult`, the transaction as
`transaction` where the sealed result was made with one, and the License Key
of the account the sealed result was made for. `id/redeem` also takes the
51Did as `51did`. `id/redeem` goes on reading `result` and `challenge`, the
obsolete names of `sealedResult` and `transaction`, as
[Package surface](../../did-specification/package-surface.md#names-that-are-obsolete)
sets out. `hc/redeem` reads neither.

Both answer with a JSON object that holds these members.

| **Member**                           | **`id/redeem`**                                                     | **`hc/redeem`**   |
|--------------------------------------|---------------------------------------------------------------------|-------------------|
| The unsealed result                  | `signature`, `context`, `factors` where sent, and `humanConfidence` | `humanConfidence` |
| `status`                             | What happened                                                       | What happened     |
| `verifiedAt`, `secondsSinceVerified` | Where `status` is `success` or `expired`                            | The same          |

`status` holds one of these words, which are the same at both endpoints.

| **`status`**  | **Meaning**                                                               |
|---------------|---------------------------------------------------------------------------|
| `success`     | The sealed result redeemed.                                               |
| `expired`     | The sealed result was not redeemed in time.                               |
| `replayed`    | The sealed result had already been redeemed.                              |
| `unreadable`  | The remote server could not read the sealed result with the inputs given. |
| `unconfirmed` | The remote server could not complete the redemption.                      |

The status code is 503 for `unconfirmed`, inviting a retry, and 200 for
every other answer.

`verifiedAt` is when the check was made, in UTC to the second, and
`secondsSinceVerified` is the number of seconds since then.

At `hc/redeem`, `humanConfidence` is always `High`, `Medium`, or `Low`, as a
`Passive` HumanConfidence is, and it is `Medium` whenever `status` is not
`success`.

At `id/redeem`, the unsealed result is present only where `status` is
`success`. On any other status, `context` holds the same word as `status`,
as it did before `status` was added. On `success`, `humanConfidence` is the
Value the 51Did carries, or `humanConfidenceNullReason` in its place, as
[The Human Confidence Value](../../did-specification/package-surface.md#the-human-confidence-value)
sets out.

### The JSON call

On a call that holds `humanconfidence`, the `humanconfidence` in the
`derived` member of the response answers for that sealed result alone. It is
the Value where the sealed result redeemed, and `Medium` for every other
status. The `humanconfidencesource` beside it is `Active`. The remote server
never answers such a call with a Value worked out from the call's other
Evidence.

An unsealed result is a value created for one request, so the rule for a
request that carries a sealed result is in
[Caching](caching.md#values-created-for-one-request).

## Human Confidence in a 51Did

A 51Did can carry the Value the browser tests worked out on the call that
made it, so that a receiver of the 51Did can check whether it was made for a
person. Where no Value was worked out, the 51Did carries Absent.
[The Human Confidence Value](../../did-specification/package-surface.md#the-human-confidence-value)
says who can read it, which values there are, and on which request a 51Did
arrives when the call requested HumanConfidence.

## What a package never exposes

The sealed result is the Evidence `query.humanconfidence`, and the page
carries the sealed result and the transaction. Beyond that, a package MUST
keep to these rules.

| **Value**         | **A package MUST NOT**                                                                                                                                                               |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| The sealed result | Add it to any Element Data, or to the output of the [JSON Builder](../pipeline-elements/json-builder.md) or the [JavaScript Builder](../pipeline-elements/javascript-builder.md)       |
| The transaction   | Offer the consumer an accessor for it                                                                                                                                                |
| The License Key   | Put it into anything a page receives, including the output of the JSON Builder and the JavaScript Builder                                                                            |

A package MUST NOT write the sealed result, the License Key, or the
transaction, in whole or in part, to a log entry or an error message. For
these three values this rule applies in place of the one in
[License Key](../pipeline-elements/cloud-request-engine.md#license-key), and
it covers every message the Cloud Request Engine builds from a request or a
response.

## Required tests

There MUST be a test for each of these:

- A sealed result that redeems gives the Value in the response as
  HumanConfidence, with HumanConfidenceSource `Active`
- Each case in
  [Where the sealed result is not redeemed](#where-the-sealed-result-is-not-redeemed)
  gives `Medium` and `Active`, and the read adds no error of its own
- Two reads of HumanConfidence for one request make one request to the
  remote server
- A request that carries a sealed result is neither stored in nor served
  from a cache
- The call holds one transaction, being the one the package kept, sent as
  `transaction`, where the request's Evidence also holds a `transaction` or
  a `challenge`
- No log entry and no error message holds the sealed result, the License
  Key, or the transaction
- A read of HumanConfidence or HumanConfidenceSource with a credential that
  does not carry it gives no value and the message that says why

## Notes for implementers

- A change to this behavior is made in every language's package together,
  for the reasons given in
  [Package surface](../../did-specification/package-surface.md#why-the-surface-is-the-same-in-every-language).
- Code comments SHOULD link to the sections here rather than repeat the
  rules, as set out in the
  [repository notes for implementers](../../README.md#notes-for-implementers).
