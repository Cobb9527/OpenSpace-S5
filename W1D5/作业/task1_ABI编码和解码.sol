// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 编码合约
contract ABIEncoder {
    // 对单个uint256进行编码
    function encodeUint(uint256 value) public pure returns (bytes memory) {
        return abi.encode(value);
    }

    // 对多个参数进行编码
    function encodeMultiple(
        uint num,
        string memory text
    ) public pure returns (bytes memory) {
        return abi.encode(num, text);
    }
}

// 解码合约
contract ABIDecoder {
    // 解码单个uint256
    function decodeUint(bytes memory data) public pure returns (uint) {
        return abi.decode(data, (uint));
    }

    // 解码多个参数
    function decodeMultiple(
        bytes memory data
    ) public pure returns (uint, string memory) {
        return abi.decode(data, (uint, string));
    }
}

// 测试合约
contract ABITest {
    // 测试单个uint256的编码和解码
    function testUint(uint256 value) public pure returns (bool) {
        // 直接使用abi编码和解码，不需要创建新的合约实例
        bytes memory encoded = abi.encode(value);
        uint256 decoded = abi.decode(encoded, (uint256));
        return value == decoded;
    }
    
    // 测试多个参数的编码和解码
    function testMultiple(
        uint256 num, 
        string memory text
    ) public pure returns (bool) {
        // 直接使用abi编码和解码
        bytes memory encoded = abi.encode(num, text);
        (uint256 decodedNum, string memory decodedText) = abi.decode(encoded, (uint256, string));
        
        return (num == decodedNum && 
                keccak256(bytes(text)) == keccak256(bytes(decodedText)));
    }
}
