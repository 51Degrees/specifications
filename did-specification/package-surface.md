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
presented from the connection it was created on, and it carries the reasons a
check could not be completed as well as the two results, so a caller can tell
a failed comparison from a comparison that never happened. The two are
independent and a package MUST NOT derive either from the other.

The Factor block answers for each factor separately, with these values:

| **Factor outcome** | **Meaning**                                                                                                  |
|--------------------|--------------------------------------------------------------------------------------------------------------|
| Verified           | The factor matched the connection the identifier was presented on.                                            |
| Mismatch           | The factor did not match that connection.                                                                     |
| Misconfigured      | The verifying server is not able to determine that factor for any request, so it could not compare this one.   |
| Not recorded       | The issuing server recorded no value for that factor, so the identifier says nothing about it either way.      |

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

### An outcome a package does not know

The set of outcomes grows, so a package will meet a word that its own version
predates. It MUST expose such a word distinguishably from the values it does
know, and it MUST NOT report it as a Mismatch, for the reason above: a value
a package cannot interpret is not evidence against the identifier.

The Context outcome already carries the word as the server sent it beside the
named value, which is what lets a caller act on an outcome the package
predates. The Factor block does not, so an unrecognized factor word currently
reaches a caller as whatever that language chose and the word itself is lost.
The six packages also differ in what they choose, four reading an unknown word
as a Mismatch and the others answering with the word or with absence. That
divergence is a gap rather than a design, and closing it means giving the
Factor block the same word-beside-the-value treatment the Context outcome
has.

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
