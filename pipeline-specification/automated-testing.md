# Automated Testing

## Types of tests

The reference implementations contain a considerable number of tests for
both functional testing and regression testing.

The tests provided are almost all [unit tests](https://en.wikipedia.org/wiki/Unit_testing),
though some unit tests also serve as
[integration tests](https://en.wikipedia.org/wiki/Integration_testing) -
for example, requiring access to live cloud server instances to pass - however
they are not distinguished as such in continuous integration. Note that
some tests are perhaps incorrectly named as integration tests.

## Performance Tests

Some level of performance regression testing is carried out in certain areas.
This is, of necessity, a gross test, since unit tests are carried out in a
wide range of environments during CI and automated build and distribution.

Performance benchmarking is not carried out as part of automated testing. Hence,
external test tools, such as JMeter, are not used as part of automated testing.

## Test Frameworks

The reference implementations make use of standard test frameworks. Java uses
JUnit4 and JUnit5 while C# uses MSTest.

## Test Tools

Mocking frameworks, Mockito in Java and Moq in C#, are used quite extensively. It is
a matter of debate as to what extent is appropriate for such tools. On the
one hand they make creating stub implementations approachable, especially where
injection of test dependencies is not possible. On the other hand, it would
often be better to consider the need for injection of test dependencies in the
design of the classes under test.

It is somewhat inconsistent to provide interfaces and default
implementations of those interfaces without considering test implementations
of those interfaces, and use of those test implementations, rather than
using a mocking tool on the default implementation.

Note in particular that mocking a logger can't be considered
good practice since the logging frameworks concerned provide no-op loggers
for such purposes.

Use of mocking tools can have unwanted side effects in terms of performance
and in terms of making it quite difficult to determine causes of test failures
when they result from incorrect specification of the mocked object. Debugging
mocks can be a lot harder than debugging test implementations. Therefore it
is essential that implementors are very familiar with mocking or any other test
tool that is used when creating the tests.

Code coverage is another testing tool that may be helpful in seeing which
areas of logic require tests to be added. However, it is not recommended that
code coverage is used as a metric. This is because, even with 100% coverage,
there are many scenarios that might not be tested. Thus, the focus should be on
ensuring different usage scenarios are tested, rather than ensuring a certain
percentage of the code is covered by tests.

## Test Cases

This section itemizes key tests, by module of the reference
implementation they are found in.

In all cases all methods of all classes SHOULD be tested for correct operation
when valid data is supplied, and correct exceptional operation is taken for
incorrect data. The cases listed here are mostly concerned with testing that
underlying functionality is correctly implemented where internal state of
the object can vary. For example a Flow Data can only be processed once, so
there MUST be a test to check that an attempt to process it twice, fails.

Numerous additional tests exist (to a total of around 500, running to
thousands of lines of code) in the reference implementations and the code of
those implementations can be consulted for more details.

### FiftyOne.Pipeline.Core

TypedKeyMap :

- (ThreadSafe and non-ThreadSafe) test each of the methods.

Pipeline:

- test for correct processing of Flow Data with one, two and three Flow Elements.
- test of correct operation of parallel flow.
- test that throwing exceptions while processing does not prevent later Flow
  Elements from running and either throws an exception at the end or not (based
  on configuration)
- test that Flow Data contains correct errors at end.

PipelineBuilder and PipelineOptions:

- check exceptional operation such as adding a closed Flow Element
- check build from options
- check Build from serialized options with abbreviated names
  - check for serialized options containing wrong option and values
  - check for constructor values
- check build from fluent builder

Flow Data:

- check that Flow Data is processed exactly once on call of process
- check that attempt to process twice fails
- check that access to Flow Data when Pipeline closed fails
- check that access to Flow Data results before processing fails

Flow Element:

Create a Test Element and associated data

- check correct process() logic
- check for correct creation of associated data type
- check for correct access following processing

Java Only:

Lookup: The Java reference implementation allows interpolation of values
(environment variables etc.) in Pipeline options files. Test for correct
operation of the various items that can be interpolated.

### FiftyOne.Pipeline.Engines

Pipeline Overhead:

Create a test Pipeline and check that the processing cost is within
reasonable bound for the cases:

- repeated execution of Pipeline
- repeated execution of Pipeline with caching enabled on Engine
- repeated execution of Pipeline with parallel Flow Data (This is an
  advanced feature, so may not be implemented)

AspectEngine:

- check Aspect Engine uses cache correctly
- if lazy loading is implemented, check that it fires only at the right
  time and only once

DataUpdateService:

DataUpdate is a complex process with many options.

- check that the options cannot be set inconsistently
- check that the callbacks are fired on update completion successfully
- check that Engine refresh is triggered on file update if configured
- check that programmatic update works correctly and resets remote update properly
- check that remote update triggers correctly and resets correctly in the event
  of both successful and unsuccessful download, with various failure scenarios
  such as HTTP timeout, HTTP 429, 400, MD5 check failure etc.
- check that Engine refreshes with correct data and that any data associated
  with earlier copy is freed correctly
- carry out a repeated refresh test to look for memory leaks

MissingPropertyService:

- check that "upgrade needed" is returned for a Property that is available in a different tier
- check that "unknown" is return for a Property that is not known
- check that "not in resource" is returned for Cloud Engine
- check unknown returned otherwise

### FiftyOne.Pipeline.Engines.Fiftyone

ShareUsage:

- check that ShareUsage substitutes illegal XML characters correctly and truncates values
- check that ShareUsage operates correctly, retrying failed data etc.
- check that adding more data stops when queue is full and resumes when it is no longer so
- check that all data in the queue is sent
- check minimum batch size and maximum batch size
- check operation of tracker (i.e. not sending duplicated data)
- check operation of filtering of headers
- check operation of SessionID
- check operation on shut down
- check that ShareUsage does not impose an undue burden on performance

SetHeaders

- check that headers are set correctly, where multiple attempts to set
  same header, for example

### JSONBuilder

- check that the output is valid JSON
- check that the maximum iterations is observed
- check that disallowed elements are not put in the output
- check that the serialization is correct

### JavaScriptBuilder

- check for normal, empty, invalid and delayed execution Properties

### Web

Tests in this area will vary by the Web support features of the language and platform.

Some Aspects of these tests look rather like integration tests and ideally will
require a [headless browser](https://en.wikipedia.org/wiki/Headless_browser) for execution.

Things to check:

- operation of the SetHeaders Engine
- operation of the JSON and JavaScript Engines
  - operation of the JavaScript that is produced  
- operation of the Sequence Element
