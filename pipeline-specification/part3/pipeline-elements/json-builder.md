# JSON Builder Element

## Overview

The JSON Builder Element creates a JSON representation of most of the values
in the Flow Data.

This is used along with the [JavaScript builder element](javascript-builder.md)
and [Sequence Element](sequence-element.md) to enable client-side features of
the Pipeline [web integration](../../features/web-integration.md).

## Accepted Evidence

This Element uses no Evidence, its only input is the current set of
Element Data instances in the Flow Data.

## Start-up activity

For performance reasons, on start-up it MAY be important to create lists of
Property metadata that meet certain criteria.

For example, a list of all Properties that have the 'delay execution' flag set.
Or, for each Property, a list of the JavaScript Properties that can cause their
value to be updated due to new Evidence.

Note that 'new Evidence' in this case refers to Evidence values that are made
available in second or subsequent requests as part of the same 'session'.
These values can then be used to determine or refine results.

See the [`PopulateMetaDataCollections`](https://github.com/51Degrees/pipeline-dotnet/blob/master/FiftyOne.Pipeline.Elements/FiftyOne.Pipeline.JsonBuilderElement/FlowElement/JsonBuilderElement.cs#L715)
method in C# for an example of creating these lists.

## Element Data

| **Name** | **Type** | **Description**                        |
|----------|----------|----------------------------------------|
| JSON     | string   | The raw JSON produced by this element. |

## Process

The Element needs to produce a JSON representation of the Flow Data.
There MUST be a top-level entry for each Element Data containing sub-entries
for each Property and its value (set to 'null' if there is no value).

There are also several metadata Properties with different suffixes that can
be added for each Property:

| **Suffix**         | **Description**                                                                                                                                                                                                                                                                              |
|--------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| nullreason         | Where the Property value is null, this meta-Property MUST be added with a string message that explains why this Property does not have a value.                                                                                                                                              |
| delayexecution     | This meta-Property MUST be added with the value 'true' for all Properties where the [metadata](../../features/properties.md#property-metadata) delay execution flag is true.                                                                                                                |
| EvidenceProperties | Where the JSON includes other Properties that are in the [metadata](../../features/properties.md#property-metadata) Evidence Properties list for this Property and those Properties have the delayed execution flag set to true, this meta-Property MUST be added to list those Properties. |

Some Elements MUST be excluded from having their Properties added to the JSON.
These are:
- [Set Headers Element](set-headers-element.md)
- [Cloud Request Engine](cloud-request-engine.md)
- [Usage sharing element](usage-sharing-element.md)

The following top-level entries might also be populated in the
final JSON output:
- If the sequence number set by the [Sequence Element](sequence-element.md) is less
  than the maximum (specified by a constant set to 10 in the reference implementations)
  then get a list of the complete names of all JavaScript Properties. Add this to the
  result under the top-level key `javascriptProperties`.
- Add any errors from the Flow Data errors collection to the result. This is structured
  as a string array of the error messages under the top-level key `errors`.

### Examples

Device Detection result including some javascript Properties.
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
  execution Properties that could be executed in order to get a value for
  this Property.

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
| SetProperties | List of strings | [Empty list] | A list of the Properties to include in the JSON. By default, all Properties will be included. Also note that some Properties, such as JavaScript Properties, will always be included, regardless of this setting. Property names will need to be fully qualified. (e.g. `device.ismobile` or `devices.profiles.hardwarename`) |
