# Device Detection cloud

## Overview

Cloud Device Detection presents [Evidence](../../pipeline-specification/features/evidence.md)
to the 51Degrees Cloud Detection server, which carries out the detection
and returns a JSON data structure, from which Device Detection Properties
are populated in the Flow Data.

This is implemented as a two-step process: a Cloud Request Engine
presents the Evidence to the 51Degrees server with an HTTP request
and copies the JSON response into Element Data in the Flow Data.

This Element Data is passed using the standard Pipeline Flow Data mechanism to
a Device Detection Cloud Engine, later in the Pipeline. Since the detection
Engine depends on the request having been processed in advance, it checks that
Element Data from the cloud request is present in Pipeline before processing.

![Cloud Engine flow](../../pipeline-specification/images/Device%20Detection%20Cloud%20Engine.png)

The majority of the logic that must be performed by the Device Detection Cloud
Engine is common to all Cloud Engines and is described in the
[Cloud Aspect Engine](../../pipeline-specification/pipeline-elements/cloud-aspect-engine.md)
document.

## Device Detection Cloud Engine configuration

There are no configuration options associated with this Engine.

## Device Detection Cloud Engine processing

When it is added to a Pipeline, Device Detection Cloud Engine initializes
itself from a Cloud Request Engine, which must have been added to the Pipeline
before it.

The Cloud Request Engine determines which Properties are available
based on the Resource Key supplied on start-up. The Device Detection Cloud Engine
then takes the details of the subset of those Properties that are relevant to
Device Detection.

See [Cloud Request Engine](../../pipeline-specification/pipeline-elements/cloud-request-engine.md)
for more details of this Engine.
