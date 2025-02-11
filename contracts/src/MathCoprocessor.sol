// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../lib/coprocessor-base-contract/src/CoprocessorAdapter.sol";

contract MathCoprocessor is CoprocessorAdapter {
    event ComputationComplete(bytes32 exprHash, uint256 result);

    constructor(address _coprocessorAddress, bytes32 _machineHash)
        CoprocessorAdapter(_coprocessorAddress, _machineHash)
    {}

    function runExecution(bytes calldata expr) external {
        callCoprocessor(expr);
    }

    function handleNotice(bytes32 exprHash, bytes memory notice) internal override {
        require(notice.length >= 32, "Invalid notice length");
        (uint256 result) = abi.decode(notice, (uint256));
        emit ComputationComplete(exprHash, result);
    }
}
