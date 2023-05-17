# Stylistic Conventions

This document contains some notes on stylistic conventions to be observed
in the specification, and doesn't form part of the specification itself.

## Voice

51Degrees style guide says to adopt a friendly personal tone
however this is a formal specification, so write in third person.

- The 51Degrees implementation rather than "our"
- It is recommended rather than we recommend.

## Spelling

- use US English spelling
- possibly hyphenated terms, render as follows:
  - "start-up"
  - "metadata"
  - "website"
  - "callback"

## Capitalization

- JSON
- DLL
- C#

Defined Terms:

Defined Terms are Capitalized.

- [Pipeline](pipeline-specification/conceptual-overview.md#pipeline)
- [Flow Element](pipeline-specification/conceptual-overview.md#flow-element)
- [Flow Data](pipeline-specification/conceptual-overview.md#flow-data)
- [Element Data](pipeline-specification/conceptual-overview.md#element-data)
- [Aspect](pipeline-specification/README.md#engine)
- [Aspect Engine](pipeline-specification/conceptual-overview.md#aspect-engine)
- Engine - Commonly used, shortened form of Aspect Engine
- [On-premise Engine](pipeline-specification/conceptual-overview.md#on-premise-engines)
- [Cloud Engine](pipeline-specification/conceptual-overview.md#cloud-engines)
- [Cloud Aspect Engine](pipeline-specification/conceptual-overview.md#cloud-aspect-engine)
- [Cloud Request Engine](pipeline-specification/conceptual-overview.md#cloud-request-engine)
- [Sequence Element](pipeline-specification/pipeline-elements/sequence-element.md)
- [Set Headers Element](pipeline-specification/pipeline-elements/set-headers-element.md)
- [Device Detection](device-detection-specification/README.md)
- [Evidence](pipeline-specification/features/evidence.md)
- [Property](pipeline-specification/features/properties.md)
- [Resource Key](pipeline-specification/pipeline-elements/cloud-request-engine.md#resource-key)

Where defined terms are introduced, in
[Conceptual overview](pipeline-specification/conceptual-overview.md)
and introductory material, they are **emboldened** on first occurrence.

Pluralized forms of Defined Terms are capitalized.

Ancillary words that go to make a noun phrase from a defined term are not
capitalized. e.g. Pipeline builder. Aspect Element builder. Property metadata.

Class names, interface names and method names are rendered in monospace e.g. `process`

When referring to an implementation class which is an instantiation
of a concept that has a Defined Term, the name of
the class is used and rendered in monospace e.g. `FlowData`

## Tables

- Bold column headers
- Equal space columns

## RFC 2119

[RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119) terms are UPPER CASE when used with the meaning defined in 
RFC 2119. Avoid use of the same terms where they do not have the RFC 2119 meaning.

MUST, SHOULD, MUST NOT, SHOULD NOT, MAY etc.

## Section Heads

Section heads use sentence case, per company style guide.

When a section head contains a defined term, the term retains its
capitalization e.g. Flow Element, and Flow Element builder. The logic for this
is that sentence case would have you say, for example,
"Taking a trip to Buenos Aires"

## Checking adherence to conventions

Refer to 51Degrees Style Guide [^1]  
Refer to 51Degrees Glossary [^1]

[^1]: These documents are not publicly accessible at present. This will be addressed
and links added in the future.

Some VSCode extensions that have proven useful:

- [Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker)
- [HTTP/s and relative link checker](https://marketplace.visualstudio.com/items?itemName=blackmist.LinkCheckMD)
- [Markdown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one)
- [Markdown Table Prettifier](https://marketplace.visualstudio.com/items?itemName=darkriszty.markdown-table-prettify)

## Consistency

Use the term "remote server" - not cloud or remote service
