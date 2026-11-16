# Disk cache

## Overview

A package MAY offer a disk store, which keeps cache entries in files in a
folder so that they outlast the process that wrote them. It sits below the
cache in memory that [caching](caching.md) describes, and answers when that
cache does not hold an entry.

The disk store is off unless a folder is named. When it is off, the package
MUST NOT create or write anything on disk for the cache. A configuration
supplied with a product counts as naming a folder, so a product whose
supplied configuration names a default folder has the disk store on until
the user changes that configuration.

A package MAY also put the disk store behind a build option that is off by
default, as Rust does with a cargo feature. A package that builds for
WebAssembly MUST leave the disk store out of its WebAssembly targets.

The folder is a file system path, and [file system paths](file-system-paths.md)
applies to it, so a relative path MUST work.

## Folder structure

The store names each file by the lowercase hexadecimal form of an
HMAC-SHA-256 of the key. The HMAC key is a 32-byte random secret. The store
MUST create the secret in a file in the folder root the first time it uses
the folder, and MUST read it back every time it opens the folder. The secret
file is the only file the store keeps in the folder root.

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
because none of them can be found by name again.

The store MUST write each file under a temporary name in the same leaf
folder, with a suffix of its own that marks it as temporary, and then rename
it into place. A reader then sees the old file or the new one, and never part
of either.

## File contents

Each file holds the following, in order.

| Bytes  | Field                                                    |
|--------|----------------------------------------------------------|
| 4      | Marker, the ASCII characters `51DF`                      |
| 1      | File format version, 1                                   |
| 4      | Length of the key in bytes, a little-endian `u32`        |
| Length | The key in full                                          |
| 1      | Entry format version, 1                                  |
| 1      | Flags, as described below                                |
| 8      | Written                                                  |
| 8      | Renewed                                                  |
| 8      | Expires, when bit 0 is set                               |
| 8      | Drop time, when bit 1 is set                             |
| Rest   | The value, as its codec wrote it                         |

In the flags, bit 0 is set when an expiry follows and bit 1 when a drop time
follows. Every other bit is 0.

Everything from the entry format version to the end is the entry format,
version 1. Every store that keeps entries as bytes uses this one entry format,
so a value written on one host reads back the same on any other. A disk store
is such a store, with the marker, the file format version and the key in
front of each entry.

Written is when the source produced the value. Renewed is when the entry's
idle period last started, which is its write or its last use. Expires is when
the entry stops being used. Drop time is when the store MUST stop returning
the entry.

The store MUST compare the key in the file with the key it was asked for on
every read. When they differ, the store MUST answer that the entry is absent.

A file that is truncated, carries the wrong marker or a version the store does
not read, or fails to decode MUST answer absent, and the store MUST remove it.

## Times

Every time in a file is a little-endian unsigned 64-bit count of nanoseconds
since the Unix epoch, in UTC. A time before the epoch is written as the epoch,
and one after the year 2554 as the largest count. Both keep their order
against any real time, so freshness checks still come out right. Times come
from the system clock in UTC.

The store MUST NOT read or write a file system time, whether modified,
accessed or created, for any decision. That includes the order in which the
least recently used files are trimmed, which comes from Renewed, or from an
index in memory that the store rebuilds from the files when it opens.

A read MUST rewrite Renewed in the file when the stored time is more than a
tenth of the time to idle in the past, and MUST NOT rewrite it otherwise. A
busy entry is then not rewritten on every read, and idle is measured to
within 10%.

A file whose Written time is later than now MUST answer absent, and the store
MUST remove it.

## Limits

The store holds its files within a byte limit for the folder. When no limit
is given, the limit is a quarter of the usable space on the volume, and at
most 8 GiB. Once the files go over the limit, the store MUST remove files,
oldest Renewed first, until they take no more than nine tenths of it. The
limit MUST hold when the store is opened again on the same folder.

The store MUST remove expired files when it opens and as writes arrive. It
MUST remove the temporary files that a crash left behind when it opens.

## Safety

The store MUST remove only files whose names and contents it recognizes as
its own. A folder setting pointed at the wrong place then never deletes a
user's files.

The store MUST create the folder readable only by the user the process runs
as.

The store MUST stay correct when more than one process uses the same folder
at once. Renaming each file into place makes that work for readers, provided
a reader allows for a file vanishing between listing it and opening it.

A failure to read or write a file, a full disk included, MUST NOT fail the
request. The store answers that the entry is absent or drops the write, and
logs a warning.

## Values created for one request

The rule in
[values created for one request](caching.md#values-created-for-one-request)
applies to every tier of a cache, the disk store included. A disk store MUST
NOT write a result that holds a [51Did](../../did-specification/README.md),
and MUST NOT serve one that it finds.

## What the files hold

The files hold the key in full. For a results cache, the key is made of
Evidence values, for example a User-Agent or an IP address.

The files sit on the machine's disk until their drop time or a trim removes
them, and they survive a restart.

## Tests

The implementor MUST provide tests that show each of the following. Linux
MUST run these tests in CI, not only compile them.

- With no folder named, the store MUST NOT create anything on disk.
- Every file MUST sit at the two-level path its key gives, with none in the
  folder root other than the secret.
- Times. Between operations, the tests set every file's modified, accessed and
  created times to the epoch and then to a far-future date. Answers, expiry,
  idle and trimming MUST be unchanged.
- Key in the file. A name collision forced through a test hook MUST answer
  absent, never the wrong value.
- An entry MUST survive a restart.
- An entry MUST answer absent after it expires.
- An entry MUST answer absent once it has been idle for the time to idle.
- The byte limit MUST hold, including when the store is opened again.
- Temporary files left behind MUST be cleared when the store opens.
- Corrupt and truncated files MUST be removed.
- A file the store did not write MUST be left untouched.
- Two stores MUST work on one folder at once.
- A folder that is full or cannot be written MUST NOT fail a request.
- A missing secret MUST lead to a new secret and an empty store.
- A result that holds a 51Did MUST never be written.
- Benefit. A disk hit MUST answer with no call to the source.
