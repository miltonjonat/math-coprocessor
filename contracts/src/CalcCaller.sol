// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../lib/coprocessor-base-contract/src/CoprocessorAdapter.sol";

contract CalcCaller is CoprocessorAdapter {
    event CalcComplete(uint256 result);
    // event CalcComplete(bytes expr, uint256 result);

    constructor(address _coprocessorAddress, bytes32 _machineHash)
        CoprocessorAdapter(_coprocessorAddress, _machineHash)
    {}

    function runExecution(bytes calldata expr) external {
        callCoprocessor(expr);
    }

    function handleNotice(bytes32 payloadHash, bytes memory notice) internal override {
        require(notice.length >= 32, "Invalid notice length!");
        (uint256 result) = abi.decode(notice, (uint256));
        emit CalcComplete(result);
        // (uint256 result, bytes memory expr) = abi.decode(notice, (uint256, bytes));
        // emit CalcComplete(expr, result);
    }

    // Add your other app logic here
}
