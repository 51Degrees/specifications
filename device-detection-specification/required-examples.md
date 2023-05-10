# Required Examples

This section describes the user-runnable examples that MUST be implemented
in order demonstrate usage of the API to the customer.

## Implementation Notes

### Execution

It MUST be possible to simply execute examples from command line/IDE as
expected by a user of the implementation language.

There MUST be unit tests for examples, to verify that
the example remains valid through various code changes. Since examples
are primarily concerned with providing visual output at the time of execution
it is often difficult to carry out verification of the results produced by the
example, and it is likely to be sufficient for a test to show that the example
runs and completes without failure.

The need for examples to be runnable as an application and as a test suggests
that they are written with example code to be executed as a public method, and
a common pattern is established across examples.

It MUST be possible to programmatically supply any necessary configuration or
parameters, such as cloud resource keys, or device detection license keys.

### Legibility

It is of importance for examples to illustrate key features of the APIs
in a simple way. For this reason, reference implementations use a number of
helper functions to simplify the code so as not to obscure the points
being illustrated. In creating the examples, 51Degrees found that there is a
trade-off between helper functions hiding unimportant details, and helper
functions hiding awkwardness of access to certain features.

Implementors MAY wish to consider adding those helper functions to their
API implementations, rather than them being accessible only in the
context of examples.

Some examples of helpers in the latter category:

- a helper that creates a hash Engine to provide access to the data file
  metadata (date and data tier).
- a helper that gets the value of a Property as a string, taking into account
  that a value might not exist or that it might be a list.

### Code Comments

We require extremely verbose comments as a module header in examples.

51Degrees generates Web documentation ([for example](https://51degrees.com/documentation/_examples__device_detection__getting_started__console__on_premise.html))
from reference implementation examples, using Doxygen. For the sake of
readability of the source of the examples text intended for Doxygen
generation is placed at the bottom of source files.

In addition, it is recommended that the examples are very densely
commented in order to help the user understand what it is doing.

### File References

Finding a path to files used by examples might not be completely straightforward, as
the example could have been downloaded from GitHub, or if it's part of
the standard distribution of the API files, it could appear at different relative paths
to the current working directory when the example is executed - especially
when executed as an automated test as opposed to being run from an IDE.

In the Java reference implementation the
[FileFinder utility](https://github.com/51Degrees/pipeline-java/blob/master/pipeline.core/src/main/java/fiftyone/pipeline/util/FileFinder.java)
is used to locate the file.

### Test Data

Many examples require test data consisting of HTTP Header Evidence - User Agent
and UserAgent Client Hints. A YAML file containing 20,000 sets of such Evidence
is distributed as one of the Git submodules referenced from on-premise Hash
detection. It is also available in a repository in
[GitHub](https://github.com/51Degrees/device-detection-data)
where it is updated on a monthly basis.

See [File References](#file-references) for a discussion of locating files.

### On-Premise Device Detection

Reference implementation examples illustrate use of the Lite Data File that is
distributed as one of the Git submodules referenced from on-premise Hash detection.
It is also updated in [GitHub](https://github.com/51Degrees/device-detection-data)
on a monthly basis.

See [File References](#file-references) for a discussion of locating files.

In the reference implementations it is stressed in comments as well as
in the output of examples that
the Lite data file has a small number of Properties.

The production date of the file in use is noted and a warning reported
if it is more than 28 days old. This serves also to illustrate how to
find the production date of the file.

### Cloud Device Detection

Reference implementation examples illustrate use of Resource Keys to access
the cloud service. A predefined link such as [this one](https://configure.51degrees.com/jqz435Nc)
can be created to create a Resource Key to provide access to the Properties
used in the examples. For simplicity, it might be convenient for such a link to
provide access to all free Properties.

Since the Resource Key is shared between several examples, it might be convenient
for it to be set as an environment variable, rather than passing as a command
argument, especially given the need for examples to be executed in
a test environment.

### Fluent Builders

Reference implementation examples demonstrate the use of the simplified
top-level builder for cloud and on-premise. Noting that [elsewhere](../pipeline-specification/reference-implementation-notes.md)
we recommend considering the trade-off between the apparent simplicity of this
approach and some disadvantages.

Additionally, assuming default values are needed
this does simplify the examples. However, it has the disadvantage that users
might not understand how to use the Pipeline builder and the various Engine
builders in concert, and hence might not be aware of how they can configure
Properties that are not exposed by the simplified builder, if they need to.

It is RECOMMENDED that at least one example demonstrates this technique for
creating a Pipeline and that it is made clear that the lifetime of the
FlowElements added to the Pipeline will probably, in production environments, be controlled by the Pipeline
they are added to (using `setAutoClose(true)`). In other words, destruction of the
Pipeline causes the elements added to it to be destroyed.

### Build from Configuration

Reference implementation examples include illustration of creating a Pipeline
from a configuration file. In XML or JSON, this configuration file can be used
to add, as a comment, a listing of all the possible options for the Pipeline
and all Engines. This information is also available in sample files:

TODO - these sample files are not yet publicly available, they are in
internal `develop` branches, but will be available at the following URLs in future:

[.NET](https://github.com/51Degrees/device-detection-dotnet/blob/master/Examples/sample-configuration.json)
[Java](https://github.com/51Degrees/device-detection-java/blob/master/device-detection.examples/console/src/main/resources/gettingStartedOnPrem.xml)

### Pipeline and Flow Data Lifecycle

Some 51Degrees support queries relate to user confusion over the intended
lifecycle of a Pipeline and Flow Data created from it.

It's important to emphasize, in examples, that only one Pipeline instance is
needed for most use cases and that it can be created as a singleton,
whose lifetime is often the same as the application that it is in.

Nevertheless, it is suggested that this lifetime be illustrated using the
equivalent of a "try-with-resources" construct, within which the Pipeline
instance is used as a factory for many Flow Data instances.

Similarly, but for a contrasting purpose, it is suggested that use of a
Pipeline as such a factory, using
its `createFlowData` method, is also illustrated with the call to that method
being part of a "try-with-resources" construct.

### ShareUsage

Since Evidence used in examples is already collected by 51Degrees there is
no value in sharing those values with 51Degrees. In addition, though use of
examples is likely to be statistically insignificant, it might nonetheless alter
the calculations that are performed regarding current usage.

Reference implementations inhibit usage sharing for console examples by ensuring
the [Usage Sharing Element](../pipeline-specification/pipeline-elements/usage-sharing-element.md)
is not added to the Pipeline, but enable it for web examples.

This is done because it has been observed that web
examples are more frequently copied verbatim as a starting point for customer
implementations. As usage sharing is so important, we want to ensure it is enabled
by default in this scenario.

Every example in which share usage is inhibited needs to have a comment saying
that in normal operation usage sharing should be enabled by adding a Usage Sharing
Element to the Pipeline.

## Concrete Examples

These examples are provided in the reference implementations to illustrate
the following features:

- On-Premise Device Detection
- Cloud Device Detection
- Native Key/TAC Detection
- Build from Configuration
- Use of Fluent Builder
- Need for Resource Key for Cloud
- Creation of Pipeline once only
- Presentation of Evidence
- Access to Properties strongly typed
- Need to dispose every Flow Data
- Match Metrics
- Use of Web Integration
- Use of Client Side detection
- Obtaining "high entropy" Evidence
- Offline Processing
- Data Update

### Getting Started Console

Examples MUST be provided that illustrate basic usage of the API for
both Cloud and On-Prem, using fluent builder and options file configuration,
when executed as a console (command line) application.

Detailed inline comments in these examples introduce the use of Evidence and
retrieval of Properties resulting from detection, as well as illustrating
correct [lifecycle management](#pipeline-and-flow-data-lifecycle) of Pipeline
and Flow Data instances.

See documentation
[cloud](https://51degrees.com/documentation/_examples__device_detection__getting_started__console__cloud.html),
[on-premise](https://51degrees.com/documentation/_examples__device_detection__getting_started__console__on_premise.html)

### Getting Started Web

These examples illustrate use of
[Web integration](../pipeline-specification/features/web-integration.md)
for both Cloud and On-Premise
by creating a Web page that can be accessed from a web server running in
the example environment that is created during execution of the example.

The example also illustrates the availability of Device Detection Properties
from client-side JavaScript as well as illustrating use of JavaScript
to collect Evidence directly from the client and present it to the server.

The example SHOULD illustrate various techniques for obtaining "high entropy
values" for presentation to the origin server as well as to the 51degrees
cloud service. See [Implementing User Agent Client Hints](https://51degrees.com/blog/implementing-user-agent-client-hints).

There is a wide choice of server-side Web frameworks, the reference
implementations illustrate basic ASP.NET Core and ASP.NET Framework usage for
C# and basic Servlet usage in Java.

See documentation
[cloud](https://51degrees.com/documentation/_examples__device_detection__getting_started__web__cloud.html),
[on-premise](https://51degrees.com/documentation/_examples__device_detection__getting_started__web__on_premise.html)

### TAC / Native Key Lookup

These examples illustrate retrieval of device data from the cloud service
using either TAC or native model name.

These examples require the user to obtain a license key in order to
configure an appropriate Resource Key.

See documentation
[TAC](https://51degrees.com/documentation/_examples__device_detection__tac_lookup__cloud.html),
[Native key](https://51degrees.com/documentation/_examples__device_detection__native_key_lookup__cloud.html)

### Match Metrics

On-premise detection provides access to various metrics that provide insight
into the detection process and confidence in the output. A key point of this
example is to illustrate that reducing the number of Properties requested
can reduce the time for detection.

[See documentation](https://51degrees.com/documentation/_examples__device_detection__match_metrics__on_premise_hash.html)

### Metadata

It is RECOMMENDED that implementors illustrate the retrieval of Evidence keys,
Properties, components and profiles from the on-premise, and
Properties and Evidence keys for cloud.

See documentation [on-premise](https://51degrees.com/documentation/_examples__device_detection__metadata__on_premise_hash.html),
[cloud](https://51degrees.com/documentation/_examples__device_detection__metadata__cloud.html).

### Performance Options

Reference implementations contain an "Offline Processing" example which
illustrates the processing of a batch file. The example also shows the
various performance options available (Low Memory, Predictive Graph, etc.)
which are commented out in the example.

Implementors might consider illustrating the differences between the various
combinations of options.

[See documentation](https://51degrees.com/documentation/_examples__device_detection__offline_processing__on_premise_hash.html)

### Performance Benchmark

Reference implementations contain a Performance Benchmark which is somewhat
similar to the ["Offline Processing" example](#performance-options).

[See documentation](https://51degrees.com/documentation/_examples__device_detection__performance__on_premise_hash.html)
Java tab.

### Data Update

Examples will need to illustrate updating an on-premise data source both by
access to remote servers and by direct update of a file store location.

The data update service has a range of options available. Implementors
SHOULD illustrate:

- file system watcher
- remote update polling
- update on start-up
- programmatic (non-automatic) update

[See documentation](https://51degrees.com/documentation/_examples__device_detection__data_file_updates__automatic.html)
