# Usage sharing

Users of the Pipeline API have the option to share data about their
usage of the system.

This process is very important to engine providers and users as it is
used to help improve the accuracy of products.

For example, the 51Degrees Device Detection product relies on usage data
from customers to give a good view of what user-agents, client-hints, etc
are active in the real world. This is a constantly evolving picture, so
good quality data is essential.

Data is shared in XML format, with multiple process requests aggregated
to produce each payload.

Shared data includes details such as:

- Evidence values
- Pipeline configuration.
- OS, programming language and API versions.

For more technical details, see the
[share usage element](../pipeline-elements/usage-sharing-element.md).
