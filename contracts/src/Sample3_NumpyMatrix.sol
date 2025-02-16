// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./MathCoprocessor.sol";

contract Sample3_NumpyMatrix is IMathCoprocessorCallback {
    MathCoprocessor mathCoprocessor;

    int256[3][3] public value;

    constructor(MathCoprocessor _mathCoprocessor) {
        mathCoprocessor = _mathCoprocessor;
    }

    function run() external {
        mathCoprocessor.runExecution("np.outer([1,2,3],[3,4,5])", this);
    }

    function computationComplete(bytes32, bytes memory result) external override {
        value = abi.decode(result, (int256[3][3]));
    }
}
