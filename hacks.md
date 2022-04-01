# Uniswap
## Gearbox
Platform: Ethereum
Link: [@nnez](https://medium.com/@nnez/different-parsers-different-results-acecf84dfb0c)
`_extractTokens()` takes last 20 bytes as tokenB, while `decodeFirstPool()` in Uniswap v3 takes from offset 23

# Compound
## Ola.finance
Platform: Fuse
Link: [Peckshield](https://twitter.com/peckshield/status/1509431646818234369) [BlockSec](https://twitter.com/blocksecteam/status/1509466576848064512?t=iT8Xd8s9b3ActYp_wYeHKQ)
`doTransferOut` expects only ERC20 underlying token. ERC677/ERC777 will callback msg.sender on `transfer()`, built-in reentrancy.

## TUSD
Platform: Ethereum
Link: [Chainsecurity](https://medium.com/chainsecurity/trueusd-compound-vulnerability-bc5b696d29e2)
`underlying` token should have only one entrypoint. Otherwise `sweepToken()` can affect debt price (disputed by [cmichel](https://twitter.com/cmichelio/status/1506134576607141889)).