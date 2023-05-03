# Usage examples

For the most part, the Pipeline specification is describing the pieces of an
empty data processing system. Many use-cases only make sense in the context
of some concrete usage of that system. As such, it may be helpful to look at
other use-case documents such as
[Device Detection](../device-detection-specification/usage-examples.md)

## Creating elements and Pipelines

Creating Flow Elements will always be done using a consistent mechanism.
In the case of C#, we use a separate builder class. For more details on this,
see the [Flow Element builder](conceptual-overview.md#flow-element-builder)
section in the conceptual overview.

```c#
var element = myElementBuilder
  .SetConfigurationFlag(true)
  .Build()
```

As with Flow Elements, C# also uses separate builder class when creating
Pipelines:

```c#
var pipeline = pipelineBuilder
  .AddElement(element)
  .Build()
```

Note that many users will not create the elements and Pipeline in code
as shown above.
Instead, they will use a configuration file which is then used to
create the requested element and Pipeline instances.

See [Pipeline configuration](features/pipeline-configuration.md) for more
details.

## Processing data

Once the Pipeline has been created, processing a request can generally
be broken down into 4 steps:

1. Create Flow Data:

   ```c#
   var flowData = pipeline.createFlowData();
   ```
2. Add [Evidence](features/evidence.md):

   ```c#
   flowData.AddEvidence("query.evidence-key", "evidence value");
   ```
3. Request the Pipeline to process the data:

   ```c#
   flowData.Process();
   ```
4. Access the results:

   ```c#
   var result = flowData.GetFromElement(element);
   ```

   See [access to results](features/access-to-results.md) for more detail on
   the different ways to access results.

