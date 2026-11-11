# JSON Builder Element

The JSON Builder Element creates a JSON representation of most of the values
in the Flow Data.

This is used along with the [JavaScript builder element](javascript-builder.md)
and [Sequence Element](sequence-element.md) to enable client-side features of
the Pipeline [web integration](../features/web-integration.md).

In particular, the functionality of this Element is very closely coupled with
the JavaScript builder element.

## Accepted Evidence

This Element accepts no Evidence, so its Evidence key filter is empty. It
reads the integer under `query.sequence` that the
[Sequence Element](sequence-element.md) adds, as described in
[Sequence number](#sequence-number), and the current set of Element Data
instances in the Flow Data.

## Start-up activity

For performance reasons, on start-up it MAY be important to create lists of
Property metadata that meet certain criteria.

For example, a list of all Properties that have the 'delay execution' flag set.
Or, for each Property, a list of the JavaScript Properties that can cause their
value to be updated due to new Evidence.

Note that 'new Evidence' in this case refers to Evidence values that are made
available in second or subsequent requests as part of the same
[session](sequence-element.md). These values can then be used to determine or
refine results.

See the [`PopulateMetaDataCollections`](https://github.com/51Degrees/51degrees-dotnet/blob/main/pipeline/JsonBuilderElement/FlowElement/JsonBuilderElement.cs#L882)
method in C# for an example of creating these lists.

## Element Data

| **Name** | **Type** | **Description**                        |
|----------|----------|----------------------------------------|
| JSON     | string   | The raw JSON produced by this element. |

## Process

The Element needs to produce a JSON representation of the Flow Data.
There MUST be a top-level entry for each Element Data containing sub-entries
for each Property and its value. A Property that has been assigned
['no value'](../features/properties.md#null-values) MUST be written as 'null',
with the `nullreason` meta-Property in the table below. A Property whose value
is null without having been assigned 'no value', which a Flow Element that is
not an Engine can produce, MUST have no entry of its own in the Element Data's
object, and no `nullreason`.
For `profiles` in the Element Data of the
[hardware profile lookup on-premise](../../device-detection-specification/pipeline-elements/hardware-profile-lookup-on-premise.md),
the value MUST be written as an empty list however many profiles match, so
that building the JSON reads no profile.

These keys MUST be written in lower case. The key of a top-level entry is the
Element Data's Data Key, and the key of a sub-entry is the Property name,
followed by the suffix of any meta-Property in the table below. The one
exception is the top-level key `javascriptProperties`, which keeps its
capital P.

There are also several metadata Properties with different suffixes that can
be added for each Property:

| **Suffix**         | **Description**                                                                                                                                                                                                                                                                          |
|--------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| nullreason         | Where the Property has been assigned 'no value', this meta-Property MUST be added with a string message that explains why this Property does not have a value.                                                                                                                           |
| delayexecution     | This meta-Property MUST be added with the value 'true' for each Property that has a value and whose [metadata](../features/properties.md#property-metadata) delay execution flag is true.                                                                                                |
| evidenceproperties | Where the JSON includes other Properties that are in the [metadata](../features/properties.md#property-metadata) Evidence Properties list for this Property and those Properties have the delayed execution flag set to true, this meta-Property MUST be added to list those Properties. |

Where a Property's value is a list of Element Data, such as `profiles` in the
[hardware profile lookup](../../device-detection-specification/pipeline-elements/hardware-profile-lookup-cloud.md),
each item MUST be written as an object whose Properties follow the rules
above for a Property that has been assigned 'no value' and for one whose value
is null.

Some Elements MUST be excluded from having their Properties added to the JSON.
These are:

- [Set Headers Element](set-headers-element.md)
- [Cloud Request Engine](cloud-request-engine.md)
- [Usage sharing element](usage-sharing-element.md)
- The JSON Builder Element itself, whose Element Data the reference
  implementations add to the Flow Data before they build the JSON.

The reference implementations achieve this with a hard-coded exclusion list which
contains the Data Key of the elements to exclude, being `set-headers`,
`cloud-response` and `json-builder`. The usage sharing element adds no Element
Data to the Flow Data, so it needs no entry in that list.

The following top-level entries might also be populated in the
final JSON output:

- If the sequence number set by the [Sequence Element](sequence-element.md) is less
  than the maximum (specified by a constant set to 10 in the reference implementations)
  then get a list of the complete names of all JavaScript Properties. Add this to the
  result under the top-level key `javascriptProperties`.
  - If sequence number is 10 (or more) then, to prevent infinite loops, we want to
    stop further execution of JavaScript property snippets. Not setting
    `javascriptProperties` means that the JavaScript produced by the
    [JavaScript Builder](javascript-builder.md) will ignore such snippets that are
    present.
- Add any errors from the Flow Data errors collection to the result. This is structured
  as a string array of the error messages under the top-level key `errors`.

### Sequence number

The Element uses the sequence number that the
[Sequence Element](sequence-element.md) adds to Evidence under `query.sequence`
as an integer (see
[adding Evidence values](../features/evidence.md#adding-evidence-values) and
[Sequence Element](sequence-element.md#process)). A Pipeline that includes the
JSON Builder Element therefore needs a Sequence Element before it. Where the
[web integration](../features/web-integration.md#pipeline-configuration)
creates the Pipeline, it adds both if they are not present.

If no Sequence Element has produced a sequence number when the Element runs,
the Element MUST fail with an error and MUST NOT set its JSON value. The error
MUST carry the message below, which is the text every implementation gives, so
that the message reads the same in every language and makes life easier for
51Degrees support.

| **Error** | **Message** |
| --- | --- |
| No Sequence Element has produced a sequence number | The JSON Builder needs a sequence number. Place a Sequence Element before the JSON Builder in the Pipeline. |

PHP names this Element the JSON Bundler, so PHP gives the same message with
JSON Bundler in place of JSON Builder, reading "The JSON Bundler needs a
sequence number. Place a Sequence Element before the JSON Bundler in the
Pipeline." Nothing else differs. Where an implementation wraps the error in
another, such as a
[Pipeline Configuration Exception](../features/exception-handling.md#pipeline-configuration-exception)
that carries the first error as its cause, the error the caller reads carries
the message.

The Pipeline handles the error as described in
[exception handling](../features/exception-handling.md#process-function).
When the Element fails, the web integration handles the error as that page
describes, and a response it serves then, such as the .NET web integration's
fallback response, is not the Element's JSON value.

A `query.sequence` value taken from a query string is text and not an integer,
so it does not count as a sequence number. An integer that a caller added to
`query.sequence` without a Sequence Element does count in .NET and Java,
because the Element reads the integer in Evidence whoever added it.

### Examples

Below is the JSON for a Device Detection result including some javascript Properties.
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

Below is the JSON from a location lookup before any coordinates have been supplied.

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

Below is the partial JSON from a TAC lookup through the cloud service that
returns multiple devices.

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

Below is JSON with an error value set.

```json
{ 
  "errors": [ "'abc' is not a valid Resource Key. See http://51degrees.com/documentation/_info__error_messages.html#Resource_key_not_valid for more information." ]
}
```

## Configuration options

None
