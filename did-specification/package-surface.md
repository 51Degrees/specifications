# Package surface

A 51Did package reads an identifier so that no application has to. This page
says what such a package exposes in every language, and what it deliberately
does not, so that the six implementations stay the same as each other. The
byte structure the surface is built on is in
[Identifier layout](identifier-layout.md).

## What a package exposes

A package MUST expose a named accessor for every field, and it MUST answer
for the Usage with the highest usage granted rather than with the bits.

| **Field**          | **.NET**           | **Java**                | **Node**           | **Python**            | **PHP**                 | **Rust**                |
|--------------------|--------------------|-------------------------|--------------------|-----------------------|-------------------------|-------------------------|
| Usage              | `Usage`            | `getUsage()`            | `usage`            | `usage`               | `getUsage()`            | `usage()`               |
| Usage is indirect  | `UsageIsIndirect`  | `isUsageIndirect()`     | `usageIsIndirect`  | `usage_is_indirect`   | `isUsageIndirect()`     | `usage_is_indirect()`   |
| Type               | `Type`             | `getType()`             | `type`             | `type`                | `getType()`             | `id_type()`             |
| License Id         | `LicenseId`        | `getLicenseId()`        | `licenseId`        | `license_id`          | `getLicenseId()`        | `license_id()`          |
| Match Key          | `MatchKey`         | `getMatchKey()`         | `matchKey`         | `match_key`           | `getMatchKey()`         | `match_key()`           |
| Terms              | `Terms`            | `getTerms()`            | `terms`            | `terms`               | `getTerms()`            | `terms()`               |

The Usage and the Type are named values in every language, being an
enumeration or the nearest equivalent, and never bare integers. The Usage has
exactly three values, being non-marketing, standard and personalized. There
is no value for an identifier with no usage bit set, because a package MUST
refuse such a Payload, reporting it the way it reports one it cannot read, as
set out in [Identifier layout](identifier-layout.md#usage).

"Usage is indirect" answers whether the issuer worked the Usage out from a
signal other than the caller stating it. It was named "Usage from consent"
until the field was restated as direct against indirect, and the old name is
not kept, so every package exposes the name in this table and no other.

The Terms answers with the address of the document the identifier was
created under, as set out in [Identifier
layout](identifier-layout.md#terms). The package turns the index into the
address, so a caller never handles the byte.

A package MUST answer with no address where the index is zero, and where
the index is not in the table it knows, using whatever that language uses
for absence rather than an empty string. It MUST NOT build an address from
an index it does not know, since that would name a document it cannot know
exists.

A package MUST also map the Usage to the `id.usage` string the remote
server uses, being `non-marketing`, `standard` and `personalized`, so that
an application can send back the usage it read without spelling the values
out itself. Java, Node, Python, PHP and Rust each expose that mapping on
the Usage value. .NET does not, which is a gap rather than a difference of
design, recorded as pipeline-dotnet issue 399.

A package MUST refuse a Payload whose version it does not know, reporting it
the way it reports one it cannot read and naming the version it found, as
set out in [Identifier layout](identifier-layout.md#version). The version
belongs to the refusal and MUST NOT appear as a member of the identifier,
because a caller has nothing to decide with it. Either the package
understood the layout, in which case the members above are the answer, or
it did not, in which case there is no identifier to expose members for.
Naming the version in the refusal is how a package says which layout it
met, whether that is a message or a field on the error, so a caller
reading a log can tell an unknown layout from a malformed one.

Reading an identifier and verifying its signature are separate questions, and
a package MUST answer them separately, so that no caller can mistake a
structurally valid identifier for a genuine one.

## What the verification outcomes are

A package that calls the remote server's verification endpoints exposes what
came back as named values rather than as strings, in the same way it exposes
the Usage and the Type. There are three answers in one response, being the
Signature outcome, the Context outcome and, where the server sent one, a
Factor block naming each factor of the Context check and how that factor
came out.

The Signature outcome says whether the identifier is one the issuer made and
nothing has altered. The Context outcome says whether the identifier is being
presented from the connection it was created on. It says whether the
identifier was verified or mismatched, and also carries the reasons a check
could not be completed, so a caller can tell a failed comparison from a
comparison that never happened. The two are
independent and a package MUST NOT derive either from the other.

The Factor block answers for each factor separately, with these values:

| **Factor outcome** | **Meaning**                                                                                                  |
|--------------------|--------------------------------------------------------------------------------------------------------------|
| Verified           | The factor matched the connection the identifier was presented on.                                            |
| Mismatch           | The factor did not match that connection.                                                                     |
| Misconfigured      | The verifying server is not able to determine that factor for any request, so it could not compare this one.   |
| Not recorded       | The issuing server recorded no value for that factor, so the identifier says nothing about it either way.      |

The server sends these as the lower case words `verified`, `mismatch`,
`misconfigured` and `notrecorded`. The comparison ignores case, as .NET does,
so a package whose language compares exactly, such as Java, MUST lower-case
the word before it compares.

Not recorded and Mismatch are different answers and a package MUST expose
them as different values. A Mismatch is a statement about the identifier,
whereas Not recorded is the absence of one, so reading the second as the
first reports a difference the identifier never claimed and makes a genuine
identifier look replayed. Misconfigured is a third thing again, being a
statement about the verifying server rather than about the identifier or the
issuer.

A caller decides what weight to give each value, and a package MUST NOT
collapse the block into a single verdict of its own, because the point of
answering per factor is that a caller weighs an address change differently
from a changed device.

### A sealed creator context result

The remote server can return the creator context check sealed. A sealed
result is one the browser carries exactly as the remote server made it.
Redemption takes the sealed result and gives the unsealed result, which for
51Did is the Signature outcome, the Context outcome, and, where the server
sent one, the Factor block.

`id/verify-context` and `id/verify-full` return the sealed result as
`sealedResult`. They also return it as `result`, with the same content, for
packages released before `sealedResult`. A package MUST read `sealedResult`,
and MUST read `result` only where the answer holds no `sealedResult`.

A package redeems a sealed result with one POST request to `id/redeem` under
the cloud endpoint it was given. Where it was given none, it uses the address
in `_51DEGREES_CLOUD_ENDPOINT`, as
[Environment variables](../pipeline-specification/features/environment-variables.md#settings)
sets out, and where that is not set, `https://cloud.51degrees.com/api/v4/`.
Every input goes in the form body, and none in the URL.

| **Input**      | **Value**                                                                                |
|----------------|------------------------------------------------------------------------------------------|
| `51did`        | The 51Did the sealed result was made for, as base64.                                     |
| `sealedResult` | The sealed result, exactly as the caller received it.                                    |
| `result`       | The same value as `sealedResult`, under its obsolete name.                               |
| `transaction`  | The transaction the check was asked for with, or empty where it was asked for with none. |
| `challenge`    | The same value as `transaction`, under its obsolete name.                                |
| `resource`     | The Resource Key the package was given.                                                  |
| `license`      | The License Key, where the package was given one.                                        |

The transaction is a value used for one page only that the sealed result is
bound to. The caller issues it and gives it to the package, and a
transaction is OPTIONAL. A package MUST send the transaction it was given
exactly as it was given, and MUST NOT make one of its own.

The remote server answers with a JSON object. Its `status` member says what
happened, its `context` member holds the Context outcome, its `signature`
member the Signature outcome, and its `factors` member, where the server
sent one, the Factor block. A successful answer also holds the Human
Confidence Value or the reason it is not there, as
[The Human Confidence Value](#the-human-confidence-value) sets out. The
status code is 200 for every answer but Unconfirmed, which has the status
code 503. The remote server redeems the sealed result as it redeems every
sealed result, and both redeem endpoints answer in the same shape, as set
out in
[Human Confidence](../pipeline-specification/features/human-confidence.md#how-the-remote-server-redeems-a-sealed-result).

A package MUST read the answer where the status code is 200 or 503, and MUST
report a 503 as Unconfirmed whatever its body holds. Where the body of a 200
is not a JSON object, or holds neither `status` nor `context`, the package
MUST report the Redemption outcome and the Context outcome as Unreadable and
the Signature outcome as Unknown. A package makes one request for each
sealed result and MUST NOT repeat it, because a sealed result redeems once.

For any other status code a package MUST raise an error and report no
outcome.

| **Status code** | **The error**                                                                                                |
|-----------------|--------------------------------------------------------------------------------------------------------------|
| 400             | Says that an input was refused, with the remote server's message from its `errors` member, or else the body. |
| 404             | Says that the remote server at the endpoint does not offer the creator context, and names the endpoint.     |
| Any other       | Names the status code and holds the body, cut short where the body is long.                                  |

Where the request does not complete, as on a connection failure or a
timeout, a package MUST raise an error and report no outcome.

The Signature outcome has these values.

| **Signature outcome** | **Meaning**                                                                       |
|-----------------------|-----------------------------------------------------------------------------------|
| Verified              | The identifier is one the issuer made, and nothing has altered it.                |
| Invalid               | The identifier is not one the issuer made, or something has altered it.           |
| Unknown               | The answer holds no Signature outcome, or a word the package does not know.       |

The server sends the first two as the lower case words `verified` and
`invalid`.

#### The Redemption outcome

The Redemption outcome says what happened at redemption. A package reads it
from `status` and MUST expose it as a named value of its own, beside the
Signature outcome and the Context outcome.

| **Redemption outcome** | **Meaning**                                                               |
|------------------------|---------------------------------------------------------------------------|
| Success                | The sealed result redeemed.                                               |
| Expired                | The sealed result was not redeemed in time.                               |
| Replayed               | The sealed result had already been redeemed.                              |
| Unreadable             | The remote server could not read the sealed result with the inputs given. |
| Unconfirmed            | The remote server could not complete the redemption.                      |

The server sends these as the lower case words `success`, `expired`,
`replayed`, `unreadable`, and `unconfirmed`.

Where the Redemption outcome is Success, the answer gives the Signature
outcome, the Context outcome, and, where the server sent one, the Factor
block, as above. Where it is anything else, the sealed result was not
redeemed, and `context` holds the same word as `status`, as it did before
`status` was added. So the Context outcome also carries Expired, Replayed,
Unreadable, and Unconfirmed as the reason the check could not be completed.
A package MUST go on reporting these four Context outcomes, so a caller
written before the Redemption outcome works as before, and SHOULD mark them
obsolete in favor of the Redemption outcome, in the way its language marks
a member obsolete.

Where the answer holds no `status`, as from a remote server that predates
it, a package MUST take the Redemption outcome from `context`.

- It is Success where `context` holds a verdict the check reached, being
  `verified`, `mismatch`, `nocontext`, `misconfigured`, or `invaliddate`
- It is the word in `context` where that word is one of the four reasons,
  being `expired`, `replayed`, `unreadable`, or `unconfirmed`
- It is Unreadable where `context` is missing or holds any other word,
  because a package MUST NOT read a word it does not know as a pass

The answer for a sealed result that was not redeemed holds no `signature`.
A package MUST then report the Signature outcome as Unknown, being the value
it gives whenever the answer holds no Signature outcome, and MUST NOT report
it as Verified or as Invalid. That value is read from the answer and not
from the Context outcome, so the two stay independent.

### Names that are obsolete

51Did has no breaking change, so every name an endpoint read or wrote before
keeps working beside its replacement.

| **Obsolete name** | **Endpoints**                                      | **Use instead** | **Message**                               |
|-------------------|----------------------------------------------------|-----------------|-------------------------------------------|
| `result` (input)  | `id/redeem`                                        | `sealedResult`  | `result is obsolete. Use sealedResult.`   |
| `challenge`       | `id/verify-context`, `id/verify-full`, `id/redeem` | `transaction`   | `challenge is obsolete. Use transaction.` |
| `result` (answer) | `id/verify-context`, `id/verify-full`              | `sealedResult`  | None, because both names are returned     |

A call that sends an obsolete input name gets an added `obsolete` member in
its JSON answer. It is an array holding a message for each obsolete name the
call used, and nothing else in the answer changes. Where a call sends both
names, the remote server uses the current one.

A package MUST send each input under both its current name and its obsolete
name, with the same value under each. It sends `sealedResult` and `result`
to `id/redeem`. It sends `transaction` and `challenge` to `id/redeem`, and
to `id/verify-context` and `id/verify-full` where it asks for a check with a
transaction. So a package keeps working against a remote server that reads
only the obsolete names. A page that asks for the check itself sends the
transaction under both names in the same way. A package MUST NOT treat an
`obsolete` member as an error, and gets one on every such call. Where a package offers a caller a
member or parameter under an obsolete name, it keeps working, and the
package SHOULD mark it obsolete with a message naming the replacement.

### The Human Confidence Value

A 51Did can carry a Human Confidence Value, so that whoever receives the
51Did can check whether it was made for a person. The Value is the
HumanConfidence that the 51Degrees browser tests worked out on the call that
made the 51Did, as
[Human Confidence](../pipeline-specification/features/human-confidence.md)
describes.

| **Value** | **Meaning**                                                               |
|-----------|---------------------------------------------------------------------------|
| High      | The browser tests worked out High on the call that made the 51Did.        |
| Medium    | The browser tests worked out Medium on the call that made the 51Did.      |
| Low       | The browser tests worked out Low on the call that made the 51Did.         |
| Absent    | No Value was worked out for the 51Did.                                    |

Absent is returned when no Value was determined. A receiver can infer
nothing from it about who was using the browser. A 51Did is Absent when:

- It predates the remote server adding the Value to 51Dids
- The call that created it did not request HumanConfidence
- It was created without creator context
- The browser tests could not run, or ran and gave no Value
- HumanConfidence came from the request alone (HumanConfidenceSource
  `Passive`)
- The remote server answering cannot read the Value

#### Who can read the Value

Only the remote server reads the Value, and it returns the Value only to a
call that presents a License Key valid for Human Confidence. Any such
License Key reads it, whoever holds it, so a receiver further down the chain
reads the Value of a 51Did it was given with its own License Key. The
browser, and anyone else who holds the 51Did, cannot read the Value from the
identifier. The Value is not a field of the Payload, and
[Identifier layout](identifier-layout.md) does not change for it. A package
MUST NOT try to read the Value from the identifier's bytes.

The Value can be read any number of times, for as long as the 51Did's
signature verifies. A receiver judges how old the Value is from the 51Did's
date. Reading the Value adds no call, and each call is counted as it was
before.

#### Where the Value is returned

The remote server returns the Value as the member `humanConfidence`, holding
`High`, `Medium`, `Low`, or `Absent`.

| **Endpoint**                          | **Where `humanConfidence` is**                                                                                                                                                   |
|---------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id/verify`                           | Beside `valid`, for a 51Did whose signature verifies.                                                                                                                            |
| `id/verify-context`, `id/verify-full` | Beside the outcomes, in an answer that holds them openly. Where the answer is a sealed result, the Value is inside it, and `id/redeem` returns it.                              |
| `id/redeem`                           | Beside `signature` and `context` where the Redemption outcome is Success, whatever the Context outcome is.                                                                       |

The License Key that counts is the one presented on the call that returns
the Value. Where that call presents a Resource Key alone, or a License Key
that is not valid for Human Confidence, the answer holds no
`humanConfidence`. It holds `humanConfidenceNullReason` in its place, a
message that says why, as the remote server gives for any other Property
the credential does not carry. Every other member of the answer is the same
either way.

A package MUST expose the Value from each call that verifies or redeems a
51Did, as a named value with exactly the four values High, Medium, Low, and
Absent. Where the answer holds `humanConfidenceNullReason`, the package
gives no Value and that message. Where the answer holds neither member, as
from a remote server that predates the Value, the package gives no Value and
a message that says the remote server did not return one. A word the package
does not know is reported as Absent, carrying the word as the server sent
it, so it never reads as High.

#### When a 51Did carries the Value

A page and the remote server go back and forth, and the
[sequence](../pipeline-specification/pipeline-elements/sequence-element.md)
goes up by one on each iteration. Which iteration returns the 51Did depends
on whether the call requested HumanConfidence.

- A call that requested HumanConfidence gets its 51Did on the iteration that
  carries the browser test answers, and that 51Did carries the Value. The
  iterations before it return no 51Did. They return every other Property as
  usual, so only the 51Did waits. On a page, the client script reports
  complete after the iteration that returns the 51Did, as
  [When a page's results complete](../pipeline-specification/features/human-confidence.md#when-a-pages-results-complete)
  describes.
- Where the browser tests cannot run, the 51Did comes on the same
  iteration, and its Value is Absent.
- A page that never sends the browser test answers gets no 51Did, as with
  any other script whose answers the remote server is waiting for.
- A call that did not request HumanConfidence gets its 51Did exactly as
  before, and its Value is Absent.

The same is true where the publisher's server makes the call, passing the
page's script to the browser and the browser's answers back to the remote
server. A call from the server that requested HumanConfidence gets no 51Did
until a later call carries the browser test answers. So a server that
requests HumanConfidence has to pass the page's script on to the browser and
the answers back, or it gets no 51Did on any call. A server that needs a
51Did on every call and cannot pass the script on should leave
HumanConfidence out of its request.

A server can also supply the visitor's JA4 and H2. They are used only on a
call that presents a License Key valid for Human Confidence, and the call is
then judged on them. On any other call they are not used, and the call is
judged as if they were not supplied.

A sealed Human Confidence result sent back to the remote server adds nothing
to a 51Did. A caller can use the 51Did alone, without redeeming any sealed
result.

### An outcome a package does not know

The set of outcomes grows, so a package will meet a word that its own version
predates. A package MUST NOT read such a word as a pass.

A factor word a package does not know MUST be reported as a Mismatch.
Verified, Misconfigured and Not recorded are each read only from their own
word, because none of them is a Mismatch, and any other word is a Mismatch, so
an unexpected value never reads as a factor that matched or as one that could
not be compared. A package that predates a new factor word therefore reports
it as a Mismatch until the package is updated, which is the cost of never
reading a value it cannot interpret as a pass.

A Context word a package does not know is reported as Unreadable, and the
Context outcome carries the word as the server sent it beside that value, so a
caller can still act on a Context outcome the package predates. Where the
remote server itself answers `unreadable`, the word carried is `unreadable`,
so a caller tells the two cases apart by the word carried.

A `status` word a package does not know is reported as the Redemption
outcome Unreadable in the same way, carrying the word as the server sent it.
A Human Confidence word a package does not know is reported as Absent, as
[Where the Value is returned](#where-the-value-is-returned) sets out.

## What a package does not expose

A package MUST NOT make any of the following public, in any language.

| **Not exposed**            | **Reason**                                                                                                                                    |
|----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| The raw flags byte         | Every bit of it has a name. The byte is the way back to masking, and masking for the non-marketing bit reads every marketing identifier as non-marketing. |
| The offsets and lengths    | The only reason to want an offset is to read the payload by hand, and the only reason to do that is to read a field that already has a name.   |
| The Terms index            | The index is meaningless without the table, and a caller holding the number is a caller who might compose an address from it. The address is the answer. |
| The Payload version        | A caller has nothing to decide with it, since the package either read the layout or refused it. It belongs to the refusal instead. |

An implementation still needs the offsets and lengths internally, and its own
tests build payloads byte by byte, so each language keeps them on a
non-public path rather than deleting them, being `internal` in .NET,
package-private in Java, a module that is not exported in Node, an underscore
module in Python, a class that is not part of the published surface in PHP,
and `pub(crate)` in Rust. The named value behind the Terms is kept on that
same non-public path in every language, so a caller only ever sees the
address.

Code that creates identifiers is in the same position, and it MUST reach the
layout through the issuer's own definition of it rather than through a
reader's public surface, so that the layout is stated once on each side and
checked against [Identifier layout](identifier-layout.md).

## Why the surface is the same in every language

An application written against one language's package is read, reviewed and
copied by people working in another. Where the packages agree, a reviewer who
knows one knows them all, and a rule written once holds everywhere. Where they
drift, a decision that is safe in one language is quietly unavailable in the
next. A change to the surface is therefore made in all six packages together,
and this page is the record of what that surface is.
