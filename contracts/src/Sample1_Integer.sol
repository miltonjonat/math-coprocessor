// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./MathCoprocessor.sol";

contract Sample1_Integer is IMathCoprocessorCallback {
    MathCoprocessor mathCoprocessor;

    int256 public value;

    constructor(MathCoprocessor _mathCoprocessor) {
        mathCoprocessor = _mathCoprocessor;
    }

    function run() external {
        mathCoprocessor.runExecution("sum([k**3 for k in range(1, 11)])", this);
    }

    function computationComplete(bytes32, bytes memory result) external override {
        value = abi.decode(result, (int256));
    }
}
