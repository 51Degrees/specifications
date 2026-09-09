# Identifier layout

This page defines the byte structure of a 51Did, so that a reader can see
exactly what an identifier holds and an implementer can write a package that
reads it. The three levels the fields belong to, the 51Did, the Envelope and
the Match Key, are defined in the [section introduction](README.md).

Every multi-byte integer is unsigned and little endian.

## Envelope

A 51Did is carried in a signed
[OWID](https://github.com/SWAN-community/owid) Envelope. The remote server
issues version 3. Versions 1 and 2 differ only in how the date is encoded,
version 1 holding hours in two bytes and versions 2 and 3 holding minutes in
four.

| **Offset**    | **Length** | **Field**                                                                                  |
|---------------|------------|--------------------------------------------------------------------------------------------|
| 0             | 1          | Version, 3 as issued.                                                                       |
| 1             | variable   | Creator domain, ASCII text ending in a zero byte, at most 253 characters before that byte.  |
| after domain  | 4          | Date, minutes since 2020-01-01T00:00:00Z.                                                   |
| after date    | 4          | Payload length in bytes.                                                                    |
| after length  | variable   | Payload, the 51Did fields defined below.                                                    |
| after payload | 64         | Signature over the preceding bytes, ECDSA on the P-256 curve with SHA-256, r followed by s. |

The date and the signature change on every call, which is why two envelopes
for the same inputs are not equal, and why comparison is done on the Match
Key instead.

The date is the minute the issuer made the Envelope. An issuer MUST state
that moment to the minute and MUST NOT round it to a coarser unit such as
the day. A receiver reads how old an identifier is from this field, and it
is one of the few checks a receiver can make without calling anyone, so a
field that only moves at midnight makes every identifier issued that day
look equally fresh and hides a replay made hours after the original. The
cloud service stated midnight in releases up to and including 4.4.33, so
identifiers those releases issued carry a date up to a day earlier than the
moment they were made, and a receiver judging age on such an identifier MUST
allow for that.

The Envelope is signed, so a 51Did package MUST create instances only by
reading bytes that are already a complete Envelope. A caller cannot assemble
one, because an unsigned identifier would be indistinguishable from a signed
one further down the chain. Reading an identifier is not the same as
verifying it, and a package MUST keep the two answers separate.

An Envelope is exchanged as base64. The remote server issues the standard
alphabet with padding, and a page that puts an identifier in a link uses the
URL-safe alphabet, so a package accepts both on the way in.

## Payload

The first five bytes are the same for every identifier type. Bits 6 and 7 of
the flags byte select the type, which determines the length and the meaning
of the Match Key that follows.

| **Offset** | **Length** | **Field**                                                           |
|------------|------------|----------------------------------------------------------------------|
| 0          | 1          | Flags.                                                               |
| 1          | 4          | License Id.                                                          |
| 5          | 32         | Match Key, a SHA-256, for the Probabilistic and Hashed Email types.  |
| 5          | 16         | Match Key, a GUID, for the Random type.                              |
| after Match Key | 1     | Terms. See below.                                                    |

A payload MAY be longer than the fields above. Bytes after the Terms carry
a creator context section whose contents and lengths belong to the
remote server that issued the identifier. A package therefore applies a lower
bound to the payload length and never an upper one, and it exposes the same
four fields whatever follows them.

An identifier issued before the Terms existed has a payload that ends at
the Match Key. A reader MUST treat a payload with no byte after the Match
Key as a Terms of zero, which says the terms are not stated in the
identifier, so the two cases mean the same thing and neither needs telling
apart from the other.

### License Id

The License Id is the raw value of the four bytes. On an identifier carrying
a creator context those bytes hold an encrypted value that only the issuer
can turn back into a licence, so the field identifies nothing outside
51Degrees, and two identifiers issued under one licence need not carry the
same value. It MUST NOT be used as a grouping or lookup key by a caller.

### Match Key

The Match Key is the stable, comparable part of the identifier. Two 51Dids
issued for the same inputs carry the same Match Key even though their
envelopes differ, so it is the value to use as a cache or de-duplication key,
and the value to compare when asking whether two identifiers stand for the
same thing.

## Flags byte

| **Bits** | **Field**          | **Meaning**                                                             |
|----------|--------------------|--------------------------------------------------------------------------|
| 0 to 2   | Usage              | The usage the identifier was created for. See below.                     |
| 3        | Usage from consent | Set when the Usage was derived from a consent string the caller sent.    |
| 4 to 5   | Unused             | Zero as issued. A reader MUST ignore these bits rather than refuse them. |
| 6 to 7   | Type               | The identifier type, which fixes the length of the Match Key.            |

### Usage

The Usage decides where an identifier may go. One created for non-marketing
MUST NOT be passed to a demand source, and one created for standard or
personalized marketing may be passed only to a recipient that has accepted
the applicable terms.

The three usages are cumulative in the byte rather than exclusive, so every
marketing identifier also carries the non-marketing bit.

| **Bits 0 to 2** | **Usage**     | **Meaning**                                                                               |
|-----------------|---------------|---------------------------------------------------------------------------------------------|
| `000`           | None          | No usage bit is set. The remote server does not issue this.                                  |
| `001`           | Non-marketing | Created for use that is not marketing.                                                       |
| `011`           | Standard      | Standard marketing, being targeting unrelated to the person's browsing or interactions.      |
| `111`           | Personalized  | Personalized marketing, being targeting related to the person's browsing or interactions.    |

Because the values are cumulative, a reader MUST answer with the highest
usage granted, testing bit 2 first, then bit 1, then bit 0. A reader that
masks for the non-marketing bit alone reads every marketing identifier as
non-marketing, which is the wrong way round for a data protection decision.
This is why a package exposes a named Usage and does not expose the flags
byte, as set out in [Package surface](package-surface.md).

A value with no bit set is not issued by the remote server, so an identifier
carrying it came from somewhere else or is damaged, and a caller SHOULD treat
it as an identifier that may not be passed on.

The names match the `id.usage` values the remote server accepts and reports,
being `non-marketing`, `standard` and `personalized`.

Bit 3 says how the Usage was arrived at, being derived from a consent string
the caller sent when the bit is set, and stated by the caller directly when
it is not. Both are legitimate, and the bit says nothing about which Usage
the identifier carries.

### Terms

The Terms says which terms document the identifier was created under, so
that the terms travel with the identifier instead of alongside it.

The byte is an index into the table below and is not a version number. An
index is used so that a later document can live at any address, rather than
only at an address this specification could compose from a number.

| **Index** | **Document**                         | **Address**                 |
|-----------|--------------------------------------|-----------------------------|
| `0`       | Not stated in the identifier         | None                        |
| `1`       | Model Terms for Marketing, version 2 | `https://m4ow.uk/mtm/2.txt` |

This table is the whole of the definition. A new terms document is a new
index added here, and every package has to be released to know it, which is
the cost of a receiver being able to trust what it reads. An index MUST NOT
be reused or repointed once published, because an identifier issued under it
is meant to stay readable years later, and repointing an index rewrites what
a past identifier says it agreed to.

Every package MUST use these names for the values, cased the way that
language cases the members of an enumeration, so that two packages describe
one thing the same way.

| **Index**     | **Name**                  |
|---------------|---------------------------|
| `0`           | Not Stated                |
| `1`           | Model Terms For Marketing 2 |
| anything else | Unknown                   |

So .NET and Rust write `NotStated`, `ModelTermsForMarketing2` and
`Unknown`, whilst Java and Python write `NOT_STATED`,
`MODEL_TERMS_FOR_MARKETING_2` and `UNKNOWN`. Where a language already has
its own settled form for the Usage and the Type values, that form wins,
because the new members have to read as though they were always there.

The name carries the version of the document rather than leaving it to the
address alone, so that a reader of the code can see which document is meant
without following a link.

A package MUST answer with the address for an index it knows, and MUST NOT
fetch it. The receiver decides what to do with the address.

The index rather than the address is carried because an address is long, and
because a receiver has to know the exact document in force when the
identifier was made. An index that maps to one immutable document can be
checked years later, where an address whose contents can be edited cannot.

#### The Reserved type

The Reserved type has no defined Match Key length, so a reader takes every
byte after the header as the Match Key and no byte is left for the Terms.
An identifier of that type therefore reads as index 0, which is correct
under the rule above and needs no special handling. Whoever assigns that
type has to fix its Match Key length, and until they do a Reserved
identifier cannot carry Terms that a package could find.

#### An index a package does not know

A package will meet an index added after it was released. It MUST report the
index, MUST answer with no address for it, and MUST NOT treat it as zero.
Zero says no terms are stated, whilst an unknown index says terms are stated
that this package cannot name, and a receiver that confused the two would
read an identifier created under terms as one created under none. A caller
meeting an unknown index SHOULD treat the identifier as covered by terms it
cannot yet read, and either update the package or refuse the identifier.

#### What zero does and does not mean

Zero does not mean the identifier is unrestricted. It means only that this
identifier does not carry the answer, so the answer has to come from
somewhere else, being the Terms Document Locator in an OpenRTB request or
whatever the surrounding protocol provides. **Carrying the Terms does not
remove the need to carry a Terms Document Locator where a protocol has
one.** Where both are present and they disagree, a receiver SHOULD treat the
identifier's own value as the one that describes the identifier, since it is
inside the signature and the accompanying data is not.

The Usage says where an identifier may go and the Terms says under which
document it was created. They answer different questions and a receiver
needs both. An identifier created for non-marketing carries zero, since the
Model Terms govern marketing use and a non-marketing identifier is not
created under them, and it is still barred from a demand source by its
Usage.

The remote server MUST NOT issue a marketing identifier whose Terms is zero,
since a marketing identifier is always created under a document.

### Type

| **Bits 6 to 7** | **Type**      | **Match Key**             | **Meaning**                                         |
|-----------------|---------------|---------------------------|------------------------------------------------------|
| `00`            | Probabilistic | 32-byte SHA-256           | Derived from the device fingerprint and IP address.  |
| `01`            | Random        | 16-byte GUID              | Generated at random by the server.                   |
| `10`            | Hashed Email  | 32-byte SHA-256           | Derived from the caller-supplied email and salt.     |
| `11`            | Reserved      | Read as the bytes present | Not yet assigned.                                    |

Identifiers issued before the type bits were defined carry zeroes there and
so read as Probabilistic, which is the type they are. A reader encountering
the reserved type MUST NOT refuse the identifier, and SHOULD unpack the
header fields and expose the remaining payload bytes as they are, so that an
identifier of a type added later still reads.
