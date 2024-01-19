# Single Keccak Create3

This is a different implementation of `CREATE3` that only requires a single keccak256 hash to calculate deployed address. 

## How it works

To achieve this, before deploying a proxy, we `SSTORE2.write` the final deployed bytecode from the deployer and store a pointer to the storage contract in the deployer. The proxies deployed from the deployer will do a `SSTORE2.read` on `CALLER.pointer` to get the final deployed bytecode and return that in its constructor.

We use a different SSTORE2 implementation here, using CREATE2 instead of CREATE under the hood. This bumps up costs slightly for the first deployment, but on the 2nd+ deployment of the same contract we get significant savings.

Because of how this works, contract constructors are never run. It's highly recommended for constructor logic to be in an `initializer` function instead. See the section on safety below.

## Gas

Gas estimates with Solady's CREATE3 are in [GasComparison.t.sol](./test/GasComparison.t.sol). Disclaimer: Gas values are measured using foundry and will be inaccurate so this should only be used as a ballpark estimate.  

Cost of deploying an ERC20:  
Single Keccak Create3, cached contract + no storage: 636k  
Solady CREATE3: 732k  
Single Keccak Create3, cached contract + storage: 810k  
Single Keccak Create3, new contract + no storage: 1.26m  
Single Keccak Create3, new contract + storage: 1.44m  

## Safety

Deployments using this proxy bypass all constructor logic and is significantly less safe than regular deployments. The danger here can largely be mitigated via adding tests to foundry deploy scripts - see example in [SafeDeployPatternDemo](./script/SafeDeployPatternDemo.s.sol).

## Acknowledgements

A significant amount of assembly logic was lifted from [Solady](https://github.com/Vectorized/solady). 

## Future Extensions

1. Utilizing SSTORE or TSTORE instead of another SSTORE2 for `storageArgs`
2. We currently cache deployed bytecode, this means deploying a second contract a different immutable variable wouldn't count as 2nd+ deployment. Can consider doing it like how solidity constructors set up immutable vars and have the proxy take in arrays of memory arguments and memory locations of immutable args