// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 数据存储合约
contract DataStorage {
    string private data;

    function setData(string memory newData) public {
        data = newData;
    }

    function getData() public view returns (string memory) {
        return data;
    }
}

// 数据消费合约
contract DataConsumer {
    address private dataStorageAddress;

    constructor(address _dataStorageAddress) {
        dataStorageAddress = _dataStorageAddress;
    }

    // 使用函数签名获取数据
    function getDataByABI() public returns (string memory) {
        // 使用abi.encodeWithSignature编码getData()函数调用
        bytes memory payload = abi.encodeWithSignature("getData()");
        
        // 调用合约
        (bool success, bytes memory returnData) = dataStorageAddress.call(payload);
        require(success, "call function failed");
        
        // 解码返回数据
        return abi.decode(returnData, (string));
    }

    // 方法1：使用abi.encodeWithSignature设置数据
    function setDataByABI1(string calldata newData) public returns (bool) {
        // 使用函数签名字符串进行编码
        bytes memory payload = abi.encodeWithSignature(
            "setData(string)",
            newData
        );
        
        // 调用合约
        (bool success, ) = dataStorageAddress.call(payload);

        return success;
    }

    // 方法2：使用abi.encodeWithSelector设置数据
    function setDataByABI2(string calldata newData) public returns (bool) {
        // 计算函数选择器
        bytes4 selector = bytes4(keccak256("setData(string)"));
        
        // 使用函数选择器进行编码
        bytes memory payload = abi.encodeWithSelector(
            selector,
            newData
        );

        // 调用合约
        (bool success, ) = dataStorageAddress.call(payload);

        return success;
    }

    // 方法3：使用abi.encodeCall设置数据
    function setDataByABI3(string calldata newData) public returns (bool) {
        // 使用abi.encodeCall进行编码（最类型安全的方法）
        bytes memory payload = abi.encodeCall(
            DataStorage.setData,
            (newData)
        );

        // 调用合约
        (bool success, ) = dataStorageAddress.call(payload);
        return success;
    }
    
    // 补充：验证三种方法是否产生相同的payload
    function verifyPayloads(string calldata newData) public pure returns (bool) {
        // 获取三种方法的payload
        bytes memory payload1 = abi.encodeWithSignature("setData(string)", newData);
        
        bytes4 selector = bytes4(keccak256("setData(string)"));
        bytes memory payload2 = abi.encodeWithSelector(selector, newData);
        
        bytes memory payload3 = abi.encodeCall(DataStorage.setData, (newData));
        
        // 比较是否相同
        return (keccak256(payload1) == keccak256(payload2) && 
                keccak256(payload2) == keccak256(payload3));
    }
}

// 补充：测试合约
contract DataTest {
    DataStorage public dataStorage;
    DataConsumer public dataConsumer;
    
    constructor() {
        // 部署DataStorage合约
        dataStorage = new DataStorage();
        // 部署DataConsumer合约，并传入DataStorage地址
        dataConsumer = new DataConsumer(address(dataStorage));
    }
    
    // 测试所有设置数据的方法
    function testSetData() public returns (bool) {
        string memory testData = "Test Data";
        
        // 测试三种方法
        bool success1 = dataConsumer.setDataByABI1(testData);
        bool success2 = dataConsumer.setDataByABI2(testData);
        bool success3 = dataConsumer.setDataByABI3(testData);
        
        // 验证数据是否正确设置
        string memory storedData = dataStorage.getData();
        
        return (success1 && success2 && success3 && 
                keccak256(bytes(storedData)) == keccak256(bytes(testData)));
    }
    
    // 测试获取数据
    function testGetData() public returns (bool) {
        string memory testData = "Test Data";
        
        // 设置数据
        dataStorage.setData(testData);
        
        // 通过ABI调用获取数据
        string memory retrievedData = dataConsumer.getDataByABI();
        
        // 验证数据是否一致
        return keccak256(bytes(retrievedData)) == keccak256(bytes(testData));
    }
} 
