| uip | 008 |
| - | - |
| title | Transparent Addresses for External Compatibility |
| description | A 32-byte address format for improved interoperability with external systems |
| author | Jennifer Helsby ([@redshiftzero](https://github.com/redshiftzero)), Henry de Valence ([@hdevalence](https://github.com/hdevalence)), Lúcás Meier ([@cronokirby](https://github.com/cronokirby)) |
| discussions-to | <https://forum.penumbra.zone/t/pre-uip-transparent-addresses/140> |
| status | Draft |
| type | Standards |
| consensus | Yes |
| created | 2024-12-10 |

## Abstract

This UIP introduces transparent addresses ("t-addresses"), a 32-byte Bech32 address format designed for maximum compatibility with external systems while maintaining convertability to full Penumbra addresses.

## Motivation

Recent compatibility issues with external systems (e.g., Noble's USDC integration) have highlighted the need for a maximally compatible address format. While the correct long-term solution is full support for Penumbra's native addresses, a shorter address format can serve as an immediate solution and future-proof escape hatch for similar issues. Penumbra's native addresses have two major differences from most other addresses in the Cosmos ecosystem, in that:

1. They are longer: 80 bytes of data (144 bytes encoded).
2. They use Bech32m encoding, instead of Bech32.

Transparent addresses are 32 bytes long, and use Bech32 encoding for maximum compatibility with external systems.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Address Format

The current Penumbra address format consists of a:

* 16-byte diversifier $d$,

* 32-byte transmission key $pk_d$, and

* 32-byte clue key $ck_d$.

The diversifier is generated by encrypting a 16-byte _address index_ which
consists of:

* 4 byte account index, the default account index being 0,

* 12 byte randomizer

The diversifier $d$ is then used to derive the diversified basepoint $B_d$ using
decaf377 hash-to-group $H_{\mathbb{G}}^{d}$:

$B_d = H_{\mathbb{G}}^{d}(d)$

This diversified basepoint is used to to derive the transmission key $pk_d$:

$pk_d = [ivk] B_d$

The new address format, the _transparent address_, consists only of the 32 byte transmission key. It is encoded using the `tpenumbra` human-readable prefix.

The transmission key for the transparent address is derived using the diversifier
corresponding to all zero bytes. Note that during scanning, the wallet scans
for incoming messages using the Incoming Viewing Key (IVK), and thus detects
all messages for all transmission keys corresponding to that IVK.

### Generation

We define the diversifier $d_0$ for the transparent address to be the zero ciphertext `[0u8; 16]`.

We derive the diversified basepoint $B_{d_0}$ using decaf377 hash-to-group $H_{\mathbb{G}}^{d}$:

$B_{d_0} = H_{\mathbb{G}}^{d_0}​(d_0)$

The Incoming Viewing Key $ivk$ and diversified basepoint $B_{d_0}$ are used to derive the transmission key $pk_{d_0}$:

$pk_{d_0} = [ivk] B_{d_0}$

This 32-byte transmission key $pk_{d_0}$ is then encoded with Bech32 with the `tpenumbra` human-readable prefix.

### Transparent Address Decoding Rules

When decoding a transparent address to its full Penumbra address:

1. The diversifier MUST be set to 16 zero bytes

2. The transmission key MUST be set to the transmission key of the transparent address

3. The clue key MUST be set to the identity element

### Diversifier Decryption

The diversifier decryption is modified as follows:

The zero ciphertext `[0u8; 16]` is defined to correspond to the address index
corresponding to the default account index 0, with no randomizer.

The implications of this are that the valid diversifiers for the
default account are:

* 1 special case diversifier: the zero ciphertext (`[0u8; 16]`)

* $2^{96}$ diversifiers that normally decrypt to the address index for the default account, i.e. those that have the first four bytes equal to `[0u8; 4]` and any randomizer

Note that if a null diversifier happened by chance - as the encryption of some address index $a$ - it will in the future be interpreted as the address index for the default account 0 instead of $a$. The probability of this event is astronomically low, $1/2^{128}$.

### Fuzzy Message Detection (FMD)

Transparent addresses are incompatible with the FMD feature of the Penumbra protocol, which enables a user to delegate a probabalistic detection capability to a third party. This is considered acceptable since other scanning improvements such as Spend Backreferences result in clients not needing to detect every transaction. Using Spend Backreferences, clients can efficiently reconstruct their entire transaction history from a single transaction, and are expected primarily to be using shielded Penumbra addresses instead of transparent addresses.

### Changes to `Ics20Withdrawal` Action

The `Ics20Withdrawal` action is modified to:

1. Add a new boolean field `use_transparent_address`

2. Deprecate the existing `use_compat_address` field

When the `use_transparent_address` field is true:

* Clients MUST set the `return_address` field to the transparent address.
* During transaction validation, the diversifier $d$ MUST be set to the zero ciphertext `[0u8; 16]` and the clue key $ck_d$ MUST be set to the identity element.

## Rationale

The design prioritizes:

1. Maximum external compatibility through fixed-size 32-byte addresses

2. Seamless conversion to full Penumbra addresses

3. Minimal changes to the core protocol

The tradeoff of having only one transparent address per wallet is
accepted as the cost of compatibility with external systems.

## Backwards Compatibility

The modification to diversifier decryption means that if a null diversifier
happened by chance, it will in the future be interpreted as the address index for the default account.
This is accepted since the probability is astronomically low, $1/2^{128}$.

## Test Cases

Transparent address:
`tpenumbra1y6k3hlmtf26w3hnwfka9wn28enytp5g0pd783ahqcradfx4qmy9qnxvspz`
Full Penumbra address:
`penumbra17fzq5lwdls9dsmy0j5kj7ega4vrcpgayvw5e7fxedkmhkuft2zy04ug8z80r9tcptq8xxt8nm0qcvpf6u3cgxdjl22zsu2x09rglwftj5rlup2lj584lvlw6t3sxdvsmk9vfly`

## Security Considerations

The primary implication of this change are the privacy concerns of transparent addresses, discussed in the section below.

## Privacy Considerations

The primary privacy issue is the linkability of transactions when the same wallet
is used for multiple IBC deposits or withdrawals. This occurs because there is
only one transparent address per wallet, and so any transactions that use the
same transparent address are linked. This can be mitigated by transferring funds
to separate wallets, but this is inconvenient for users. Implementations SHOULD
provide a warning to users when they are about to use a transparent address for
an IBC transfer, and clearly communicate the privacy implications of using a
transparent address. Transparent addresses were named as such to make
this privacy issue explicit.

## Copyright

Copyright and related rights waived via [CC0](https://github.com/penumbra-zone/UIPs/blob/main/LICENSE).