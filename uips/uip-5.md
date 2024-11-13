| uip | 5 |
| - | - |
| title | Outbound Packet Forwarding Middleware Support |
| description | Add configurable memo field to Ics20Withdrawal to support outbound multi-hop ICS20 transfers using Packet Forwarding Middleware |
| author | Ava Howell |
| discussions-to | https://forum.penumbra.zone/t/pre-uip-outbound-packet-forwarding-middleware-support/121 |
| status | Draft |
| type | Standards Track |
| consensus | No |
| created | 2024-11-06 |

## Abstract

This specification adds support for outbound transfers from Penumbra that are routed across multiple interchain hops with the interchain standard IBC Packet Forwarding Middleware (PFM). By adding a user-configurable memo field to the Ics20Withdrawal transaction type, an outbound transaction can specify a multi-chain withdrawal path, greatly simplifying the UX for withdrawals that require a multi-hop interchain path.

## Motivation

The IBC Packet Forwarding Middleware (PFM) enables seamless multi-hop token transfers across IBC-connected chains. This is accomplished through the usage of the memo field in the `FungibleTokenPacketData` struct that is used to encode the details of a transfer. When a multi-hop withdrawal is initiated, the user specifies the details of the route that the packet should take by JSON-encoding a struct inside the FungibleTokenPacketData's memo field. Currently, Penumbra hardcodes an empty string for the memo field in ICS20 transfers, preventing users from specifying the routing information required for PFM. The minimal protocol-level change to support outbound multi-hop packets from penumbra is to add memo support to Ics20Withdrawal actions, allowing users to take advantage of more complex IBC routing paths while maintaining their privacy.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Ics20Withdrawal Changes

The `Ics20Withdrawal` struct and associated protobuf types shall be modified to add a new `ics20_memo` field:

```rust
pub struct Ics20Withdrawal {
    // Existing fields...
    pub amount: Amount,
    pub denom: asset::Metadata,
    pub destination_chain_address: String,
    pub return_address: Address,
    pub timeout_height: IbcHeight,
    pub timeout_time: u64,
    pub source_channel: ChannelId,
    pub use_compat_address: bool,
    
    // New field
    pub ics20_memo: String,
}
```

The `From<Ics20Withdrawal> for pb::FungibleTokenPacketData` impl, which encodes the withdrawal in the ICS-compatible packet data type, SHALL be modified to include the contents of this new field:

```rust
impl From<Ics20Withdrawal> for pb::FungibleTokenPacketData {
    fn from(w: Ics20Withdrawal) -> Self {
        let return_address = match w.use_compat_address {
            true => w.return_address.compat_encoding(),
            false => w.return_address.to_string(),
        };

        pb::FungibleTokenPacketData {
            amount: w.value().amount.to_string(),
            denom: w.denom.to_string(),
            receiver: w.destination_chain_address,
            sender: return_address,
            memo: w.ics20_memo,
        }
    }
}
```

The `ics20_memo` field:
- MAY contain any valid UTF-8 string
- MAY be empty

## Rationale

There are two major parts of Packet Forwarding Middleware support:

- Outbound PFM Support (what this UIP supports): the support for sending packets that can be autonomously routed over multiple intermediate chains before reaching their destination.
- Packet Forwarding Middleware support: the actual forwarding middleware implementation, which runs in the chain's state machine and allows the chain to forward packets sent from other chains.

This UIP implements (1), using a minimal protocol change (adding the configurable memo field). This gives the majority of end-user benefit from PFM support, notably that users can experience superior UX in withdrawing from the Penumbra chain, while avoiding complex protocol development work and assurance. A separate UIP for implementing (2) in the Penumbra IBC stack could be considered in the future.


## Backwards Compatibility

This UIP adds an additional field to the Ics20Withdrawal struct, which would be a breaking change and require a protocol upgrade.

## Test Cases

```rust
#[test]
fn test_ics20_withdrawal_memo() {
    let withdrawal = Ics20Withdrawal {
        amount: Amount::from(1000u64),
        denom: asset::Metadata::dummy(),
        destination_chain_address: "cosmos1...".to_string(),
        return_address: Address::dummy(),
        timeout_height: IbcHeight::new(1, 1000),
        timeout_time: 1000000,
        source_channel: ChannelId::new(0),
        use_compat_address: false,
        ics20_memo: "{\"forward\":{...}".to_string(),
    };
    
    let packet_data: FungibleTokenPacketData = withdrawal.into();
    assert_eq!(packet_data.memo, withdrawal.ics20_memo);
}
```

## Security Considerations

This change would add a new string field, controlled by the user, to the Ics20Withdrawal transaction. On other Cosmos chains, there have been concerns around spam related to very-long ICS20 packet memos. Penumbra's fee system charges a fee based on byte size of the transaction in transaction encoding, so that concern should be partially mitigated by that mechanism.

Clients implementing PFM support should be aware of the following considerations:

1. Address compatibility requirements for PFM refunds are handled at the client layer.
2. Timeout and error handling handling in multi-hop transfers may require specific client-side logic to ensure address compatibility.
3. The memo contents should be validated by clients to ensure they match PFM specifications.

## Copyright

Copyright and related rights waived via [CC0](https://github.com/penumbra-zone/UIPs/blob/main/LICENSE).
