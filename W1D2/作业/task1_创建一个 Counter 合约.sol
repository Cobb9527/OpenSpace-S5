// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// 使用 Remix 创建一个 Counter 合约并部署到任意以太坊测试网:Counter 合约具有
// 一个状态变量 counter
// get()方法: 获取 counter 的值
// add(x) 方法: 给变量加上 x 。


// 定义Counter合约
contract Counter {
    // 声明状态变量counter
    // private表示只能在合约内部访问
    // 使用uint256类型存储较大的正整数
    uint256 private counter;
    
    // 构造函数，在部署合约时调用
    // 初始化counter的值为0
    constructor() {
        counter = 0;
    }
    
    // get函数：获取counter的当前值
    // public表示可以被外部调用
    // view表示这是一个只读函数，不会修改状态
    // returns (uint256)指定返回值类型为uint256
    function get() public view returns (uint256) {
        return counter;
    }
    
    // add函数：将counter的值增加x
    // public表示可以被外部调用
    // 参数x指定要增加的值
    // 返回增加后的counter值
    function add(uint256 x) public returns (uint256) {
        // 使用SafeMath的加法（Solidity 0.8.0以上版本内置了溢出检查）
        counter = counter + x;
        // 返回更新后的counter值
        return counter;
    }
}
