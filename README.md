# Math Coprocessor

[Cartesi Coprocessor](https://github.com/zippiehq/cartesi-coprocessor) that allows smart contracts to evaluate math functions using Python

## Introduction

Smart contracts written in Solidity often need to perform mathematical operations that are either too resource intensive, or are simply unavailble in Solidity.
A trivial example of the latter is to perform an exponentiataion with a floating-point base (i.e., `x^y` where `x` is not an integer).

This project proposes a simple solution using Cartesi Coprocessors, that allows smart contracts to send an arbitrary Python mathematical expression along with a callback to be called with the ABI-encoded result.
This implementation includes support for [NumPy](https://numpy.org/) and arbitrary ABI encodings.

## Usage

Smart contracts should call the [MathCoprocessor](./contracts/src/MathCoprocessor.sol) contract passing the desired expression to be evaluated, along with an [IMathCoprocessorCallback](./contracts/src/MathCoprocessor.sol#L6) callback to be invoked with the result.

A trivial implementation for integer arithmetic can be found in [Sample1_Integer.sol](./contracts/src/Sample1_Integer.sol).

Expressions are evaluated using the Python [asteval](https://lmfit.github.io/asteval/) safe evaluator, which includes support for many mathematical functions.
Results that are integers, or n-dimensional integer arrays, are automatically ABI-encoded as `int256` or n-dimensional arrays of that type.

If the result is not an integer (e.g., a floating-point number), the expression itself must ABI-encode it explicitly.
To that end, the [encode](https://eth-abi.readthedocs.io/en/stable/encoding.html) method from the [eth-abi](https://github.com/ethereum/eth-abi) Python package is available, and can be called in the expression to provide arbitrary ABI encoding.
An example using fixed-decimals encoding with 6 decimals can be found in [Sample2_FloatDecimals.sol](./contracts/src/Sample2_FloatDecimals.sol).

Finally, [NumPy](https://numpy.org/) support is illustrated in [Sample3_NumptMatrix.sol](./contracts/src/Sample3_NumpyMatrix.sol).

## Building and running

You may use the [cartesi-coprocessor](https://docs.mugen.builders/cartesi-co-processor-tutorial/installation#1-coprocessor-cli) CLI tool to build and run the project.

Fist, start a devnet:

```bash
cartesi-coprocessor start-devnet
```

Then, build and publish the MathCoprocessor back-end there (this will take some time).

```bash
cartesi-coprocessor publish --network devnet
```

Take note of the resulting machine hash, and then deploy the MathCoprocessor contract:

```bash
cartesi-coprocessor deploy --contract-name MathCoprocessor --network devnet --constructor-args 0x95401dc811bb5740090279Ba06cfA8fcF6113778 
<machine-hash>
```

_Note_: the first constructor argument above is the Coprocessor Task Issuer address for devnet.

Finally, deploy any desired sample contracts there too:

```bash
cartesi-coprocessor deploy --contract-name Sample1_Integer --network devnet --constructor-args <math-coprocessor-address>
```

You may then interact with the sample contract using a tool like `cast`.
For instance:

```bash
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
RPC_URL=http://localhost:8545
cast send \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL \
  $SAMPLE1_ADDRESS \
  "run()"
```

And then, after some seconds, check the result:

```bash
cast call \
  --rpc-url $RPC_URL \
  $SAMPLE1_ADDRESS \
  "value()(int256)" 
```
