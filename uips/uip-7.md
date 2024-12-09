| uip | 7 |
| - | - |
| title | Stake Boost |
| description | Improves decentralization by boosting rewards for small validators |
| author | Henry de Valence ([@hdevalence](https://github.com/hdevalence)) |
| discussions-to | <https://forum.penumbra.zone/t/uip-staking-boost/134> |
| status | Draft |
| type | Standards Track |
| consensus | Yes |
| created | 2024-12-08 |

## Abstract

This UIP introduces Stake Boost, a mechanism to improve validator
decentralization by allocating a portion of staking rewards in each epoch to a
single validator, selected uniformly at random from the active set. As all
validators have an equal chance of being boosted, this mechanism boosts rewards
for smaller validators relative to larger ones, incentivizing stake
distribution across the network.

## Motivation

Currently, Penumbra's stake distribution is more centralized than desirable.
While gradual decentralization has been occurring naturally and UI improvements
have aimed to encourage this process, additional economic incentives could help
accelerate stake distribution across the network. The Stake Boost mechanism
provides direct economic incentives for delegators to stake with smaller
validators, helping to create a more decentralized and robust network.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Parameters

A new chain parameter `staking_boost_percent` is added to the staking
parameters. This parameter define the percentage of new staking issuance
allocated to the boost mechanism. 

The default value for `staking_boost_percent` should be `20`, though for
clarity this only affects newly generated parameters (e.g., for testnets);
parameter selection on Penumbra mainnet is subject to community consensus and
governance.

### Validator Selection

At the end of each epoch, one validator in the active set is chosen to be
boosted.  To select the boosted validator, a `ChaCha20Rng` should be seeded
with the previous block's app hash.

As described below, this is an imperfect source of randomness compared to a
real VRF, but probably good enough for this mechanism.

### Reward Distribution

Staking reward issuance is changed from the current logic to divert `staking_boost_percent` of rewards to the boost mechanism.

TODO: fill in

## Rationale

The Staking Boost mechanism creates economic incentives for decentralization by
differentially rewarding validators of different sizes.

For small validators, the boost provides an outsized return relative to their
delegation pool size. Consider a minimal validator with only the required
minimum bond: while their pro-rata share of the regular rewards would be
minimal, winning the boost (which occurs with equal probability for all
validators) provides a fixed-size reward independent of stake. This
significantly increases their expected returns and makes them much more
attractive to delegators.

For large validators, the same fixed-size boost becomes insignificant when
divided across their large delegation pool. A validator with outsized voting
power would see only a tiny increase in their effective APY from winning the
boost, as the boost amount would be diluted across their large delegation pool.

This asymmetric effect is intentional: it creates strong incentives for
delegators to stake with smaller validators, as their expected returns will be
much higher, while avoiding disruption to the basic stability of the network by
maintaining most rewards on a pro-rata basis.

The random selection mechanism is chosen for simplicity of implementation while
preserving the desired economic effects.  Rewarding validators only in
expectation also minimizes some potential Sybil issues, as described below.

## Backwards Compatibility

This would be a breaking consensus change, requiring a network upgrade.

## Security Considerations

The Stake Boost mechanism has two primary security considerations:
proposer manipulation and validator sybiling.

A proposer could potentially manipulate the app hash to influence the boost
allocation.  However, this manipulation is unlikely to occur in practice for
three reasons.  First, proposer selection is weighted by stake, so the
proposer at the end of an epoch is likely to be a large validator, for whom
the value of the boost is minimal relative to their pro-rata rewards.
Second, performing manipulation would require developing custom software, whose
development cost likely exceeds the potential reward.  Third, manipulation
would either be a one-off event with minimal benefit, or would be recurrent
and create public evidence of malfeasance, exposing the validator to social
slashing.

The mechanism could incentivize validator sybiling, where validators split
their stake across multiple validator identities to increase their chance of
winning the boost.  However, two factors minimize this in practice.  First,
because the boost value is constant, it provides diminishing returns to large
validators, who have little incentive to sybil.  Second, the validator set
size limit creates a floor on the effectiveness of sybiling.  Small validators
considering whether to split their stake must weigh the potential boost
rewards against the risk that both validators could be pushed out of the
active set by other validators competing for the boost.  While any mechanism
that provides additional support for small validators necessarily creates some
incentive for sybiling, this design minimizes that effect in practice.

## Privacy Considerations

The Stake Boost mechanism operates entirely on public chain data and does not
introduce new privacy considerations beyond those already present in Penumbra's
staking system.

## Copyright

Copyright and related rights waived via [CC0](https://github.com/penumbra-zone/UIPs/blob/main/LICENSE).
