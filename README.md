# Semgrep rules for smart contracts

In this repository you can find [semgrep](https://semgrep.dev/) rules that look for patterns of vulnerabilities in smart contracts based on actual DeFi exploits as well as gas optimization rules that can be used as a part of the CI pipeline.

## Disclaimer

Currently semgrep supports [Solidity](https://semgrep.dev/docs/language-support/) in `experimental` mode. Some of the rules may not work until Solidity is in `beta` at least.

## Scanning

semgrep + [smart-contract-sanctuary](https://github.com/tintinweb/smart-contract-sanctuary) = ❤️

```shell
$ semgrep --config solidity/security ~/smart-contract-sanctuary-arbitrum/contracts/mainnet
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

## Using in Github Actions

Create `run-semgrep.yaml` in `.github/workflows` with the following contents:
```yaml
# Name of this GitHub Actions workflow.
name: Run Semgrep

on:
  # Scan changed files in PRs (diff-aware scanning):
  pull_request: {}
  # On-demand 
  workflow_dispatch: {}

jobs:
  semgrep:
    # User-definable name of this GitHub Actions job:
    name: Scan
    # If you are self-hosting, change the following `runs-on` value: 
    runs-on: ubuntu-latest

    container:
      # A Docker image with Semgrep installed. Do not change this.
      image: returntocorp/semgrep

    # Skip any PR created by dependabot to avoid permission issues:
    if: (github.actor != 'dependabot[bot]')

    steps:
      # Fetch project source with GitHub Actions Checkout.
      - uses: actions/checkout@v3
      # Fetch semgrep rules
      - name: Fetch semgrep rules
        uses: actions/checkout@v3
        with:
          repository: decurity/semgrep-smart-contracts
          path: rules
      # Run security and gas optimization rules
      - run: semgrep ci --sarif --output=semgrep.sarif || true
        env:
           SEMGREP_RULES: rules/solidity/security rules/solidity/performance
      # Upload findings to GitHub Advanced Security Dashboard
      - name: Upload findings to GitHub Advanced Security Dashboard
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: semgrep.sarif
        if: always()
```

## Security Rules

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
encode-packed-collision | Generic | Hash collision with variable length arguments in abi.encodePacked
openzeppelin-ecdsa-recover-malleable | OpenZeppelin | Potential signature malleability
BETA: basic-arithmetic-underflow | Umbrella Network, Remittance Token | Possible arithmetic underflow
unrestricted-transferownership | Ragnarok Online Invasion | Contract ownership can be transfered by anyone
msg-value-multicall | Sushiswap | Function with constant msg.value can be called multiple times
no-bidi-characters | Generic | The code must not contain any of Unicode Direction Control Characters
delegatecall-to-arbitrary-address | Generic | An attacker may perform delegatecall() to an arbitrary address.
incorrect-use-of-blockhash | Generic | blockhash(block.number) and blockhash(block.number + N) always returns 0.
accessible-selfdestruct | Generic | Contract can be destructed by anyone in $FUNC
no-slippage-check| Generic|  No slippage check in a Uniswap v2/v3 trade
balancer-readonly-reentrancy-getrate | Balancer | getRate() call on a Balancer pool is not protected from the read-only reentrancy.
balancer-readonly-reentrancy-getpooltokens | Balancer | getPoolTokens() call on a Balancer pool is not protected from the read-only reentrancy.
curve-readonly-reentrancy | Curve | get_virtual_price() call on a Curve pool is not protected from the read-only reentrancy.

## Gas Optimization Rules

Rule ID | Description
--- | ---
array-length-outside-loop | Caching the array length outside a loop saves reading it on each iteration, as long as the array's length is not changed during the loop.
init-variables-with-default-value | Explicitly initializing a variable with its default value costs unnecessary gas.
state-variable-read-in-a-loop | Replace state variable reads and writes within loops with local variable reads and writes.
unnecessary-checked-arithmetic-in-loop | A lot of times there is no risk that the loop counter can overflow. Using Solidity's unchecked block saves the overflow checks.
use-custom-error-not-require | Consider using custom errors as they are more gas efficient while allowing developers to describe the error in detail using NatSpec.
use-multiple-require | Using multiple require statements is cheaper than using && multiple check combinations. 
use-nested-if | Using nested is cheaper than using && multiple check combinations.
use-prefix-decrement-not-postfix | The prefix decrement expression is cheaper in terms of gas.
use-prefix-increment-not-postfix | The prefix increment expression is cheaper in terms of gas.
use-short-revert-string | Shortening revert strings to fit in 32 bytes will decrease gas costs for deployment and gas costs when the revert condition has been met.
non-payable-constructor | Consider making costructor payable to save gas.
non-optimal-variables-swap | Consider swapping variables using `($VAR1, $VAR2) = ($VAR2, $VAR1)` to save gas.
inefficient-state-variable-increment | <x> += <y> costs more gas than <x> = <x> + <y> for state variables.

## Best Practices Rules

Rule ID | Description
--- | ---
use-abi-encodecall-instead-of-encodewithselector | To guarantee arguments type safety it is recommended to use `abi.encodeCall` instead of `abi.encodeWithSelector`.
use-ownable2step | By demanding that the receiver of the owner permissions actively accept via a contract call of its own, `Ownable2Step` and `Ownable2StepUpgradeable` prevent the contract ownership from accidentally being transferred to an address that cannot handle it.
