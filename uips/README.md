# Penumbra Improvement Proposal (UIP) process

Read [UIP-1](./uip-1.md) for information on the UIP process.

## Meetings

|  №  | Date | Agenda | Notes | Recording |
| :-: | :--: | :----: | :---: | :-------: |
|     |      |        |       |           |

## Penumbra Improvement Proposals (UIPs)

|        №        |                        Title                         |                   Author(s)                    |
| :-------------: | :--------------------------------------------------: | :--------------------------------------------: |
| [1](./uip-1.md) | Penumbra Improvement Proposal Process and Guidelines | Henry de Valence <hdevalence@penumbralabs.xyz> |
| [2](./uip-2.md) |                 UIP Editor Handbook                  | Henry de Valence <hdevalence@penumbralabs.xyz> |
| [3](./uip-3.md) |       Process for Approving External Resources       | Henry de Valence <hdevalence@penumbralabs.xyz> |
| [4](./uip-4.md) | Spend Backreferences |  Jennifer Helsby ([@redshiftzero](https://github.com/redshiftzero)), Henry de Valence ([@hdevalence](https://github.com/hdevalence)), Lúcás Meier ([@cronokirby](https://github.com/cronokirby)) |
| [5](./uip-5.md) | Outbound Packet Forwarding Middleware Support | Ava Howell <ava@penumbralabs.xyz> |
| [6](./uip-6.md) | App Version Safeguard | Conor Schaefer ([@conorsch](https://github.com/conorsch)), Lucas Meier ([@cronokirby](https://github.com/cronokirby)) |
| [7](./uip-7.md) | Stake Boost | Henry de Valence ([@hdevalence](https://github.com/hdevalence)) |

## Contributing

Files in this repo must conform to [markdownlint](https://github.com/DavidAnson/markdownlint). Install [markdownlint](https://github.com/DavidAnson/markdownlint) and then run:

```shell
markdownlint --config .markdownlint.yaml '**/*.md'
```

### Running the site locally

Prerequisites:

1. Install [Rust](https://www.rust-lang.org/tools/install)
1. Install [mdbook](https://rust-lang.github.io/mdBook/guide/installation.html)

```sh
mdbook serve -o
```
