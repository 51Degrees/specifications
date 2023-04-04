
# Core 

The core package contains everything needed to construct a Pipeline and pass through a Flow Data object.

## Flow data

The **Flow Data** object is primarily a container for various data sets. It is the mechanism by which inputs are provided to the pipeline and outputs are returned to the user.

**Flow Data** must be capable of being thread safe. In other words, it must handle being accessed and updated by multiple threads simultaneously. However, non-thread aware data structures are preferred when possible for performance reasons. The **Pipeline** can decide at creation time if a concurrent structure is required or not.

**Flow Data** objects are created by the pipeline and can only be used within the pipeline they were created by. The Process method on **Flow Data** will use the pipeline that created the **Flow Data** to process it.

**Flow Data** consists of four main elements:

-   Errors – A collection of errors. This defaults to null and will be populated with error data by a **Flow Element** if an error occurs within it. Note that this collection must be thread safe.
-   Evidence – A data set containing the input data that is passed to the pipeline for processing.
-   Cancellation token – Where possible, this should use the cancellation functionality provided by the implementing language. Any element, or the caller of the Pipeline API, can use this to prevent any further elements from doing any processing. If the token is set, subsequent **Flow Elements** must not process and any active long running processes should be cancelled as soon as possible.
-   Data – One or more data sets, stored in a dictionary, each of which contains data about a given aspect. Each data set implements the **Element Data** interface and is stored using the data key from the **Flow Element** that created it.

Example of the values that could be stored in the ‘Data’ structure:

| **Key**  | **Value**           |
|----------|---------------------|
| device   | **DeviceData**      |
| location | **GeoLocationData** |

Note that all of the entries in the value column must implement the **Element Data** interface.

### Errors

The errors collection should be null unless any errors occurred within any of the **Flow Elements** during processing. When an error occurs, it should be added to the errors list along with the **Flow Element** that it occurred in (if known).

### Cancellation Token

The cancellation token is a way for a **Flow Element**, or the external caller, to cancel any long-running processing and stop any further elements from acting on the **Flow Data**. When a **Flow Element’s** process method is passed a **Flow Data** with the cancellation token set, it should do nothing.

### Evidence

Evidence is data stored with a dictionary-style interface which is used as an input by **Flow Elements** within the **Pipeline**. The keys are added using the case in which they are expected by the **Flow Element**, and can be split into \<prefix\>.\<field\>. If a **Flow Element** wants to receive a piece of evidence, regardless of the case in the key, it can use a case insensitive comparator in its required keys. Currently defined examples of keys are:

-   header.user-agent
-   header.[header-name]
-   cookie.[cookie-name]
-   server.client-ip
-   server.host-ip

Any new evidence should be defined in a similar manner.

The prefix indicates where the request has come from. Currently defined prefixes are:

-   query – Used for evidence specifically set by the application, or values supplied in a query string or the body of a post request. The suffix is the parameter name.
-   header – evidence came from an HTTP header. The suffix is the header name.
-   cookie – evidence came from a cookie. The suffix is the cookie name.
-   server – evidence came from a server that received a request but did not fit into any other category. For example, the IP address of the server.
-   fiftyone – used internally by 51Degrees.
-   location – Used in some cases to supply geolocation information.

The prefixes above are in order from highest to lowest precedence. I.e. if the same evidence value is available with two different prefixes (For example, `header.user-agent` and `query.user-agent`), then the entry with the higher prefix in the list above will be used.

The evidence collection does not need to be thread safe as it may be read concurrently but should never be written to concurrently.

### Data

Each **Element Data** in the **Flow Data** will have an associated string name, usually relating to a specific aspect of the request. (e.g. ‘device’ or ‘location’). These strings must always be lower case.

These **ElementData** instance should be accessible by this string name or some proxy object that contains the name. For example, the flow element that created it.

I.e. these are equivalent:

```
flowData.get(“device”);
flowData.getFromElement(deviceDetectionEngine);
```

In strongly typed languages, returning the **Element Data** as the correct type is preferred. This will probably require the use of generics. Note that in the first line above, this would not be possible, as the returned object would have to be an implementation of the **Element Data** interface rather than the underlying concrete type.

## Element data

**Element Data** is a container for properties. The **Element Data** instance must expose the data that it holds through an accessor requiring a string key. These keys may be stored in whichever case the **Flow Element** deems suitable, however lower case is the preferred format. When a value is requested using a key, a case insensitive comparator should be used. (Meaning that data[“Value”] and data[“value”] would return the same value). Keys may only contain alphanumeric characters, full stop or hyphen.

Note that 51Degrees contains some properties that also use the ‘/’ character. No new properties will be added with this character, but it must be accommodated.

The returned value will be an object (or equivalent root type for the end user’s programming language). As such, property values may be any simple or complex type.

This string-keyed accessor should be used internally and must be exposed to the user. However, it should not be the primary user-facing mechanism for accessing properties. Element specific implementations should be created to provide strongly typed property accessors. For example, [Device Detection Aspect Data](/device-detection-specification/data-model.md)

This functionality is demonstrated with pseudo-code below, showing two ways of accessing the same property:

```
flowData.getFromElement(deviceDetectionEngine).get(“ismobile”);
flowData.getFromElement(deviceDetectionEngine).isMobile;
```

The second line is clearly the preferable one as type safety is maintained, no ‘magic strings’ are required, and the user will get autocomplete hints in the IDE.

**Element Data** instances will be created as needed by **Flow Elements**. They will then be stored within the **Flow Data** object under the appropriate key. Consequently, non-thread safe collections are sufficient and preferred, from a performance point of view.

## Flow element

A **Flow Element** is a black box which takes a **Flow Data** and performs some operation. This processing may read evidence and/or **Element Data** instances that have been added by previous elements. It may add new evidence values and must add an instance of its own element data, which may or may not have properties populated.

A **Flow Element** can be added to multiple pipelines once it has been built. This means that the processing performed by a flow element must be thread safe and must either have no state that is dependent on a pipeline, or must maintain this state internally for each pipeline it is added to.

By default, resources for **Flow Elements** must automatically be cleaned up by the **Pipeline** they are attached to when it closes. However, this behavior must be overridable in order to support the advanced scenario of adding **Flow Elements** to multiple **Pipelines**.

A **Flow Element** must implement the following:

1.  Process method which accepts a **Flow Data** object.
2.  EvidenceKeyFilter property which returns an **Evidence Key Filter** instance that can be used to identify the evidence keys that the **Flow Element** can make use of.
3.  DataKey property that determines the key for this element's **Element Data** within **Flow Data**. For example ‘device’ for the device detection engine.

## Flow element builder

It is highly recommended that **flow elements** have some associated builder/factory that is used to create **flow element** instances.

The exact specification of this component is less important than having a common mechanism for construction of elements. This provides consistency for users and will assist in the implementation of other parts of the specification.

In most languages, we have found the builder pattern to be the best approach.

## Pipeline

## Pipeline builder

# Engines

## Aspect data

## Aspect engine

## Aspect engine builder

# Cloud engines

## Cloud request engine

## Cloud aspect engine