# File system paths

Where file system paths are supplied as parameters, the Pipeline API MUST
be able to work with relative paths in any form that the user might
reasonably expect to be able to use.

For example, ASP.NET Framework uses a tilde (~) to
[signify](https://www.cryer.co.uk/brian/csharp/tilde_virtual_paths_in_asp_net.htm)
the current application's virtual directory.

Therefore, it SHOULD be possible for users to supply paths using this
tilde notation for things such as Engine data file locations.
