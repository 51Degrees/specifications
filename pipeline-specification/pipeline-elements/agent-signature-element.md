# Agent Signature Element

The Agent Signature Element reads the three HTTP request headers that an
automated agent sends when it signs its request under the IETF Web Bot Auth
protocol, checks the signature against a public key that the agent
publishes, and reports what the signature proves.

An **agent** here means a program that fetches pages on someone's behalf,
such as a search crawler or an assistant acting for a user, rather than a
person using a browser. Almost no traffic is signed today, so a request with
no signature at all is the ordinary case and MUST NOT be reported as a
failure.

Four terms are used throughout this specification:

- A **key directory** is a small JSON document that an agent publishes at a
  well known address, holding the public keys that the agent signs with.
- A **thumbprint** is a short fingerprint of a public key, worked out from
  the key itself, so two parties can name the same key without sending the
  whole key.
- The **signature base** is the exact block of text that the agent signed,
  rebuilt line by line by the verifier from the parts of the request that
  the agent said it covered.
- An **agent card** is a JSON document in which an agent says who it is,
  what it is for and where its keys are. The registry draft calls it a
  Signature Agent Card.

The standards this Element implements are:

- [draft-ietf-webbotauth-httpsig-protocol-00](https://datatracker.ietf.org/doc/draft-ietf-webbotauth-httpsig-protocol/),
  the protocol itself.
- [draft-meunier-webbotauth-httpsig-directory-00](https://datatracker.ietf.org/doc/html/draft-meunier-webbotauth-httpsig-directory),
  the key directory.
- [draft-meunier-webbotauth-registry-03](https://datatracker.ietf.org/doc/html/draft-meunier-webbotauth-registry-03),
  the agent card and the registry of cards.
- [RFC 9421](https://datatracker.ietf.org/doc/html/rfc9421), HTTP Message
  Signatures, which defines the signature base and how a signature is
  checked.
- [RFC 8941](https://datatracker.ietf.org/doc/html/rfc8941), Structured
  Field Values, which defines the syntax of all three headers.
- [RFC 7638](https://datatracker.ietf.org/doc/html/rfc7638) and
  [RFC 8037 Appendix A.3](https://datatracker.ietf.org/doc/html/rfc8037#appendix-A.3),
  which define the thumbprint that the `keyid` signature parameter carries.

A signed request carries three headers. The example below is taken from the
protocol draft and is wrapped here for width only, as a real header is on
one line:

```
Signature-Agent: sig="https://signer.example.com"
Signature-Input: sig=("@authority" "signature-agent";key="sig");
    created=1700000000;expires=1700011111;keyid="ba3e64==";
    tag="web-bot-auth"
Signature: sig=:abc==:
```

All three headers are RFC 8941 dictionaries. The dictionary key, `sig`
above, is the signature label and MUST match across the headers for the
three parts to belong to one signature.

## Accepted Evidence

The Element asks for every `header.*` Evidence key. A signature names the
parts of the request it covers, it may cover any request header, and only
a part the verifier can rebuild can be checked, so a fixed list of headers
would leave a signature covering any other header unable to be rebuilt.

Five keys have named roles:

- `header.signature`
- `header.signature-input`
- `header.signature-agent`
- `header.host`
- `header.protocol`

Evidence keys MUST be matched without regard to case.

`header.host` and `header.protocol` are not read for their own sake. They
are the only Evidence from which the two derived components that RFC 9421
calls `@authority` and `@scheme` can be rebuilt, and the protocol draft
requires a signer to cover either `@authority` or `@target-uri`.

## Start-up activity

The list of accepted Evidence and the list of Property metadata SHOULD be
built on start-up rather than for each request.

The key directory cache and whatever the implementation uses to make HTTPS
requests are created on start-up and released when the Element is disposed
of. A client the Element makes for itself MUST NOT follow redirects,
because the address fetched is chosen by whoever sent the request, and a
redirect would move the fetch somewhere the checks made before the request
never saw. Where a client for HTTPS requests is supplied by the caller,
the Element MUST NOT dispose of it, because the caller owns it, and the
caller decides for themselves whether it follows redirects.

Registries of agent cards, where any are configured, MAY be read lazily on
first use rather than on start-up, because a card never changes whether a
signature is valid.

## Element Data

The Element Data key is `agent-signature`. Every Property is a value that
can say it has no value together with the reason why, so an absent detail
never looks like an answer. Only `AgentSignature` and
`AgentSignatureReason` always have a value.

| **Name**                    | **Type**  | **Description**                                                                                                                                                       |
|-----------------------------|-----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| AgentSignature              | string    | The outcome, one of `Absent`, `Invalid`, `Unverified`, `Timeout` and `Verified`. Always has a value.                                                                  |
| AgentSignatureReason        | string    | Why the outcome is what it is, one of the seventeen reason codes below. Always has a value.                                                                           |
| AgentSignatureAgent         | string    | The `Signature-Agent` member value exactly as the agent sent it, for example `https://chatgpt.com`. Has a value once the header has been read.                        |
| AgentSignatureKeyId         | string    | The `keyid` signature parameter, being the thumbprint of the key the agent signed with. Has a value once the signature has been paired with its parameters.           |
| AgentSignatureAlgorithm     | string    | The RFC 9421 registry name of the algorithm settled on, or the name the agent asked for when the Element does not verify that algorithm.                              |
| AgentSignatureCreated       | date time | The point in time the `created` parameter names.                                                                                                                      |
| AgentSignatureExpires       | date time | The point in time the `expires` parameter names.                                                                                                                      |
| AgentSignatureNonce         | string    | The `nonce` parameter, when the agent sent one. Checking that a nonce is never reused is the caller's job, see [error handling](#error-handling).                     |
| AgentSignaturePurpose       | string    | What the agent says it uses fetched pages for, taken from the key directory's `purpose` field, or from the agent card when the directory does not say.                |
| AgentSignatureName          | string    | The `client_name` field of the agent card.                                                                                                                            |
| AgentSignatureProductToken  | string    | The `rfc9309-product-token` field of the agent card, being the name the agent answers to in a robots.txt file, so that a caller can join it to `CrawlerProductTokens`. |
| AgentSignatureCardUrl       | string    | The `client_id` field of the agent card, which is the address the card was fetched from.                                                                               |

Property names MUST be matched without regard to case.

Where a Property has no value it MUST carry a message saying why. The
messages are:

| **Situation**                                                          | **Message**                                                        |
|------------------------------------------------------------------------|--------------------------------------------------------------------|
| No signature headers in the request                                     | No signature headers were present in the request                    |
| The signature or its headers could not be read                          | The signature headers could not be read                             |
| No signature in the request carried the Web Bot Auth tag                | No signature in the request was made for automated agent traffic    |
| The signature named no agent                                            | The signature named no agent, so there was nowhere to fetch a key from |
| The signature covered nothing tying it to the request                   | The signature covered nothing that ties it to this request, so it was not checked. |
| The agent carried its key set inline and inline key sets are off        | The agent sent its key with the request rather than publishing it, which this element does not accept. |
| Any other outcome, where the signature simply did not carry the detail  | The signature did not carry this information                        |
| Purpose, where the key directory was never read                         | The signature was not verified so the directory was not read        |
| Purpose, where the key directory was read and says nothing              | The agent does not say what its keys are for                        |
| Any agent card Property, where no card was found                        | No agent card available                                             |

## Process

Nearly every request carries no signature at all, so the Element MUST test
for the two signature headers before it parses or allocates anything, and
MUST answer that case from values that do not change between requests.

The steps below run in order and stop at the first failure. Each failure
names the status and the reason code that the two mandatory Properties
report. The Element MUST NOT throw for any header content, whatever a
sender puts in the three headers, and MUST NOT stop the Pipeline.

1. Neither `header.signature` nor `header.signature-input` is present.
   Status **Absent**, reason `NoSignature`. Every other Property has no
   value.
2. One of the two headers is present without the other, or either fails to
   parse, or the same label does not appear in both, or the
   `Signature-Agent` header fails to parse. Status **Invalid**, reason
   `Malformed`.
3. No signature carries the parameter `tag="web-bot-auth"`. Status
   **Invalid**, reason `TagMismatch`. Where more than one signature
   carries that tag, each is checked independently through the steps
   below, which is what the protocol draft asks for and what the
   draft's reverse proxy case needs, since a proxy adds a second
   signature beside the agent's own. The first that verifies answers
   the request, and where none does the first tagged signature's
   outcome is reported. The number checked MUST be bounded (the .NET
   implementation checks three), because each one can cost a
   directory wait and the header is written by the sender. Signatures
   carrying other tags are discarded without counting.
4. The signature's `created` or `expires` names a time outside the range
   the implementation can hold. Status **Invalid**, reason `Malformed`.
   Carrying such a value forward as the nearest time the implementation
   can hold would make a `created` far in the future read as one long
   ago, and the signature would then pass the check at step 6 rather
   than failing it.
5. The signature is missing `created`, `expires` or `keyid`. Status
   **Invalid**, reason `MissingParameter`.
6. `created` is later than now plus the clock skew, status **Invalid**,
   reason `NotYetValid`. `expires` is earlier than now minus the clock skew,
   status **Invalid**, reason `Expired`. Where a maximum lifetime is
   configured and `expires` minus `created` is longer than it, status
   **Invalid**, reason `Expired`.
7. No `Signature-Agent` member can be used for this signature, see
   [finding the agent](#finding-the-agent). Status **Unverified**, reason
   `NoAgent`. A signature with no key to check it against has not been
   found wanting, so the status is not Invalid.
8. The member that applies carries its key set inline in a `data:` URI and
   the Element is not configured to accept an inline key set. Status
   **Unverified**, reason `InlineDirectory`. A key set sent with the
   request is chosen by whoever sent the request, so a signature that
   checks out against it proves only that the sender holds the matching
   private key and says nothing about which agent sent the request.
9. The covered components include neither `@authority` nor `@target-uri`.
   Status **Invalid**, reason `UnboundSignature`. The protocol draft has an
   agent cover one of the two so that the signature says something about
   the request it arrived on. A signature covering neither would check out
   just as well against a request sent to any other site, so one captured
   elsewhere could be replayed here.
10. A covered component cannot be rebuilt from the Evidence, see
    [rebuilding the signature base](#rebuilding-the-signature-base). Status
    **Unverified**, reason `ComponentUnavailable`.
11. The key directory is resolved through the cache, see
    [obtaining the key](#obtaining-the-key).
    - The fetch has not finished when the wait budget runs out. Status
      **Timeout**, reason `DirectoryPending`.
    - The fetch failed, meaning a refused address, a network error, a
      status other than 200, a media type that is not allowed, a response
      longer than the configured size limit, a document that could not be
      read, or a directory response signature that did not check out.
      Status **Unverified**, reason `DirectoryUnavailable`.
    - The directory was read and holds no key that the `keyid` names. Status
      **Invalid**, reason `UnknownKey`. A directory that resolves without the
      key is evidence that the key was withdrawn, which is why this is
      Invalid where a directory that will not resolve is not.
    - The key carries `nbf` or `exp` values that exclude the moment named by
      `created`. Status **Invalid**, reason `KeyExpired`.
12. The algorithm is settled from the key and the `alg` parameter, see
    [algorithms](#algorithms). Where the algorithm is not one the Element
    verifies, status **Unverified**, reason `UnsupportedAlgorithm`.
13. The signature base is checked against the key. A signature that does
    not check out gives status **Invalid**, reason `SignatureMismatch`. A
    signature that checks out gives status **Verified**, reason `Verified`.

Once the key directory has been read, the purpose and the agent card
Properties are populated whatever the later steps decide, so a signature
that fails at step 12 or 13 still reports what the agent publishes about
itself.

### Finding the agent

Each `Signature-Agent` member is a string holding a URI with an optional
`type` parameter, which is one of `directory`, `jwks_uri` and `cimd` and
defaults to `directory`. A member with any other type MUST make the header
unreadable, which reports `Malformed`.

The URI resolves to the address the keys are fetched from:

| **Type**  | **Member value**                              | **Key address**                                                    |
|-----------|-----------------------------------------------|----------------------------------------------------------------------|
| directory | a bare origin                                  | the origin followed by `/.well-known/http-message-signatures-directory` |
| jwks_uri  | the address of the keys themselves              | as given                                                             |
| cimd      | the address of an agent card                    | the card, then the card's `jwks_uri`, or the keys the card carries inline in its `jwks` field |
| directory | a `data:` URI carrying the directory inline     | none, and the directory is refused unless inline key sets are configured on |

A member of type `directory` MUST be a bare origin, with at most the path
`/` and with no query, fragment or user information. The well known path is
joined onto the member as text, so a member ending in `?` or `#` would
otherwise turn the well known path into a query or a fragment and let the
sender choose the whole address fetched.

The scheme MUST be `https`, and the sole exception is a `data:` URI of type
`directory`. The protocol draft permits `http`, and this Element does not,
because a key fetched over plain HTTP proves nothing about who sent it. A
`data:` URI MUST state the media type
`application/http-message-signatures-directory+json`, so an implied
`text/plain` is rejected. A directory carried in a `data:` URI is accepted
only where the operator has turned the inline directory option on, which
is off by default, and a signature resolved that way otherwise reports
Unverified with reason `InlineDirectory` as step 8 of the
[process](#process) describes.

The member that applies to a signature is the one that the signature covers,
which is settled as follows:

- Where the covered components include `"signature-agent";key="<label>"`,
  the member with that label is used. Where no member carries the label, the
  status is Unverified with reason `NoAgent`.
- Where the covered components include the whole header as
  `"signature-agent"` with no label, the sole member is used. Where the
  header carries more than one member, there is no way to tell which one
  signed, so the status is Unverified with reason `NoAgent`.
- Where the covered components include no `signature-agent` component at
  all, the status is Unverified with reason `NoAgent`, even where the header
  is present, because anyone can add a header to a request and only the
  covered part of a request is protected by the signature.

Verifiers MAY also accept the older form in which `Signature-Agent` is a
bare quoted string rather than a dictionary. That member has no label. This
is on by default and is configurable, see
[configuration options](#configuration-options).

### Rebuilding the signature base

The signature base is built as RFC 9421 section 2.5 sets out. There is one
line for each covered component, in the order the signer listed them,
written as the strict RFC 8941 serialisation of the component identifier,
then a colon and a space, then the value, then a newline. The last line is
the text `"@signature-params"`, then a colon and a space, then the strict
serialisation of the `Signature-Input` member's inner list with its
parameters in the order the signer sent them. The signature is then
checked over the ASCII bytes of that text. Strict serialisation matters
because a compliant signer builds its base from the strict form whatever
spacing its header carries, so a verifier that copied the header text as
sent would wrongly reject a signer whose spacing differs legally from the
strict form, such as one writing a space after a parameter semicolon.

- A component identifier that is not a string MUST make the signature
  unverifiable.
- A component listed twice MUST make the signature unverifiable, because
  RFC 9421 forbids a base that is ambiguous.
- Header components are taken from the Evidence, trimmed of surrounding
  space, and a header seen more than once is joined with `, `. Any request
  header may be covered, which is why the Element asks for every header as
  Evidence.
- A component that carries the `key` parameter is a named member of a
  dictionary header, and the value is the strict serialisation of that
  member's value with its parameters. A member with no explicit value
  serialises as `?1`, which RFC 8941 defines as boolean true.
- The `sf`, `bs` and `tr` parameters ask for a header to be rewritten before
  it is signed, which this Element does not do, so a component carrying any
  of them cannot be rebuilt.
- The `req` parameter names part of a related request, which only arises
  when signing a response, so a request component carrying it cannot be
  rebuilt.
- `@authority` is built from the Host header as RFC 9421 section 2.2.3
  describes, being the host lowercased with a port removed where the port is
  the default one for the scheme. A host written in square brackets, as an
  IPv6 address is, keeps its brackets and only a port after the closing
  bracket is removed.
- `@scheme` is the value of `header.protocol` lowercased.
- `@target-uri`, `@method`, `@path` and `@query` cannot be rebuilt, because
  the request line is not in the Evidence today. A signature covering any of
  them reports Unverified with reason `ComponentUnavailable`.

A signature covering `@authority` and `signature-agent`, which is what the
protocol draft's own example and the published test vectors do, can always
be rebuilt.

### Obtaining the key

Keys are fetched over HTTPS and held in a cache. The cache is keyed on the
resolved key address together with the member type, not on the origin and
not on the `keyid`, so an agent that names its keys directly and an agent
that names an origin are held apart. The type belongs in the key because
what a fetch does with an address depends on the type, and the sender
writes both, so keyed on the address alone a request naming a real agent's
key address under the wrong type would cache a failure that then answers
the real agent's requests for the negative cache lifetime.

The cache MUST be bounded, because a sender chooses the `Signature-Agent`
value and could otherwise fill memory by naming a different agent on every
request. The bound is a least recently used cache of a configurable size.

Requests MUST NOT queue behind a fetch. The behavior is:

- On a miss, one fetch is started for that address and every request that
  arrives while the fetch runs waits on the same fetch. Twenty first
  requests for one agent MUST cause one fetch, not twenty.
- A request waits for the fetch only for the wait budget. Where the fetch
  has not finished by then, the request reports **Timeout** with reason
  `DirectoryPending` and the fetch is left running, so that a later request
  from that agent finds the result. This means that the first request from
  an agent the Pipeline has never seen can report Timeout, which is
  deliberate and is not a fault.
- Where the request has already been abandoned by the caller before the
  lookup starts, no fetch is started at all and the request reports Timeout.
- A fetch that fails is remembered as a failure for the negative cache
  lifetime, which is shorter than the ordinary lifetime, so an outage at one
  agent does not cause a fetch on every request.
- An entry older than its lifetime is refreshed by starting a fresh fetch,
  while the copy already held answers the request that triggered the
  refresh and every other request that arrives while the refresh runs.
  This is what the protocol draft asks for, because a directory that fails
  to resolve MUST NOT throw away a key already held. Where the refresh
  succeeds and the key is gone, the next request reports `UnknownKey`.
- Keys already held answer for at most one further cache lifetime whilst
  refreshes keep failing, and then answer no longer. Taking a directory
  offline is how an agent withdraws a key that has been stolen, so keys
  that answered for ever after the directory stopped responding would
  make withdrawal impossible.
- Where a response carries `Cache-Control: max-age`, the shorter of that
  value and the configured lifetime is used. The configured lifetime is
  never exceeded.
- A directory carried inline in a `data:` URI is neither fetched nor
  cached, and is only read at all where inline key sets are configured on.

Every address fetched comes from a header the sender wrote, or from a
document fetched because of one, so an address MUST be checked before a
request is made rather than trusted:

- Key directory, agent card, `jwks_uri` and registry addresses MUST be
  HTTPS and MUST carry no user information, because anything before an
  `@` in the authority names a user rather than a host and is a well worn
  way of writing an address that reads as one host and connects to
  another.
- An address written as an IP address in a loopback, private, link local,
  carrier grade or IPv6 unique local range, or as the unspecified
  address, MUST be refused. Those addresses only appear inside a network,
  and a sender-chosen address in one of them is how a server is made to
  fetch its own internal services. A name that resolves to such an
  address cannot be refused this way, because the name is resolved when
  the connection is made, so a deployment facing the public internet
  SHOULD also route these fetches through an outbound proxy that enforces
  an allow list.
- Redirects MUST NOT be followed on directory and card fetches, and a
  directory or card whose final address is not the address asked for MUST
  be rejected.
- The response body is read against a configurable size limit, and a body
  longer than the limit makes the fetch fail. The documents are small,
  and the address they are read from is chosen by whoever sent the
  request, so the size has to be held down.

The fetch itself:

- The request sends an `Accept` header of
  `application/http-message-signatures-directory+json`, and a `User-Agent`
  header naming the product and its version.
- The response MUST have status 200. A directory MUST carry the media type
  `application/http-message-signatures-directory+json`. Where the address
  came from a `jwks_uri`, `application/json` is accepted as well, because
  keys named directly are an ordinary JSON document.
- The document MUST be an object with a `keys` array holding at least one
  key. Each key carries `kty` and, depending on the key type, `kid`, `use`,
  `alg`, `crv`, `x`, `y`, `n` and `e`, and MAY carry `nbf` and `exp`. The
  top level `purpose` and `signature_agent` fields are kept.
- `nbf` and `exp` are Unix seconds. A value above 100,000,000,000 is a time
  more than a thousand years away, so implementations MUST read such a value
  as milliseconds, divide it by 1,000 and log the fact at debug level. At
  least one published directory serves milliseconds.
- The `keyid` from the signature is matched first against the thumbprint
  worked out from each key, and then against the `kid` that the directory
  gives each key. The protocol draft says `keyid` carries the thumbprint,
  while some directories also use the thumbprint as the `kid`, so both are
  tried.
- Where the response carries `Signature` and `Signature-Input` headers with
  `tag="http-message-signatures-directory"`, the signature over the response
  MUST be checked with the key in the body that its `keyid` names, and a
  check that does not pass makes the directory unavailable. A response
  carrying no such headers MUST be accepted, because the directory draft
  only recommends them and agents signing today do not all send them. A
  response signed under some other tag says nothing about the directory and
  is accepted.
- Where the response carries a `Content-Digest` header with a `sha-256`
  member, the digest MUST be checked over the body before the response
  signature is checked. A digest the implementation cannot read is not
  evidence against the response.

### The agent card and registries

The agent card carries `client_id`, `client_name`, `client_uri`, `contacts`,
either `jwks_uri` or the keys inline in `jwks`, and inside a `web_bot_auth`
object the fields `rfc9309-product-token`, `purpose`, `trigger` and
`expected-user-agent`.

A card MUST be rejected where `client_id` is missing or is not the address
the card was fetched from, where the card carries both `jwks` and
`jwks_uri`, or where the request was redirected, because the registry draft
says a card is returned directly with a 200.

A card reaches the result in two ways:

1. The `Signature-Agent` member has type `cimd`. The card is the thing
   fetched and its keys are the directory. Where the card cannot be read,
   the status is Unverified with reason `DirectoryUnavailable`.
2. One or more registries of cards are configured. A registry is a plain
   text document listing one card address per line, where a `#` starts a
   comment and blank lines are skipped. Each listed address MUST pass the
   same address checks as every other fetched address, because although
   the registry's own address is configured by the operator, the lines
   are whatever the registry served, and a line that fails the checks is
   dropped. Each card is fetched once and indexed by its `jwks_uri`. The
   registries are read once for the life of the process, so a registry or
   card that cannot be fetched at that read, for any reason, is not
   retried until the process restarts. Implementations MUST document this
   to users, because unlike a key directory fetch, which is retried and
   recovers on its own, a failure here persists after the fault is dealt
   with, and only the card Properties are affected. When a signature
   of type `directory` or `jwks_uri` resolves to a key address that matches
   an indexed card, the card Properties are populated from that card.

A card that cannot be fetched MUST NOT change the signature status. The card
Properties simply have no value.

### Algorithms

The algorithm is settled from the key and from the optional `alg` signature
parameter:

- Where the key names an algorithm in the JOSE names that RFC 7518 and
  RFC 8037 register, it is mapped to the RFC 9421 registry name. `EdDSA`
  becomes `ed25519`, `PS512` becomes `rsa-pss-sha512`, `ES256` becomes
  `ecdsa-p256-sha256` and `HS256` becomes `hmac-sha256`.
- Where the key names no algorithm, the key type decides. An `OKP` key on
  the `Ed25519` curve is `ed25519`, an `EC` key on `P-256` is
  `ecdsa-p256-sha256`, and an `oct` key is a shared secret and so is
  `hmac-sha256`. An `RSA` key does not say on its own which RSA algorithm it
  is for, so the signature has to.
- Where the key and the signature both name an algorithm and the two differ,
  there is nothing safe to check with, so the algorithm is treated as
  unsupported and the name reported is the one the signature asked for.
- Where neither names an algorithm, the algorithm is unsupported and the
  name reported is whatever the key said about itself.

`ed25519`, `rsa-pss-sha512` and `ecdsa-p256-sha256` MUST be verified. Any
other name, `hmac-sha256` included, reports Unverified with reason
`UnsupportedAlgorithm`. `hmac-sha256` is never verified because the protocol
draft forbids shared secrets for signing requests, and a request that
arrives signed that way points at a misconfigured agent, so it SHOULD be
logged at warning level once for each key id rather than on every request.

Notes for implementers:

- RSA-PSS uses a salt the same length as the hash, being 64 bytes, as
  RFC 9421 section 3.3.1 specifies.
- ECDSA signatures are the 64 byte pairing of r and s that RFC 9421 section
  3.3.4 specifies, not a DER encoding.
- A key the implementation cannot read MUST count as a signature that did
  not check out, because a signature that cannot be checked has not been
  checked.

### Statuses

| **Status** | **Meaning**                                                                                                                            |
|------------|------------------------------------------------------------------------------------------------------------------------------------------|
| Absent     | The request carried no signature headers. This is the ordinary case and is never evidence against the request.                           |
| Invalid    | The request carried a signature and something about the signature or its headers is wrong.                                               |
| Unverified | The request carried a signature that could not be checked. This is not evidence against the agent.                                       |
| Timeout    | The agent's key directory was still being fetched when the wait budget ran out. The fetch continues, so a later request finds the result. |
| Verified   | The signature checked out against a key the agent publishes.                                                                             |

### Reason codes

| **Reason code**      | **Status** | **Meaning**                                                                                          |
|----------------------|------------|--------------------------------------------------------------------------------------------------------|
| NoSignature          | Absent     | Neither the `Signature` header nor the `Signature-Input` header was present.                           |
| Malformed            | Invalid    | One of the two headers was present without the other, or one of the three headers could not be read.    |
| TagMismatch          | Invalid    | No signature in the request carried the `web-bot-auth` tag.                                            |
| MissingParameter     | Invalid    | The signature was missing one of the required `created`, `expires` and `keyid` parameters.             |
| Expired              | Invalid    | The signature had expired, or it was valid for longer than the configured maximum lifetime.            |
| NotYetValid          | Invalid    | The signature was created further into the future than the configured clock skew allows.               |
| NoAgent              | Unverified | The signature named no agent, so there was nowhere to fetch a key from.                                |
| InlineDirectory      | Unverified | The agent carried its key set inline in a `data:` URI and the Element is not configured to accept that. |
| UnboundSignature     | Invalid    | The signature covered neither `@authority` nor `@target-uri`, so nothing ties it to this request and one captured elsewhere could be replayed here. |
| ComponentUnavailable | Unverified | The signature covered part of the request that cannot be rebuilt from the Evidence the Pipeline holds. |
| DirectoryPending     | Timeout    | The key directory was still being fetched when the wait budget ran out.                                |
| DirectoryUnavailable | Unverified | The key directory could not be fetched or could not be read.                                           |
| UnknownKey           | Invalid    | The key directory was read and holds no key with the key id the signature names, which is evidence that the key was withdrawn. |
| KeyExpired           | Invalid    | The key itself was not valid at the time the signature was created.                                    |
| UnsupportedAlgorithm | Unverified | The signature uses an algorithm this Element does not verify.                                          |
| SignatureMismatch    | Invalid    | The signature did not check out against the key the agent publishes.                                   |
| Verified             | Verified   | The signature checked out against a key the agent publishes.                                           |

Every reason code MUST be exposed as a constant that a caller can compare
against.

### Error handling

Verification is an enrichment and never a gate. Every failure, from a
header that cannot be parsed through to an agent whose server is down, MUST
be reported through the two mandatory Properties and MUST NOT stop the
Pipeline or raise an error out of the Element.

Checking that a `nonce` is never reused is out of scope. The nonce is
reported as a Property and the caller decides how long to remember one for,
because only the caller knows the traffic.

Where the implementation runs Flow Data concurrently, the cache and the
fetching MUST be safe to use from more than one thread at once, and a
network call MUST NOT be made while a lock is held.

## Configuration options

| **Parameter**                  | **User configurable** | **Optional** | **Default**             | **Notes**                                                                                                                       |
|--------------------------------|-----------------------|--------------|-------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| HTTP client                     | yes                   | yes          | one owned by the Element | The client that key directories, agent cards and registries are fetched with. A client the Element makes for itself does not follow redirects. A client supplied by the caller is not disposed of by the Element and is used exactly as it was given. |
| Cache size                      | yes                   | yes          | 1000                    | The number of key directories held in the cache.                                                                                 |
| Cache lifetime                  | yes                   | yes          | 24 hours                | How long a fetched key directory is reused for. This matches the `max-age` the drafts recommend a directory is served with.       |
| Negative cache lifetime         | yes                   | yes          | 5 minutes               | How long a failed fetch is remembered for.                                                                                       |
| Wait budget                     | yes                   | yes          | 350 milliseconds        | How long a request waits for a fetch before it reports Timeout.                                                                  |
| Fetch timeout                   | yes                   | yes          | 5 seconds               | The time limit on a single fetch.                                                                                                |
| Clock skew                      | yes                   | yes          | 60 seconds              | The tolerance on the `created` and `expires` parameters, which allows for clocks that differ a little.                            |
| Maximum lifetime                | yes                   | yes          | zero, meaning no limit  | The longest a signature may be valid for. A signature valid for longer reports Invalid with reason `Expired`. There is no limit by default, because the protocol draft only recommends one, and it recommends 24 hours. |
| Registry                        | yes                   | yes          | none                    | The address of a registry of agent cards. More than one MAY be configured.                                                       |
| Allow the older Signature-Agent | yes                   | yes          | true                    | Whether the bare quoted string form of the `Signature-Agent` header, which the earlier drafts used, is accepted.                  |
| Allow inline directory          | yes                   | yes          | false                   | Whether a key set carried inline in a `data:` URI is accepted. Off by default, because an inline key set is chosen by whoever sent the request, so a signature that checks out against it says nothing about which agent sent the request. Turn it on only where every caller is already trusted, such as a test harness. |
| Maximum response size           | yes                   | yes          | 262,144 bytes           | The most that is read from a key directory, agent card or registry response before the fetch is abandoned.                       |

Every period MUST be checked when the Element is built, and a negative
period or one longer than a year MUST be refused there. A bad period that
only surfaced on the request path would make the request that happened to
arrive first carry the blame for a setting made at start-up.

Every option except the HTTP client MUST also be settable from a Pipeline
configuration file, so that the Element can be added by name without
writing code. The client is the exception because a configuration file
holds text and a client cannot be written as text.
