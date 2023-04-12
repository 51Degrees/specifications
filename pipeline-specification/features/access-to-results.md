# General guidance

Where string keys are used, the following rules apply:

- strings should only contain alphanumeric characters, full stop or hyphen.
- Some 51Degrees properties also use the ‘/’ character. No new properties will
  be added with this character, but it must be accommodated.
- lower-case is preferred but not required.
- string comparisons must be case insensitive.

# Accessing results

There are multiple ways to access the results of processing.

Firstly, these are the mechanisms for getting element data:

1. It must be possible to get Element Data by supplying the string key
   for the element. For example:
   ```c#
   IElementData deviceData = flowData.Get(DeviceDetectionEngine.ElementDataKey);
   ```
2. In strongly typed languages, it should be possible to get Element Data
   instance by supplying the type of the data required. For example:
   ```c#
   IDeviceData deviceData = flowData.Get<IDeviceData>();
   ```   
3. In strongly typed languages, it should be possible to get an Element Data
   instance by supplying an element instance.
   For example:
   ```c#
   IDeviceData deviceData = flowData.GetFromElement(deviceDetectionEngine);
   ```   
4. In strongly typed languages it may be useful to get the type of
   Element Data associated with a Flow Element, without getting an associated
   instance. For example:
   ```c#
   Type deviceDataType = getDataTypeFromElement(deviceDetectionEngine);
   ```      

Below are the mechanisms for getting properties:

1. It must be possible to get a property value from an Element Data instance by
   supplying the string key for that property. For example:
   ```c#
   object propertyValue = deviceData.Get("ismobile");
   ```
2. It should be possible to get a property value from an Element Data instance
   by using standard property accessors for the language. For example:
   ```c#
   IAspectPropertyValue<bool> propertyValue = deviceData.IsMobile;
   ```


