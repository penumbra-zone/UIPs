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

This specification introduces a method to improve Penumbra sync speeds by adding additional data that can be used by DAGSync clients. `Spend` actions will contain a new `encrypted_backref` field, allowing clients to traverse their transaction graph backwards and quickly recover their entire transaction history.

## Motivation

DAGSync is a graph-aware fast syncing algorithm. A client, upon detecting a single transaction involving them, can check that outputs visible to them are spent or not. If the output is unspent, then they have identified a live note they can potentially spend in the future, else if the output is unspent, they can continue the process forwards in the transaction graph, until they reach unspent notes.

The design of Penumbra currently does not allow traversal backwards through the transaction graph, only forwards. A `Spend` intentionally does not reveal the note being spent, only the nullifier that is revealed. By including on the `Spend` an encrypted reference back to the note commitment being spent, such that only the note owner can view it, we enable DAGSync clients to efficienctly reconstruct the transaction history both backwards and forwards.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Modification to `SpendBody`

The `Spend` action will be augmented with an additional field `encrypted_backref` on the `SpendBody`:

```
message SpendBody {
    // A commitment to the value of the input note.
    penumbra.core.asset.v1.BalanceCommitment balance_commitment = 1;
    // The nullifier of the input note.
    penumbra.core.component.sct.v1.Nullifier nullifier = 6;
    // The randomized validating key for the spend authorization signature.
    penumbra.crypto.decaf377_rdsa.v1.SpendVerificationKey rk = 4;
    // NEW: An encryption of the commitment of the input note to the sender's OVK.
    bytes encrypted_backref = 7;
}
```

Clients MAY populate the `encrypted_backref` field with the encrypted note commitment corresponding to the note they are spending.

Transaction parsing rules MUST ensure the length of the `encrypted_backref` bytes field on a `Spend` has either 48 or zero bytes in length.

This allows for a phased adoption period such that clients have time to implement support for `Spend` backreferences. See the [Backwards Compatibility section](#backwards-compatibility) for further discussion.

### Encryption of Spend Backreference

The `encrypted_backref` should be encrypted using `ChaCha20-Poly1305`. [RFC-8349](https://datatracker.ietf.org/doc/rfc8439/) specifies that (key, nonce) pairs MUST NOT be reused.

We derive a new symmetric key, the Backreference Key $brk$, from the `OutgoingViewingKey` $ovk$ using the BLAKE2b-512 hash function and personalization string `"Penumbra_Backref"`:

```
brk = BLAKE2b-512("Penumbra_Backref", ovk)
```

One advantage of using a single key is that we can scan all spends using this key without having to do key derivation each time.

The first 12 bytes of the nullifier `nf` on the spend is used as the nonce $n$:

```
n = nf[:12]
```

There is a single nullifier per spend/note, thus this nonce will not repeat, satisfying the requirement that no (key, nonce) pair be reused for encrypting different plaintexts.

Encryption of the 32-byte note commitment $cm$ is performed using `ChaCha20-Poly1305` with the $(brk, n)$ tuple and outputs the 32-byte ciphertext $c$ and a 16-byte MAC:

```
(c, MAC) = ChaCha20-Poly1305(brk, n, cm)
```

The transmitted data in the `encrypted_backref` field consists of a concatenation of the ciphertext $c$ and MAC:

```
encrypted_backref = c || MAC
```

The `encrypted_backref` is thus 48 bytes (32 byte ciphertext + 16 byte MAC).

### EffectHash

Currently the `EffectHash` for the `Spend` action is computed as:

`effect_hash = BLAKE2b-512(len(type_url) || type_url || proto_encode(proto))`

where `type_url` is the bytes of a variable-length Type URL defining the proto message, `len(type_url)` is the length of the Type URL encoded as 8 bytes in little-endian  order, and `proto` represents the proto used to represent the effecting data, and `proto_encode` represents encoding the proto message as a vector of bytes.

#### `EffectHash` Backwards Compatibility

The `EffectHash` computation is unchanged if the new `encrypted_backref` field is not populated. The `EffectHash` computation is a domain-separated hash of the Protobuf encoding of the `Spend` message. Protobuf encoding rules skip encoding default values. The new `encrypted_backref` field is a `bytes` field with a default value of an empty array, thus if it is not populated, it will be skipped, ensuring backwards compatibility.

For spends that populate a 48-byte `encrypted_backref` field, the field will be included in the `EffectHash` per the existing `proto_encode` method as described above.

### Transaction Perspectives and Views

The `TransactionPerspective` and `TransactionView` will be unchanged. The backreference is treated as an internal sync optimization detail.

## Rationale

ZCash has considered a similar approach wherein backwards syncing is enabled using references encoded into the memo fields. Wallets can periodically construct transactions that stuff references to previous transaction hashes into the memo field of the dummy transaction. The advantage of the memo-stuffing approach is that DAGSync-aware clients can populate these fields without a change to the consensus rules. The disadvantage, however, is that the user's transaction history is polluted with dummy transactions, and a client must scan forward to find one of these dummy transactions before it can go backwards.

### Non-Unique Note Commitments

Note commitments correspond to the contents of a note, not to individual note instances. If two note instances have the same exact contents, they will share the same note commitment. This requires two notes to be generated with the same `Rseed`: for honest users the `Rseed` is generated randomly, but an honest user may nevertheless receive two notes constructed with the same `Rseed`. However, the Penumbra protocol allows this possibility of duplicate note commitments, so during syncing clients should allow the possibility of selecting a note commitment that appears in multiple transaction IDs. In the rare case that the `encrypted_backref` field refers to a note commitment that is a duplicate note commitment, the client should continue syncing using each transaction ID.

## Backwards Compatibility

There should be no compatibility issues since the `EffectHash` for a `Spend` will be unchanged if the `encrypted_backref` field is absent. Once all clients have added `encrypted_backref` support, a future UIP could make the field mandatory.

## Security Considerations

This specification considered several security considerations:

1. Encryption: The symmetric encryption scheme used for `encrypted_backref` uses a symmetric key derived from the OVK. Using a nonce derived from the nullifier field that is guaranteed to be unique for double-spend protection, we ensure that no duplicate (key, nonce) pairs can appear.
2. Malleability prevention: Including `encrypted_backref` in the `EffectHash` transaction signing mechanism ensures that the field cannot be replaced by an adversary. If the field is malleable and the adversary knows the client is using DAGSync, an adversary may attempt to force clients to forget or lose funds.

## Privacy Considerations

Adding the `encrypted_backref` field introduces a potential distinguisher for client software based on the presence or absence of the field. The privacy leak is that the field signals whether a user has updated to a specific client version or higher, i.e. one that supports `encrypted_backref`. No other information is revealed. The privacy impact can be mitigated entirely by requiring `encrypted_backref` for all spend actions in a future protocol upgrade once there is broad client support.

The design decision to include `encrypted_backref` reflects the fact that the information leakage is minor, and is justified to improve sync performance, reducing user friction and improving protocol adoption and thus the anonymity set of the network.

## Copyright

Copyright and related rights waived via [CC0](https://github.com/penumbra-zone/UIPs/blob/main/LICENSE).
