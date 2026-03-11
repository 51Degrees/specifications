# Translation Engine

The Translation Engine translates values from one source Flow Element using a translation source and stores the translated output in its own Element Data.

## Terms
- `SourceElementDataKey` : The Element data that the Translation engine retrives value to be translated from.
- `SourceProperty`: The property that will be the input to the translation i.e. The property for the value that will be translated.
- `DestinationProperty`: The property that will be the output to the translation i.e. The property for the value that is the translation.

## Features

- Allow one or more translation engines to be added to the same pipeline. e.g. In parallel, one Translation engine could sit after a device detection element and another could sit behind an ip intelligence element. 

## Components
- `ITranslationEngine` | `TranslationEngine`: Provides the main logic, performing a translation based on the translation provided.
- `TranlationEngineBuilder`: Provides methods to build a TranslationEngine, either though code or from configuration.
- `ITranslationElementData` | `TranslationElementData`: The Element data for the `TranslationEngine`. This holds the translated values. 

## Translation Element Responsibilities and Behavior

### `TranslationEngine`
- Loads resources (translation text files) and stores them for lookup. These could also be ingested from some other format if there is a suitable use case,
- Reads source values from the source Flow Element Data,
- Resolves target translation from Evidence keys,
- Uses translation source(s) to transate the source value,
- Writes translated properties to its own Element Data.

### Key Considerations
1. A Translation Engine has exactly one source Element key (`SourceElementDataKey`),
2. It translates one or more named properties from that source Element,
3. Output properties are explicitly mapped per translation
   (`SourceProperty` -> `DestinationProperty`),
4. Multiple Translation Engines can exist in one pipeline, and share the same output Element Data,
5. Supported source value types are:
   - string
   - list/collection of strings

## Sources

Sources should follow the naming convention `[x].[locale].yml` (`yml` or `yaml` are both acceptable)
where `x` can be anything (e.g. `countries`)]
and `locale` is the language locale code (e.g. `en_GB`).

Source files are provided as one file per translation Language files for example:

- `en_GB.yml`
- `es_ES.yml`

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
- `query.accept-language`
- `header.accept-language`

> e.g "en_GB"

The highest preference language in the highest preference evidence key is used.

## Element Data

Translated values are stored in the `TranslationElementData`.

The ElementData can be retrieved from the Flow Data like so: 
- `flowdata.Get<ITranslationData>()`

If source property `Country` is mapped to destination property
`CountryTranslated`, the data can be retrieved with strongly typed accessors like so:

- `flowData.Get<ITranslatedData>()["CountryTranslated"]`


## Processing

Construction: 
1. Reads the files provided,
2. Builds translation lookups. These are keyed on the language from the file names which will match the evidence provided.

Per request, the Eengine:

1. Iterates configured translations by source property,
2. Reads source property value,
3. If value is string:
   - translate single value
4. If value is list of strings:
   - translate each item
5. Writes translated value to translation Element Data using destination property name,

Note: If translation is not available for the word, or language, a "no value" is the result. With an
appropriate no value message.

## Behavior of Multiple Engines

Pipelines can support multiple simultaneous translation contexts by using
multiple Translation Engine instances. Both write to the same Element Data, meaning it
must be thread safe.

## Configuration

The Translation Engine should be configurable using simple values:

- Source element data key e.g `ip-intelligence`
- Translation registrations
  (`source property, destination property`)

## Example (configuration-first)

```json
{
  "Elements": [
    {
      "BuilderName": "TranslationEngine",
      "BuildParameters": {
        "SourceElementDataKey": "ip-intelligence",
        "Sources": [
          "country-langs/en_GB.yaml",
          "country-langs/fr_Fr.yaml",
          "country-langs/es_ES.yaml"
        ],
        "Translations": [
          {
            "SourceProperty": "Country",
            "DestinationProperty": "CountryTranslated",
          }
        ]
      }
    },

    {
      "BuilderName": "TranslationEngine",
      "BuildParameters": {
        "SourceElementDataKey": "ip-intelligence",
        "Sources": [
          "countrycode-langs/en_GB.yaml",
          "countrycode-langs/fr_Fr.yaml",
          "countrycode-langs/es_ES.yaml"
        ],
        "Translations": [
          {
            "SourceProperty": "CountryCode",
            "DestinationProperty": "CountryCodeTranslated",
          }
        ]
      }
    }
  ]
}
```

## Example (dotnet code)

```c#
var countryTranslation = new TranslationEngineBuilder(loggerFactory)
   .AddSources([
          "country-langs/en_GB.yaml",
          "country-langs/fr_Fr.yaml",
          "country-langs/es_ES.yaml"])
   .AddSourceElementDataKey("ip-intelligence")
   .AddTranslation("Country", "CountryTranslated")
   .Build();
var countryCodeTranslation = new TranslationEngineBuilder(loggerFactory)
   .AddSources([
          "countrycode-langs/en_GB.yaml",
          "countrycode-langs/fr_Fr.yaml",
          "countrycode-langs/es_ES.yaml"])
   .AddTranslation("CountryCode", "CountryCodesTranslated")
   .Build();
```

