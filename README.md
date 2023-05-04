# Specifications

## Introduction

This repository contains specifications for the Pipeline API and some 51Degrees
products.

## Contents

| Name                                                                       | Description                                                                                                                     |
|----------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| [Table of contents](table-of-contents.md)                                  | A more in-depth table of contents for this repository                                                                           |
| [Pipeline Specification](pipeline-specification/README.md)                 | Specification for the Pipeline API and its operation. This covers core functionality.                                           |
| [Device Detection Specification](device-detection-specification/README.md) | Specification for the Device Detection service. This builds on the concepts and features defined in the Pipeline specification. |

## Notes for implementers

- These specifications are written to be language agnostic. The precise
  details of how to implement features is often not specified. This allows
  implementers to choose the most appropriate mechanism for the target language.
  For example, Java and .NET developers would be familiar with the use of a
  fluent builder to create instances. However, a Node.JS developer would not
  normally use this approach.
- [Java](https://github.com/51Degrees/pipeline-java) and
  [.NET](https://github.com/51Degrees/pipeline-dotnet) are considered the reference
  implementations. At least one of these SHOULD be reviewed by the reader to
  see what a real-world implementation of the specification looks like. There
  is also [a section](pipeline-specification/reference-implementation-notes.md)
  containing reflections on the architectural choices made when creating the
  Java and .NET versions. This could be helpful when designing future implementations.
- URLs in these specifications are fixed. Code comments SHOULD include
  references to these URLs in order to avoid re-writing the same descriptions
  and definitions in multiple places.
- CI/CD scripts and the like are out of scope. However, implementers will need to be
  mindful of the requirement to have the ability to build and test the software
  in a non-interactive CI/CD environment. See 51Degrees 
  [CI/CD documentation](https://github.com/51Degrees/common-ci#readme) for more details.

