// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../lib/coprocessor-base-contract/src/CoprocessorAdapter.sol";

interface IMathCoprocessorCallback {
    function computationComplete(bytes32 exprHash, bytes memory result) external;
}

contract MathCoprocessor is CoprocessorAdapter {
    event ComputationComplete(bytes32 exprHash, bytes result);
    
    mapping (bytes32 => IMathCoprocessorCallback[]) callbacks;

    constructor(address _coprocessorAddress, bytes32 _machineHash)
        CoprocessorAdapter(_coprocessorAddress, _machineHash)
    {}

    function runExecution(bytes calldata expr, IMathCoprocessorCallback callback) external {
        callCoprocessor(expr);
        if (callback != IMathCoprocessorCallback(address(0))) {
            callbacks[keccak256(expr)].push(callback);
        }
    }

    function handleNotice(bytes32 exprHash, bytes memory notice) internal override {
        require(notice.length >= 32, "Invalid notice length");
        emit ComputationComplete(exprHash, notice);
        for (uint i = 0; i < callbacks[exprHash].length; i++) {
            callbacks[exprHash][i].computationComplete(exprHash, notice);
        }
        delete callbacks[exprHash];
    }
}
