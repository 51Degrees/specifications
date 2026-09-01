# Derived Property Element

The Derived Property Element produces new Property values from Property
values that other Flow Elements in the Pipeline have already produced,
following rules written in a script, and stores the results in its own
Element Data.

*This page was produced with AI assistance on 1 September 2026 and needs
human review before it is treated as settled.*

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
- `Three-valued`: A test can be true, false or unknown, where unknown
  means a Property the test needs was not available on that request.
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
ordered Element list and, for each source Property, confirms that an
Element earlier in the Pipeline has the Element Data key and lists the
Property in its Property metadata.

- A required Property with no supplier fails the Pipeline build, with a
  message naming the Property and naming any Element later in the
  Pipeline that would have supplied the Property had the ordering been
  different.
- An optional Property with no supplier is logged at information level,
  and the Property is absent on every request.
- Two Elements in one Pipeline producing the same derived Property name
  fail the Pipeline build in the same check.

### Absent and invalid source Properties

A source Property is available when the source Element Data is present,
the Property is present, the value has a value, and the value converts
to the type the script infers for the Property. The source Property is
absent otherwise. A value that does not convert is absent as well, and
values are never coerced loosely, so the strings `N/A`, `Unknown` and an
empty string never become false or zero.

Every source Property is required unless the script lists the Property
under `Optional`.

- **A required Property that is absent** makes the output a value that
  has no value, carrying a message that names every absent required
  Property rather than only the first, along with the reason each one
  was not available and the usual causes. This uses the existing
  no-value mechanism, being `AspectPropertyValue` with `NoValueMessage`
  in .NET and the equivalent in each other language, which the
  Translation Element already uses for a source Property without a
  value. No new `MissingPropertyReason` value is needed and that
  enumeration does not change.
- **An optional Property that is absent** makes every condition naming
  the Property unknown, and the script decides what unknown means
  through `Present`, through the counts of evaluated and failed checks,
  and through rule order.

### Logging and exposed metadata

At build, one information line per script gives the name, the version,
the format, the source and the output Property. At debug level, one
entry per script prints the compiled model as canonical JSON, with
PascalCase keys, two-space indent, literal types preserved, and the
inferred types and computed dependencies included, so that anyone
holding the log can reconstruct what was evaluated without the file. At
Pipeline build, one information line names each optional Property that
has no supplier. A deprecated script logs a warning carrying the note
the author left.

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

Where a required source Property was absent, the returned value has no
value, and the no-value message names every absent required Property.

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
3. For each script, evaluates the required-Property check, then the
   checks, then the rules in order, taking the value of the first rule
   whose condition is true,
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
`device.IsHeadless`, `device.WebDriver`, `device.IsVisible`,
`device.BrowserReleaseYear`, `device.BrowserReleaseAge` and
`ip.HumanProbability`, and returns one of `High`, `Medium`, `Low` or
`Unknown`. The device detection Engine supplies the Properties under
`device` and the IP intelligence Engine supplies the Property under
`ip`, so both Engines are added to the Pipeline ahead of the Derived
Property Element.
