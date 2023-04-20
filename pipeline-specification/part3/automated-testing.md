# Automated Testing

## Types of tests
The reference implementations contain a considerable number of tests both
to support functional testing and regression testing. 

The tests provided are almost all [unit tests](https://en.wikipedia.org/wiki/Unit_testing), though some unit tests
also serve as [integration tests](https://en.wikipedia.org/wiki/Integration_testing) - 
for example, requiring access to live cloud server instances to pass - however
they are not distinguished as such in continuous integration[^CI]. Note that
some tests are perhaps incorrectly named as integration tests.

[^CI]: For example, integration testing is often carried out on a push
to a particular branch of a repo, which provides access to test servers etc.
rather than being carried out locally on a developer's local machine.

## Performance Tests

Some level of performance regression testing is carried out in certain areas. 
This is, of necessity, a gross test, since unit tests are carried out in a 
wide range of environments during CI and automated build and distribution.

Performance benchmarking is not carried out as part of automated testing. Hence, 
external test tools, such as JMeter, are not used as part of automated testing.

## Test Frameworks

The reference implementations make use of standard test frameworks. Java uses
JUnit4 and JUnit5 and C# uses Visual Studio Test Tools.

## Test Tools

Mocking frameworks, in particular Mockito, are used quite extensively. It is
a matter of debate as to what extent is appropriate for such tools. On the
one hand they make creating stub implementations approachable, especially where
injection of test dependencies is not possible. On the other hand, it would
often be better to consider the need for injection of test dependencies in the
design of the classes under test.

It is somewhat inconsistent to provide interfaces and default 
implementations of those interfaces without considering test implementations
of those interfaces, and use of those test implementations, rather than
using a mocking tool on the default implementation.

Note that in particular mocking a logger can't be considered
good practice since the logging frameworks concerned provide no-op loggers
for such purposes.

Use of mocking tools can have unwanted side effects in terms of performance
and in terms of making it quite difficult to determine causes of test failures
when they result from incorrect specification of the mocked object. Debugging 
mocks can be a lot harder than debugging test implementations.

## Test Cases

This section itemises key required tests, by module of the reference 
implementation they are found in.

Numerous additional tests exist in the reference implementations and the code
of those implementation should be consulted.

### Core

TypedKeyMap :
- (ThreadSafe and non-ThreadSafe) test each of the methods.

Pipeline: 
**not all of these in Java** ++
**existing implementation mock elements**
- Test for correct processing of FlowData with one, two and three Flow Elements.
- Test of correct operation of parallel flow.
- Test that FlowData.stop() works correctly
- Test that throwing exceptions while processing terminates processing, or doesn't
depending on configuration. Test that flow data contains correct errors at end.

FlowData:

**pipeline is mocked**

- check that flowdata is processed once and only once on call of process
- check that attempt to process twice fails
- check that adding evidence as a value and as a map works
- check that adding data works
- check that getting typed data works
- ...

Java Only: 

Lookup: The Java reference implementation allows interpolation of values
(environment variables etc.) in pipeline options files. Test for correct 
operation of the various items that can be interpolated.


