# Usage examples

## Introduction

This document contains descriptions of Device Detection use-cases along with
C# examples.

Many of these examples build on the concepts established in the Pipeline
specification, so it may be helpful to first become familiar with
the [usage examples](../pipeline-specification/usage-examples.md) there.

## Create a Device Detection Pipeline

There are several different ways that a Pipeline might be created. However, once
created, usage must be as similar as possible.
In particular, a cloud Pipeline must be a drop-in replacement for an on-premise
Pipeline for performing Device Detection and querying the results.

Creating an on-premise Device Detection Pipeline in code:

```c#
var deviceDetectionEngine = deviceDetectionHashEngineBuilder
  .SetPerformanceProfile(PerformanceProfiles.MaxPerformance)
  .Build("data file path");
var pipeline = pipelineBuilder
  .AddElement(deviceDetectionEngine)
  .Build();
```

Creating a Pipeline for Device Detection using the 51Degrees cloud service will
look slightly different:

```c#
var cloudEngine = cloudRequestEngineBuilder.Build(resourceKey);
var deviceDetectionEngine = deviceDetectionCloudEngineBuilder.Build();
var pipeline = pipelineBuilder
  .AddElement(cloudEngine)
  .AddElement(deviceDetectionEngine)
  .Build();
```

Device Detection Pipelines can also
be [created from configuration](../pipeline-specification/features/build-from-configuration.md).

```c#
var pipeline = pipelineBuilder
  .BuildFromConfiguration(configuration);
```

## Simple Device Detection

A user wishes to find out whether a device is a mobile or not, based on the
User-Agent header.

```c#
// The 'using' construct ensures that memory is cleaned up 
// after processing is complete. This is very important for 
// the on-premise implementation.
using(var flowdata = pipeline.CreateFlowData())
{
  flowdata.AddEvidence(Constants.USER_AGENT_KEY, userAgentValue);
  flowdata.Process();

  var isMobile = flowData.Get<IDeviceData>().IsMobile.Value;
}
```

## Property not available

A Property might not be available in some scenarios. We need to ensure that the
user is informed of why the Property cannot be accessed and how to gain access
if they want to. This feature is described in more detail, covering more scenarios in
the [Pipeline specification](../pipeline-specification/features/properties.md#missing-properties)

```c#
using(var flowdata = pipeline.CreateFlowData())
{
  flowdata.AddEvidence(Constant.USER_AGENT_KEY, userAgentValue);
  flowdata.Process();

  // Expect an error to be thrown on the line below.
  // The Tac property is only available in the 'TAC' data file. As such
  // it is the least likely to be available.
  // If the TAC data file is being used, then all properties will be 
  // available and this line should not throw an error.
  var tac = flowData.Get<IDeviceData>().Tac;
}
```

## Web integration

The mechanics of this will differ significantly by language.
See [Pipeline - web integration](../pipeline-specification/features/web-integration.md)
for more detail.
However, the outcome should be the same. It must be simple for the user to
create a web application where:

1. Each request (following any filtering, etc) will have all relevant Evidence
   values extracted, added to a Flow Data and processed.
2. This Flow Data will be made available in whatever mechanism is common for
   shared web session data in that environment, allowing other components to
   easily make use of the Device Detection results.

For detailed examples see:
- [Java getting started web - cloud](https://github.com/51Degrees/device-detection-java/tree/master/device-detection.examples/web/getting-started.cloud)
- [Java getting started web - on premise](https://github.com/51Degrees/device-detection-java/tree/master/device-detection.examples/web/getting-started.onprem)
- [.NET getting started web - cloud](https://github.com/51Degrees/device-detection-dotnet/tree/master/Examples/Cloud/GettingStarted-Web)
- [.NET getting started web - on premise](https://github.com/51Degrees/device-detection-dotnet/tree/master/Examples/OnPremise/GettingStarted-Web)

### Apple model detection

Modifying the simple web application described above to be able to correctly
identify Apple models must also be very easy. For example, by adding a line
similar to the following in the HTML:

```html
<script async src='51Degrees.core.js' type='text/javascript'></script>
```

For more details on the expected functionality see
the [web integration](../pipeline-specification/features/web-integration.md)
section of the Pipeline specification.

## Automatic data updates

All [data update](../pipeline-specification/features/data-updates.md)
functionality should be part of configuration.
This Pipeline creation example demonstrates how to configure the Pipeline to
update the Device Detection data file when needed:

```c#
// This parameter must be set to true for auto updates to work
var makeTempCopyOfDataFile = true;
var deviceDetectionEngine = deviceDetectionHashEngineBuilder
  .SetPerformanceProfile(PerformanceProfiles.MaxPerformance)
  .SetLicenseKey(licenseKey)
  .SetAutoUpdate(true)
  .Build("data file path", makeTempCopyOfDataFile);
var pipeline = pipelineBuilder
  .AddElement(deviceDetectionEngine);
```

For more detailed examples see:
- [Java data file updates](https://github.com/51Degrees/device-detection-java/blob/master/device-detection.examples/console/src/main/java/fiftyone/devicedetection/examples/console/UpdateDataFile.java)
- [.NET data file updates](https://github.com/51Degrees/device-detection-dotnet/blob/master/Examples/OnPremise/UpdateDataFile-Console/Program.cs)

## Property metadata

[Property metadata](../pipeline-specification/features/properties.md#property-metadata)
must be exposed by the Device Detection Engine.
Note that this information should be available for both cloud and On-premise Engines:

```c#
foreach (var property in deviceDetectionEngine.Properties)
{
  // Do something with property data.
}
```

For more detailed examples see:
- [Java cloud metadata](https://github.com/51Degrees/device-detection-java/blob/master/device-detection.examples/console/src/main/java/fiftyone/devicedetection/examples/console/MetadataCloud.java#L113)
- [.NET cloud metadata](https://github.com/51Degrees/device-detection-dotnet/blob/master/Examples/Cloud/Metadata-Console/Program.cs#L111)

## Extended on-premise metadata

Additional [Device Detection metadata](pipeline-elements/device-detection-on-premise.md#metadata)
must be exposed by the On-premise Engine.

```c#
foreach (var component in deviceDetectionEngine.Components)
{
  // Do something with component data.
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

For more detailed examples see:
- [Java on-premise metadata](https://github.com/51Degrees/device-detection-java/blob/master/device-detection.examples/console/src/main/java/fiftyone/devicedetection/examples/console/MetadataOnPrem.java#L134)
- [.NET on-premise metadata](https://github.com/51Degrees/device-detection-dotnet/blob/master/Examples/OnPremise/Metadata-Console/Program.cs#L126)

## TAC/Native key lookup

A user wishes to get details of devices matching a
specific [TAC](https://en.wikipedia.org/wiki/Type_Allocation_Code) or native
key.

```c#
var cloudEngine = cloudAspectEngineBuilder.Build(resourceKey);
var hardwareProfileEngine = hardwareProfileCloudEngineBuilder.Build();
var pipeline = pipelineBuilder()
  .AddElement(cloudEngine)
  .AddElement(hardwareProfileEngine)
  .Build();

using(var flowdata = pipeline.CreateFlowData())
{
  flowdata.AddEvidence(Constants.TAC_KEY, tacValue);
  flowdata.Process();

  var profiles = flowData.GetFromElement(hardwareProfileEngine).Profiles.Value;
  foreach(var profile in profiles)
  {
    var hardwareName = profile.HardwareName.Value;
  }
}
```

For more detailed examples see:
- [.NET TAC lookup](https://github.com/51Degrees/device-detection-dotnet/blob/master/Examples/Cloud/TAC-Console/Program.cs)
- [.NET native key lookup](https://github.com/51Degrees/device-detection-dotnet/blob/master/Examples/Cloud/NativeModel-Console/Program.cs)
- [Java TAC lookup](https://github.com/51Degrees/device-detection-java/blob/master/device-detection.examples/console/src/main/java/fiftyone/devicedetection/examples/console/TacCloud.java)
- [Java native key lookup](https://github.com/51Degrees/device-detection-java/blob/master/device-detection.examples/console/src/main/java/fiftyone/devicedetection/examples/console/NativeModelCloud.java)

