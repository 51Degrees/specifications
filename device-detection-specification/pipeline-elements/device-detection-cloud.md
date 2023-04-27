# Device detection cloud

## Overview

Cloud Device Detection presents [Evidence](../../pipeline-specification/features/evidence.md) 
to the 51Degrees Cloud Detection server, which carries out the detection 
and returns a JSON data structure, from which device detection properties 
are populated in the **FlowData**.

This is implemented as a two-step process: a Cloud Request Engine
presents the Evidence to the 51Degrees server with an HTTP request
and copies the JSON response into ElementData in the FlowData.

This ElementData is passed using the standard Pipeline FlowData mechanism to
a Device Detection Cloud Engine, later in the Pipeline. Since the detection 
engine depends on the request having been processed in advance, it checks that
ElementData from the cloud request is present in Pipeline before processing.

![Cloud engine flow](../../pipeline-specification/images/Device%20Detection%20Cloud%20Engine.png)

The majority of the logic that must be performed by the Device Detection Cloud
Engine is common to all cloud engines and is described in the 
[Cloud Aspect Engine](../../pipeline-specification/pipeline-elements/cloud-aspect-engine.md) 
document.

## Device detection cloud engine configuration

There are no configuration options associated with this engine.

## Device detection cloud engine processing

When it is added to a pipeline, Device Detection Cloud Engine initializes
itself from a Cloud Request Engine, which must have been added to the pipeline
before it. 

The Cloud Request Engine determines which properties are available
based on the resource key supplied on start-up. The Device Detection Cloud engine 
then takes the details of the subset of those properties that are relevant to 
device detection.

See [Cloud Request Engine](../../pipeline-specification/pipeline-elements/cloud-request-engine.md) 
for more details of this engine.