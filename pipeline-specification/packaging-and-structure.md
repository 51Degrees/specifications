# Packaging and Structure

Some general guidance as to how to structure an implementation based on 
51Degrees experience.

## Modularity

Using language-provided modularity features to provide separation
of concerns and to provide for applications being able selectively to
use features  without having to import unused features.

Excessive modularity, of course, makes the libraries hard to use.

Use of transitive dependencies can be very helpful and allow definition
of a single library aggregation. Most of the dependencies in pipeline
are required for most use cases. However, if it is of concern that various
features are not included then facilities such as Maven's optional dependency can 
be used.

## Reference Modularity

51Degrees pipeline reference implementations are developed in a single repository
allowing for a single build cycle. Specific features, such as Device Detection,
use separate repos.

Pipeline itself is modularized as follows:

- **Common** base utilities potentially of wider application than Pipeline
- **Core** features essential to Pipeline, Flow Data, Flow Elements etc.
- **Engines** base classes providing features that are beyond what is provided in Flow Elements
- **Web** Adaptors and features to assist with use of Pipeline in a Web environment
- **51Engines** features specific to 51Degrees and 51Degrees Engines:
  - **ShareUsage**
  - **SetHeaders**
  - **Sequence**
- **Engine Implementations** Separate Modules for each of the following:
    - **JSON**
    - **JavaScript**
    - **CloudRequest**

This diagram illustrates the structure of .NET NuGet packages:

![Illustration of package structure](images/v4%20Packages.png)

## Cross-language modularity

We use Git for our repository management and this allows us to share certain
items, such as test data, between languages using Git [submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules).

## Versioning

We distribute pipeline with a single version number for all modules/artifacts.
In principle, using an aggregator module would allow both simple update
and multiple distinct module versions, but we have considered that there
are insufficient advantages to this approach.

## Examples

We do not distribute examples as compiled artifacts. 

There would be advantages to distributing examples using a separate repository 
to the code they exemplify in order to
ensure that distributed library artifacts are used. However, this would make 
regression testing of the examples more complicated during the release cycle.

For more details, see [required examples](required-examples.md).

## Tests

Automated tests and expected to be present in the same repository as the
API code and will be run as part of CI/CD workflows.
For more details, see [automated testing](automated-testing.md).

### Test Data

We recommend that for convenience, test data of some kind is distributed with 
library code and examples. We also recommend that alternative means of updating
test data are provided.

