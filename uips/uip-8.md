| uip | 0008 |
| - | - |
| title | Address Attestations |
| description | Address Attestations demonstrate approval of an arbitrary message |
| author | Jennifer Helsby ([@redshiftzero](https://github.com/redshiftzero)), Henry de Valence ([@hdevalence](https://github.com/hdevalence)), Lúcás Meier ([@cronokirby](https://github.com/cronokirby)) |
| discussions-to | URL |
| status | Draft |
| type | Standards Track |
| consensus | No |
| created | 2024-11-22 |

## Abstract

This specification enables an entity controlling a Penumbra address to demonstrate approval of an arbitrary message.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

Since Penumbra addresses are ultimately associated with a spending key, we can:

1. Provide a way to sign an arbitrary message using decaf377-rdsa and a user’s existing spend authorization key.
2. Provide a Zero Knowledge Proof (ZKP) that demonstrates that the address is derived from the spending key, and that the randomized verification key is a correct randomization of the spend verification key.
3. Define a way to bundle up the attestation which consists of a decaf377-rdsa signature, a randomized verification key, a ZKP, and the required public inputs to verify the ZKP.

### Signing

Arbitrary byte messages $m$ will be signed using decaf377-rdsa in the [SpendAuth signature domain](https://protocol.penumbra.zone/main/crypto/decaf377-rdsa.html#spendauth-signatures). The payload $p$ that will be signed is:

$p = \texttt{BLAKE2b-512}(\texttt{b"Penumbra\_AddrAtt"} || m)$

where `BLAKE2b-512` is the BLAKE2b-512 hash function.

The domain separator $\texttt{b"Penumbra\_AddrAtt"}$ is used to prevent a scenario where an address attestation could be used to approve an attacker-controlled message, such as a transaction.

We will demonstrate in the ZKP below that the randomized verification key $rk$ is correctly derived from the spend verification key $ak$ associated with the address.

### Zero Knowledge Proof

The Penumbra address consists of a diversifier $d$, a transmission key $pk_d$, and a clue key $ck_d$. We need to demonstrate in the proof statements that the transmission key $pk_d$ is derived via:

$pk_d = [ivk] B_d$

where $B_d$ is the diversified basepoint for the address, and the incoming viewing key $ivk$ is derived using rate-2 Poseidon hashing:

$ivk = \texttt{hash\_2}(\texttt{from\_le\_bytes}(\texttt{b"penumbra.derive.ivk"}), nk, \texttt{decaf377\_s}(ak)) \mod r$

where $nk$ is the nullifier-deriving key and $ak$ is the spend verification key.

We also need to demonstrate that the randomized verification key $rk$ is a correct randomization of the spend verification key $ak$ given a witnessed randomizer $\alpha$:

$rk = ak + [\alpha]B_{\texttt{SpendAuth}}$

Both of these checks are performed by the existing [SpendProof](https://protocol.penumbra.zone/main/shielded_pool/action/spend.html#spend-zk-snark-statements), so we reuse that ZKP using the following `SpendProof` public and private inputs.

#### Public Inputs

##### Merkle Root

The Merkle root provided should be that of an empty Penumbra state commitment
tree. This is represented by the zero element of the base field (i.e., the additive identity in Fq).

##### Balance Commitment

The balance commitment is derived using a fixed zero blinding factor and a value of zero.

##### Nullifier

The nullifier is derived using a rate-3 Poseidon hash of the note commitment $cm$, nullifier-deriving key $nk$ and domain separator $ds$ derived below:

`nf = hash_3(ds, (nk, cm, pos))`

where the position `pos = 0`. The domain separator `ds` used for nullifier
derivation is computed as:

```
ds = from_le_bytes(BLAKE2b-512(b"penumbra.nullifier")) mod q
```

The resultant nullifier $nf$ is provided as part of the attestation.

##### Randomized Verification Key

The randomized verification key $rk$ is provided as part of the attestation.

#### Witness

##### Merkle Proof of Inclusion

By using a zero value note, the note will be treated as a dummy note in the `SpendCircuit`. This means signers/verifiers do not need to maintain state or provide a valid Merkle authentication path or anchor.

When generating the Merkle proof, clients can use an empty Merkle tree.

##### Note

The witnessed note has zero value, an Rseed consisting of zero bytes [0u8; 32], the fixed asset ID of the Penumbra staking token, and the address that is being attested to.

##### Balance blinding factor

The blinding factor must be zero.

##### Spend authorization randomizer

The randomizer $\alpha$ is used for generating the randomized spend authorization key.

##### Spend verification key

The spend verification key $ak$ corresponds to the spend key that controls the note.

##### Nullifier-deriving key

The nullifier-deriving key $nk$ corresponds to the spend key that controls the note.

### Attestation Format

The attestation $a$ consists of:

* a 64 bytes SpendAuth signature $\sigma$ derived as described above,
* a 32 byte randomized verification key $rk$,
* a 32 byte nullifier $nf$,
* a 192 byte spend ZKP $\pi$.

These four components are concatenated into a 320 byte array and provided to verifiers:

$a = \sigma || rk || nf || \pi$

Verifiers need the verification key for the spend ZKP (provided in the `penumbra-proof-params` crate) and the address being attested to in order to verify this attestation.

### Custody RPCs

The `CustodyService` should be extended with a new RPC method for address attestations:

```protobuf
service CustodyService {
  // ...
  // Create an address attestation for the provided message
  rpc CreateAddressAttestation(CreateAddressAttestationRequest) returns (CreateAddressAttestationResponse);
}

message CreateAddressAttestationRequest {
  // The message to attest to as a google.protobuf.Any
  google.protobuf.Any message = 1;
  // The address to create the attestation with
  Address address = 2;
}

message CreateAddressAttestationResponse {
  // The resulting attestation
  bytes attestation = 1;
}
```

The message field MUST be a `google.protobuf.Any` rather than raw bytes. This allows:
1. Custody backends to decode and understand specific message types they support
2. Wallets to implement domain-specific user confirmation flows (e.g. "You are attesting that you control this address for purpose X")

Custody backends SHOULD reject requests containing message types they don't recognize. This ensures users only approve attestations whose meaning and implications are well-understood by their wallet software. When requesting user confirmation, custody backends SHOULD decode the message and display a purpose-specific confirmation prompt that clearly explains the implications of the attestation to the user.

## Rationale

Using a separate proof for address attestations was considered, but given that the
spend proof already checks the derivation of the randomized verification key as
well as its cryptographic linkage to the address on the note, it was decided to
reuse the existing spend proof. The benefit of this is not having to run another
decentralized setup to generate the proving and verification key for the new proof. The downside is that the attestation is slightly larger,
due to the need to provide the nullifier (32 bytes) as a public input. This
was considered an acceptable tradeoff in order to reuse the existing Penumbra
circuits.

## Backwards Compatibility

No backward compatibility issues found.

## Security Considerations

We use the separate domain separator $\texttt{Penumbra\_AddrAtt}$ for address attestations to prevent a scenario where an address attestation could be used to approve a malicious transaction. This is a concern due to the use of the spend authorization domain of the decaf377-rdsa signature scheme.

For address attestations, the payload $p_{AA}$ being signed consists of:

$p_{AA} = \texttt{BLAKE2b-512}(\texttt{b"Penumbra\_AddrAtt"} || m)$

whereas for transactions, the payload $p_T$ being signed consists of the transaction bytes:

$p_T = \texttt{transaction\_bytes}$

In the [decaf377-rdsa signature scheme](https://protocol.penumbra.zone/main/crypto/decaf377-rdsa.html#decaf377-rdsa), the challenge $c$ is computed as:

$c = H(\texttt{R\_bytes} || \texttt{A\_bytes} || p)$

where $\texttt{R\_bytes}$ is a commitment to a nonce, $\texttt{A\_bytes}$ are the bytes of the verification key, and $p$ is the payload.

For address attestations, the payload $p$ is $p_{AA}$, so the challenge $c$ is:

$c = H(\texttt{R\_bytes} || \texttt{A\_bytes} || \texttt{BLAKE2b-512}(\texttt{b"Penumbra\_AddrAtt"} || m))$

For transactions, the payload $p$ is $p_T$, so the challenge $c$ is:

$c = H(\texttt{R\_bytes} || \texttt{A\_bytes} || \texttt{transaction\_bytes})$

As a result, a malicious actor cannot use an address attestation to approve a transaction and vice versa.

## Privacy Considerations

A randomized verification key is used in a similar manner as on spends: it
prevents the linkage of addresses. While the randomized verification key ($rk$) is included in the attestation, it provides no information about the underlying spend key that is shared across multiple addresses, other than the fact that the $rk$ was correctly derived from the $ak$ associated with the note.

## Copyright

Copyright and related rights waived via [CC0](https://github.com/penumbra-zone/UIPs/blob/main/LICENSE).
