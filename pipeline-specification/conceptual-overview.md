
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

## Flow element

## Flow element builder

## Pipeline

## Pipeline builder

# Engines

## Aspect data

## Aspect engine

## Aspect engine builder

# Cloud engines

## Cloud request engine

## Cloud aspect engine