TODO - Taken from old spec. Needs review and refactor


---
### JsonBuilderElement

The json builder element creates a JSON representation with most of the values in the
flowdata.

The **ElementDataKey** is ‘json-builder’  
The **ElementData** contains a single string property called ‘Json’  
The **EvidenceKeyFilter** is empty

---
*Configuration Options*

| Builder method name | Type | Default | Description |
|---|---|---|------|
| SetProperties | List of strings | [Empty list] | A list of the properties to include in the JSON. By default, all properties will be included. Also note that some properties, such as JavaScript properties, will always be included, regardless of this setting. Property names must be fully qualified. (e.g. ‘device.ismobile’ or ‘devices.profiles.hardwarename’) |

Configuration Example:

**Incorrect**
```
"PipelineOptions": {
  "Elements": [
    {
      "BuilderName": "JsonBuilderElement",
      "BuildParameters": {
        "Properties": [ "ismobile", "city", "hardwarename" ]
      }
    }
  ]
}
```

**Correct**
```
"PipelineOptions": {
  "Elements": [
    {
      "BuilderName": "JsonBuilderElement",
      "BuildParameters": {
        "Properties": [ "device.ismobile", "location.city", "devices.profiles.hardwarename" ]
      }
    }
  ]
}
```

---
*Startup*

This element needs to build some helper collections when it first starts up:


1.  A list, DelayedExecutionProperties, of the complete names of all properties that have delay execution = true.
    1.  This can be determined by looking at the ‘DelayExecution’ flag on
        property meta data for each element in the pipeline.
    2.  Ensure that the complete name is stored. I.e. [element data
        key].[property name] For example, device.ismobile.
    3.  Ensure properties with nested sub-properties are handled correctly. For example, hardware.devices.ismobile.

2.  A collection, DelayedEvidenceProperties, of key value pairs when the key is the complete name of the property and the value is the list of complete property names that, when executed, can help determine the value of that property.  
This must be populated for all properties for which a value cannot be determined until the delayed execution properties are executed. For example, the location.javascript property must be executed before location.country can be populated. The key would be location.country and the value would be a list containing one element: location.javascript.
    1.  This can be determined by using the list of delayed execution properties generated above, in combination with the ‘EvidenceProperties’ list on property meta data.
        1.  EvidenceProperties contains only the property name. For example, ‘country’. These must be converted into complete names before they can be compared with the names in the list of delayed execution properties.
    2.  As above, complete names must be used, and sub-properties handled
        correctly.

---
*Process*

Get sequence number from evidence key ‘query.sequence’. If not present, throw an
error “Sequence number not present in evidence. This is mandatory. Check that
the SequenceElement exists in the pipeline before this JsonBuilderElement”

Create a nested collection C1 of string =\> object key value pairs to hold the
values that will end up in the JSON

For each property each element (except the json-builder element itself), perform
the following:


-   Get the complete name by combining the element name with the property name. Full stop separators are used and the result MUST be all lowercase. For example, the IsMobile property on the device detection engine becomes ‘device.ismobile’
-   Get the property value as a variable - V1.
-   If the V1 is **AspectPropertyValue** and it has a value, set V1 to the
    value. If it does not have a value, add two items to the nested collection C1:
    -   [complete name], null
    -   [complete name]+”nullreason”, [no value message from aspect property value]
-   If V1 is not null:
    -   If V1 is a list of other element data items, repeat this process for each item in the list. Set V1 = the result C1 from that call. Naming is important here, the current ‘complete name’ will become the ‘element name’ in the next level down. For example, when performing a TAC lookup, multiple profiles can be returned. In JSON, the ismobile property would then be represented as ‘hardware.profiles.ismobile’. ‘hardware’ is the **ElementDataKey** and ‘profiles’ is the name of the property, which contains the list of profile objects.
    -   Add to C1: [complete name], V1
    -   If DelayedExecutionProperties contains this property then Add to C1: [complete name]+”delayexecution”, true
-   If the complete name is in DelayedEvidenceProperties then add to C1:
    [complete name]+”evidenceproperties”, [value from DelayedEvidenceProperties]

If sequence number \< 10, get a list of the complete names of all JavaScript
properties. Add this to the result under the key ‘javascriptProperties’.

Add any errors from the flowdata Errors collection to the result. This must be a
simple string list of the error messages under the key ‘errors’.
