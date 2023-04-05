# General guidance

- Where string keys are used, the following rules apply:
  - strings can only contain alphanumeric characters, full stop or hyphen.
    - Some 51Degrees properties also use the ‘/’ character. No new properties will 
      be added with this character, but it must be accommodated. 
  - lower-case is preferred but not required.
  - string comparisons must be case insensitive.

# Accessing results

There are multiple ways to access the results of processing.

Firstly, these are the mechanisms for getting element data:

1. It must be possible to get an element's output data by supplying the string key 
   for that element. For example:
   ```c#
   IElementData deviceData = flowData.Get("device");
   ```
2. In strongly typed languages, it should be possible to get an element's output 
   data by supplying the type of the data you want to get. For example:
   ```c#
   IDeviceData deviceData = flowData.Get<IDeviceData>();
   ```   
3. In strongly typed languages, it should be possible to get an element's output 
   data by supplying the element that you want to get the output data for. 
   For example:
   ```c#
   IDeviceData deviceData = flowData.GetFromElement(deviceDetectionEngine);
   ```   

Below are the mechanisms for getting properties:

1. It must be possible to get a property value from an element's data by 
   supplying the string key for that property. For example:
   ```c#
   object propertyValue = deviceData.Get("ismobile");
   ```
2. It should be possible to get a property value from an element's data
   by using standard property accessors for the language. For example:
   ```c#
   IAspectPropertyValue<bool> propertyValue = deviceData.IsMobile;
   ```
3. get property directly from flow data by string (Remove from spec? It's not demonstrated, 
   doesn't work if there are properties with the same name, isn't type-safe and isn't used 
   internally.)

