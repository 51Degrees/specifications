# Derived Property Element

The Derived Property Element produces new Property values from Property
values that other Flow Elements in the Pipeline have already produced,
following rules written in a script, and stores the results in its own
Element Data.

The Element handles Properties that follow simply from Properties
already in the Flow Data. Anything more involved is written as an
ordinary Flow Element in code, which is the way such work is done today,
and the Element is deliberately not a replacement for writing one.

## Terms
- `Script`: One YAML or JSON file describing how one output Property is
  computed. A script names the Property it produces, names the source
  Properties it reads, defines any number of named checks, and lists
  rules that are read in order until one of them matches.
- `Model`: The in-memory form a script becomes after parsing and
  validation. Every language builds the same model from the same script,
  and everything after parsing works on the model rather than on the
  text.
- `Check`: A named true or false test defined in a script, which rules
  can then count or refer to by name.
- `SourceProperty`: A Property produced by another Element, named in a
  script as `elementDataKey.PropertyName`, for example
  `device.IsCrawler`.
- `DerivedProperty`: The output Property one script produces, written
  into this Element's own Element Data.

## Features

- The Derived Property Element is a Flow Element and not an Aspect
  Engine, because the Element holds no data file, makes no request over
  the network and uses no resource key. In .NET the Element extends
  `FlowElementBase`, exactly as the Translation Element does.
- One Element can hold many scripts, with one output Property per
  script.
- Scripts reach the builder from the package, from files on disk or from
  strings in code, and all three ways can be mixed in one Element.
- Allow one or more Derived Property Elements to be added to the same
  Pipeline. Each one writes into the same Element Data under the key
  `derived`, in the same way every Translation Engine shares
  `translation`.

## Components
- `IDerivedPropertyElement` | `DerivedPropertyElement`: Provides the main
  logic, evaluating the compiled scripts once per request.
- `DerivedPropertyElementBuilder`: Accepts scripts, validates and
  compiles them, and builds the Element.
- `IDerivedPropertyData` | `DerivedPropertyData`: The Element Data for
  the `DerivedPropertyElement`. This holds the output values, one per
  script.
- `DerivedScript`, with `DerivedScriptParser` and
  `DerivedScriptValidator`: The model, the YAML and JSON parsers that
  produce the model, and the validator that checks the model before the
  Element is built.
- `DerivedPropertyMetaData`: The full Property metadata block of a
  script, exposed by the Element.
- `BuiltInScript`: The enumeration naming every script shipped in the
  package.

## Derived Property Element Responsibilities and Behavior

### `DerivedPropertyElementBuilder`
- Reads the scripts given to it, whichever of the three source forms
  each script arrived in,
- Parses each script into the model, accepting YAML and JSON and
  producing the same model from both,
- Validates every script and reports every fault at once,
- Compiles each script into an immutable tree of small evaluators, with
  each source Property resolved to an Element Data key, a Property name,
  a reader for the source value type and a converter to the type the
  script infers,
- Builds the Element holding only the compiled model.

### `DerivedPropertyElement`
- Checks that the rest of the Pipeline supplies the source Properties
  when the Pipeline adds the Element,
- Reads each source Property once per request,
- Evaluates the checks and then the rules of each script,
- Writes one value, or one no-value carrying a message, per script into
  its own Element Data,
- Exposes the Property metadata of every script it holds.

### Validation

Validation collects every fault and raises one exception after checking
everything, rather than stopping at the first fault. Each fault carries:

- the script name,
- the source, being the built-in name, the file path, or the word
  `code`,
- a path in the document, such as `Rules[3].When.All[1]`,
- the line number, where the parser supplies one,
- a plain message saying what is wrong.

The exception message lists every fault, one per line. The faults the
validator reports are listed in the format 1 reference linked under
[Sources](#sources).

### The Pipeline check

The Element cannot see the rest of the Pipeline when the Element is
built, so source Property availability is checked when the Pipeline adds
the Element, through the call every language's Flow Element base already
receives (`AddPipeline` in .NET). At that point the Element walks the
Element list and, for each source Property, confirms that some Element in
the Pipeline has the Element Data key and lists the Property in its
Property metadata.

- A source Property no Element in the Pipeline supplies fails the
  Pipeline build, with a message naming the Property.
- Two Elements in one Pipeline producing the same derived Property name
  fail the Pipeline build in the same check, and so do two Elements
  replacing the same Property of another Element.

**Where an Element sits in the Pipeline is not judged.** A Pipeline
reports the Elements it holds flattened, with the members of a group that
runs in parallel placed after every Element at the top level, so a
position in that list does not say what ran before what. An
implementation that judges position fails Pipelines that are correct,
including one that runs its source Engines in parallel and adds this
Element after that group.

Nothing is lost, because a source Property that has not been written by
the time the Element runs is a source Property that cannot be read, which
the one rule below already answers. The derived Property has no value and
the message names the Property that was missing.

### Absent and invalid source Properties

A source Property is available when the source Element Data is present,
the Property is present, the value has a value, and the value converts
to the type the script infers for the Property. The source Property is
absent otherwise. A value that does not convert is absent as well, and
values are never coerced loosely, so the strings `N/A`, `Unknown` and an
empty string never become false or zero.

There is one rule and it holds for every source Property a script names,
which is that the Property is either there or it is not.

- **Where every source Property a script names is available**, the
  checks and then the rules run, and the script chooses a value.
- **Where any one of them is absent**, the Element writes a value that
  has no value, and reading that value raises the language's existing
  no-value error.

Evaluation is therefore two-valued, because every check and every rule
condition is either true or false and the rules only ever run once every
source Property has been read.

The no-value message names every absent Property rather than only the
first, and for each one says what the Element that supplies the Property
reported, in this shape.

> Derived property 'HumanConfidence' has no value because 2 source
> properties were not available. 'device.BrowserReleaseYear' (element
> 'device' has no value for 'BrowserReleaseYear': \<the source no-value
> message where there is one, otherwise 'property not present on this
> request'\>). 'ip.HumanProbability' (...). Usual causes are the element
> that supplies the property not being in the pipeline, the property
> being excluded in the engine configuration, the property not being
> included in the resource key, or JavaScript that populates the
> property not having run yet.

Where exactly one Property is absent the count reads `1 source property
was not available`, and where more than one is absent the count reads
`<n> source properties were not available`.

The Element uses the existing no-value mechanism, being
`AspectPropertyValue` with `NoValueMessage` in .NET and the equivalent
in each other language, which the Translation Element already uses for a
source Property without a value. No new `MissingPropertyReason` value is
needed and that enumeration does not change.

Every script ends in an `Else` rule, which validation enforces, so a
script whose source Properties have all been read always chooses a
value and there is no path where no rule matched. The `DefaultValue` a
script gives in its output block is metadata carried through to the
Property definition, and nothing reads that default while a request is
being processed.

### Logging and exposed metadata

At build, one information line per script gives the name, the version,
the format, the source and the output Property. At debug level, one
entry per script prints the compiled model as canonical JSON, with
PascalCase keys, two-space indent, literal types preserved, and the
inferred types and computed dependencies included, so that anyone
holding the log can reconstruct what was evaluated without the file. A
deprecated script logs a warning carrying the note the author left.

The Element's Property metadata list carries one entry per script with
the name, the value type as the language's type, the category from the
script's output block, and available true, which is what the Flow
Element metadata interface supports. The full output block is exposed as
`DerivedPropertyMetaData` through the Element (for example
`element.Scripts`, each carrying `Name`, `Version` and `Output`), so a
JSON builder, the cloud or a documentation generator can read every
field.

### Key Considerations

1. One script produces exactly one output Property, and the name of that
   output Property is the name the value appears under in the `derived`
   Element Data,
2. Scripts are selected by name only. There is one script per name, and
   the `Version` inside a script is for the authors and for the build
   log, playing no part in selection,
3. Once `Build` returns, the Element holds only the compiled model. No
   path, no text and no reference to the source is kept,
4. All expensive work happens at build, so per request there is no
   reflection, no string parsing, no regular expressions, no locks and
   no mutable state shared between requests,
5. The compiled model is immutable, so parallel Elements and concurrent
   `Process` calls need nothing further,
6. Multiple Derived Property Elements can exist in one Pipeline and each
   one writes into the same Element Data, meaning the Element Data must
   be thread safe,
7. The Element reads Properties from other Elements, so a Derived
   Property Element on its own in a Pipeline produces nothing.

## Sources

The script format is described by the format 1 reference at
https://github.com/51Degrees/derived-properties/blob/main/docs/format-1.md,
which is the normative description of the script format. The format is
not repeated here.

Scripts can be provided in three ways, and the three ways can be mixed
in one Element:

1. **As built-in scripts** - Named by the `BuiltInScript` enumeration,
   which is generated at package build time from the scripts the package
   ships:
   ```csharp
   .AddScript(BuiltInScript.HumanConfidence)
   ```

2. **As file paths** - The builder reads files from disk, supporting
   wildcards:
   ```csharp
   .AddScriptFile("derived/*.yaml")
   .AddScriptFile("derived/HumanConfidence.yaml")
   ```

3. **As script text** - A name given alongside the text of the script,
   where YAML or JSON is detected from the content. This form is
   available from code only:
   ```csharp
   .AddScript("HumanConfidence", scriptText)
   ```

There is no URL source. A script never arrives over the network.

Selection is by name only, and there is one script per name. Two scripts
in the same Element producing the same output Property name is a
validation fault, and two Elements in one Pipeline producing the same
derived Property name fails the Pipeline build.

## Accepted evidence

The Element accepts no evidence at all, so the evidence key filter is
empty.

Every input the Element reads is a Property that another Element in the
Pipeline has already produced, and nothing is read from the request
itself, so there is no evidence key for the Element to ask for. Anything
that needs the raw evidence, being headers, query string or cookies,
belongs in the Element that parses the evidence rather than in a script.

## Element Data

Derived values are stored in the `DerivedPropertyData` under the Element
Data key `derived`. Every instance of the Element in a Pipeline shares
that key, in the same way every Translation Engine shares `translation`.

The Element Data can be retrieved from the Flow Data like so:
- `flowData.Get<IDerivedPropertyData>()`

There is one entry per script, keyed by the output Property name. If a
script produces `HumanConfidence`, the value can be retrieved with
strongly typed accessors like so:

- `flowData.Get<IDerivedPropertyData>().GetAs<IAspectPropertyValue<string>>("HumanConfidence")`

Where any source Property the script names was absent, the returned
value has no value, and the no-value message names every Property that
could not be read.

## Processing

Construction, in the builder:
1. Reads the scripts from the sources given,
2. Parses each script into the model,
3. Validates every script, raising one exception listing every fault,
4. Compiles each script into an immutable tree of evaluators, with the
   rules held as an array.

Per request, the Element:

1. Gets each distinct source Element Data once,
2. Fills a fixed-size slot array with each Property's converted value
   and its state, being available or absent along with the reason for
   the absence,
3. For each script, confirms that every source Property the script names
   was read, then evaluates the checks, then the rules in order, taking
   the value of the first rule whose condition is true,
4. Writes one value, or one no-value carrying a message, per script into
   the `derived` Element Data.

Message strings for absent Properties are built only when a Property is
absent. The compiled model is immutable and nothing is shared between
requests, so concurrent `Process` calls need nothing further.

## Configuration

The Derived Property Element is configurable using json configuration:

```json
{
  "Elements": [
    {
      "BuilderName": "DerivedPropertyElement",
      "BuildParameters": {
        "Scripts": [
          "HumanConfidence"
        ],
        "ScriptFiles": [
          "derived/*.yaml",
          "derived/StaffDevice.json"
        ]
      }
    }
  ]
}
```

`Scripts` is a list of built-in script names, and `ScriptFiles` is a
list of file paths where wildcards are allowed. The third source form,
script text passed from code, is not available from configuration.

The Derived Property Element is configurable using the builder:

- `AddScript(BuiltInScript script)`: Add a script shipped in the
  package.
- `AddScriptFile(string path)`: Add a script file from disk (supports
  wildcards).
- `AddScript(string name, string content)`: Add a script from a string
  in code, where YAML or JSON is detected from the content.

## Example (dotnet code)

```c#
var derivedProperties = new DerivedPropertyElementBuilder(loggerFactory)
  .AddScript(BuiltInScript.HumanConfidence)
  .AddScriptFile("derived/*.yaml")
  .Build();

var pipeline = new PipelineBuilder(loggerFactory)
  .AddFlowElement(deviceDetectionEngine)
  .AddFlowElement(ipIntelligenceEngine)
  .AddFlowElement(derivedProperties)
  .Build();

using (var flowData = pipeline.CreateFlowData())
{
  flowData.AddEvidence("header.user-agent", userAgent);
  flowData.AddEvidence("server.client-ip", clientIp);
  flowData.Process();

  var confidence = flowData
    .Get<IDerivedPropertyData>()
    .GetAs<IAspectPropertyValue<string>>("HumanConfidence");

  if (confidence.HasValue)
  {
    Console.WriteLine(confidence.Value);
  }
  else
  {
    Console.WriteLine(confidence.NoValueMessage);
  }
}
```

The `HumanConfidence` script used above reads `device.IsCrawler`,
`device.BrowserReleaseYear`, `device.BrowserReleaseAge` and
`ip.HumanProbability`, and returns one of `High`, `Medium` or `Low`.
Naming a Property in a script makes the Property necessary, so a script
names only Properties that are in the data. The device detection Engine
supplies the Properties under `device` and the IP intelligence Engine
supplies the Property under `ip`, so both Engines are added to the
Pipeline ahead of the Derived Property Element.

## The cloud

The 51Degrees cloud serves a derived Property by running this same
Element inside its own Pipeline, rather than by carrying an evaluator of
its own. That is the whole reason the Element is a normal Flow Element
with no data file, no resource key and no network call.

### Position in the Pipeline

The Element goes after every Element that supplies a source Property the
script names, and before the JSON Builder that writes the response. In
the 51Degrees cloud that means after the device detection and IP
intelligence Engines and before `CloudJsonBuilderElement`.

The Element checks its own position when it is added to the Pipeline and
fails the build naming the Property and the Element that would have
supplied it, so a cloud service configured in the wrong order does not
start rather than returning an empty Property on every request.

### The response

The JSON Builder walks every Element Data on the Flow Data rather than
only the Aspect Engines, so the derived Element Data is carried with no
change to the JSON Builder. Keys are lower cased there, so a script whose
output Property is `HumanConfidence` appears as:

```json
"derived": { "humanconfidence": "High" }
```

Where a source Property was not available, the Property is null and the
usual no-value key carries the reason, which is how a cloud customer is
told why rather than being left with a silently absent Property:

```json
"derived": {
  "humanconfidence": null,
  "humanconfidencenullreason": "Derived property 'HumanConfidence' has no value because 1 source property was not available. 'device.BrowserReleaseYear' (element 'device' held 'Unknown' which cannot be read as int). ..."
}
```

A cloud implementation MUST carry the no-value message rather than
dropping the Property, because a derived Property that is simply absent
gives a customer nothing to act on.

### What a cloud implementation owes

1. The Element Data key `derived` MUST map to the cloud component whose
   vendor id is `derived`, so that the response and the Property listing
   both carry the Property under the component it belongs to.
2. The Property MUST be listed against the products that carry it, so
   that a resource key can select it in the same way as any other
   Property.
3. The component SHOULD declare the source Properties as dependencies,
   so that a customer whose resource key carries the derived Property but
   not one of its sources is told before they see an empty Property.
4. The conformance cases in the shared script repository SHOULD be run
   through the cloud end to end, evidence in and JSON out, which is what
   proves that a cloud answer and a self-hosted answer agree.

### Ownership of the rule

A cloud served band and a customer served band are different products
and should be described as such. A Property computed in the cloud is for
the customer who wants an answer without owning a rule, and this Element
with the customer's own script is for the customer who wants to own the
rule and see it. Both should exist.
