# Translation Engine

The Translation Engine translates values from one source Flow Element using a translation source and stores the translated output in its own Element Data.
It is intended to work alongside a dedicated translation-source element that provides the source element data.

## Terms
- `SourceElementDataKey` : The Element data that the Translation engine retrives value to be translated from.
- `SourceProperty`: The property that will be the input to the translation i.e. The property for the value that will be translated.
- `DestinationProperty`: The property that will be the output to the translation i.e. The property for the value that is the translation.

## Features

- Allow one or more translation engines to be added to the same pipeline. e.g. One Translation engine could sit after both a device detection element and another could sit behind an ip intelligence element. 

## Translation Element responsibilities and behavior

### `TranslationEngine`
- Calls service to Load resources (for example embedded files) and exposes sources by name.
- Reads source values from the source flow element data.
- Resolves target translation from evidence keys.
- Uses translation source(s) published by the source engine.
- Writes translated properties to its own element data

1. A Translation Engine has exactly one source element key (`SourceElementDataKey`).
2. It translates one or more named properties from that source element.
3. Output properties are explicitly mapped per translation
   (`SourceProperty` -> `DestinationProperty`).
4. Output values are written under the Translation Engine element data key.
5. Multiple Translation Engines can exist in one pipeline if each uses a unique element data key.
6. Supported source value types are:
   - string
   - list/collection of strings
   - Any string wrapped in `IWeightedValue<string>`
   - Any string or above type wrapped in `AspectPropertyValue<>`
7. Language is resolved from an ordered list of evidence keys; first available key wins.
8. A translation is a source-property mapping that can translate a string for a target language.
9.  Translation source retrieval is handled by a separate source element.


## Sources

Sources should be stored in the `translations` folder as Embedded resources
however the full path can be supplied to load them in configuration. 
Source files can be provided as one file per translation Language files for example:

- `en_GB.yaml`
- `en_ES.yaml`

Each file contains source-to-destination entries for one translation.


## Accepted evidence

The engine only uses evidence for language selection.

Typical evidence keys:

- `query.translation`
- `header.accept-language`

> e.g "en_GB"

## Element data

Translated values are stored in the engine's own Element Data.

If source property `Country` is mapped to destination property
`CountryTranslated` by an engine with key `translation`,
the translated value is available as:

- `flowData.Get("translation")["CountryTranslated"]`

If multiple languages should be translated per engine per property, 
mappings could be expressed as such: 
French example: 
destination property: `CountryTranslated`
- `flowData.Get("countrytranslation")["CountryTranslated"]`

> This is intentionally separate from source element data.


## Processing

Construction: 
1. Calls a resource service that pulls in embedded resource files from the `Translations` folder.
2. Builds translation lookups. These are keyed on the file names which will match the evidence provided.

Per request, the engine:

1. Iterates configured translations by source property.
2. Reads source property value.
3. If value is string:
   - translate single value
4. If value is list of strings:
   - translate each item
   - keep original item where no mapping exists
5. Writes translated value to translation element data using destination property name.

## Behavior in the same pipeline

Pipelines can support multiple simultaneous translation contexts by using:

- multiple Translation Engine instances with different element data keys, and/or
- different evidence key precedence per engine.

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
          "translations.en_gb.yaml",
          "translations.en_fr.yaml",
          "translations.en_es.yaml"
        ],
        "Translations": [
          {
            "SourceProperty": "Country",
            "DestinationProperty": "CountryTranslated",
          },
          {
            "SourceProperty": "CountryCodes",
            "DestinationProperty": "CountryCodesTranslated",
          }
        ]
      }
    }
  ]
}
```

## Example (dotnet code)

```c#
var translationEngine = new TranslationEngineBuilder(loggerFactory)
    .AddTranslation(new CountryNameTranslation("Country", "CountryTranslated"))
    .AddTranslations([new CountryNameTranslation("CountryCodes", "CountryCodesTranslated")])
    .Build();
```

