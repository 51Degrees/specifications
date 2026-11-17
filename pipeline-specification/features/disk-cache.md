# Disk cache

## Overview

A package MAY offer a disk store, which keeps cache entries in files in a
folder so that they outlast the process that wrote them. It sits below the
cache in memory that [caching](caching.md) describes, and answers when that
cache does not hold an entry.

An entry is a key and its value. The source is what produces a value when no
cache holds it, such as an Engine's processing or a request to the cloud
service. A codec turns a value into bytes and back. The cache in memory and
the disk store are each a tier of the cache, and the cache in memory is the
tier above the disk store.

The disk store is off unless a folder is named. When it is off, the package
MUST NOT create or write anything on disk for the cache. A configuration
supplied with a product counts as naming a folder, so a product whose
supplied configuration names a default folder has the disk store on until
the user changes that configuration.

A package MAY also put the disk store behind a build option that is off by
default, for example an optional feature of its build. A package that builds
for WebAssembly MUST leave the disk store out of its WebAssembly targets.

The folder is a file system path, and [file system paths](file-system-paths.md)
applies to it, so a relative path MUST work.

## Folder structure

The store names each file by the lowercase hexadecimal form of an HMAC
([RFC 2104](https://www.rfc-editor.org/rfc/rfc2104)) with SHA-256 of the key.
The HMAC key is a 32-byte random secret. The store MUST create the secret in a
file in the folder root the first time it uses the folder, and MUST read it
back every time it opens the folder. The secret file is the only file the
store keeps in the folder root.

The first two hexadecimal characters of the name give the first folder, and
the next two give the second folder inside it. A file whose name starts
`3fa9` is at `3f/a9/` below the folder root. That gives 65,536 leaf folders,
so 8 million entries come to about 120 files in each. The store MUST create a
folder only when it first needs one.

The secret matters because Evidence is chosen by the sender of a request.
With a plain hash, a sender could try keys until every entry landed in one
folder. Because the sender does not know the secret, it cannot tell which
folder a key lands in.

When the secret file is missing, unreadable or not 32 bytes long, the store
MUST create a new secret and remove every file it recognizes as its own,
because none of them can be found by name again. A secret file that another
store has open does not count as unreadable. In that case the store MUST
refuse the folder as [safety](#safety) says, and MUST NOT create a secret or
remove anything. A secret file that the store lacks the permission to read
does not count as unreadable either, and the store MUST fail as
[safety](#safety) says.

The store MUST write each file under a temporary name in the same leaf
folder, with a suffix of its own that marks it as temporary, and then rename
it into place. A reader then sees the old file or the new one, and never part
of either.

## File contents

Each file holds the following, in order.

| **Bytes** | **Field**                                                |
|-----------|----------------------------------------------------------|
| 4         | Marker, the ASCII characters `51DF`                      |
| 1         | File format version, 1                                   |
| 4         | Length of the key in bytes, a little-endian `u32`        |
| Length    | The key in full                                          |
| 1         | Entry format version, 1                                  |
| 1         | Flags, as described below                                |
| 8         | Written                                                  |
| 8         | Renewed                                                  |
| 8         | Expires, when bit 0 is set                               |
| 8         | Drop time, when bit 1 is set                             |
| 8         | Data published                                           |
| 2         | Value format version, a little-endian `u16`              |
| Rest      | The value, as its codec wrote it                         |

In the flags, bit 0 is set when an expiry follows and bit 1 when a drop time
follows. Every other bit is 0. A file with any other bit set fails to decode.

Everything from the entry format version to the end is the entry format,
version 1. Every store that keeps entries as bytes MUST use this one entry
format, so that an entry written by one such store reads back the same from any
other that uses the same codec. A disk store is such a store, with the marker,
the file format version and the key in front of each entry.

Written is when the source produced the value. Renewed is when the entry's
idle period last started, which is its write or its last use. Expires is when
the cache above the store stops using the value. Drop time is when the store
MUST stop returning the entry. Without the flag for an expiry or a drop time,
the entry has no such limit. The time to idle is a setting of the store. An
entry whose Renewed is the time to idle or more in the past MUST answer
absent. When no time to idle is set, an entry never answers absent for being
idle.

Data published is the published date of the data that produced the value,
such as a data file or the cloud service's data, written as the epoch when
the source has none. Value format version is the version of the format its
codec writes the value in. The cache above the store gives the store the
published date of the data its source uses now and the version its codec
writes now. An entry whose Data published or Value format version differs
from those MUST answer absent, and the store MUST remove it, so that a data
update or an upgrade never serves values from older data or an older format.

The store MUST compare the key in the file with the key it was asked for on
every read. When they differ, the store MUST answer that the entry is absent.

A file that starts with the marker but is truncated, carries a version the
store does not read, or fails to decode MUST answer absent, and the store MUST
remove it. A file that does not start with the marker MUST answer absent, and
the store MUST leave it in place.

## Times

Every time in a file is a little-endian unsigned 64-bit count of nanoseconds
since the Unix epoch, in UTC. A time before the epoch is written as the epoch,
and one later than the largest count can hold (July 2554) as the largest
count. Both keep their order against any real time, so freshness checks still
come out right. Written, Renewed, Expires and the drop time come from the
system clock in UTC, and Data published comes from the source.

The store MUST NOT read or write a file system time, whether modified,
accessed or created, for any decision. That includes the order in which the
least recently used files are trimmed, which comes from Renewed, or from an
index in memory that the store rebuilds from the files when it opens.

When a time to idle is set, a read MUST rewrite Renewed in the file when the
stored time is more than a tenth of the time to idle in the past, and MUST NOT
rewrite it otherwise. A busy entry is then not rewritten on every read, and
idle is measured to within 10%.

When no time to idle is set, a read MUST rewrite Renewed in the file when the
stored time is more than an hour in the past, and MUST NOT rewrite it
otherwise. Renewed then still records the last use to within an hour, so
trimming removes the least recently used entries.

A read that rewrites Renewed MUST write the whole file under a temporary name
and rename it into place, as every write does, and MUST NOT put an older value
back over a newer write of the same entry.

A file whose Written time is later than now MUST answer absent, and the store
MUST remove it.

## Limits

The store holds its files within a byte limit for the folder. When no limit
is given, the limit is a quarter of the sum of the space the store's files take
and the space still free on the volume, both read when the store opens, and at
most 8 GiB.
Once the files go over the limit, the store MUST remove files, oldest Renewed
first, until they take no more than nine tenths of it. The limit MUST hold
when the store is opened again on the same folder.

The store MUST remove files past their drop time or their time to idle when it
opens, and again, at an interval it documents, while writes arrive. It MUST
remove the temporary files that a crash left behind when it opens.

## Safety

The store MUST remove only files it recognizes as its own, being the secret
file, a file at the path its name gives whose name is 64 lowercase hexadecimal
characters and which starts with the marker, and a file in a leaf folder with
the store's temporary suffix. A folder setting pointed at the wrong place then
never deletes a user's files.

The store's configuration names the folder. When the store opens, a store
that lacks the permissions it needs on the named folder, to create it or to
read, write and remove files in it, MUST fail with an error that names the
folder. Whether
other users of the machine can reach the folder is for whoever deploys the
package to decide, and is outside this page.

A disk store's folder MUST NOT be used by more than one store at the same
time, whether the stores are in one process or in several. Each store names a
folder of its own, and a package MAY run many stores for different purposes,
each with its own folder. A store that opens a folder after another has closed
it, such as the same service after a restart, uses the entries already there.
A later version of a package reads the files an earlier version wrote when it
supports their format version. Sharing a folder between the stores of
different packages is not supported, and a store is not required to detect a
store of another package.

A store MUST refuse a folder that another store of the same package has open,
and MUST find that out before it reads or creates the secret or removes any
file. Across processes it can find out by holding an exclusive lock on the
secret file while the folder is open. Some operating system file locks, such as
POSIX record locks, belong to the whole process and do not stop a second store
in the same process, so the store MUST also check the folders that stores in
its own process have open, compared by their full canonical path, for example
in a list kept for the whole process. A store that refuses a folder MUST log a
warning saying that each store needs a folder of its own, MUST leave every file
in the folder untouched, and MUST carry on without the disk store, so that no
request fails.

Once the store is open, a failure to read or write a file, a full disk
included, MUST NOT fail the request. The store answers that the entry is absent or drops the write, and
logs a warning.

## Values created for one request

The rule in
[values created for one request](caching.md#values-created-for-one-request)
applies to every tier of a cache, the disk store included. A disk store MUST
NOT write a result that holds such a value, a
[51Did](../../did-specification/README.md) for example, and MUST NOT serve one
that it finds.

## What the files hold

The files hold the key in full. For a results cache, the key is made of
Evidence values, for example a User-Agent or an IP address.

The files stay on the machine's disk across restarts until the store removes
them, after their drop time or time to idle, in a trim, when a read finds them
made from other data or in another value format, or when it creates a new
secret.

## Tests

The implementor MUST provide tests that show each of the following. These
tests MUST run in CI on Linux, not only compile.

- With no folder named, the store MUST NOT create anything on disk.
- Every file MUST sit at the two-level path its key gives, with none in the
  folder root other than the secret.
- Format. A file written for a known key, value and value format version at
  fixed times MUST match
  the layout in [file contents](#file-contents) byte for byte, and a file
  built from that layout MUST read back.
- Times. Between operations, the tests set every file's modified and accessed
  times, and its created time where the platform allows it, to the epoch and
  then to a far-future date. Answers, expiry, idle and trimming MUST be
  unchanged.
- Key in the file. A name collision forced through a test hook MUST answer
  absent, never the wrong value.
- An entry MUST survive a restart.
- An entry MUST answer absent after its drop time.
- An entry MUST answer absent once it has been idle for the time to idle.
- Files past their drop time or time to idle MUST be removed when the store
  opens.
- A read MUST rewrite Renewed when, and only when, it is more than a tenth of
  the time to idle old.
- With no time to idle set, a read MUST rewrite Renewed when, and only when,
  it is more than an hour old, and trimming MUST remove the least recently
  used entries first.
- A read that rewrites Renewed MUST NOT put an older value back over a newer
  write of the same entry.
- A file whose Written time is later than now MUST answer absent and be
  removed.
- The byte limit MUST hold, including when the store is opened again.
- Temporary files left behind MUST be cleared when the store opens.
- Corrupt and truncated files that start with the marker MUST be removed.
- A file that starts with the marker and carries a file format or entry
  format version other than 1 MUST answer absent and be removed.
- A file the store did not write MUST be left untouched.
- A store in a second process MUST refuse a folder that a store in another
  process has open, log a warning and carry on without the disk store.
- A second store in the same process MUST refuse a folder that the first store
  has open, log a warning and carry on without the disk store.
- A store that refuses a folder MUST leave every file in it untouched,
  including the secret.
- A store that lacks the permissions it needs on the named folder when it
  opens MUST fail with an error that names the folder.
- An entry whose Data published differs from the current published date, and
  one whose Value format version differs from the current version, MUST each
  answer absent and be removed.
- A folder that fills up, or that a file cannot be written to, after the store
  opens MUST NOT fail a request.
- A missing secret MUST lead to a new secret and an empty store.
- A secret file that is not 32 bytes long MUST lead to a new secret and an
  empty store.
- A result that holds a 51Did MUST NOT be written, and one found in a file
  MUST NOT be served.
- Benefit. A disk hit MUST answer with no call to the source.
