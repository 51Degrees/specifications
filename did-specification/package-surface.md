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
| Usage from consent | `UsageFromConsent` | `isUsageFromConsent()`  | `usageFromConsent` | `usage_from_consent`  | `isUsageFromConsent()`  | `usage_from_consent()`  |
| Type               | `Type`             | `getType()`             | `type`             | `type`                | `getType()`             | `id_type()`             |
| License Id         | `LicenseId`        | `getLicenseId()`        | `licenseId`        | `license_id`          | `getLicenseId()`        | `license_id()`          |
| Match Key          | `MatchKey`         | `getMatchKey()`         | `matchKey`         | `match_key`           | `getMatchKey()`         | `match_key()`           |
| Terms              | `Terms`            | `getTerms()`            | `terms`            | `terms`               | `getTerms()`            | `terms()`               |
| Terms Index        | `TermsIndex`       | `getTermsIndex()`       | `termsIndex`       | `terms_index`         | `getTermsIndex()`       | `terms_index()`         |
| Terms Url          | `TermsUrl`         | `getTermsUrl()`         | `termsUrl`         | `terms_url`           | `getTermsUrl()`         | `terms_url()`           |

The Usage and the Type are named values in every language, being an
enumeration or the nearest equivalent, and never bare integers.

The Terms is a named value like the Usage and the Type, the Terms Index is
the byte behind it, and the Terms Url is the address it stands for, all as
set out in [Identifier layout](identifier-layout.md#terms).

A package MUST answer with no address where the index is zero, or where the
index is one it does not know, using whatever that language uses for
absence, and it MUST NOT answer with an empty string or with an address
built from the index.

The Terms Index is the one place this specification asks for a raw value,
and it is asked for because a package will meet an index added after it was
released. Without the index such a caller has a named value meaning unknown
and no way to find out what it stands for, so it can neither look the
document up by hand nor report which index it could not read. The Terms
therefore has a value for an index the package does not know, and that value
MUST be distinct from the one for zero.

A package MUST also map the Usage to the `id.usage` string the remote
server uses, being `non-marketing`, `standard` and `personalized`, so that
an application can send back the usage it read without spelling the values
out itself. Java, Node, Python, PHP and Rust each expose that mapping on
the Usage value. .NET does not, which is a gap rather than a difference of
design, recorded as pipeline-dotnet issue 399.

Reading an identifier and verifying its signature are separate questions, and
a package MUST answer them separately, so that no caller can mistake a
structurally valid identifier for a genuine one.

## What a package does not expose

A package MUST NOT make any of the following public, in any language.

| **Not exposed**            | **Reason**                                                                                                                                    |
|----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| The raw flags byte         | Every bit of it has a name. The byte is the way back to masking, and masking for the non-marketing bit reads every marketing identifier as non-marketing. |
| The offsets and lengths    | The only reason to want an offset is to read the payload by hand, and the only reason to do that is to read a field that already has a name.   |

An implementation still needs the offsets and lengths internally, and its own
tests build payloads byte by byte, so each language keeps them on a
non-public path rather than deleting them, being `internal` in .NET,
package-private in Java, a module that is not exported in Node, an underscore
module in Python, a class that is not part of the published surface in PHP,
and `pub(crate)` in Rust.

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
