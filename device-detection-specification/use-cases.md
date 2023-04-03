# Introduction

This document contains descriptions of device detection use-cases along with pseudo-code examples.

Many of these examples build on the concepts established in the pipeline specification, so it may be helpful to first become familiar with the [use-cases there](/pipeline-specification/use-cases.md).

# Create a device detection pipeline

There are several different ways that a pipeline might be created. However, once created, usage must be as similar as possible.
In particular, a cloud pipeline must be a drop-in replacement for an on-premise pipeline for performing device detection and querying the results.

Creating an on-premise device detection pipeline in code:

```
var deviceDetectionEngine = deviceDetectionHashEngineBuilder
  .setPerformanceProfile(performanceProfiles.MaxPerformance)
  .build("data file path")
var pipeline = pipelineBuilder
  .addElement(deviceDetectionEngine)
```

Creating a pipeline for device detection using the 51Degrees cloud service will 
look slightly different: 

```
var cloudEngine = cloudAspectEngineBuilder
  .build(resourceKey)
var deviceDetectionEngine = deviceDetectionCloudEngineBuilder
  .build()
var pipeline = pipelineBuilder
  .addElement(cloudEngine)
  .addElement(deviceDetectionEngine)
```

Device detection pipelines can also be [created from configuration](/pipeline-specification/features/build-from-configuration.md).

```
var pipeline = pipelineBuilder
  .buildFromConfiguration(configuration)
```

# Simple device detection

A user wishes to find out whether a device is a mobile or not, based on the User-Agent header.

```
// The 'with' construct represents some mechanism to ensure that memory is cleaned up after processing is complete. This is very important for the on-premise implementation.
with(var flowdata = pipeline.createFlowData())
{
  flowdata.addEvidence(Constant.USER_AGENT_KEY, userAgentValue);
  flowdata.Process();

  var isMobile = flowData.get<iDeviceData>().isMobile.value
}
```

# Property not available

A property might not be available in some scenarios. We need to ensure that the used is informed of why the property cannot be accessed and how to gain access if they want to. This feature is described in more detail in the [pipeline specification](/pipeline-specification/features/properties.md#missing-properties)

Some sample scenarios are:
1. An on-premise user attempts to access a property that is not available in the data file they are using.
2. A cloud user attempts to access a property that is not included with their [resource key](TODO link).

```
with(var flowdata = pipeline.createFlowData())
{
  flowdata.addEvidence(Constant.USER_AGENT_KEY, userAgentValue);
  flowdata.Process();

  // Expect an error to be thrown on the line below. (assuming this property is not available)
  var tac = flowData.get<iDeviceData>().tac.value
}
```

# Web integration

The mechanics of this will differ significantly by language. See [pipeline - web integration](../pipeline-specification/features/web-integration.md) for more detail.
However, the outcome should be the same. It must be simple for the user to create a web application where:

1. Each request (following any filtering, etc) will have all relevant evidence values extracted, added to a flow data and processed.
2. This flow data will be made available in whatever mechanism is common for shared web session data in that environment, allowing other components to easily make use of the device detection results. 

## Apple model detection

Modifying the simple web application described above to be able to correctly identify Apple models must also be very easy. For example, by adding a line similar to the following in the HTML:

```
<script async src='51Degrees.core.js' type='text/javascript'></script>
```

For more details on the expected functionality see the [web integration](/pipeline-specification/features/web-integration.md) section of the pipeline specification.

# Automatic data updates

All [data update](/pipeline-specification/features/data-updates.md) functionality should be part of configuration.
This pipeline creation example demonstrates how to configure the pipeline to update the device detection data file when needed:

```
var deviceDetectionEngine = deviceDetectionHashEngineBuilder
  .setPerformanceProfile(performanceProfiles.MaxPerformance)
  .setLicenseKey(licenseKey)
  .build("data file path")
var pipeline = pipelineBuilder
  .addElement(deviceDetectionEngine)
```

# Property meta data

[Property meta data](/pipeline-specification/features/properties.md#property-meta-data) must be exposed by the device detection engine:

```
foreach (var property in deviceDetectionEngine.Properties)
{
  // Do something with property data
}
```

# Extended On-Premise meta data

Additional [device detection meta data](pipeline-elements/device-detection-on-premise.md#meta-data) must be exposed by the on-premise engine:

```
foreach (var component in deviceDetectionEngine.Components)
{
  // Do something with component data
}
foreach (var profile in deviceDetectionEngine.Profiles)
{
  // Do something with profile data
}
foreach (var value in deviceDetectionEngine.Values)
{
  // Do something with value data
}
```

# TAC/Native Key lookup

A user wishes to get details of devices matching a specific [TAC](https://en.wikipedia.org/wiki/Type_Allocation_Code) or native key.

```
var cloudEngine = cloudAspectEngineBuilder
  .build(resourceKey)
var hardwareProfileEngine = hardwareProfileCloudEngineBuilder
  .build()
var pipeline = pipelineBuilder()
  .addElement(cloudEngine)
  .addElement(hardwareProfileEngine)

with(var flowdata = pipeline.createFlowData())
{
  flowdata.addEvidence(Constant.TAC_KEY, tacValue);
  flowdata.Process();

  var profiles = flowData.getFromElement(hardwareProfileEngine).profiles.value
  foreach(var profile in profiles) 
  {
    var hardwareName = profile.hardwareName.Value;
  }
}
```