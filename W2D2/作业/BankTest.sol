// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address public user;
    uint256 public constant DEPOSIT_AMOUNT = 1 ether;

    function setUp() public {
        bank = new Bank();
        user = makeAddr("user");
        vm.deal(user, 10 ether);
    }

    function test_DepositETH() public {
        // 使用 user 地址进行测试
        vm.startPrank(user);

        // 记录存款前的余额
        uint256 balanceBefore = bank.balanceOf(user);

        // 期望会触发 Deposit 事件
        vm.expectEmit(true, false, false, true);
        emit Bank.Deposit(user, DEPOSIT_AMOUNT);

        // 执行存款
        bank.depositETH{value: DEPOSIT_AMOUNT}();

        // 验证存款后的余额是否正确更新
        uint256 balanceAfter = bank.balanceOf(user);
        assertEq(balanceAfter, balanceBefore + DEPOSIT_AMOUNT, "Balance not updated correctly");

        vm.stopPrank();
    }
} 
