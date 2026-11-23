# Human Confidence

Human Confidence is how confident the remote server is that a person is
using the browser. This page says what a consumer reads, and what the
language package does when the value reaches the publisher's server sealed.
A sealed value is one the browser carries exactly as the remote server made
it, and the publisher's server redeems it for the level.

## What a consumer reads

A consumer reads two Properties of the `derived` Element Data, as set out in
[Derived Property Element](../pipeline-elements/derived-property-element.md),
and nothing more. A consumer never handles a sealed value.

| **Property**            | **Values**                 |
|-------------------------|----------------------------|
| `HumanConfidence`       | `High`, `Medium`, or `Low` |
| `HumanConfidenceSource` | `Active` or `Passive`      |

HumanConfidence can also be `Unknown`, which the built-in script in
[Derived Property Element](../pipeline-elements/derived-property-element.md)
returns. A sealed value is always `High`, `Medium`, or `Low`.

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

The challenge the package kept MUST be the only `challenge` in the call.
Evidence under any prefix whose key strips to `challenge`, in any letter
case, MUST be left out of the call, as the Engine's
[processing](../pipeline-elements/cloud-request-engine.md#processing) does
for `values`, `resource`, `license`, and `licence`, and the package's own
challenge sent in its place.

The call carries the
[License Key](../pipeline-elements/cloud-request-engine.md#license-key) from
the package's own configuration, and a package MUST NOT take the License Key
from Evidence. On a request that carries a sealed value, its
[Requested Properties](../pipeline-elements/cloud-request-engine.md#requested-properties)
MUST name `derived.HumanConfidence`, which the package adds where the
configured list does not hold it. The Engine removes the prefixes as it does
for all Evidence, so the remote server receives `humanconfidence` and
`challenge`, beside `license`.

The call is the Engine's one request for the Flow Data, so the Engine's
`TimeoutSeconds` applies to it, and redeeming has no timeout of its own.

The response gives the level as `humanconfidence` in its `derived` member,
being `High`, `Medium`, or `Low`, which the package exposes as
HumanConfidence. There is no other Property to read.

### Where the sealed value is not redeemed

On a request that carries a sealed value, a package MUST give
HumanConfidence `Low` and HumanConfidenceSource `Active` where any of these
is true:

- The Pipeline has no Cloud Request Engine
- The Cloud Request Engine has no License Key
- The Cloud Request Engine made no request for the Flow Data, as in a
  [recovery period](../pipeline-elements/cloud-request-engine.md#recovery-mode)
- The request failed, or did not complete within `TimeoutSeconds`
- The `derived` member of the response is absent, or holds no
  `humanconfidence`
- The `humanconfidence` in the response is null, or is any value other than
  `High`, `Medium`, or `Low`, `Unknown` included

A read of HumanConfidence or HumanConfidenceSource MUST NOT throw for any of
these, and MUST NOT add an error of its own to the Flow Data. A failed request is still
recorded once as the Cloud Request Engine's error, as its
[processing](../pipeline-elements/cloud-request-engine.md#processing)
describes, and [exception handling](exception-handling.md#process-function)
applies to that error as it does on any other request.

## How the remote server redeems a sealed result

The remote server seals and redeems Human Confidence levels and 51Did
creator context results under the same rules.

- A sealed result redeems once.
- A sealed result redeems within 10 seconds of being made.
- A sealed result redeems only for the account it was made for. Where that
  account holds License Keys, it redeems only with a License Key of that
  account.
- A sealed result made with a challenge redeems only with that challenge.
- A response that carries a redeemed result is never cached.

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
- The call holds one `challenge`, being the one the package kept, where the
  request's Evidence also holds one
- No log entry and no error message holds the sealed value, the License Key,
  or the challenge

## Notes for implementers

- A change to this behavior is made in every language's package together,
  for the reasons given in
  [Package surface](../../did-specification/package-surface.md#why-the-surface-is-the-same-in-every-language).
- Code comments SHOULD link to the sections here rather than repeat the
  rules, as set out in the
  [repository notes for implementers](../../README.md#notes-for-implementers).
