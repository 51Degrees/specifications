# Usage examples

For the most part, the pipeline specification is describing the pieces of an 
empty data processing system. Many use-cases only make sense in the context 
of some concrete usage of that system. As such, it may be helpful to look at 
other use-case documents such as 
[device detection](../device-detection-specification/usage-examples.md)

## Creating elements and pipelines

Creating **Flow Elements** should always be done using a consistent mechanism.
In the case of C#, we use a separate builder class. For more details on this, 
see the [flow element builder](conceptual-overview.md#flow-element-builder) 
section in the conceptual overview.

```c#
var element = myElementBuilder
  .SetConfigurationFlag(true)
  .Build()
```

As with **Flow Elements**, C# also uses separate builder class when creating 
**Pipelines**:

```c#
var pipeline = pipelineBuilder
  .AddElement(element)
  .Build()
```

Note that many users will not create the elements and pipeline in code
as shown above. 
Instead, they will use a configuration file which is then used to 
create the required element and pipeline instances.

See [pipeline configuration](features/pipeline-configuration.md) for more 
details.

## Processing data

Once the pipeline has been created, processing a request can generally 
be broken down into 4 steps:

1. Create **Flow Data**:
    ```c#
    var flowData = pipeline.createFlowData();
    ```
2. Add [evidence](features/evidence.md):
    ```c#
    flowData.AddEvidence("query.evidence-key", "evidence value");
    ```
3. Request the **Pipeline** to process the data:
    ```c#
    flowData.Process();
    ```
4. Access the results:
    ```c#
    var result = flowData.GetFromElement(element);
    ```
    See [access to results](features/access-to-results.md) for more detail on
    the different ways to access results.
