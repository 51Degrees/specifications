# Introduction

This repository contains specifications for the Pipeline API and some 51Degrees services.

# Specifications

| Name                              | Description                                                         |
|-----------------------------------|---------------------------------------------------------------------|
| Pipeline Specification            | Specification for the Pipeline API. This covers core functionality. |
| Device Detection Specification    | Specification for the device detection service                      |

# Notes for implementers

-   These specifications are written to be language agnostic. The precise details of how to implement features is often not specified. This allows implementers to choose the most appropriate mechanism for the target language. For example, Java and .NET developers would be familiar with the use of a fluent builder to create instances. However, a Node.JS developer would not normally use this approach.
-   Java and .NET are considered the reference implementations. At least one of these should be reviewed by the reader to see what a real-world implementation of the specification looks like.
-   URLs in these specifications are fixed. Code comments should include references to these URLs in order to avoid re-writing the same descriptions and definitions in multiple places.
-   CI/CD scripts and the like are out of scope. However, implementers should be mindful of the requirement to have the ability to build and test the software in a non-interactive CI/CD environment.