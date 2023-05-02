# Stylistic Conventions

This document contains some notes on stylistic conventions to be observed
in the specification, and doesn't for part of the specification.

## Voice. 

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

remote server - not cloud or remote service

## Capitalization

- JSON
- DLL
- C#

Defined Terms:

Defined Terms are Capitalized.

- Pipeline
- Flow Element
- Flow Data
- Element Data
- Engine
- Aspect Engine
- Cloud Aspect Engine
- Cloud Request Engine
- On-premise Engine
- Cloud Engine
- Sequence Element
- Set Headers Element
- Device Detection
- Evidence
- Property
- Properties
- Flow Data
- Resource Key
- Aspect

Where defined terms are introduced, in Conceptual overview and introductory
material, they are **emboldened** on first occurrence.

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

RFC 2119 terms are UPPER CASE when used with the meaning defined in RFC 2119.
Avoid use of the same terms where they do not have the RFC 2119 meaning.

MUST, SHOULD, MUST NOT, SHOULD NOT, MAY etc.

## Section Heads

Section heads use sentence case, per company style guide..

When a section head contains a defined term the term retains its
capitalization e.g. Flow Element, and Flow Element builder. The logic for this
is that sentence case would have you say, for example,
"Taking a trip to Buenos Aires"

## Checking adherence to conventions

Refer to 51Degrees Style Guide.
Refer to 51Degrees Glossary

IntelliJ has a useful linter for markdown.

Link checking - check all links

Table Formatting - check all tables

