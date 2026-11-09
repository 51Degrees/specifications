# File system paths

Where file system paths are supplied as parameters, the Pipeline API MUST
be able to work with relative paths. A relative path is resolved against the
working directory of the process.

ASP.NET uses a tilde (~) to
[signify](https://www.cryer.co.uk/brian/csharp/tilde_virtual_paths_in_asp_net.htm)
the application root.

Therefore, in .NET web applications, it SHOULD be possible for users to
supply paths using this tilde notation for things such as Engine data file
locations.

Every other language takes a path as given, with no tilde expansion.
