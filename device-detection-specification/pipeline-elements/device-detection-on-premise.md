
# Native component

# Builder

## Sample configuration

# Engine

# Meta-data

## Overview

On-premise device detection has two related meta-data structures:
1. The device detection data file includes meta-data relating to the structure of the values that are stored in the file. This is exposed by the device detection engine in order to allow users to query the data. \*
2. All flow elements expose a list of meta-data relating to properties populated by that element. In the case of the device detection engine, this list will include property meta-data derived from the data file meta-data mentioned above. 

\* Note that, due to the structure of the data, this is not intended to support high-performance querying scenarios. For that use-case, customers are directed to our 'csv' data file, which can be consumed and stored in a database or whatever other form is required for querying. 

```mermaid
erDiagram
    Component ||--|{ Property : has
    Property ||--|{ Value : has possible
    Component ||--|{ Profile : has
    Profile ||--|{ Value : has
```

## Component

A **component** defines a group of **properties** that are related.

In a 51Degrees data set, each **property** can only be related to one **component**. For example, the `Browser Name`
**property** is part of the `Software` **component**, whereas the `Model Name` **property** is part of
the `Hardware` **component**.

The metadata associated with a **component** is:

| Metadata | Description |
| -------- | ----------- |
| Id       | The unique id of the **component**. This is a number and will remain the same when a data file is updated. |
| Name     | The name of the **component** that gives a more 'human' identifier than id. By convention, this is unique within the data file. |
| Default profile| The default **profile** for the **component**. This is used to provide **values** for the **component's** **properties** when a **profile** matching the @evidence cannot be found. |
| Properties| The **properties** associated with this **component**. |

## Property

The **properties** exposed by the device detection engine contain more information than that which is defined by the standard **property meta data** interface.
In addition to the usual information, the following must be made available:

| Metadata | Description |
| -------- | ----------- |
| Description| A description of the **property** explaining what it refers to, and what significance its values have. |
| URL      | A URL where more information on the **property** can be found. |
| Component| The **component** to which the **property** belongs. This is subtly different from the category, in that a **profile** defines the values for all the **properties** of a single **component**, which likely contains multiple categories of **properties**. |
| Values   | The **values** that the **property** can have. As a simple example, a **property** named ``'IsSmartPhone'`` might have three values: ``true``, ``false``, and ``unknown``.|
| Default Value| The default **value** for the **property** if it is not otherwise known. In the above example, the **property** named ``'IsSmartPhone'`` would probably have ``unknown`` as the default value. |
| List     | Whether or not the **property** may have multiple values. For example, the connectivity types a device supports would be a list, as a single device might support Bluetooth, HSDPA, LTE, Wi-Fi, etc. |
| Obsolete | Whether the **property** is obsolete and only exists to maintain backward compatibility. |
| Display Order| The suggested order in which to display the **property** when listing **properties**. |
| Mandatory| Whether the **property** is mandatory or not. If a **property** is mandatory, a **profile** must have a non-default value for it to be classed as valid. |
| Show     | Whether the **property** should be displayed in situations such as a page listing **properties**. Less important **properties** may not be displayed. |
| Show Values| Whether values of the **property** should be displayed in situations such as a page listing the **property's** values. Showing all the values can make a very long list. |

## Profile

A **profile** defines a unique set of **values** for all **properties** of a single **component**. 

| Metadata | Description |
| -------- | ----------- |
| Id       | The unique id of the **profile**. This is usually a number and will remain the same when a data file is updated. |
| Name     | The name of the **profile** that gives a more 'human' identifier than id, usually describing what the **values** it contains are. By convention, this is unique within the data file. |
| Component| The **component** to which the **profile** relates. This is the **component** which the **profile** contains **values** for. |
| Values   | The **values** that define the **profile**. |

## Value

Each **property** has a set of possible **values** that it can return.
The metadata associated with a **value** is:

| Metadata | Description |
| -------- | ----------- |
| Name     | The **value** as a string. This uniquely identifies the **value** only within the **values** relating to the same **property**. |
| Property | The **property** to which the **value** relates. This, in combination with the name, uniquely identifies the **value** within the device detection data file. |
| Description| A description of the **value** explaining what it refers to, and what it means if a **profile** has this **value**. |
| URL      | A URL where more information on the **value** can be found. |


# Performance guidance



