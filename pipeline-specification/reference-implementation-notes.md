# Reference Implementation Architecture Notes

This section discusses architectural aspects of the reference implementations
(C# and Java) which were implemented with extensibility in mind and to provide the basis 
for possible re-use in the creation of Flow Elements and Engines.

It is not the intention to constrain or limit implementations to follow 
the patterns listed here, indeed, in some languages such patterns are not
idiomatic or are hard to achieve. In other cases experience says that the 
desirability of doing so may be in question. 
However, taking advantage of the existing design may be expedient, or desirable.

## Interfaces, Base Classes, Inheritance

The reference implementations follow "classic" OO approach of defining 
interfaces, implementing abstract base classes and creating default
implementations for the majority of features of the system.

Frequently, the default implementation is the only implementation, so the 
strict separation of concerns represented by this approach doesn't result
in a useful ability to specialize. In addition, both Java and C# now provide 
for default interface methods which provide for a simpler but no less 
extensible base.

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
hierarchies. As well as simplifying test configuration and the like.

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

This could be resolved by simplifying the constructors and defining a standard  
approach to default values. 

A pipeline is usually constructed using a fluent builder which accepts flow elements
being added to it in flow order. Those flow elements are usually created using
fluent builders of their own, which may in turn accept features, such as a cache,
constructed using a builder of its own.

A special builder is provided to simplify the creation of commonly used pipelines
such as on-premise or cloud device detection. These hide the complexity
of pipeline creation by automatically inserting elements, and choosing 
default values, but the price for that simplification is considerable. There is 
more code to maintain, more creation scenarios, which require explanation in
documentation and examples. The custom pipeline builder is also difficult or 
impossible to use with web integrations and cannot be used when building from a
configuration file. Finally, if the user is using this builder and decides they 
need some capability that is beyond its scope, they have to migrate to the 
'standard' pipeline builder.

On the whole, we prefer solutions that will reduce complexity for users. However,
care should be taken to try to avoid some of the issues described above.
