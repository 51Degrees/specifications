# Required Examples

It is difficult to demonstrate usage of the Pipeline API without a
concrete use-case. Consequently, the reference implementations do
not have many examples in the core repository.

The examples that MUST be implemented in the core are all
demonstrations of how to create Flow Elements. These all determine
star sign from a birth date, and do so in a number of different ways:

- Simple Element with hard-coded logic.
- Replace part of the hard-coded logic with an external data source,
  creating an On-Premise Engine.
- Modify the simple Element to get its input data from client-side
  JavaScript.
- Replace the hard-coded logic with a call to a remote service,
  creating a Cloud Engine.

Reference implementations also contain the following examples:

- Create a Pipeline that [shares usage](features/usage-sharing.md) with
  51Degrees. Configured from options file.
- Demonstrate usage of a [cache](features/caching.md) with an Engine.
- Compute a property from properties other Elements have already
  produced, using the
  [Derived Property Element](pipeline-elements/derived-property-element.md).

## Derived Property Element example

Every reference implementation MUST provide one example for the
[Derived Property Element](pipeline-elements/derived-property-element.md).
It MUST NOT need a resource key, a data file or a network connection, so
that it runs anywhere, and it MUST NOT depend on the content of the
shared script repository, because a test in a language repository that
read a script from that repository would break whenever a script changed.

The example MUST show all four of the following. The order is left to
each language, so that the example can follow whatever reads most
naturally there:

1. A script held in the example itself and passed to the builder as text,
   producing a value from source Properties an Element in the example
   supplies.
2. A script read from a file beside the example.
3. The same Pipeline built from a configuration file rather than from
   code, naming the builder and passing the script through build
   parameters.
4. What the caller sees when a source Property named by the script is
   not available on the request, which is a Property with no value and a
   message naming what was missing. This case MUST be shown rather than
   only described, because it is the behaviour customers most often meet
   first and the one the two valued model exists to make plain.

Where a language's package embeds scripts from the shared repository, the
example MAY also show a built in script being selected by name, but MUST
keep that part working when no script is embedded, so that the example
still runs on a checkout without the shared repository present.

The .NET reference implementation of this example is
`Examples/DerivedProperty` in
[pipeline-dotnet](https://github.com/51Degrees/pipeline-dotnet).
