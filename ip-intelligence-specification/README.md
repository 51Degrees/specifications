# IP Intelligence Specification

## Introduction

This folder structure contains a language agnostic specification for the IP
Intelligence Engine that can be used by
the [51Degrees v4 Pipeline API](../pipeline-specification/README.md).

The IPI Intelligence Engine provides information on the network and location
properties associated with an IP address. Returned properties can range from
the owner of the IP range, to the city in which the IP is being used in.

We aim to avoid specific details of classes, interfaces, methods or the like.
The focus is on the behavior rather than the method by which that behavior is
achieved. This allows implementers to choose an architectural approach that is
most appropriate and familiar for uses of the target language.

## Structure

This specification builds on the concepts and features defined in the
[Pipeline specification](../pipeline-specification/README.md). The reader will
need to be familiar with the basics from there before reading this.  
Structurally, this specification is broken down into separate markdown files
in multiple directories.
