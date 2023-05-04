# Evidence

## Overview

Evidence is the name for the input values added to a Flow Data instance.

It is stored as key-value pairs and is used by Flow Elements within the
Pipeline and is immutable once created.
Keys MUST be case-insensitive and will usually be split into \<prefix\>.\<field\>.

Currently, defined examples of keys are:

- `header.user-agent`
- `header.[header-name]`
- `cookie.[cookie-name]`\*
- `server.client-ip`
- `server.host-ip`

Any new Evidence keys can be defined in a similar manner.

\* Note that the 'cookie' prefix is a bit of a special case as cookies are supplied
to the web server using an HTTP header. Generally, 51Degrees Engines will not make
use of `header.cookie`. Cookie values will usually need to be under `cookie.` keys in order to be
used.

The prefix indicates where the value has come from. Currently, defined prefixes are:

- `query` – Used for Evidence specifically set by the application, or values supplied
  in a query string or the body of a post request. The suffix is the parameter name.
- `header` – Evidence came from an HTTP header. The suffix is the header name.
- `cookie` – Evidence came from a cookie. The suffix is the cookie name.
- `server` – Evidence came from a server that received a request but did not fit into
  any other category. For example, the IP address of the server.
- `fiftyone` – used internally by 51Degrees.
- `location` – Used in some cases to supply geo-location information.

The prefixes above are in order from highest to lowest precedence. I.e. if the same
Evidence value is available with two different prefixes (For example,
`header.user-agent` and `query.user-agent`), then the entry whose prefix is earlier
in the list above MUST be used.

If any other prefixes are present then their order of precedence is alphabetical.
This rule just ensures that any conflicts are resolved deterministically.
For example the [Cloud Request Engine](../pipeline-elements/cloud-request-engine.md#processing)

## Adding Evidence values

Evidence is immutable. However, it might be desireable for some Flow Elements
to add new values to Evidence for later elements to use.

In order to allow for something similar this usage scenario, we suggest creating a helper function
that will pull a value from an existing Element Data if available, or
fallback to pulling it from Evidence if needed.

For example, if Device Detection Engine requests `query.sec-ch-ua-platform`
from this function, it would return a Property value from any Element Data
with that Property name.
It there were no such Property, if would return the value from Evidence entry
that matched that name.
If multiple Element Data instances include Properties with this name,
an exception/error can be thrown.

This function MAY be defined on Flow Data itself, as a separate helper, or
both. That is an implementation detail that will depend on the language and
design patterns being used.
