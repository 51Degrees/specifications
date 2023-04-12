# Overview

Evidence is the name for the input values added to a **Flow Data** instance.

It is stored as key-value pairs and is used by **Flow Elements** within the 
**Pipeline** and is immutable once created. 
Keys should be case-insensitive and will usually be split into \<prefix\>.\<field\>.

Currently, defined examples of keys are:

- `header.user-agent`
- `header.[header-name]`
- `cookie.[cookie-name]`
- `server.client-ip`
- `server.host-ip`

Any new evidence should be defined in a similar manner.

The prefix indicates where the value has come from. Currently, defined prefixes are:

- `query` – Used for evidence specifically set by the application, or values supplied 
  in a query string or the body of a post request. The suffix is the parameter name.
- `header` – evidence came from an HTTP header. The suffix is the header name.
- `cookie` – evidence came from a cookie. The suffix is the cookie name.
- `server` – evidence came from a server that received a request but did not fit into 
  any other category. For example, the IP address of the server.
- `fiftyone` – used internally by 51Degrees.
- `location` – Used in some cases to supply geolocation information.

The prefixes above are in order from highest to lowest precedence. I.e. if the same 
evidence value is available with two different prefixes (For example, 
`header.user-agent` and `query.user-agent`), then the entry whose prefix is earlier 
in the list above should be used.

# Adding evidence values

Evidence is immutable. However, it may be desireable for some **Flow Elements** 
to add new values to evidence for later elements to use.

In order to allow for this scenario, we suggest creating a helper function
that will pull a value from an existing **Element Data** if available, or 
fallback to pulling it from evidence if needed.

For example, if device detection requests `query.sec-ch-ua-platform` from this
function, it would return a property value from any **Element Data** with
that property name.
It there were no such property, if would return the value from evidence entry 
that matched that name.
If multiple **Element Data** instances include properties with this name, 
an exception/error should be thrown.