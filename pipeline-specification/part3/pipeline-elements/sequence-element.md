
TODO - Taken from old spec. Needs review and refactor

### SequenceElement

The sequence element does not have any configuration parameters.

The **ElementDataKey** is ‘sequence’

The **ElementData** contains no properties.

---
*EvidenceKeyFilter*

-   query.session-id

-   query.sequence

---
*Process*

If the evidence contains no session id, then create one and add it to the
evidence. This is usually the string representation of a Guid. However, it could
be any string that is (nearly) guaranteed to be unique.

If the evidence contains no sequence number, then add one to the evidence
initialized to 1. Otherwise, parse the value and increment it, assigning the new
value back to the evidence collection.

If the value cannot be parsed, then set it to 1 and log an error. “Failed to
increment usage sequence number”