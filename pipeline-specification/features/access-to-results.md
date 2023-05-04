# Access to results

## General guidance

Where string keys are used, the following rules apply:

- Strings SHOULD only contain alphanumeric characters, full stop or hyphen.
- Some 51Degrees Properties also use the ‘/’ character. No new Properties will
  be added with this character, but it will need to be accommodated.
- Lower-case SHOULD be used.
- String comparisons MUST be case insensitive.

## Accessing results

There are multiple ways to access the results of processing.

Firstly, these are the mechanisms for getting Element Data:

1. It MUST be possible to get Element Data by supplying the string key
   for the element. For example:

   ```c#
   IElementData deviceData = flowData.Get(DeviceDetectionEngine.ElementDataKey);
   ```
2. In strongly typed languages, it SHOULD be possible to get an Element Data
   instance by supplying the type of the data that is needed. For example:

   ```c#
   IDeviceData deviceData = flowData.Get<IDeviceData>();
   ```
3. In strongly typed languages, it SHOULD be possible to get an Element Data
   instance by supplying an element instance.
   For example:

   ```c#
   IDeviceData deviceData = flowData.GetFromElement(deviceDetectionEngine);
   ```
4. In strongly typed languages it MAY be useful to get the type of
   Element Data associated with a Flow Element, without getting an associated
   instance. For example:

   ```c#
   Type deviceDataType = getDataTypeFromElement(deviceDetectionEngine);
   ```

Below are the mechanisms for getting Properties:

1. It MUST be possible to get a Property value from an Element Data instance by
   supplying the string key for that Property. For example:

   ```c#
   object propertyValue = deviceData.Get("ismobile");
   ```
2. It SHOULD be possible to get a Property value from an Element Data instance
   by using standard Property accessors for the language. For example:

   ```c#
   IAspectPropertyValue<bool> propertyValue = deviceData.IsMobile;
   ```

