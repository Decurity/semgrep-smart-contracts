# Solidity semgrep rules

In this repository you can find [semgrep](https://semgrep.dev/) rules based on actual DeFi exploits.

## Disclaimer

Currently semgrep supports [Solidity](https://semgrep.dev/docs/language-support/) in `experimental` mode. Some of the rules may not work until Solidity is in `beta` at least.

## Scanning

semgrep + [smart-contract-sanctuary](https://github.com/tintinweb/smart-contract-sanctuary) = ❤️

```shell
$ semgrep --config rules ~/smart-contract-sanctuary-arbitrum/contracts/mainnet
```

## Testing

Each rule is accompanied by an actual vulnerable source code that was targeted by an exploit. Vulnerable lines are marked with `// ruleid: ...`

In case a rule is not yet supported by semgrep, you will find `// todoruleid: ...`

Run tests: 

```shell
$ semgrep --test rules
```

Validate rules: 

```shell
$ semgrep --validate --config rules
```

## Rules

Rule ID | Targets | Description
--- | --- | ---
compound-borrowfresh-reentrancy | Compound, Ola Finance, Hundred Finance, Agave | Function borrowFresh() in Compound performs state update after doTransferOut()
compound-sweeptoken-not-restricted | TUSD, Compound | Function sweepToken is allowed to be called by anyone
erc677-reentrancy | Ola Finance | ERC677 callAfterTransfer() reentrancy
erc777-reentrancy | Bacon Protocol | ERC777 tokensReceived() reentrancy
gearbox-tokens-path-confusion | Gearbox | UniswapV3 adapter implemented incorrect extraction of path parameters
keeper-network-oracle-manipulation | Inverse Finance | Keep3rV2.current() call has high data freshness, but it has low security, an exploiter simply needs to manipulate 2 data points to be able to impact the feed.
basic-oracle-manipulation | Onering Finance, Deus Finance | getSharePrice() can be manipulated via flashloan
redacted-cartel-custom-approval-bug | Redacted Cartel | transferFrom() can steal allowance of other accounts
BETA: arbitrary-low-level-call | Auctus Options, Starstream Finance, BasketDAO, Li Finance | An attacker may perform call() to an arbitrary address with controlled calldata
BETA: basic-arithmetic-underflow | Umbrella Network | Possible arithmetic underflow