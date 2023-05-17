# C# and Java implementation architecture notes

This section discusses architectural aspects of the reference implementations
(written in C# and Java) which were designed with extensibility in mind and
to provide the basis for possible re-use in the creation of Flow Elements and
Engines.

While much of the original design of this API has stood the test of time,
there are some areas that are consistent sources of difficulty in terms
of documentation, maintenance or user understanding. These areas are highlighted
below in order to allow future implementors to see where it may be most
beneficial to consider other approaches.

It is not the intention to constrain or limit implementations to follow
the patterns listed here, indeed, in some languages such patterns are not
idiomatic or are hard to achieve. In other cases experience says that the
desirability of doing so might be in question.
However, taking advantage of the existing design could be expedient, or desirable.

## Interfaces, base classes, inheritance

The reference implementations follow a "classic" Object-Oriented approach of defining
interfaces, implementing abstract base classes and creating default
implementations for the majority of features of the system.

In some cases, specialization is used to provide quite deep hierarchies of
classes, for example Flow Element -> Aspect Engine -> Cloud Aspect Engine ->
Device Detection Cloud Engine. This approach was chosen to most easily allow
common logic to be shared between classes. It provides for numerous
extensibility points but means that for any resulting Engine, it can be quite
difficult to find out at what level of the inheritance hierarchy a desired
inherited feature is implemented.

An approach using well known design patterns such as the
[strategy](https://en.wikipedia.org/wiki/Strategy_pattern) and/or
[decorator](https://en.wikipedia.org/wiki/Decorator_pattern) patterns could
allow the code sharing benefits to be preserved while avoiding the downsides
of multi-level inheritance hierarchies.

## Parameterized types

Generics are used throughout the reference implementations and serve, for
example, to bind functionality to data structures and metadata using
[Curiously Recurring Template Pattern](https://en.wikipedia.org/wiki/Curiously_recurring_template_pattern).
This pattern is used effectively
but the limited number of top level classes makes it harder to find what
data structure is being used at what level of the parameterized class.

## Dependency injection and inversion of control

Dependency injection and IoC are used throughout. Notably, the concept
of shared services allows the injection of caches, data update and other
services. This allows easy mocking/stubbing for test scenarios.

However, greater use of dependency injection along with the application of other
design patterns would allow the simplification of class hierarchies. As well as
potentially preventing some extremely close coupling between core classes that
can add considerable complexity to test setup.

## Builders

Builders are an intrinsic part of the current reference architecture and,
like the classes they build, are extensively subclassed and parameterized. There
are builders for many significant components and for all Engines (and most of their
supertypes). As with the Element/Engine classes mentioned previously, this was done
primarily to allow easy sharing of logic.  

Considerable simplification would theoretically be possible between the builders and
their target classes in the area of Property getters and setters, as well as
the target class constructors, of which there are usually several.

It's not always easy to establish the default value of a configuration item that
can be set in a builder, since it might be set in the target class, a superclass
of that target class, the builder or a superclass of the builder.

In the case of device detection, some defaults are specified in the native C/C++
code, but this is unavoidable.

In all cases, there SHOULD be some mechanism to specify the default values
alongside configuration property setters. For example in C# a custom attribute
is added to setters. Where the default value cannot be provided (for example,
it is configured in native code) a link to the location in the native source
file is provided instead.

For future implementations, it is RECOMMENDED that these builders are redesigned
to flatten the class hierarchy and simplify constructors. A standard approach to
default values SHOULD also be defined up front. Ideally, the simplified design
would also mean fewer places where defaults could be set.

### The pre-packaged Pipeline builder

A Pipeline is usually constructed using a fluent builder which accepts Flow Elements
being added to it in flow order. Those Flow Elements are usually created using
fluent builders of their own, which can in turn accept features, such as a cache,
constructed using a builder of its own.

A special builder is provided to simplify the creation of commonly used Pipelines
for on-premise or cloud Device Detection. This hides the complexity
of Pipeline creation by automatically inserting elements, and choosing
default values, but the price for that simplification is considerable. There is
more code to maintain, more creation scenarios, which require explanation in
documentation and examples. The special Pipeline builder is also difficult or
impossible to use with web integrations and cannot be used when building from a
configuration file. Finally, if the user is using this builder and decides they
need some capability that is beyond its scope, they have to migrate to the
'standard' Pipeline builder.

On the whole, we prefer solutions that will reduce complexity for users, such as
this special builder. However, if this is implemented, care will need to be taken
to avoid the issues described above.
