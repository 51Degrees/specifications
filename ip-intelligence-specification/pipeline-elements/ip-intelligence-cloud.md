# IP Intelligence Cloud

## Overview

Cloud IP Intelligence presents [Evidence](../../pipeline-specification/features/evidence.md)
to the 51Degrees Cloud IP Intelligence server, which carries out the detection
and returns a JSON data structure, from which IP Intelligence Properties
are populated in the Flow Data.

This Engine is the Cloud Aspect Engine for IP Intelligence.

See [here](../../pipeline-specification/pipeline-elements/cloud-request-engine.md)
for an overview of the data flow for Cloud Engines.

## Accepted Evidence

This element uses no Evidence, it works on Property values in Element Data
in the Flow Data.

## Start-up activity

When it is added to a Pipeline, IP Intelligence Cloud Engine initializes
itself from a [Cloud Request Engine](../../pipeline-specification/pipeline-elements/cloud-request-engine.md),
which MUST have been added to the Pipeline before it.

The Cloud Request Engine is a shared element defined in the Pipeline
specification. It handles the HTTP request to the 51Degrees cloud service
and returns the full JSON response. Multiple Cloud Aspect Engines (e.g.
IP Intelligence and Device Detection) can share a single Cloud Request
Engine in the same Pipeline, each extracting its own relevant properties
from the response.

The Cloud Request Engine determines which Properties are available
based on the Resource Key supplied on start-up. The IP Intelligence Cloud Engine
then takes the details of the subset of those Properties that are relevant to
IP Intelligence.

## Element Data

The Element Data populated by this engine must be interface compatible with
the Element Data populated by the [on-premise](ip-intelligence-on-premise.md)
Engine.

See [data model](../data-model.md) for more information.

## Process

The majority of the processing SHOULD be handled by the shared
[Cloud Aspect Engine](../../pipeline-specification/pipeline-elements/cloud-aspect-engine.md#processing)
logic.

This will just need to filter and parse the JSON provided by the Cloud Aspect
Engine to the form that is needed for the Element Data output.

Note that IP Intelligence properties may include
[weighted values](../data-model.md). The cloud response
returns these as JSON arrays of objects with value and weight fields,
and the Engine MUST parse them into the appropriate weighted value
types used by the Element Data.

## Configuration options

There are no configuration options associated with this Engine.
