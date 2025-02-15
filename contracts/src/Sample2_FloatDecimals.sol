// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./MathCoprocessor.sol";

contract Sample2_FloatDecimals is IMathCoprocessorCallback {
    MathCoprocessor mathCoprocessor;

    struct FloatDecimals {
        int256 integer;
        uint8 decimals;
    }
    FloatDecimals public value;

    constructor(MathCoprocessor _mathCoprocessor) {
        mathCoprocessor = _mathCoprocessor;
    }

    function run() external {
        mathCoprocessor.runExecution("x = log(4) ** log(3); encode(['int256','uint8'], [round(x * 10**6), 6])", this);
    }

    function computationComplete(bytes32, bytes memory result) external override {
        (value.integer, value.decimals) = abi.decode(result, (int256, uint8));
    }
}
