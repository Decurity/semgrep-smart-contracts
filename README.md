# Semgrep rules for smart contracts

In this repository you can find [semgrep](https://semgrep.dev/) rules that look for patterns of vulnerabilities in smart contracts based on actual DeFi exploits.

## Disclaimer

Currently semgrep supports [Solidity](https://semgrep.dev/docs/language-support/) in `experimental` mode. Some of the rules may not work until Solidity is in `beta` at least.

## Scanning

semgrep + [smart-contract-sanctuary](https://github.com/tintinweb/smart-contract-sanctuary) = ❤️

```shell
$ semgrep --config solidity ~/smart-contract-sanctuary-arbitrum/contracts/mainnet
```

## Testing

Each rule is accompanied by an actual vulnerable source code that was targeted by an exploit. Vulnerable lines are marked with `// ruleid: ...`

In case a rule is not yet supported by semgrep, you will find `// todoruleid: ...`

Run tests: 

```shell
$ semgrep --test solidity
```

Validate rules: 

```shell
$ semgrep --validate --config solidity
```

## Rules

Rule ID | Targets | Description
--- | --- | ---
compound-borrowfresh-reentrancy | Compound, Ola Finance, Hundred Finance, Agave | Function borrowFresh() in Compound performs state update after doTransferOut()
compound-sweeptoken-not-restricted | TUSD, Compound | Function sweepToken is allowed to be called by anyone
erc20-public-transfer | Creat Future | Custom ERC20 implementation exposes _transfer() as public
erc20-public-burn | HospoWise | Anyone can burn tokens of other accounts
erc677-reentrancy | Ola Finance | ERC677 callAfterTransfer() reentrancy
erc777-reentrancy | Bacon Protocol | ERC777 tokensReceived() reentrancy
erc721-reentrancy | Hype Bears | ERC721 onERC721Received() reentrancy
erc721-arbitrary-transferfrom | Distortion Genesis | Custom ERC721 implementation lacks access control checks in _transfer()
gearbox-tokens-path-confusion | Gearbox | UniswapV3 adapter implemented incorrect extraction of path parameters
keeper-network-oracle-manipulation | Inverse Finance | Keep3rV2.current() call has high data freshness, but it has low security, an exploiter simply needs to manipulate 2 data points to be able to impact the feed.
basic-oracle-manipulation | Onering Finance, Deus Finance | getSharePrice() can be manipulated via flashloan
redacted-cartel-custom-approval-bug | Redacted Cartel | transferFrom() can steal allowance of other accounts
rigoblock-missing-access-control | RigoBlock | setMultipleAllowances() is missing onlyOwner modifier
oracle-price-update-not-restricted | Rikkei Finance, Aave | Oracle price data can be submitted by anyone
superfluid-ctx-injection | Superfluid | A specially crafted calldata may be used to impersonate other accounts
tecra-coin-burnfrom-bug | Tecra Coin | Parameter "from" is checked at incorrect position in "_allowances" mapping
arbitrary-low-level-call | Auctus Options, Starstream Finance, BasketDAO, Li Finance | An attacker may perform call() to an arbitrary address with controlled calldata
sense-missing-oracle-access-control | Sense Finance | Oracle update is not restricted in onSwap(), rule by [Arbaz Kiraak](https://twitter.com/ArbazKiraak)
proxy-storage-collision | Audius | Proxy declares a state var that may override a storage slot of the implementation
uniswap-callback-not-protected | Generic | Uniswap callback is not protected
BETA: basic-arithmetic-underflow | Umbrella Network, Remittance Token | Possible arithmetic underflow

## Not greppable incidents

I haven't come up with rules for the following incidents:

- Fantasm ([description](https://twitter.com/RugDocIO/status/1501629678993518599), [contract](https://ftmscan.com/address/0x880672ab1d46d987e5d663fc7476cd8df3c9f937))
- Paraluni ([description](https://slowmist.medium.com/paraluni-incident-analysis-58be442a4f99), [contract](https://www.contract-diff.xyz/?address=0xa386f30853a7eb7e6a25ec8389337a5c6973421d&chain=1))
- Flurry Finance ([description](https://twitter.com/CertiKTech/status/1496298929599746048), [contract](https://bscscan.com/address/0x5085c49828b0b8e69bae99d96a8e0fcf0a033369))