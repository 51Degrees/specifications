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
