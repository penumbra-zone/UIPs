| uip | 06 |
| - | - |
| title | App Version Safeguard |
| description | Add a safeguard against running or migration with an incorrect version of PD. |
| author | Conor Schaefer ([@conorsch](https://github.com/conorsch)), Lucas Meier ([@cronokirby](https://github.com/cronokirby)) |
| discussions-to | <https://forum.penumbra.zone/t/pre-uip-version-aware-migrations-for-chain-upgrades> |
| status | Draft |
| type | Informational |
| consensus | No |
| created | 2024-11-12 |

## Abstract

This proposal describes a simple, backwards-compatible mechanism to safeguard node operators
against running or migrating with the wrong version of PD.
It works by saving the current app version in non-consensus storage, allowing the node
to detect if a migration is running against the wrong version, or the node is being
started against the wrong version.

## Motivation

Starting PD with `pd start` or migrating during upgrade with `pd migrate` require using the
correct version of PD, otherwise the resulting node will be operating with the wrong app hash,
preventing it from syncing with the rest of the network.
This is problematic during an upgrade, which depends on sufficient nodes (by voting power)
reaching consensus on the new state of the network; errors here can delay upgrades
significantly.

For example, during the chain upgrade on mainnet to v0.80.0, at height 501975, there was confusion about apphash mismatches when the network resumed, due to operator error: one validator operator mistakenly ran the pd migrate command using the old version of pd, i.e. 0.79.x, when they should have used v0.80.0 instead.
This resulted in a different app hash in that validator’s state, preventing the network from reaching consensus on the first post-upgrade block.
Fortunately, the problem was quickly diagnosed, and the validator was able to rerun the migration from backed up state, resolving the problem and allowing the chain to resume.

This kind of error can be prevented at the software level, preventing this
as a potential operator error.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

We add a new non-consensus state key: `app_version_safeguard` (UTF-8), which can be used
to store a u64 version value, as 8 little endian bytes.

### Starting

When starting, PD SHOULD check that the app version safeguard is either:

- not present,
- or equal to the APP_VERSION constant in the app crate.

Then, PD SHOULD write the APP_VERSION constant into the `app_version_safeguard` slot.

### Migrating

When migrating, PD SHOULD, in the context of an atomic migration transaction,

- check that app version safeguard is absent, or equal to the APP_VERSION constant of the *pre-migration* version of the app crate
- write the APP_VERSION constant of the *post-migration* version of the app crate into the `app_version_safeguard` slot.

## Backwards Compatability

This proposal is backwards compatible, because we never assume that the safeguard value is
pesent in the state.

## Rationale

We want to make sure that mechanism is backwards compatible, so that node operators
are not forced to upgrade to the point release, and only gain benefits by doing so.

We also want a point release to be possible for this change, so that node operators can benefit
from the safeguard ahead of a future upgrade, rather than only after it.

## Security Considerations

There are no security considerations for this proposal.

## Privacy Considerations

There are no privacy considerations for this proposal.

## Copyright

Copyright and related rights waived via [CC0](https://github.com/penumbra-zone/UIPs/blob/main/LICENSE).
