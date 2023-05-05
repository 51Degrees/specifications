# Automated Testing

Device Detection automated testing follows the guidelines set out
in [Pipeline Automated Testing](../../pipeline-specification/part3/automated-testing.md)
and the general comments made there are not usually repeated here.

## Device Detection Cloud Engine

Testing of several
parts of the operation of the Cloud Engine might require access to a
remote server and hence the tests can appear more as integration tests
than unit tests.

The Java reference implementation doesn't provide a stub server and doesn't
approach testing by processing of canonical JSON examples, so does require
a remote server. Some parts of testing are carried out using mocks.

- Test for correct return of values with known Resource Key
- Test for correct operation when Resource Key doesn't contain correct Properties
- Test for correct operation on transient network failure

General tests

- Test for correct operation when data is not available in this tier
- Test for availability of typed getters for Properties
- Test for correct operation of Evidence keys

## Device Detection On-premise Engine

Carry out similar tests to Cloud Engine, in addition

- Test for correct operation of SWIG
- Test for correct operation of performance configuration
- Test for correct operation of data tier

## Examples

Testing of examples is strongly RECOMMENDED, at least to assess whether they
compile and can be run. It's usually not practical to assess the correctness
of any output from tests of examples.
