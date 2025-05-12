# UIP: Encrypted LP metadata

| uip | UIP-9 |
| - | - |
| title | Encrypted Position metadata |
| description | Adds contextual information about bundles of positions |
| author | Erwan Or ([@erwanor](https://github.com/erwanor)), Lúcás Meier ([@cronokirby](https://github.com/cronokirby))
| discussions-to | https://forum.penumbra.zone/t/uip-encrypted-lp-metadata/185 |
| status | Draft |
| type | Standards Track |
| consensus | [Yes/No] |
| created | May 10th, 2025 |

## Abstract

This UIP introduces an encrypted `position_metadata` field for `PositionOpen` actions, enabling private self-communication of contextual information about liquidity positions. The encrypted metadata is only visible to the position creator, and can be automatically synchronized across devices.

## Motivation

Penumbra liquidity positions can be combined to express complex trading strategies and approximate arbitrary CFMMs. For instance, a DEX frontend might generate a bundle of positions that approximate a constant-product market maker ("UniswapV2"). These positions constitute a passive strategy persisting on-chain until withdrawal.

However, without metadata, these related positions appear indistinguishable from other unrelated positions. This limits usability when managing multiple strategies or bundles simultaneously.

By adding encrypted position metadata, we enable view services to privately index a user's positions based on strategy type and bundle identifiers, facilitating coherent rendering and management of position collections.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Definition of position metadata

We define a fixed-size `PositionMetadata` message allowing private categorization of liquidity positions. The message consists of:

1. A 32-bit strategy identifier
2. A 32-bit bundle identifier

This design permits a single subaccount to manage up to 2^32 - 1 distinct bundles per strategy type. The fixed-size wire format is important for privacy, as it prevents leaking information about the metadata contents through ciphertext length side channels.

Note that supporting larger numbers of bundles is unnecessary, as users can generate arbitrary numbers of subaccounts to organize positions when needed.

**Protobuf definition**

```protobuf
// Metadata about a position, or bundle of positions.
// See UIP-9 for more details.
message PositionMetadata {
  // A strategy tag for the bundle, convention:
  // 0x1 - Skip
  // 0x2 - Arbitrary
  // 0x3 - Linear
  // 0x4 - Stable
  // ... every other tags are unreserved.
  fixed32 strategy = 1;
  // A unique identifier for the bundle this position belongs to.
  fixed32 identifier = 2;
}

```

Strategy and identifiers are user-scoped: they are interpreted only by the holder of the originating OVK and have no global registry besides the base cases defined in this UIP.

To allow distinguisability between bundles, clients SHOULD select identifiers uniformly at random. To ensure the metadata is valid, clients MUST specify non-zero values for both `strategy` and `id`.

To prevent metadata size leakage, clients MUST ensure that the serialized PositionMetadata is exactly 10 bytes or absent. See transaction parsing rules for more details.


### Modifications to the `PositionOpen` action

An `encrypted_metadata` field is added to the `PositionOpen` action.

```protobuf=
message PositionOpen {
	// Contains the data defining the position, sufficient to compute its `PositionId`.
	//
	// Positions are immutable, so the `PositionData` (and hence the `PositionId`)
	// are unchanged over the entire lifetime of the position.
	Position position = 1;
	// NEW: Position metadata encrypted to the user's OVK. 
	bytes encrypted_metadata = 2;
}
```

Clients MAY populate the `encrypted_metadata` field with an authenticated encryption of a `PositionMetadata` message.

To prevent information leakage through the size of the metadata, transaction validation MUST enforce that `encrypted_metadata` is either absent or exactly 50 bytes (24-byte nonce, 10 bytes of ciphertext plus a 16-bytes authentication tag).

### `PositionMetadataKey`

We define a symmetric key `PositionMetadataKey` derived from the user's outgoing viewing key using a personalization string for our domain-separated hash construction:

```
pmk := BLAKE2b_256("Penumbra_PosMeta", ovk)
```

This follows the pattern used by the `BackreferenceKey` in [UIP-4](https://uips.penumbra.zone/uip-4.html#backreference-key), and other symmetric key usage in the protocol.

### Metadata encryption


We employ authenticated encryption using XChaCha20-Poly1305 as specified in [RFC8439](https://datatracker.ietf.org/doc/rfc8439/), with the following parameters:

- Key: The derived `PositionMetadataKey`
- Nonce: A unique 24-byte value
- Associated data: None
- Plaintext: The serialized `PositionMetadata` (10 bytes)

The encryption operation produces:
```
(ciphertext, auth_tag) = XChaCha20_Poly1305_Encrypt(pmk, nonce, metadata)
```

The `encrypted_metadata` field is then constructed as:
```
encrypted_metadata = nonce || ciphertext || auth_tag
```

Clients SHOULD use the last 24 bytes of the associated position's id.

```
nonce := Blake2b_256(Position)[8..]
```
Clients MAY use random nonces if separation of concerns between `Position` nonces and metadata nonces is preferred.

### Backwards compatibility
This UIP builds on the compatibility framework established in UIP-4, using the `EffectHash` mechanism to ensure consistency across client versions.

#### Effect hash construction

The `EffectHash` of a transaction action binds to both its type and serialized content:

```
effect_hash = BLAKE2b-256(len(type_url) || type_url || proto_encode(proto))
```

#### Hash consistency across versions

The `encrypted_metadata` field is added as an optional field to the `PositionOpen` action. When this field is absent, it is omitted entirely from the serialized protobuf. This ensures that:

1. Old clients and upgraded nodes compute identical effect hashes for `PositionOpen` actions without metadata
2. Upgraded clients and upgraded nodes always compute consistent effect hashes

This design maintains backward compatibility while allowing gradual adoption of the metadata feature.

**Transaction Perspective and Views**

To support viewing decrypted metadata, client implementations will need to extend the `TransactionPerspective` with the appropriate key material.

1. Add the `PositionMetadataKey` to `TransactionPerspective`
2. Extend the `PositionOpenView` to support two variants:
   - A view with decrypted, visible metadata when the key is available
   - A view with opaque metadata when the key is unavailable

This extension can be implemented in client software without requiring chain-level consensus changes.


## Security considerations

This specification considered several security considerations:

### Nonce reuse risks

Our  scheme uses XChaCha20-Poly1305 with a 24-byte nonce as specified in `draft-irtf-cfrg-xchacha-01`, as of writing this UIP, no RFC has been finalized. With random nonce generation, the birthday bound gives a collision probability of approximately q^2 * 2^-192 after encrypting q messages. Encrypting up to ten billion entries gives negligible (2^-37) accidental collision probability.

This provides a comfortable security margin for all possible user stories.

### Malleability prevention

The `EffectHash` mechanism binds the entire action content, including the encrypted metadata, to the transaction signature. This prevents any malleability attacks where an adversary might attempt to replace or modify the encrypted metadata, as such modifications would invalidate the transaction signature.

## Privacy considerations

### Metadata presence as a distinguisher

The presence or absence of encrypted metadata creates a potential distinguisher between different client implementations or user behaviors. This could reduce anonymity set sizes by allowing observers to partition transactions based on this distinguisher.

A future protocol upgrade should address this by requiring all `PositionOpen` actions to include encrypted metadata, using the skip strategy tag as a sentinel value for positions that can skip metadata tracking. This would eliminate the distinguisher at the cost of slightly increased transaction size for `PositionOpen`s (+ 50 bytes).

### Fixed-size metadata

Our design ensures that encrypted metadata has a fixed size of exactly 50 bytes when present. This prevents information leakage through size side channels - an observer cannot distinguish between different types of strategies or bundle identifiers based on the size of the encrypted data.

The combination of authenticated encryption and fixed-size ciphertext ensures that no information about the position metadata is leaked to anyone without access to the position creator's outgoing viewing key.


## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
