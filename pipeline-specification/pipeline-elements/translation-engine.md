# Translation Engine

The Translation Engine translates values from one source Flow Element using a translation source and stores the translated output in its own Element Data.

## Terms
- `SourceElementDataKey` : The Element data that the Translation engine retrieves, that contains values to be translated from.
- `SourceProperty`: The property that will be the input to the translation i.e. The property for the value that will be translated.
- `DestinationProperty`: The property that will be the output to the translation i.e. The property for the value that is the translation.

## Features

- Allow one or more translation engines to be added to the same pipeline. e.g. In parallel, one Translation engine could sit after a device detection element and another could sit behind an ip intelligence element. 

## Components
- `ITranslationEngine` | `TranslationEngine`: Provides the main logic, performing a translation based on the translation provided.
- `TranslationEngineBuilder`: Provides methods to build a TranslationEngine through code.
- `ITranslationElementData` | `TranslationElementData`: The Element data for the `TranslationEngine`. This holds the translated values. 

## Translation Element Responsibilities and Behavior

### `TranslationEngine`
- Loads resources (translation text files) and stores them for lookup. These could also be ingested from some other format if there is a suitable use case,
- Reads source values from the source Flow Element Data,
- Resolves target translation from Evidence keys,
- Uses translation source(s) to translate the source value,
- Writes translated properties to its own Element Data.

### Key Considerations
1. A Translation Engine has exactly one source Element key (`SourceElementDataKey`),
2. It translates one or more named properties from that source Element,
3. Output properties are explicitly mapped per translation
   (`SourceProperty` -> `DestinationProperty`),
4. Multiple Translation Engines can exist in one pipeline, and share the same output Element Data,
5. Supported source value types are:
  - `string`
  - Any `string` wrapped in `IWeightedValue<string>`
  - list/collection of `string` or `IWeightedValue<string>`
  - Any of the above types wrapped in `AspectPropertyValue<>`
6. The target translation language is either set as a fixed language in the constructor which is passed to the `TranslationEngineBase` or it resolved at request time from an ordered list of evidence keys; first available key wins.
7. A translation is a source-property mapping that can translate a string for a target language.

## Sources

Sources should follow the naming convention `[x].[locale].yml` (`yml` or `yaml` are both acceptable)
where `x` can be anything (e.g. `countries`)
and `locale` is the language locale code (e.g. `en_GB`).

Sources can be provided in two ways:

1. **As file paths** - The builder reads files from disk, supporting wildcards:
   ```csharp
   .AddSource("countries/*.yml")
   .AddSource("countryCodes.en_GB.yaml")
   ```

2. **As file contents** - A dictionary keyed by filename, where the value is the YAML content:
   ```csharp
   .AddSource("countries.en_GB.yml", "England: Angleterre\nScotland: Ecosse")
   ```
   This is useful for engines with built-in data (e.g., embedded resources).

Source files are provided as one file per translation Language, for example:

- `countries.en_GB.yml`
- `countryCodes.es_ES.yaml`

Each file contains source-to-destination entries for one translation.
For example:
```
England: Angleterre
```

Note that the key is not necessarily always the same. In the above example, the key is the English word.
However, the key could be another language, or even an ISO country code for example.

## Accepted evidence

The engine only uses evidence for language selection.

Accepted evidence keys (in order of precidence):

- `query.translation`
- `header.accept-language`

The evidence value itself can be provided in 3 ways:
- language locale format e.g "en_GB"
- language locale hyphonated e.g. "en-GB"
- and just the two letter langauge code e.g. "en"

The support for the above formats are influenced by the `accept-language` [standard format](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Accept-Language) where the highest preference language in the highest preference evidence key is used.

## Element Data

Translated values are stored in the `TranslationElementData`.

The ElementData can be retrieved from the Flow Data like so: 
- `flowdata.Get<ITranslationData>()`

If source property `Country` is mapped to destination property
`CountryTranslated`, the data can be retrieved with strongly typed accessors like so:

- `flowData.Get<ITranslationData>().GetAs<string>("CountryTranslated")`

## Processing

Construction: 
1. Reads the files provided,
2. Builds translation lookups. These are keyed on the language from the file names which will match the evidence provided.

Per request, the engine:

1. Determines the target language from the evidence.
2. Iterates configured translations by source property,
3. Reads source property value,
4. If value is string:
   - translate single value
5. If value is list of strings:
   - translate each item
6. Writes translated value to translation Element Data using destination property name,

If translation is not available for the word or language, the configured `MissingTranslationBehavior` is employed:
- `Original` (default): The original value is kept and presented as is.
- `EmptyString`: An empty string is presented in the original value's place.
- `FlowError`: A flow error is added to FlowData indicating the lack of a translation.

## Behavior of Multiple Engines

Pipelines can support multiple simultaneous translation contexts by using
multiple Translation Engine instances. Both write to the same Element Data, meaning it
must be thread safe.

## Configuration
The Translation Engine is configurable using jsonConfiguration:

```json
{
  "Elements": [
    {
      "BuilderName": "TranslationEngine",
      "BuildParameters": {
        "SourceElementDataKey": "ip",
        "Sources": [
          "countries/*.yml",
        ],
        "Translations": [
          {
            "SourceProperty": "Country",
            "DestinationProperty": "CountryTranslated"
          }
        ]
      }
    },
    {
      "BuilderName": "TranslationEngine",
      "BuildParameters": {
        "SourceElementDataKey": "ip",
        "Sources": [
          "countrycodes/*.yaml"
        ],
        "FixedLanguage":"en_GB",
        "MissingTranslationBehaviour": "Original",
        "Translations": [
          {
            "SourceProperty": "CountryCode",
            "DestinationProperty": "CountryCodeTranslated"
          }
        ]
      }
    }
  ]
}
```

The Translation Engine is configurable using the builder:

- `SetSourceElementDataKey(string)`: Source element data key e.g `ip`
- `AddSource(string)`: Add a translation source file (supports wildcards)
- `AddTranslation(string source, string destination)`: Map source property to destination property
- `SetFixedLanguage(string)`: Optional fixed language (e.g. "en_GB"). If not set, language is determined from evidence
- `SetMissingTranslationBehavior(MissingTranslationBehavior)`: Behavior when translation is missing (Original, EmptyString, FlowError)

## Example (dotnet code)

```c#
var countryTranslation = new TranslationEngineBuilder(loggerFactory)
  .SetSourceElementDataKey("ip-intelligence")
  .AddSource("country-langs/*.yaml")
  .AddTranslation("Country", "CountryTranslated")
  .SetMissingTranslationBehavior(MissingTranslationBehavior.Original)
  .Build();

var countryCodeTranslation = new TranslationEngineBuilder(loggerFactory)
  .SetSourceElementDataKey("ip-intelligence")
  .AddSource("countrycode-langs/en_GB.yaml")
  .SetFixedLanguage("en_GB")
  .AddTranslation("CountryCode", "CountryCodesTranslated")
  .Build();
```

