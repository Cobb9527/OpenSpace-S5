// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FunctionSelector {
    // 存储值的状态变量
    uint256 private storedValue;

    // 获取存储值的函数
    function getValue() public view returns (uint) {
        return storedValue;
    }

    // 设置存储值的函数
    function setValue(uint value) public {
        storedValue = value;
    }

    // 获取getValue()函数的选择器
    function getFunctionSelector1() public pure returns (bytes4) {
        // 方法1：使用bytes4(keccak256())计算函数选择器
        // 函数选择器是函数签名的keccak256哈希的前4个字节
        // 函数签名格式：函数名(参数类型1,参数类型2,...)
        return bytes4(keccak256("getValue()"));
    }

    // 获取setValue(uint)函数的选择器
    function getFunctionSelector2() public pure returns (bytes4) {
        // 方法1：使用bytes4(keccak256())计算函数选择器
        return bytes4(keccak256("setValue(uint256)"));
    }
    
    // 补充：通过函数选择器验证函数
    function verifySelector() public pure returns (bool) {
        // 方法2：使用this.function.selector获取函数选择器
        bytes4 selector1 = this.getValue.selector;
        bytes4 selector2 = this.setValue.selector;
        
        // 验证两种方法获取的选择器是否相同
        return (selector1 == getFunctionSelector1() &&
                selector2 == getFunctionSelector2());
    }
    
    // 补充：获取完整的函数签名
    function getFunctionSignature1() public pure returns (string memory) {
        return "getValue()";
    }
    
    function getFunctionSignature2() public pure returns (string memory) {
        return "setValue(uint256)";
    }
    
    // 补充：通过选择器调用函数的示例
    function callFunctionBySelector(bytes4 selector, uint256 value) public returns (bool) {
        // 使用低级call通过选择器调用函数
        // 对于setValue，需要对参数进行ABI编码
        if (selector == this.setValue.selector) {
            (bool success, ) = address(this).call(
                abi.encodeWithSelector(selector, value)
            );
            return success;
        }
        // 对于getValue，不需要参数
        else if (selector == this.getValue.selector) {
            (bool success, ) = address(this).call(
                abi.encodeWithSelector(selector)
            );
            return success;
        }
        return false;
    }
}

// 补充：测试合约
contract FunctionSelectorTest {
    FunctionSelector private fs;
    
    constructor() {
        fs = new FunctionSelector();
    }
    
    function testSelectors() public view returns (bool) {
        // 测试两种方法获取的选择器是否相同
        return fs.verifySelector();
    }
    
    function testFunctionCall() public returns (bool) {
        // 测试通过选择器调用函数
        bytes4 setSelector = fs.getFunctionSelector2();
        bytes4 getSelector = fs.getFunctionSelector1();
        
        // 先设置值
        bool setSuccess = fs.callFunctionBySelector(setSelector, 123);
        // 再获取值
        bool getSuccess = fs.callFunctionBySelector(getSelector, 0);
        
        return setSuccess && getSuccess;
    }
}

