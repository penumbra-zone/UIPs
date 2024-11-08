| cip | 1 |
| - | - |
| title | Penumbra Improvement Proposal Process and Guidelines |
| author | Henry de Valence <hdevalence@penumbralabs.xyz> |
| status | Living |
| type | Meta |
| created | 2024-11-01 |

## Table of Contents

* What is a UIP?
* UIP Rationale
* UIP Types
* UIP Work Flow
  * Shepherding a UIP
  * Core UIPs
  * UIP Process
* What belongs in a successful UIP?
* UIP Formats and Templates
* UIP Header Preamble
  * author header
  * discussions-to header
  * type header
  * category header
  * created header
  * requires header
* Linking to External Resources
  * Data Availability Specifications
  * Consensus Layer Specifications
  * Networking Specifications
  * Digital Object Identifier System
* Linking to other UIPs
* Auxiliary Files
* Transferring UIP Ownership
* UIP Editors
* UIP Editor Responsibilities
* Style Guide
  * Titles
  * Descriptions
  * UIP numbers
  * RFC 2119 and RFC 8174
* History
* Copyright

## What is a UIP

UIP stands for Penumbra (UM) Improvement Proposal. A UIP
is a design document providing information to the
Penumbra community, or describing a new feature
for Penumbra or its processes or environment.
The UIP should provide a concise technical specification
of the feature and a rationale for the feature. The UIP
author is responsible for building consensus within the
community and documenting dissenting opinions.

## UIP Rationale

We intend UIPs to be the primary mechanisms for proposing
new features, for collecting community technical input on
an issue, and for documenting the design decisions that have
gone into Penumbra. Because the UIPs are maintained as text
files in a versioned repository, their revision history is
the historical record of the feature proposal.

For Penumbra software clients and core devs, UIPs are a
convenient way to track the progress of their implementation.
Ideally, each implementation maintainer would list the UIPs
that they have implemented. This will give end users a
convenient way to know the current status of a given
implementation or library.

## UIP Types

There are three types of UIP:

* **Standards Track UIP** describes any change that affects
  most or all Penumbra implementations, such as a change to
  the network protocol, a change in block or transaction
  validity rules, proposed standards/conventions, or any
  change or addition that affects the interoperability of
  software using Penumbra. Standards
  Track UIPs consist of three parts: a design document,
  an implementation, and (if warranted) an update to the
  formal specification. Standards Track UIPs are marked as either
  being "Consensus" or "Non-Consensus", depending on whether they
  affect the consensus-critical state transition function.
  Consensus UIPs SHOULD be approved by an on-chain signaling proposal
  to signal acceptance by the community.
* **Meta UIP** describes a process surrounding Penumbra or proposes
  a change to (or an event in) a process. Meta UIPs are like
  Standards Track UIPs but apply to areas other than the Penumbra
  protocol itself. They may propose an implementation, but not to
  Penumbra’s codebase; they often require community consensus; unlike
  Informational UIPs, they are more than recommendations, and users
  are typically not free to ignore them. Examples include procedures,
  guidelines, changes to the decision-making process, and changes to
  the tools or environment used in Penumbra development.
* **Informational UIP** describes a Penumbra design issue, or
  provides general guidelines or information to the Penumbra community,
  but does not propose a new feature. Informational UIPs do not necessarily
  represent Penumbra community consensus or a recommendation, so users
  and implementers are free to ignore Informational UIPs or follow their advice.

It is highly recommended that a single UIP contain a single key
proposal or new idea. The more focused the UIP, the more successful
it tends to be. A change to one client doesn’t require a UIP; a
change that affects multiple clients, or defines a standard for
multiple apps to use, does.

A UIP must meet certain minimum criteria. It must be a clear and
complete description of the proposed enhancement. The enhancement
must represent a net improvement. The proposed implementation, if
applicable, must be solid and must not complicate the protocol unduly.

## Penumbra Improvement Proposal (UIP) Workflow

### Shepherding a UIP

Parties involved in the process are you, the champion or UIP author,
the UIP editors, and the Penumbra Core Developers.

Before diving into writing a formal UIP, make sure your idea stands
out. Consult the Penumbra community to ensure your idea is original,
saving precious time by avoiding duplication. We highly recommend
opening a discussion thread on the [Penumbra forum](https://forum.penumbra.zone)
for this purpose.

Once your idea passes the vetting process, your next responsibility
is to present the idea via a UIP to reviewers and all interested
parties. Invite editors, developers, and the community to give their
valuable feedback through the relevant channels. Assess whether the
interest in your UIP matches the work involved in implementing it
and the number of parties required to adopt it. For instance,
implementing a Core UIP demands considerably more effort than a CRC,
necessitating adequate interest from Penumbra client teams. Be
aware that negative community feedback may hinder your UIP's
progression beyond the Draft stage.

### Consensus UIPs

For Consensus UIPs, you'll need to either provide a client implementation
or persuade clients to implement your UIP, given that client
implementations are mandatory for Consensus UIPs to reach the Final
stage (see "UIP Process" below).

To effectively present your UIP to client implementers, request a
Penumbra CoreDevsCall (CDC) call by posting a comment linking your
UIP on a CoreDevsCall agenda GitHub Issue.

The CoreDevsCall allows client implementers to:

* Discuss the technical merits of UIPs
* Gauge which UIPs other clients will be implementing
* Coordinate UIP implementation for network upgrades

These calls generally lead to a "rough consensus" on which UIPs
should be implemented. Rough Consensus is informed based on the
IETF's [RFC 7282](https://www.rfc-editor.org/rfc/rfc7282) which
is a helpful document to understand how decisions are made in
Celestia CoreDevCalls. This consensus assumes that UIPs are not
contentious enough to cause a network split and are technically
sound. One important excerpt from the document that highlights
based on [Dave Clark's 1992 presentation](http://www.ietf.org/proceedings/24.pdf)
is the following:

> *We reject: kings, presidents and voting.*
  *We believe in: rough consensus and running code.*

On-chain voting is one way to signal community sentiment, but it
is only one aspect of rough consensus.

:warning: The burden falls on client implementers to estimate
community sentiment, obstructing the technical coordination
function of UIPs and AllCoreDevs calls. As a UIP shepherd,
you can facilitate building community consensus by ensuring
the Penumbra forum thread for your UIP encompasses as much
of the community discussion as possible and represents various
stakeholders.

In a nutshell, your role as a champion involves writing the UIP
using the style and format described below, guiding discussions
in appropriate forums, and fostering community consensus around
the idea.

### UIP Process

The standardization process for all UIPs in all tracks follows
the below status:

* **Idea**: A pre-draft idea not tracked within the UIP Repository.
* **Draft**: The first formally tracked stage of a UIP in development.
  A UIP is merged by a UIP Editor into the UIP repository when properly
  formatted.
  * ➡️  Draft: If agreeable, UIP editor will assign the UIP a number
    (generally the next available number) and merge
    your pull request. The UIP editor will not unreasonably deny a UIP.
  * ❌ Draft: Reasons for denying Draft status include being too
    unfocused, too broad, duplication of effort, being technically
    unsound, not providing proper motivation or addressing backwards
    compatibility, or not in keeping with the Penumbra values and
    code of conduct.
* **Review**: A UIP Author marks a UIP as ready for and requesting
  Peer Review.
* **Last Call**: The final review window for a UIP before moving to
  Final. A UIP editor assigns Last Call status and sets a review end
  date (last-call-deadline), typically 14 days later.
  * ❌ Review: A Last Call which results in material changes or substantial
    unaddressed technical complaints will cause the UIP to revert
    to Review.
  * ✅ Final: A successful Last Call without material changes or
    unaddressed technical complaints will become Final.
* **Final**: This UIP represents the final standard. A Final UIP
  exists in a state of finality and should only be updated to correct
  errata and add non-normative clarifications. A PR moving a UIP from
  Last Call to Final should contain no changes other than the status
  update. Any content or editorial proposed change should be separate
  from this status-updating PR and committed prior to it.

#### Other Statuses

* **Stagnant**: Any UIP in Draft, Review, or Last Call that remains
  inactive for 6 months or more is moved to Stagnant. Authors or UIP
  Editors can resurrect a proposal from this state by moving it back
  to Draft or its earlier status. If not resurrected, a proposal may
  stay forever in this status.
* **Withdrawn**: The UIP Author(s) have withdrawn the proposed UIP.
  This state has finality and can no longer be resurrected using this
  UIP number. If the idea is pursued at a later date, it is considered
  a new proposal.
* **Living**: A special status for UIPs designed to be continually
  updated and not reach a state of finality. This status caters to
  dynamic UIPs that require ongoing updates.

As you embark on this exciting journey of shaping Penumbra's future
with your valuable ideas, remember that your contributions matter.
Your technical knowledge, creativity, and ability to bring people
together will ensure that the UIP process remains engaging, efficient,
and successful in fostering a thriving ecosystem for Penumbra.

## What belongs in a successful UIP

A successful Penumbra Improvement Proposal (UIP) should consist of
the following parts:

* **Preamble**: RFC 822 style headers containing metadata about the UIP,
  including the UIP number, a short descriptive title (limited to a maximum
  of 44 words), a description (limited to a maximum of 140 words),
  and the author details. Regardless of the category, the title and description
  should not include the UIP number. See below for details.
* **Abstract**: A multi-sentence (short paragraph) technical summary that
  provides a terse and human-readable version of the specification section.
  By reading the abstract alone, someone should be able to grasp the essence
  of what the proposal entails.
* **Motivation (optional)**: A motivation section is crucial for UIPs that
  seek to change the Penumbra protocol. It should clearly explain why the
  existing protocol specification is insufficient for addressing the problem
  the UIP solves. If the motivation is evident, this section can be omitted.
* **Specification**: The technical specification should describe the syntax
  and semantics of any new feature. The specification should be detailed
  enough to enable competing, interoperable implementations for any of the
  current Penumbra clients.
* **Parameters**: Summary of any parameters introduced by or changed by the UIP.
* **Rationale**: The rationale elaborates on the specification by explaining
  the reasoning behind the design and the choices made during the design process.
  It should discuss alternative designs that were considered and any related work.
  The rationale should address important objections or concerns raised during
  discussions around the UIP.
* **Backwards Compatibility (optional)**: For UIPs introducing backwards
  incompatibilities, this section must describe these incompatibilities and
  their consequences. The UIP must explain how the author proposes to handle
  these incompatibilities. If the proposal does not introduce any backwards
  incompatibilities, this section can be omitted.
* **Test Cases (optional)**: Test cases are mandatory for UIPs affecting
  consensus changes. They should either be inlined in the UIP as data (such
  as input/expected output pairs) or included in `../assets/uip-###/<filename>`.
  This section can be omitted for non-Consensus proposals.
* **Reference Implementation (optional)**: This optional section contains
  a reference/example implementation that people can use to better understand
  or implement the specification. This section can be omitted for all UIPs (
  mandatory for Consensus UIPs to reach the Final stage).
* **Security Considerations**: All UIPs must include a section discussing
  relevant security implications and considerations. This section should
  provide information critical for security discussions, expose risks, and
  be used throughout the proposal's life-cycle. Examples include security-relevant
  design decisions, concerns, significant discussions, implementation-specific
  guidance, pitfalls, an outline of threats and risks, and how they are
  addressed. UIP submissions lacking a "Security Considerations" section
  will be rejected. A UIP cannot reach "Final" status without a Security
  Considerations discussion deemed sufficient by the reviewers.
* **Privacy Considerations**: All UIPs must include a section discussing
  relevant privacy implications and considerations. This section should
  provide information critical for privacy discussions, expose risks, and
  be used throughout the proposal's life-cycle. Examples include privacy-relevant
  design decisions, concerns, significant discussions, implementation-specific
  guidance, pitfalls, an outline of threats and risks, and how they are
  addressed. UIP submissions lacking a "Privacy Considerations" section
  will be rejected. A UIP cannot reach "Final" status without a Pecurity
  Considerations discussion deemed sufficient by the reviewers.
* **Copyright Waiver**: All UIPs must be in the public domain. The
  copyright waiver MUST link to the license file and use the following
  wording: Copyright and related rights waived via CC0.

## UIP Formats and Templates

UIPs should be written in [markdown](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet)
format. There is a [UIP template](./cip-template.md) to follow.

## UIP Header Preamble

Each UIP must begin with an RFC 822 style header preamble in a
markdown table.
In order to display on the UIP site, the frontmatter must be formatted
in a markdown table. The headers must appear in the following order:

* `cip`: UIP number (this is determined by the UIP editor)
* `title`: The UIP title is a few words, not a complete sentence
* `description`: Description is one full (short) sentence
* `author`: The list of the author’s or authors’ name(s) and/or
  username(s), or name(s) and email(s). Details are below.
* `discussions-to`: The url pointing to the official discussion thread
* `status`: Draft, Review, Last Call, Final, Stagnant, Withdrawn, Living
* `last-call-deadline`: The date last call period ends on (Optional field,
  only needed when status is Last Call)
* `type`: One of Standards Track, Meta, or Informational
* `consensus`: Yes or No (Always No for Meta or Informational)
* `created`: Date the UIP was created on
* `requires`: UIP number(s) (Optional field)
* `withdrawal-reason`: A sentence explaining why the UIP was withdrawn.
  (Optional field, only needed when status is Withdrawn)

Headers that permit lists must separate elements with commas.

Headers requiring dates will always do so in the format of ISO 8601 (yyyy-mm-dd).

### `author` header

The `author` header lists the names, email addresses or usernames of the
authors/owners of the UIP. Those who prefer anonymity may use a username
only, or a first name and a username. The format of the `author` header
value must be:

> Random J. User &lt;<address@dom.ain>&gt;

or

> Random J. User ([@username](https://github.com/username))

or

> Random J. User ([@username](https://github.com/username) &lt;<address@dom.ain>&gt;

if the email address and/or GitHub username is included, and

> Random J. User

if neither the email address nor the GitHub username are given.

At least one author must use a GitHub username, in order to get
notified on change requests and have the capability to approve
or reject them.

### `discussions-to` header

While an UIP is a draft, a `discussions-to` header will indicate
the URL where the UIP is being discussed.

The preferred discussion URL is a topic on [Penumbra Forums](https://forum.penumbra.zone/).
The URL cannot point to Github pull requests, any URL which is
ephemeral, and any URL which can get locked over time (i.e. Reddit topics).

### `type` header

The `type` header specifies the type of UIP: Standards Track,
Meta, or Informational.

### `consensus` header

The `consensus` header specifies whether the UIP is consensus-critical.

### `created` header

The `created` header records the date that the UIP was
assigned a number. Both headers should be in yyyy-mm-dd
format, e.g. 2001-08-14.

### `requires` header

UIPs may have a `requires` header, indicating the UIP
numbers that this UIP depends on. If such a dependency
exists, this field is required.

A `requires` dependency is created when the current UIP
cannot be understood or implemented without a concept or
technical element from another UIP. Merely mentioning another
UIP does not necessarily create such a dependency.

## Linking to External Resources

Other than the specific exceptions listed below, links to
external resources **SHOULD NOT** be included. External
resources may disappear, move, or change unexpectedly.

The process governing permitted external resources is
described in [UIP-3](./uip-3.md).

## Linking to other UIPs

References to other UIPs should follow the format `UIP-N`
where `N` is the UIP number you are referring to. Each UIP
that is referenced in an UIP **MUST** be accompanied by a
relative markdown link the first time it is referenced, and
**MAY** be accompanied by a link on subsequent references.
The link **MUST** always be done via relative paths so that
the links work in this GitHub repository, forks of this repository,
the main UIPs site, mirrors of the main UIP site, etc.
For example, you would link to this UIP as `./uip-1.md`.

## Auxiliary Files

Images, diagrams and auxiliary files should be included in a
subdirectory of the `assets` folder for that UIP as follows:
`assets/cip-N` (where **N** is to be replaced with the UIP
number). When linking to an image in the UIP, use relative
links such as `../assets/uip-1/image.png`.

## Transferring UIP Ownership

It occasionally becomes necessary to transfer ownership of UIPs
to a new champion. In general, we'd like to retain the original
author as a co-author of the transferred UIP, but that's really
up to the original author. A good reason to transfer ownership
is because the original author no longer has the time or interest
in updating it or following through with the UIP process, or has
fallen off the face of the 'net (i.e. is unreachable or isn't
responding to email). A bad reason to transfer ownership is because
you don't agree with the direction of the UIP. We try to build
consensus around an UIP, but if that's not possible, you can
always submit a competing UIP.

If you are interested in assuming ownership of an UIP, send a
message asking to take over, addressed to both the original author
and the UIP editor. If the original author doesn't respond to the
email in a timely manner, the UIP editor will make a unilateral
decision (it's not like such decisions can't be reversed :)).

## UIP Editors

The current UIP editors are

* Henry de Valence ([@hdevalence](https://github.com/hdevalence))
* Finch ([@plaidfinch](https://github.com/plaidfinch))

If you would like to become a UIP editor, please check [UIP-2](./cip-2.md).

## UIP Editor Responsibilities

For each new UIP that comes in, an editor does the following:

* Read the UIP to check if it is ready: sound and complete. The ideas
  must make technical sense, even if they don't seem likely to get to
  final status.
* The title should accurately describe the content.
* Check the UIP for language (spelling, grammar, sentence
  structure, etc.), markup (GitHub flavored Markdown), code style

If the UIP isn't ready, the editor will send it back to the
author for revision, with specific instructions.

Once the UIP is ready for the repository, the UIP editor will:

* Assign an UIP number (generally the next unused UIP number, but the decision
  is with the editors)
* Merge the corresponding [pull request](https://github.com/penumbra-zone/UIPs/pulls)
* Send a message back to the UIP author with the next step.

Many UIPs are written and maintained by developers with write
access to the Penumbra codebase. The UIP editors monitor UIP
changes, and correct any structure, grammar, spelling, or markup
mistakes we see.

The editors don't pass judgment on UIPs. We merely do the
administrative & editorial part.

## Style Guide

### Titles

The `title` field in the preamble:

* Should not include the word "standard" or any variation thereof; and
* Should not include the UIP's number.

### Descriptions

The `description` field in the preamble:

* Should not include the word "standard" or any variation thereof; and
* Should not include the UIP's number.

### UIP numbers

When referring to UIPs, it must be written in the hyphenated form `UIP-X` where
`X` is that UIP's assigned number.

### RFC 2119 and RFC 8174

UIPs are encouraged to follow [RFC 2119](https://www.ietf.org/rfc/rfc2119.html)
and [RFC 8174](https://www.ietf.org/rfc/rfc8174.html) for terminology
and to insert the following at the beginning of the Specification section:

> The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
  "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and
  "OPTIONAL" in this document are to be interpreted as described in RFC
  2119 and RFC 8174.

## History

This document was adapted fairly directly from the [Celestia CIP process](https://github.com/celestiaorg/CIPs/blob/main/cips/cip-1.md).

That process was in turn derived heavily from [Ethereum's EIP Process](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1.md)
written by Hudson Jameson which is derived from [Bitcoin's BIP-0001](https://github.com/bitcoin/bips)
written by Amir Taaki which in turn was derived from [Python's PEP-0001](https://peps.python.org/).
In many places text was simply copied and modified. Although the PEP-0001
text was written by Barry Warsaw, Jeremy Hylton, and David Goodger, they
are not responsible for its use in the Celestia Improvement Process, and
should not be bothered with technical questions specific to Penumbra, Celestia or
the UIP. Please direct all comments to the UIP editors.

## Copyright

Copyright and related rights waived via [CC0](https://github.com/penumbra-zone/UIPs/blob/main/LICENSE).
