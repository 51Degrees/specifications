Evidence is the name for the input values added to a flow data instance.
It is stored as key-value pairs and is used by **Flow Elements** within the 
**Pipeline**. Keys should be case-insensitive and will usually be split into 
\<prefix\>.\<field\>.

Currently defined examples of keys are:

- header.user-agent
- header.[header-name]
- cookie.[cookie-name]
- server.client-ip
- server.host-ip

Any new evidence should be defined in a similar manner.

The prefix indicates where the value has come from. Currently defined prefixes are:

- query – Used for evidence specifically set by the application, or values supplied 
  in a query string or the body of a post request. The suffix is the parameter name.
- header – evidence came from an HTTP header. The suffix is the header name.
- cookie – evidence came from a cookie. The suffix is the cookie name.
- server – evidence came from a server that received a request but did not fit into 
  any other category. For example, the IP address of the server.
- fiftyone – used internally by 51Degrees.
- location – Used in some cases to supply geolocation information.

The prefixes above are in order from highest to lowest precedence. I.e. if the same 
evidence value is available with two different prefixes (For example, 
`header.user-agent` and `query.user-agent`), then the entry with the higher prefix 
in the list above should be used.

The evidence collection does not need to be thread safe as it may be read 
concurrently but should never be written to concurrently.
