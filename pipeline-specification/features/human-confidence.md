# Human Confidence

Human Confidence is how confident the remote server is that a person is
using the browser. This page says what a consumer reads, and what the
language package does when the value reaches the publisher's server sealed.
A sealed value is one the browser carries exactly as the remote server made
it, and the publisher's server redeems it for the level.

## What a consumer reads

A consumer reads two Properties of the `derived` Element Data, as set out in
[Derived Property Element](../pipeline-elements/derived-property-element.md),
and nothing more. A consumer never reads a level from a sealed value and
never redeems one, because the package does both.

| **Property**            | **Values**                 |
|-------------------------|----------------------------|
| `HumanConfidence`       | `High`, `Medium`, or `Low` |
| `HumanConfidenceSource` | `Active` or `Passive`      |

HumanConfidence can also be `Unknown`, which the built-in script in
[Derived Property Element](../pipeline-elements/derived-property-element.md)
returns. A sealed value is always `High`, `Medium`, or `Low`.

HumanConfidenceSource says how HumanConfidence was worked out for the
request. `Passive` means HumanConfidence was worked out from the request
alone. `Active` means the browser also ran the 51Degrees browser tests, and
HumanConfidence then reaches the publisher's server sealed, as
[When HumanConfidence arrives sealed](#when-humanconfidence-arrives-sealed)
sets out. On a request that carries no sealed value, the two Properties are
the ones the Pipeline gives without this page, which where the Pipeline uses
the cloud are the ones in the `derived` member of the remote server's
response.

Where the credential does not carry HumanConfidence or HumanConfidenceSource,
and the request carries no sealed value, that Property has no value, and a
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
server sealed. A `Passive` HumanConfidence is never sealed. The page sends
the sealed value to the publisher's server as the parameter
`humanconfidence`, which the
[web integration](web-integration.md#populating-evidence) adds as the
Evidence `query.humanconfidence`.

A request carries a sealed value where its Evidence holds
`query.humanconfidence` with a value that is not empty. On every such
request the language package's server-side Pipeline MUST redeem the sealed
value itself, as
[Redeeming through the JSON call](#redeeming-through-the-json-call) sets
out, and MUST give the two Properties as this table says.

| **Case**                          | **HumanConfidenceSource** | **HumanConfidence**                   |
|-----------------------------------|---------------------------|---------------------------------------|
| The sealed value was redeemed     | `Active`                  | The level, `High`, `Medium`, or `Low` |
| The sealed value was not redeemed | `Active`                  | `Low`                                 |

A package MUST NOT give a level from a sealed value it has not redeemed.

A package MUST give HumanConfidenceSource `Active` on every request that
carries a sealed value, whether or not the value was redeemed. The package
sets `Active` itself, because the remote server seals only an `Active`
level, so it does not ask the remote server for HumanConfidenceSource in
order to redeem.

A package MUST redeem a sealed value once for a request. Every read of
HumanConfidence for that request gives the same level and makes no further
request to the remote server.

On a request that carries no sealed value, nothing on this page changes what
the Pipeline does.

Redeeming belongs to the package. An example MUST NOT redeem a sealed value
itself, and only shows the two Properties being read.

## The challenge

Each sealed value is bound to the page that asked for it by a **challenge**,
a value used for one page only. The name is the one a
[sealed 51Did creator context result](../../did-specification/package-surface.md#a-sealed-creator-context-result)
uses. For Human Confidence the package issues the challenge, so a challenge
is REQUIRED for every sealed value. For 51Did the caller issues it, and it
is OPTIONAL.

1. The package MUST give each page it serves a new challenge, and MUST keep
   the challenge on the server.
2. The page sends the challenge to the remote server when it asks for Human
   Confidence, and the remote server seals the result to that challenge.
3. The package MUST send the challenge it kept when it redeems the sealed
   value, so the value redeems only for the page it was made for.

A package MUST NOT use one challenge for two pages, and MUST NOT take the
challenge it redeems with from the request. The package issues and checks
the challenge itself, so a consumer never sees it.

## Redeeming through the JSON call

The JSON call is the request that the
[Cloud Request Engine](../pipeline-elements/cloud-request-engine.md) makes to
the `json` endpoint for each Flow Data, as its
[processing](../pipeline-elements/cloud-request-engine.md#processing)
describes. The package redeems through that call. It MUST NOT make another
request to redeem, and it uses no other endpoint. The call holds this
Evidence.

| **Evidence**            | **Value**                               |
|-------------------------|-----------------------------------------|
| `query.humanconfidence` | The sealed value, exactly as it arrived |
| `query.challenge`       | The challenge the package kept          |

The challenge the package kept MUST be the only challenge in the call. The
remote server also reads `transaction` as another name for the challenge.
Evidence under any prefix whose key strips to `challenge` or `transaction`,
in any letter case, MUST therefore be left out of the call, as the Engine's
[processing](../pipeline-elements/cloud-request-engine.md#processing) does
for `values`, `resource`, `license`, and `licence`, and the package's own
challenge sent as `challenge` in its place.

The call carries the
[License Key](../pipeline-elements/cloud-request-engine.md#license-key) from
the package's own configuration, and a package MUST NOT take the License Key
from Evidence. On a request that carries a sealed value, its
[Requested Properties](../pipeline-elements/cloud-request-engine.md#requested-properties)
MUST name `derived.HumanConfidence`, which the package adds where the
configured list does not hold it. A name the package adds MUST be left out
of the comparison and the report that
[Properties the remote server did not return](../pipeline-elements/cloud-request-engine.md#properties-the-remote-server-did-not-return)
describes, so the report is made for the configured list alone and stays
the same from one request to the next. The Engine removes the prefixes as
it does for all Evidence, so the remote server receives `humanconfidence` and
`challenge`, beside `license`.

The call is the Engine's one request for the Flow Data, so the Engine's
`TimeoutSeconds` applies to it, and redeeming has no timeout of its own.

The response gives the level as `humanconfidence` in its `derived` member,
being `High`, `Medium`, or `Low`, which the package exposes as
HumanConfidence. There is no other Property to read. That member answers
for the sealed value alone, as
[How the remote server redeems a sealed result](#how-the-remote-server-redeems-a-sealed-result)
sets out.

### Where the sealed value is not redeemed

On a request that carries a sealed value, a package MUST give
HumanConfidence `Low` and HumanConfidenceSource `Active` where any of these
is true:

- The Pipeline has no Cloud Request Engine
- The Cloud Request Engine has no License Key
- The package holds no challenge it kept for the page the request came
  from, as when the challenge was used before
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
request that carries a sealed value, the read gives `Low` and `Active` in
its place.

## How the remote server redeems a sealed result

The remote server seals and redeems Human Confidence levels and 51Did
creator context results under the same rules.

- A sealed result redeems once.
- A sealed result redeems within 10 seconds of being made.
- A sealed result redeems only for the account it was made for.
- A sealed result made with a challenge redeems only with that challenge.
- A response that carries a redeemed result is never cached.

On a call that holds `humanconfidence`, the `humanconfidence` in the
`derived` member of the response answers for that sealed value alone. It is
the level where the value redeemed, `Low` where the value did not redeem,
and null with a `humanconfidencenullreason` where the remote server could
not complete the redemption. The `humanconfidencesource` beside it is
`Active`. The remote server never answers such a call with a level worked
out from the call's other Evidence.

A redeemed level is a value created for one request, so the rule for a
request that carries a sealed value is in
[Caching](caching.md#values-created-for-one-request).

## What a package never exposes

The sealed value is the Evidence `query.humanconfidence`, and the page
carries the sealed value and the challenge. Beyond that, a package MUST keep
to these rules.

| **Value**        | **A package MUST NOT**                                                                                                                                                               |
|------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| The sealed value | Add it to any Element Data, or to the output of the [JSON Builder](../pipeline-elements/json-builder.md) or the [JavaScript Builder](../pipeline-elements/javascript-builder.md)       |
| The challenge    | Offer the consumer an accessor for it                                                                                                                                                |
| The License Key  | Put it into anything a page receives, including the output of the JSON Builder and the JavaScript Builder                                                                            |

A package MUST NOT write the sealed value, the License Key, or the
challenge, in whole or in part, to a log entry or an error message. For
these three values this rule applies in place of the one in
[License Key](../pipeline-elements/cloud-request-engine.md#license-key), and
it covers every message the Cloud Request Engine builds from a request or a
response.

## Required tests

There MUST be a test for each of these:

- A sealed value that redeems gives the level in the response as
  HumanConfidence, with HumanConfidenceSource `Active`
- Each case in
  [Where the sealed value is not redeemed](#where-the-sealed-value-is-not-redeemed)
  gives `Low` and `Active`, and the read adds no error of its own
- Two reads of HumanConfidence for one request make one request to the
  remote server
- A request that carries a sealed value is neither stored in nor served from
  a cache
- The call holds one challenge, being the one the package kept, sent as
  `challenge`, where the request's Evidence also holds a `challenge` or a
  `transaction`
- No log entry and no error message holds the sealed value, the License Key,
  or the challenge
- A read of HumanConfidence or HumanConfidenceSource with a credential that
  does not carry it gives no value and the message that says why

## Notes for implementers

- A change to this behavior is made in every language's package together,
  for the reasons given in
  [Package surface](../../did-specification/package-surface.md#why-the-surface-is-the-same-in-every-language).
- Code comments SHOULD link to the sections here rather than repeat the
  rules, as set out in the
  [repository notes for implementers](../../README.md#notes-for-implementers).
