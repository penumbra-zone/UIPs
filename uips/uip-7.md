| uip            | 7                                                                         |
| -------------- | ------------------------------------------------------------------------- |
| title          | Noble Forwarding Address Design                                           |
| description    | Specification of generation of Penumbra-linked Noble forwarding addresses |
| author         | Chris Czub <chris@penumbralabs.xyz>                                       |
| discussions-to | <https://forum.penumbra.zone>                                             |
| status         | Draft                                                                     |
| type           | Standards Track                                                           |
| consensus      | No                                                                        |
| created        | 2024-11-11                                                                |

## Abstract

Noble Signerless Forwarding, implemented by Noble as the `x/forwarding` module, provides the capability to permissionlessly create Noble accounts that will automatically transfer deposited funds via IBC to a deterministically derived associated address on another chain. This UIP specifies a mechanism through which Penumbra wallet implementations can produce one-time-use Noble forwarding addresses associated with the wallet's sub-accounts.

## Motivation

Supporting Noble Signerless Forwarding allows Penumbra users to easily interact with services that support Noble, without the service needing to IBC handshake with Penumbra or integrate any Penumbra APIs.

By programmatically producing deterministic one-time-use forwarding addresses, transaction linkability is made more difficult, providing users enhanced privacy by default with straightforward usability.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

Penumbra implementations **SHOULD** implement the address format and registration process as described within this document to ensure cross-client consistency. As this is entirely implemented in the client and non-consensus, this suggestion is unenforceable but **SHOULD NOT** be violated if the client implementation supports registering for Noble Signerless Forwarding.

### Penumbra Noble Forwarding Address Index Format

Every Noble forwarding address has a one-to-one relationship with a Penumbra address. Penumbra addresses used for Noble forwarding use a special address index format to avoid collisions with regular Penumbra addresses:

```
LE32(account) + [0xFF; 10] + LE16(sequence number)
```

The first four bytes **MUST** consist of the little-endian encoding of the associated Penumbra account number.

The next ten bytes (the first ten bytes of the address index's randomizer) **MUST** all be `0xFF`, to indicate the address index is used for Noble.

The final two bytes (the last two bytes of the randomizer) **MUST** be the little-endian encoding of the Noble sequence number.

This address index can then be used with the wallet's FVK to generate a payment address.

Reference Rust implementation:

```rust
fn get_forwarding_address_for_sequence(
    sequence: u16,
    account: Option<u32>,
    fvk: &FullViewingKey,
) -> Address {
    // Noble Randomizer: [0xff; 10] followed by LE16(sequence)
    let mut randomizer: [u8; 12] = [0xff; 12];
    let seq_bytes = sequence.to_le_bytes();
    randomizer[10..].copy_from_slice(&seq_bytes);

    let index = AddressIndex {
        account: account.unwrap_or_default(),
        randomizer,
    };

    let (address, _dtk) = fvk.incoming().payment_address(index.into());

    address
}
```

#### The Sequence Number

Each Penumbra address used for Noble forwarding has two bytes reserved for a sequence number. The sequence number **SHOULD** count from decimal 0 to 65,535. If the maximum sequence number has been reached, it is **OPTIONAL** to reuse random sequence numbers, otherwise the user **SHOULD** be informed to use a different Penumbra account index for subsequent Noble forwarding transactions.

### Noble Address Format

Noble forwarding addresses are deterministically generated from a Penumbra address and the IBC channel associated with Penumbra stored on Noble. The display representation of a Noble forwarding address is as a Bech32 encoding with the prefix `noble` and **MUST BE** 44 characters long.

The input for the Bech32 encoding is a series of bytes consisting of `sha256(sha256("forwarding") + channel + recipient)` with the first twelve bytes discarded.

`channel` is the channel associated with Penumbra on the Noble side (for example, "channel-221") and `recipient` is the Bech32m encoded Penumbra address associated with the forwarding address index.

Reference Rust implementation:

```rust

impl NobleForwardingAddress {
    pub fn bytes(&self) -> Vec<u8> {
        // Based on https://github.com/noble-assets/forwarding/blob/main/x/forwarding/types/account.go#L17
        let channel = self.channel.clone(); // "channel-221"
        let recipient = self.recipient.clone(); // the penumbra address derived from the address index, "penumbra18..."
        let bz = format!("{channel}{recipient}").as_bytes().to_owned();
        let th = Sha256::digest("forwarding".as_bytes());
        let mut hasher = Sha256::new();
        hasher.update(th);
        hasher.update(bz);

        // This constructs the account bytes for the Noble forwarding address
        // Only use bytes 12 and on:
        hasher.finalize()[12..].to_vec()
    }
}

impl Display for NobleForwardingAddress {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        let addr_bytes = &self.bytes();

        write!(
            f,
            "{}",
            bech32str::encode(&addr_bytes, "noble", bech32str::Bech32)
        )
    }
}
```

### Generating the Noble Address

The process to generate the displayed Noble address for a given Penumbra address is:

1. Determine the sequence number
2. Generate the Penumbra address associated with the sequence number
3. Encode the Penumbra address as a Noble forwarding address

### Determining the Sequence Number

The next unused sequence number **SHOULD** be determined via binary search using the response of submitting registration transactions to Noble as an oracle.

If binary search fails and every sequence number has been used, the implementor **MAY** choose to reuse addresses by selecting random sequence numbers, otherwise the user **SHOULD** be informed to use a different account to continue receiving unused forwarding addresses.

Submitting a `RegisterAccount` transaction to Noble results in one of several responses:

- The Noble address needs funds deposited before it can be registered
- The Noble address was previously unregistered as a forwarding address, and registration was successful
- The Noble address was already registered as a forwarding address

In the process of binary search, the first sequence number `n` which results in a "needs funds deposited" response (with the `n-1` sequence number either being previously registered or `-1`) indicates the next sequence number that should be used for forwarding.

### Registering the Noble Forwarding Address

Once the next sequence number has been determined, the user **SHOULD** be displayed the associated Bech32-encoded Noble address, along with a message prompting them to make their deposit to the Noble address.

The client **SHOULD** also begin optimistically submitting `RegisterAccount` transactions to Noble at this time until receiving a successful registration response, with exponential backoff for retries. When the Noble address receives funds, a subsequent `RegisterAccount` transaction should succeed, retries are no longer necessary, and the user can be notified that their forwarding transaction was successful.

## Rationale

### Address Index Format

Using a fixed substring of ten `0xFF` bytes in the address index's randomizer balances unlikelihood of collision with other addresses while allowing `2^16 - 1` one-time-use forwarding addresses to be associated with each account.

### Binary Search of Noble Responses

By performing binary search of Noble responses to `RegisterAccount` transactions it is possible to statelessly determine the next available sequence number. The lack of state tracking makes cross-client compatibility easier to achieve.

## Security Considerations

Noble's permissionless registration process is safe because the receiver address and channel is embedded within the Noble address, meaning Noble forwarding addresses are self authenticating.

## Privacy Considerations

Forwarding address unlinkability was a design consideration that motivated single-use forwarding addresses. A user may use multiple distinct and unlinkable forwarding addresses that all deposit to the same Penumbra account.

Privacy may be degraded and users subject to profiling and linkability if the same forwarding address is used for deposits repeatedly. For this reason, it is not suggested that sequence numbers are re-used, and if they are, users **SHOULD** be notified prior to display and prompted to use a different account.

## Copyright

Copyright and related rights waived via [CC0](https://github.com/celestiaorg/UIPs/blob/main/LICENSE).
