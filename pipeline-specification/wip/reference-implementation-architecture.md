# Reference Implementation Architecture

This section discusses architectural aspects of the reference implementations
(C# and Java) which were implemented with extensibility in mind and to provide the basis 
for possible re-use in the creation of Flow Elements and Engines.

It is not the intention to constrain or limit implementations to follow 
the patterns listed here, indeed, in some languages such patterns are not
idiomatic or are hard to achieve. In other cases experience says that the 
desirability of doing so may be in question. 
However, taking advantage of existing base classes may be expedient, or desirable.

## Interfaces, Base Classes, Inheritance

The reference implementations follow "classic" OO approach of defining 
interfaces, implementing abstract base classes and creating default
implementations for the majority of features of the system.

Frequently, the default implementation is the only implementation, so the 
strict separation of concerns represented by this approach doesn't result
in a useful ability to specialize, and could be said to have been 
"premature generification". In addition, both Java and C# now provide for default 
interface methods which provide for a simpler but no less extensible base.

In other cases, specialization is used to provide quite deep hierarchies of 
classes, for example Flow Element -> Aspect Engine -> Cloud Aspect Engine -> 
Device Detection Cloud Engine. This provides for numerous extensibility points
but means that for any resulting Engine, it can be quite difficult to find 
out at what level of the inheritance hierarchy a desired inherited feature 
is implemented.

## Parameterized Types and CRTP

Generics are used throughout the reference implementations and serve, for 
example, to bind functionality to data structures and metadata. 
This pattern is used effectively
but the limited number of top level classes makes it harder to find what 
data structure is being used at what level of the parameterized class.

## Dependency Injection and Inversion of Control

Limited use is made of these techniques. Notably, the concept of shared services
does allow the injection of caches, data update and other services.

Greater use of dependency injection would allow the simplification of class 
hierarchies and would allow for the straightforward injection of test
implementations, rather than resorting to the complex use of mocking frameworks
for tests. 
[comment](Partially disagree with this. There are certainly places where 
greater use of dependency injection would improve separation of concerns and 
aid maintainability. 
However, on mocking specifically: Mocking is only possible *because* dependency 
injection is being used. Using concrete test implementations is simply an 
alternative to mocking. In .NET, both techniques are in different places based
on which one makes the most sense.)

## Builders

Builders are an intrinsic part of the current reference architecture and,
like the classes they build, are extensively subclassed and parameterized. There 
are builders for many significant components and for all engines (and each of their
supertypes).

Considerable simplification would theoretically be possible between the builders and 
their target classes in the area of property getters and setters, as well as 
the target class constructors, of which there are usually several.

It's not usually very easy to establish the default value of a configuration item that 
can be set in a builder, since it can be set in the target class, a superclass 
of that target class, the builder or a superclass of the builder.
[comment](This is very true. My strong preference is for all defaults to be assigned 
to the fields in the builder - .NET has some changes in develop to be more consistent 
in this area - There are some cases where the existing functionality requires that
the default be set elsewhere. I'm fairly sure this could have been avoided by being
stricter about defaults in the initial design though.)

A pipeline is usually constructed using a fluent builder which accepts flow elements
being added to it in flow order. Those flow elements are usually created using
fluent builders of their own, which may in turn accept features, such as a cache,
constructed using a builder of its own.

A special builder is provided to simplify the creation of commonly used pipelines
such as on-premise or cloud device detection. These hide the complexity
of pipeline creation by automatically inserting elements, and choosing 
default values, but the price for that simplification is to limit the 
flexibility of configuration.
[comment](I propose we remove this from the spec. The benefit seems almost non 
existent and the downsides are considerable - More code to maintain, more documentation, 
very difficult to use this with web integration, more complicated to migrate from 
this to more advanced scenarios)

## Options Files

As an alternative to the use of builders, Pipelines may be configured using 
XML (Java and C#) or JSON (C# Only) files containing the names and values
of items to configure in the engines they specify.

## Flow Data Concurrency and Property Values

In most cases Flow Data is used in a single threaded way. However, 
engine instances are used across threads and may be shared between pipelines, as
well as possibly participating in parallel flows,
so engines need to make sure that the data they add to Flow Data is thread safe.

They also need to have regard to sharing of results between different flow data 
instances and the possible retention of those results beyond the lifetime
of the flow data and the potential use of the data in caches.

*Not really sure if this is meaningful or actionable*