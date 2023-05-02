# JSON Builder Element

## Overview

The JSON Builder Element creates a JSON representation of most of the values 
in the Flow Data.

This is used along with the [JavaScript builder element](javascript-builder.md)
and [Sequence element](sequence-element.md) to enable client-side features of 
the Pipeline [web integration](../../features/web-integration.md).

## Accepted Evidence

This Element uses no evidence, its only input is the current set of 
Element Data instances in the Flow Data.

## Start-up activity

For performance reasons, on start-up it may be important to create lists of 
Property metadata that meet certain criteria.

For example, a list of all Properties that have the 'delay execution' flag set.
Or, for each property, a list of the JavaScript Properties that can cause their
value to be updated due to new Evidence.

Note that 'new Evidence' in this case refers to Evidence values that are made 
available in second or subsequent requests as part of the same 'session'.
These values can then be used to determine or refine results.

See the [`PopulateMetaDataCollections`](https://github.com/51Degrees/pipeline-dotnet/blob/master/FiftyOne.Pipeline.Elements/FiftyOne.Pipeline.JsonBuilderElement/FlowElement/JsonBuilderElement.cs#L715)
method in C# for an example of creating these lists.

## Element data

| **Name** | **Type** | **Description**                        |
|----------|----------|----------------------------------------|
| json     | string   | The raw JSON produced by this element. |

## Process

The Element needs to produce a JSON representation of the Flow Data. 
There should be a top-level entry for each Element Data containing sub-entries 
for each property and its value (set to 'null' if there is no value).

There are also several meta-data Properties with different suffixes that may 
be added for each property:

| **Suffix**         | **Description**                                                                                                                                                                                                                                                                              |
|--------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| nullreason         | Where the property value is null, this meta-property must be added with a string message that explains why this property does not have a value.                                                                                                                                              |
| delayexecution     | This meta-property must be added with the value 'true' for all properties where the [meta-data](../../features/properties.md#property-metadata) delay execution flag is true.                                                                                                                |
| evidenceproperties | Where the JSON includes other properties that are in the [meta-data](../../features/properties.md#property-metadata) evidence properties list for this property and those properties have the delayed execution flag set to true, this meta-property must be added to list those properties. |

Some Elements should be excluded from having their properties added to the JSON. 
These are:
- [Set headers element](set-headers-element.md)
- [Cloud request engine](cloud-request-engine.md) 
- [Usage sharing element](usage-sharing-element.md) 

<span style="color:yellow">How is this property exclusion achieved?  Is an exclusion-list of 
certain properties?</span>

The following top-level entries that may be populated in the 
final JSON output:
- If the sequence number set by the [sequence element](sequence-element.md) is less 
  than the maximum (specified by a constant set to 10 in the reference implementations) 
  then get a list of the complete names of all JavaScript properties. Add this to the 
  result under the top-level key `javascriptProperties`.
- Add any errors from the Flow Data errors collection to the result. This is structured
  as a string array of the error messages under the top-level key `errors`.

### Examples

Device detection result including some javascript properties.
Note the `screenpixelswidth` Property is currently zero because device
detection does not know how wide the screen is.
The `screenpixelswidthjavascript` Property contains the JavaScript snippet that
can be executed to gather this information.

```json
{
  "device": {
    "ismobile": false,
    "screenpixelswidth": 0,
    "screenpixelswidthjavascript": "//Set screen pixels width cookie.\r\ndocument.cookie = \"51D_ScreenPixelsWidth=\" + screen.width;"
  },
  "javascriptProperties": [
    "device.screenpixelswidthjavascript"
  ]
}
```

Result from a location lookup before any coordinates have been supplied.
- The `javascript` Property contains the script to be executed to get the 
  coordinate values.
- The `javascriptdelayexecution` Property indicates that we don't want the
  `javascript` snippet to be executed immediately because it will prompt 
  the user to allow their location to be read.
- The `zipcode` Property is null because we haven't yet supplied coordinates
- The `zipcodenullreason` Property contains a description of why `zipcode` 
  is null
- The `zipcodeevidenceproperties` Property contains a list of the delayed 
  execution properties that could be executed in order to get a value for 
  this property.

```json
{
  "location": {
    "javascript": "\r\nif (navigator.geolocation) {\r\n\tnavigator.geolocation.getCurrentPosition(function(pos) {\r\n        for (var key in pos.coords) {\r\n            document.cookie = \"51D_Pos_\" + key + \"=\" + pos.coords[key];\r\n        }\r\n        // 51D replace this comment with callback function.\r\n\t}, function(e) {\r\n        document.cookie =\"51D_Pos_Error=\" + encodeURIComponent(e.message);\r\n        // 51D replace this comment with callback function.\r\n    });\r\n}\r\n",
    "javascriptdelayexecution": true,
    "zipcode": null,
    "zipcodenullreason": "This property requires evidence values from JavaScript running on the client. It cannot be populated until a future request is made that contains this additional data.",
    "zipcodeevidenceproperties": ["location.javascript"]
  },
  "javascriptProperties": [
    "location.javascript"
  ]
}

```

Partial result from a TAC lookup that returns multiple devices.

```json
{
  "hardware": {
    "profiles": [
      {
        "hardwaremodel": "5217",
        "hardwarename": [
          "5217"
        ],
        "hardwarevendor": "Coolpad"
      },
      {      
        "hardwaremodel": "5200",
        "hardwarename": [
          "5200"
        ],
        "hardwarevendor": "Coolpad"
      },
      {
        "hardwaremodel": "5310",
        "hardwarename": [
          "5310"
        ],
        "hardwarevendor": "Coolpad"
      }
    ]
  }
}
```

JSON with an error value set.

```json
{ 
  "errors": [ "'abc' is not a valid Resource Key. See http://51degrees.com/documentation/_info__error_messages.html#Resource_key_not_valid for more information." ]
}
```

## Configuration options

| **Name**      | **Type**        | **Default**  | **Description**                                                                                                                                                                                                                                                                                                       |
|---------------|-----------------|--------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| SetProperties | List of strings | [Empty list] | A list of the properties to include in the JSON. By default, all properties will be included. Also note that some properties, such as JavaScript properties, will always be included, regardless of this setting <span style="color:yellow">Also metaproperties are included regardless of the setting</span>. Property names must be fully qualified. (e.g. `device.ismobile` or `devices.profiles.hardwarename`) |

<span style="color:yellow">So is this mechanism for exclusion as well?  If some property is not present in this list - will it
be excluded from json?</span>
