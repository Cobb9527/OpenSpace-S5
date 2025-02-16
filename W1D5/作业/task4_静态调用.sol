// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 被调用的合约
contract Callee {
    // 一个简单的pure函数，返回固定值
    function getData() public pure returns (uint256) {
        return 42;
    }
}

// 调用者合约
contract Caller {
    // 使用staticcall调用其他合约的函数
    function callGetData(address callee) public view returns (uint256 data) {
        // 1. 准备函数调用的数据
        bytes memory payload = abi.encodeWithSignature("getData()");
        
        // 2. 使用staticcall进行调用
        // staticcall用于调用view/pure函数，不允许修改状态
        (bool success, bytes memory returnData) = callee.staticcall(payload);
        
        // 3. 检查调用是否成功
        require(success, "staticcall function failed");
        
        // 4. 解码返回数据
        return abi.decode(returnData, (uint256));
    }
}

// 补充：测试合约
contract StaticCallTest {
    Callee public callee;
    Caller public caller;
    
    constructor() {
        // 部署被调用合约
        callee = new Callee();
        // 部署调用者合约
        caller = new Caller();
    }
    
    // 测试静态调用
    function testStaticCall() public view returns (bool) {
        // 调用并验证返回值
        uint256 result = caller.callGetData(address(callee));
        return result == 42;
    }
    
    // 测试对错误地址的调用
    function testFailedCall() public view {
        // 使用一个不存在的合约地址
        caller.callGetData(address(0));
        // 这个调用应该会失败并抛出异常
    }
}
