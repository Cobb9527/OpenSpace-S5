// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 导入Forge标准库
import "forge-std/Test.sol";

contract Caller {
    // 发送以太币的函数
    function sendEther(address to, uint256 value) public returns (bool) {
        // 检查接收地址不为零地址
        require(to != address(0), "Cannot send to zero address");
        
        // 检查合约余额是否足够
        require(address(this).balance >= value, "sendEther failed");
        
        // 使用call发送以太币
        (bool success, ) = to.call{value: value}("");
        
        // 检查发送结果
        require(success, "sendEther failed");
        
        return success;
    }
    
    // 接收以太币的函数
    receive() external payable {}
    
    // 查询合约余额的函数
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

// 测试合约 - 继承Test合约
contract CallerTest is Test {
    Caller caller;
    
    // 在每个测试用例前设置环境
    function setUp() public {
        caller = new Caller();
    }
    
    // 测试成功发送以太币
    function testSendEther() public {
        // 设置初始余额
        uint256 amount = 1 ether;
        deal(address(caller), amount);
        
        // 验证发送是否成功
        bool success = caller.sendEther(address(this), amount);
        assertTrue(success);
        
        // 验证余额变化
        assertEq(address(caller).balance, 0);
    }
    
    // 测试发送零以太币
    function testSendZeroEther() public {
        bool success = caller.sendEther(address(this), 0);
        assertTrue(success);
    }
    
    // 测试余额不足的情况
    function testFailInsufficientBalance() public {
        // 尝试发送1 ETH，但合约余额为0
        vm.expectRevert("sendEther failed");
        caller.sendEther(address(this), 1 ether);
    }
    
    // 测试发送到零地址
    function testFailSendToZeroAddress() public {
        vm.expectRevert("Cannot send to zero address");
        caller.sendEther(address(0), 1 ether);
    }
    
    // 模糊测试：测试不同金额
    function testFuzz_sendEther(uint256 amount) public {
        // 限制测试金额范围，避免极端情况
        vm.assume(amount > 0 && amount <= 100 ether);
        
        // 向合约发送测试金额
        deal(address(caller), amount);
        
        // 执行发送
        bool success = caller.sendEther(address(this), amount);
        assertTrue(success);
        
        // 验证余额
        assertEq(address(caller).balance, 0);
    }
    
    // 接收以太币
    receive() external payable {}
}
