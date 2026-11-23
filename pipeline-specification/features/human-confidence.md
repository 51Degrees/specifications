# Human Confidence

Human Confidence is how confident the remote server is that a person is
using the browser. This page says what a consumer reads, and what the
language package does when the value reaches the publisher's server sealed,
meaning the browser can carry the value but cannot read or change it.

## What a consumer reads

A consumer reads two Properties of the `derived` Element Data, as set out in
[Derived Property Element](../pipeline-elements/derived-property-element.md),
and nothing more. A consumer never handles a sealed value.

| **Property**            | **Values**                |
|-------------------------|---------------------------|
| `HumanConfidence`       | `High`, `Medium` or `Low` |
| `HumanConfidenceSource` | `Active` or `Passive`     |

HumanConfidence can also be `Unknown`, which the built-in script in
[Derived Property Element](../pipeline-elements/derived-property-element.md)
returns. A sealed value is always `High`, `Medium` or `Low`.

## When HumanConfidence arrives sealed

Where the page uses the 51Degrees client script with the remote server and
HumanConfidenceSource is `Active`, HumanConfidence reaches the publisher's
server sealed. A `Passive` HumanConfidence is never sealed. The page sends
the sealed value to the publisher's server as the parameter
`humanconfidence`, which the
[web integration](web-integration.md#populating-evidence) adds as the
Evidence `query.humanconfidence`.

The language package's server-side Pipeline redeems the sealed value itself,
as the 51Did packages do their work, and HumanConfidence then carries the
level that came back. Examples only show the two Properties being read.

| **Case**                          | **HumanConfidenceSource** | **HumanConfidence**                  |
|-----------------------------------|---------------------------|--------------------------------------|
| The sealed value was redeemed     | `Active`                  | The level, `High`, `Medium` or `Low` |
| The sealed value was not redeemed | `Active`                  | `Low`                                |

The package redeems a sealed value once, and every read of HumanConfidence
for that request gives the same level.

## The challenge

Each sealed value is bound to the page that asked for it by a **challenge**,
a value used for one page only. A
[sealed 51Did creator context result](../../did-specification/package-surface.md#a-sealed-creator-context-result)
is bound the same way, under the same name.

1. The package gives each page it serves a new challenge, and keeps the
   challenge on the server.
2. The page sends the challenge to the remote server when it asks for Human
   Confidence, and the remote server seals the result to that challenge.
3. The package sends the challenge it kept when it redeems the sealed value,
   so the value redeems only for the page it was made for.

The package issues and checks the challenge itself, so a consumer never sees
it.

## Redeeming through the JSON call

The package redeems through the JSON call that its
[Cloud Request Engine](../pipeline-elements/cloud-request-engine.md) already
makes, with this Evidence.

| **Evidence**            | **Value**                                                     |
|-------------------------|---------------------------------------------------------------|
| `query.humanconfidence` | The sealed value, exactly as it arrived                       |
| `query.challenge`       | The challenge the package kept, replacing any in the request  |

The call carries the
[License Key](../pipeline-elements/cloud-request-engine.md#license-key) from
the package's own configuration, and names `derived.HumanConfidence` in its
[Requested Properties](../pipeline-elements/cloud-request-engine.md#requested-properties).
The Engine removes the prefixes as it does for all Evidence, so the remote
server receives `humanconfidence` and `challenge`, beside `license`.

The response gives the level as `humanconfidence` in its `derived` member,
being `High`, `Medium` or `Low`, which the package exposes as
HumanConfidence. There is no other Property to read. Where the package has
no License Key, the call fails, or the response holds no level, the package
gives HumanConfidence `Low`.

## What the service guarantees

The remote server seals and redeems Human Confidence levels and 51Did
creator context results under the same rules.

- A sealed result redeems once.
- A sealed result redeems within 10 seconds of being made.
- A sealed result redeems only for the account it was made for, with a
  License Key of that account.
- A response that carries a redeemed result is never cached.

A package MUST NOT store a redeemed level in a cache or serve one from it, as
[Caching](caching.md#values-created-for-one-request) says for every value
created for one request. For the Cloud Request Engine, a request that carries
`query.humanconfidence` is neither stored in nor served from the cache.

## What a package never exposes

A package MUST NOT make the sealed value, the License Key or the challenge
part of its public surface, or write any of them to a log. The page carries
the sealed value and the challenge, but the License Key never goes into
anything a page receives.

## Notes for implementers

- A change to this behavior is made in every language's package together,
  for the reasons given in
  [Package surface](../../did-specification/package-surface.md#why-the-surface-is-the-same-in-every-language).
- Code comments SHOULD link to the sections here rather than repeat the
  rules, as set out in the
  [repository notes for implementers](../../README.md#notes-for-implementers).
