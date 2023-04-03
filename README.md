# Introduction

This repository contains specifications for the Pipeline API and some 51Degrees
services. <span style="color: orange">avoid use of services, since pipeline has
the concept of "service" - "product" maybe? and in any case, here is a list of
our many products:

- Device Detection
- er, um ...
  </span>

<span style="color: orange">wonder if this would be better as
gh-pages? https://pages.github.com/ or as some other document source format?</style>

# Specifications

| Name                           | Description                                                                                                                 |
|--------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| Pipeline Specification         | Specification for the Pipeline API <span style="color: orange">and its operation???</span>. This covers core functionality. |
| Device Detection Specification | Specification for the device detection service   <span style="color: orange">Capitalise?</span>                             |

# Notes for implementers

- These specifications are written to be language agnostic. The precise
  details of how to implement features is often not specified. This allows
  implementers to choose the most appropriate mechanism for the target language.
  For example, Java and .NET developers would be familiar with the use of a
  fluent builder to create instances. However, a Node.JS developer would not
  normally use this approach. <span style="color: orange">probably want some
  implementation notes ... but markdown doesn't allow that ...</span>
- Java and .NET are considered the reference
  implementations <span style="color: orange">link?</style>. At least one of
  these should be reviewed by the reader to see what a real-world implementation
  of the specification looks like.
- URLs in these specifications are fixed. Code comments should include
  references to these URLs in order to avoid re-writing the same descriptions
  and definitions in multiple places. <span style="color: orange">how will this
  be done, will there be a "reflector", otherwise isn't the whole thing brittle
  against the need to keep the repo the same and to keep the file breakdown of
  content the same?</style>
- CI/CD scripts and the like are out of scope. However, implementers should be
  mindful of the requirement to have the ability to build and test the software
  in a non-interactive CI/CD environment.