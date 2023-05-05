# Device Detection cloud

## Overview

Cloud Device Detection presents [Evidence](../../pipeline-specification/features/evidence.md)
to the 51Degrees Cloud Detection server, which carries out the detection
and returns a JSON data structure, from which Device Detection Properties
are populated in the Flow Data.

This Engine is the Cloud Aspect Engine for Device Detection.

See [here](../../../pipeline-specification/part3/pipeline-elements/cloud-request-engine.md)
for an overview of the data flow for Cloud Engines.

## Accepted Evidence

This element uses no Evidence, it works on Property values in Element Data
in the Flow Data.

## Start-up activity

When it is added to a Pipeline, Device Detection Cloud Engine initializes
itself from a Cloud Request Engine, which MUST have been added to the Pipeline
before it.

The Cloud Request Engine determines which Properties are available
based on the Resource Key supplied on start-up. The Device Detection Cloud Engine
then takes the details of the subset of those Properties that are relevant to
Device Detection.

## Element Data

The Element Data populated by this engine must be interface compatible with
the Element Data populated by the [on-premise](device-detection-on-premise.md)
Engine.

See [data model](../data-model.md) for more information.

## Process

The majority of the processing SHOULD be handled by the shared
[Cloud Aspect Engine](../../pipeline-specification/part3/pipeline-elements/cloud-aspect-engine.md#processing)
logic.

This will just need to filter and parse the JSON provided by the Cloud Aspect
Engine to the form that is needed for the Element Data output

## Configuration options

There are no configuration options associated with this Engine.
