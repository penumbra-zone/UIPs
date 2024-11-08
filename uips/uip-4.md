# UIP: Spend Backreferences

| uip | 4 |
| - | - |
| title | Spend Backreferences |
| description | Spend Backreferences enable improved sync performance |
| author | Jennifer Helsby ([@redshiftzero](https://github.com/redshiftzero)), Henry de Valence ([@hdevalence](https://github.com/hdevalence)), Lúcás Meier ([@cronokirby](https://github.com/cronokirby))|
| discussions-to | <https://forum.penumbra.zone/t/uip-spend-backreferences/110> |
| status | Draft |
| type | Standards Track |
| consensus | Yes |
| created | 2024-11-06 |

## Abstract

This specification introduces a method to improve Penumbra sync speeds by adding additional data that can be used by DAGSync clients. `Spend` actions will contain a new `backref_commitment` field, allowing clients to traverse their transaction graph backwards and quickly recover their entire transaction history.

## Motivation

DAGSync is a graph-aware fast syncing algorithm. A client, upon detecting a single transaction involving them, can check that outputs visible to them are spent or not. If the output is unspent, then they have identified a live note they can potentially spend in the future, else if the output is unspent, they can continue the process forwards in the transaction graph, until they reach unspent notes.

The design of Penumbra currently does not allow traversal backwards through the transaction graph, only forwards. A `Spend` intentionally does not reveal the note being spent, only the nullifier that is revealed. By including on the `Spend` an encrypted reference back to the note commitment being spent, such that only the note owner can view it, we enable DAGSync clients to efficienctly reconstruct the transaction history both backwards and forwards.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Modification to `SpendBody`

The `Spend` action will be augmented with an additional field `backref_commitment` on the `SpendBody`:

```
message SpendBody {
    // A commitment to the value of the input note.
    penumbra.core.asset.v1.BalanceCommitment balance_commitment = 1;
    // The nullifier of the input note.
    penumbra.core.component.sct.v1.Nullifier nullifier = 6;
    // The randomized validating key for the spend authorization signature.
    penumbra.crypto.decaf377_rdsa.v1.SpendVerificationKey rk = 4;
    // NEW: An encryption of the commitment of the input note to the sender's OVK.
    optional bytes backref_commitment = 7;
}
```

Clients MAY populate the `backref_commitment` field with the encrypted note commitment corresponding to the note they are spending. Initially the field will be optional, allowing for a phased adoption period such that clients have time to implement support for `Spend` backreferences.

### Encryption of Spend Backreference

The `backref_commitment` should be encrypted using `ChaCha20-Poly1305`. [RFC-8349](https://datatracker.ietf.org/doc/rfc8439/) specifies that (key, nonce) pairs MUST NOT be reused.

We derive a symmetric key $k$ from the `OutgoingViewingKey` $ovk$ using the BLAKE2b-512 hash function and personalization string `"Penumbra_Backref"`:

```
k = BLAKE2b-512("Penumbra_Backref", ovk)
```

One advantage of using a single key is that we can scan all spends using this key without having to do key derivation each time.

A random 16-byte nonce $n$ will be generated and provided as a prefix in the `backref_commitment` field.

Encryption is performed using the $(k, n)$ tuple and outputs the 32-byte ciphertext of the 32-byte note commitment, and a 16-byte MAC. The transmitted data in the `backref_commitment` field consists of a concatenation of the nonce, ciphertext and MAC:

```
backref_commitment = n || ciphertext || MAC
```

The `backref_commitment` is thus 64 bytes (16 byte nonce + 32 byte ciphertext + 16 byte MAC).

### EffectHash

Currently the `EffectHash` for the `Spend` action is computed as:

`effect_hash = BLAKE2b-512(len(type_url) || type_url || proto_encode(proto))`

where `type_url` is the bytes of a variable-length Type URL defining the proto message, `len(type_url)` is the length of the Type URL encoded as 8 bytes in little-endian  order, and `proto` represents the proto used to represent the effecting data, and `proto_encode` represents encoding the proto message as a vector of bytes.

#### Backwards Compatibility

The `EffectHash` computation is unchanged if the new `backref_commitment` field is not populated. This is the behavior provided by making the field `optional` in the `SpendBody` protocol message. However, if the `backref_commitment` field is populated, then it is included in the `EffectHash` computation per the existing `proto_encode` method as described above.

### Transaction Perspectives and Views

The `TransactionPerspective` and `TransactionView` will be unchanged. The backreference is treated as an internal sync optimization detail.

## Rationale

ZCash has considered a similar approach wherein backwards syncing is enabled using references encoded into the memo fields. Wallets can periodically construct transactions that stuff references to previous transaction hashes into the memo field of the dummy transaction. The advantage of the memo-stuffing approach is that DAGSync-aware clients can populate these fields without a change to the consensus rules. The disadvantage, however, is that the user's transaction history is polluted with dummy transactions, and a client must scan forward to find one of these dummy transactions before it can go backwards.

## Backwards Compatibility

Since the `backref_commitment` field is proposed to be optional, there should be no compatibility issues. The `EffectHash` for a `Spend` will be unchanged if the `backref_commitment` field is absent. Once all clients have added `backref_commitment` support, a future UIP could make the field mandatory.

## Security Considerations

This specification considered several security considerations:

1. Encryption: The symmetric encryption scheme used for `backref_commitment` uses a symmetric key derived from the OVK. Using a random nonce, included as part of the ciphertext, ensures that no duplicate (key, nonce) pairs can appear. Nonces MUST not repeat to ensure this.
2. Malleability prevention: Including `backref_commitment` in the `EffectHash` transaction signing mechanism ensures that the field cannot be replaced by an adversary. If the field is malleable and the adversary knows the client is using DAGSync, an adversary may attempt to force clients to forget or lose funds.

## Copyright

Copyright and related rights waived via [CC0](https://github.com/penumbra-zone/UIPs/blob/main/LICENSE).
