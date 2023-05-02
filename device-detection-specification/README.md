# Device Detection specification

## Introduction

This folder structure contains a language agnostic specification for a device
detection Engine that can be used by
the [51Degrees v4 Pipeline API](../pipeline-specification/README.md).
We aim to avoid specific details of classes, interfaces, methods or the like.
The focus is on the behavior rather than the method by which that behavior is
achieved. This allows implementers to choose an architectural approach that is
most appropriate and familiar for uses of the target language.

## Structure

This specification builds on the concepts and features defined in the
[Pipeline specification](../pipeline-specification/README.md) the reader should
at least be familiar with the basics from there before reading this.  
Structurally, this specification is broken down into separate markdown files
in multiple directories.
If you're not sure where to start, we recommend looking at
[usage examples](usage-examples.md) first.
