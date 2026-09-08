# 51Did specification

This section describes the **51Did**, the 51Degrees identifier issued by the
remote server and read by the 51Did packages in each language. It builds on
the concepts defined in the
[Pipeline specification](../pipeline-specification/README.md).

A 51Did is described at three levels, and this specification keeps them
distinct because callers make different decisions at each one.

- The **51Did** is the identifier as a whole, meaning the concept together
  with the rules for how it is issued, compared and licensed.
- The **Envelope** is the data model that carries a 51Did. It is a signed
  [OWID](https://github.com/SWAN-community/owid), holding the version, the
  creator domain, the date, the payload and the signature. It is created
  afresh on every call, so two envelopes for the same inputs differ byte for
  byte because the date and the signature differ.
- The **Match Key** is the part of the payload that is stable and comparable,
  being the bytes after the flags byte and the License Id. Two 51Dids for the
  same inputs carry the same Match Key. Callers compare Match Keys and never
  envelopes.

## Contents

| **Name**                                     | **Description**                                                                                                    |
|----------------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| [Identifier layout](identifier-layout.md)    | The byte structure of the Envelope and of the 51Did payload, including the flags byte, the Usage and the Match Key. |
| [Package surface](package-surface.md)        | What a 51Did package exposes to a caller in every language, and what it MUST NOT expose.                            |

## Notes for implementers

- The byte layout is read and written in one place per language, being the
  51Did package for that language. Application code MUST NOT read the layout
  by hand, and the packages therefore keep the offsets and lengths out of
  their public surface. The reasoning is in
  [Package surface](package-surface.md).
- The packages that implement this specification are
  [pipeline-dotnet](https://github.com/51Degrees/pipeline-dotnet),
  [pipeline-java](https://github.com/51Degrees/pipeline-java),
  [pipeline-node](https://github.com/51Degrees/pipeline-node),
  [pipeline-python](https://github.com/51Degrees/pipeline-python),
  [pipeline-php-did](https://github.com/51Degrees/pipeline-php-did) and
  [rust](https://github.com/51Degrees/rust). The .NET package is the
  reference implementation.
- Code comments SHOULD link to the sections here rather than repeat the
  definitions, as set out in the
  [repository notes for implementers](../README.md#notes-for-implementers).
