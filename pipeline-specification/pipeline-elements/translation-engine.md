# Translation Engine

The Translation Engine translates values from one source Flow Element into
language-specific values and stores the translated output in its own Element Data.
It is intended to work alongside a dedicated translation-source element that
loads and publishes translation mappings.

## Purpose

- Keep translation logic independent from source engines.
- Keep translation-source loading independent from translation execution.
- Allow one or more translation engines to be added to the same pipeline.
- Support language-specific value mapping without mutating source engine data.

## Element responsibilities


### `ResourceEngine`
- Loads resources (for example embedded files) and exposes sources by name.

### `TranslationEngine`
- Reads source values from one configured source flow element.
- Resolves language from evidence keys.
- Uses translation source(s) published by the source engine.
- Writes translated properties to its own element data.

## Key behavior

1. A Translation Engine has exactly one source element key (`SourceElementDataKey`).
2. It translates one or more named properties from that source element.
3. Output properties are explicitly mapped per translation
   (`SourceProperty` -> `DestinationProperty`).
4. Output values are written under the Translation Engine element data key.
5. Multiple Translation Engines can exist in one pipeline if each uses a unique element data key.
6. Supported source value types are:
   - string
   - list/collection of strings
7. Language is resolved from an ordered list of evidence keys; first available key wins.
8. A translation is a source-property mapping that can translate a string for a target language.
9. Translation source retrieval is handled by a separate source element.

## Accepted evidence

The engine only uses evidence for language selection.

Typical evidence keys:

- `query.language`
- `header.accept-language`

## Element data

Translated values are stored in the engine's own Element Data.

If source property `Country` is mapped to destination property
`CountryTranslated` by an engine with key `countrytranslation`,
the translated value is available as:

- `flowData.Get("countrytranslation")["CountryTranslated"]`

If multiple languages should be translated per engine per property, 
mappings could be expressed as such: 
French example: 
destination property: `CountryTranslated-fr`
- `flowData.Get("countrytranslation")["CountryTranslated-fr"]`

> This is intentionally separate from source element data.

> There will be no way to provide StronglyTypedAccessors for every translation 
> so we need to use the above method of accessing the property values.

## Processing

Construction: 
1. Resolves target language from configured evidence keys.
2. The source element data from `SourceElementDataKey` is cached 
as FrozenDictionary<string, FrozenDictionary<string, string>> to remove need for retrieval of full data.

Per request, the engine:

1. Iterates configured translations by source property.
2. Reads source property value.
3. If value is string:
   - translate single value
4. If value is list of strings:
   - translate each item
   - keep original item where no mapping exists
5. Writes translated value to translation element data using destination property name.

## Language behavior in the same pipeline

Pipelines can support multiple simultaneous translation contexts by using:

- multiple Translation Engine instances with different element data keys, and/or
- different language evidence key precedence per engine.

For example:

- `countrytranslation-fr` reads `query.language.fr`
- `countrytranslation-de` reads `query.language.de`

## Configuration

The Translation Engine should be configurable using simple values:

- source element data key e.g `countrytranslation`
- translation element data key e.g. `ip-intelligence`
- translation source element data key `resourceengine`
- language evidence keys e.g  `query.language`
- translation registrations
  (`source property + destination property + translation source name`)

The translation-source engine should be independently configurable with:

- source engine element data key
- list of YAML resource identifiers
- optional source names/aliases

## Example (configuration-first)

```json
{
  "Elements": [
    {
      "BuilderName": "ResourceEngine",
      "BuildParameters": {
        "ElementDataKey": "resourceengine",
        "Sources": [
          "translations.en_gb.yaml",
          "translations.en_fr.yaml",
          "translations.en_es.yaml"
        ]
      }
    },
    {
      "BuilderName": "TranslationEngine",
      "BuildParameters": {
        "ElementDataKey": "countrytranslation",
        "SourceElementDataKey": "ip-intelligence",
        "TranslationSourceElementDataKey": "resourceengine",
        "LanguageEvidenceKeys": [
          "query.language",
          "header.accept-language"
        ],
        "Mappings": [
          {
            "SourceProperty": "Country",
            "DestinationProperty": "CountryTranslated",
            "TranslationSource": "en_gb"
          }
        ]
      }
    }
  ]
}
```

## Example (code)

```c#
var translationEngine = new TranslationEngineBuilder(loggerFactory)
    .SetSourceElementDataKey("ip-intelligence")
    .SetTranslationSourceElementDataKey("resourceengine")
    .SetElementDataKey("countrytranslation")
    .AddLanguageEvidenceKeys(new[] { "query.language", "header.accept-language" })
    .AddTranslation(new CountryNameTranslation("Country", "CountryTranslated", "en_GB"))
    .Build();
```

## Example (YAML-backed translation)

Language files can be provided as one file per language, for example:

- `en_GB.yaml`
- `en_ES.yaml`

Each file contains source-to-destination entries for one language.
