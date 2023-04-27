# Required Examples

## Features

It is recommended that the following features are demonstrated in examples:

- On-Premise Device Detection
- Cloud Device Detection
- Native Key/TAC Detection
- Build from Configuration
- Use of Fluent Builder
- Need for Resource Key for Cloud
- Creation of Pipeline once only
- Presentation of evidence
- Access to properties strongly typed
- Need to dispose every flow data
- Match Metrics
- Use of Web Integration
- Use of Client Side detection
- Obtaining "high entropy" evidence
- Offline Processing
- Data Update

The examples in the reference implementations demonstrate combinations of the
above features - see [Concrete Examples](#concrete-examples).

## Implementation Notes

### Execution

It is recommended that examples are simply executable from an IDE, so
examples should be runnable in such a context.

It is recommended that unit tests be provided for examples, to verify that
the example remains valid though various code changes. Since examples
are primarily concerned with providing visual output at the time of execution
it is often difficult to carry out verification of the results produced by the
example, and it is likely to be sufficient for a test to show that the example
runs and completes without failure.

The need for examples to be runnable as an application and as a test suggests
that they are written with the common code to be executed from either
environment, and a pattern may be established across examples.

<span style="color:yellow">It's been discussed that the existing examples 
should be modified to make it possible to simply copy the example code from 
the web documentation, paste it into a project and run it.

This goal is fundamentally at odds with using an common/helper code from
examples. I'm not quite sure where this will land, so maybe we leave this
as an open question to be clarified in future?
</span>

### Legibility

It is of importance for examples to illustrate key features of the APIs
in a simple way. For this reason, reference implementations use a number of 
helper functions to simplify the code so as not to obscure the points
being illustrated. In creating the examples, 51Degrees found that there is a
trade-off between helper functions hiding unimportant details, and helper
functions hiding awkwardness of access to certain features.

Implementors may wish to consider adding those helper functions to their
API implementations, rather than them being accessible only in the
context of examples.

Some examples of helpers in the latter category:
- a helper that creates a hash engine to provide access to the data file 
metadata (date and data tier). 
- a helper that gets the value of a property as a string, taking into account
that a value may not exist or that it may be a list.

### Code Comments

We recommend extremely verbose and pedagogic comments as a module header and in 
the code of examples. 

51Degrees generates Web documentation ([for example](https://51degrees.com/documentation/_examples__device_detection__getting_started__console__on_premise.html)) 
from reference implementation examples, using Doxygen. For the sake of 
readability of the source of the examples text intended for Doxygen
generation is placed at the bottom of source files.

<span style="color:yellow">Would be nice to include links to the documentation on 
documenting ([here](https://51degrees.visualstudio.com/Pipeline/_git/documentation?path=/Documenting.md&_a=preview) 
and [here](https://51degrees.visualstudio.com/Pipeline/_git/documentation?path=/Documenting%20Code.md&_a=preview).)
However, this repo isn't on GitHub so we can't really do that at the moment.
</span>

### File References

Finding a path to files used by examples may not be completely straightforward, as
the example may have been downloaded from GitHub, or if it's part of
the standard distribution of the API files, it may appear at different relative paths
to the current working directory when the example is executed - especially
when executed as an automated test as opposed to being run from an IDE.

In the Java reference implementation the 
[FileFinder utility](https://github.com/51Degrees/pipeline-java/blob/master/pipeline.core/src/main/java/fiftyone/pipeline/util/FileFinder.java)
is used to locate the file.

### Test Data

Many examples require test data consisting of HTTP Header Evidence - User Agent
and UserAgent Client Hints. A YAML file containing 20,000 sets of such evidence
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
the Lite data file has a small number of properties and limited accuracy as it 
contains only a relatively small subset of detection data.
<span style="color:yellow">In v4, the same detection graph is used in all 
data files, so accuracy and size of training data is actually identical.
It's only the properties that change.
(v3 data files do use a smaller data set for lite, but I don't think that's 
worth talking about.)
</span>

The production date of the file in use is noted and a warning reported
if it is more than 28 days old. This serves also to illustrate how to
find the production date of the file.

### Cloud Device Detection

Reference implementation examples illustrate use of Resource Keys to access 
the cloud service. A predefined link [such as](https://configure.51degrees.com/jqz435Nc)
can be created to create a resource key to provide access to the properties 
used in the examples. For simplicity, it may be convenient for such a link to
provide access to all free properties.

Since the resource key is shared between several examples, it may be convenient 
for it to be set as an environment variable, rather than passing as a command 
argument, especially given the need for examples to be executed in 
a test environment.

### Fluent Builders

Reference implementation examples demonstrate the use of the simplified
top-level builder for cloud and on-premise. <span style="color:yellow">
The spec recommends that this simplified builder is not implemented
(Or, if it is implemented, there will need to be effort on reducing 
the issues that arrise from it's use)</span>
 Assuming default values are needed
this does simplify the examples. However, it has the disadvantage that users
may not understand how to use the pipeline builder and the various engine 
builders in concert, and hence may not be aware of how they can configure
properties that are not exposed by the simplified builder, should they need to.

It is recommended that at least one example demonstrates this technique for 
creating a pipeline and that it is made clear that the lifetime of the
FlowElements added to the pipeline should, in general, be controlled by 
the pipeline
they are added to (`setAutoClose(true)`). In other words, destruction of the 
pipeline causes the elements added to it to be destroyed.

It is recommended that examples make reference to the options available
and their default values in a Git submodule (and see below regarding an
example XML options file containing the same information as an XML comment).
<span style="color:yellow">reference that submodule in GitHub</span>

### Build from Configuration

Reference implementation examples include illustration of creating a pipeline
from a configuration file. In XML, this configuration file can be used to add,
as a comment, a listing of all the possible options for the pipeline and all 
engines. This information is also available in a Git submodule 
<span style="color:yellow">reference that submodule in GitHub</span>. 

### Pipeline and FlowData Lifecycle

Some 51Degrees support queries relate to user confusion over the intended
lifecycle of a Pipeline and FlowData created from it.

It's important to emphasize, in examples, that only one Pipeline is usually 
required in any implementation and that it can be created as a singleton,
whose lifetime is often the same as the application that it is in.

Nevertheless, it is suggested that this lifetime be illustrated using the 
equivalent of a "try-with-resources" construct, within which the Pipeline
instance is used as a factory for many FlowData instances.

Similarly, but for a contrasting purpose, it is suggested that use of a 
Pipeline as such a factory, using 
its `createFlowData` method, is also illustrated with the call to that method
being part of a "try-with-resources" construct.

### ShareUsage

Since evidence used in examples is already collected by 51Degrees there is 
no value in sharing those values with 51Degrees. In addition, though use of
examples is likely to be statistically insignificant, it may nonetheless alter
the calculations that are performed regarding current usage.

For somewhat arbitrary reasons, reference implementations inhibit usage
sharing for console examples, but enable it for web examples. Every example in
which share usage is inhibited needs to have a comment saying that in normal
operation it should not be, which diminishes the clarity of the example.

## Concrete Examples

These examples are provided in the reference implementations to illustrate
 [features](#features) mentioned.

### Getting Started Console

Examples should be provided that illustrate basic usage of the API for
both Cloud and On-Prem, using fluent builder and options file configuration,
when executed as a console application.

Detailed inline comments in these examples introduce the use of evidence and
retrieval of properties resulting from detection, as well as illustrating
correct [lifecycle management](#pipeline-and-flowdata-lifecycle) of Pipeline
and FlowData instances.

See documentation
[cloud](https://51degrees.com/documentation/_examples__device_detection__getting_started__console__cloud.html), 
[on-premise](https://51degrees.com/documentation/_examples__device_detection__getting_started__console__on_premise.html)

### Getting Started Web

These examples illustrate use of 
[Web integration](../../pipeline-specification/features/web-integration.md) 
for both Cloud and On-Premise
by creating a Web page that can be accessed from a web server running in
the example environment that is created during execution of the example.

The example also illustrates the availability of device detection properties
from client-side JavaScript as well as illustrating use of JavaScript
to collect evidence directly from the client and present it to the server.

The example should illustrate various techniques for obtaining "high entropy
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
example is to illustrate that reducing the number of properties requested 
can reduce the time for detection.

[See documentation](https://51degrees.com/documentation/_examples__device_detection__match_metrics__on_premise_hash.html)

### Metadata

It is recommended that implementors illustrate the retrieval of evidence keys,
properties, components and profiles from the on-premise, and 
properties and evidence keys for cloud. 

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

Examples should illustrate updating an on-premise data source both by
access to remote servers and by direct update of a file store location.

The data update service has a range of options available. Implementors 
should illustrate:

- file system watcher
- remote update polling 
- update on start-up 
- programmatic (non-automatic) update

[See documentation](https://51degrees.com/documentation/_examples__device_detection__data_file_updates__automatic.html)