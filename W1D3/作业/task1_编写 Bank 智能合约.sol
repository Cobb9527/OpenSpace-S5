// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13; 

// 定义Bank合约
contract Bank {
    // 声明一个public的address类型变量admin，用于存储管理员地址
    // public关键字会自动生成一个getter函数，允许外部查询admin地址
    address public admin;
    
    // 使用mapping（映射）来存储每个地址的存款余额
    // 键(key)是地址，值(value)是无符号整数（代表存款金额）
    mapping(address => uint256) public balances;
    
    // 定义一个结构体，用于存储存款人的信息
    struct Depositor {
        address userAddress;    // 存款人的地址
        uint256 amount;        // 存款金额
    }
    
    // 声明一个固定大小为3的数组，用于存储前三名存款用户
    // public关键字允许外部查看这个数组
    Depositor[3] public topDepositors;
    
    // 记录合约中的总存款金额
    uint256 public totalDeposits;
    
    // 定义事件，用于记录重要操作，方便前端监听和查询
    // indexed关键字允许按照depositor进行过滤查询
    event Deposit(address indexed depositor, uint256 amount);        // 存款事件
    event Withdrawal(uint256 amount);                               // 提现事件
    event TopDepositorUpdated(address indexed depositor, uint256 amount, uint256 rank);  // 排行榜更新事件
    
    // 构造函数，在合约部署时执行一次
    // 将合约部署者的地址设置为管理员
    constructor() {
        admin = msg.sender;  // msg.sender 表示调用合约的地址，在部署时是部署者的地址
    }
    
    // 修饰器（modifier）：用于在函数执行前检查条件
    // 这里检查调用者是否为管理员
    modifier onlyAdmin() {
        // require 用于检查条件，如果条件为false，则回滚交易并返回错误消息
        require(msg.sender == admin, "Only admin can call this function");
        _; // 继续执行被修饰的函数
    }
    
    // receive 函数：当向合约发送ETH时自动调用
    // external表示只能从外部调用，payable表示函数可以接收ETH
    receive() external payable {
        deposit(); // 调用存款函数处理收到的ETH
    }
    
    // 存款函数：允许用户存入ETH
    // public表示可以公开调用，payable表示函数可以接收ETH
    function deposit() public payable {
        // 检查存款金额必须大于0
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        // 更新用户的存款余额
        // msg.value 表示随交易发送的ETH数量
        balances[msg.sender] += msg.value;
        
        // 更新合约的总存款金额
        totalDeposits += msg.value;
        
        // 更新存款排行榜
        updateTopDepositors(msg.sender, balances[msg.sender]);
        
        // 触发存款事件
        emit Deposit(msg.sender, msg.value);
    }
    
    // 更新前三名存款用户的内部函数
    // private表示只能在合约内部调用
    function updateTopDepositors(address depositor, uint256 amount) private {
        // 首先检查用户是否已经在排行榜中
        for (uint i = 0; i < 3; i++) {
            if (topDepositors[i].userAddress == depositor) {
                // 如果用户已在排行榜中，更新其金额
                topDepositors[i].amount = amount;
                // 重新排序
                sortTopDepositors();
                return;
            }
        }
        
        // 如果用户不在排行榜中，检查是否应该加入
        if (amount > 0) {
            for (uint i = 0; i < 3; i++) {
                if (amount > topDepositors[i].amount) {
                    // 将现有记录向后移动一位
                    for (uint j = 2; j > i; j--) {
                        topDepositors[j] = topDepositors[j-1];
                    }
                    // 在正确的位置插入新记录
                    topDepositors[i] = Depositor(depositor, amount);
                    // 触发排行榜更新事件
                    emit TopDepositorUpdated(depositor, amount, i + 1);
                    break;
                }
            }
        }
    }
    
    // 对排行榜进行排序的内部函数
    // 使用冒泡排序算法
    function sortTopDepositors() private {
        for (uint i = 0; i < 2; i++) {
            for (uint j = i + 1; j < 3; j++) {
                // 如果后面的金额大于前面的金额，交换位置
                if (topDepositors[j].amount > topDepositors[i].amount) {
                    // 使用临时变量进行交换
                    Depositor memory temp = topDepositors[i];
                    topDepositors[i] = topDepositors[j];
                    topDepositors[j] = temp;
                }
            }
        }
    }
    
    // 管理员提取资金的函数
    // external表示只能从外部调用
    // onlyAdmin修饰器确保只有管理员可以调用
    function withdraw(uint256 amount) external onlyAdmin {
        // 检查提取金额是否超过总存款
        require(amount <= totalDeposits, "Insufficient contract balance");
        
        // 更新总存款金额
        totalDeposits -= amount;
        
        // 将ETH转给管理员
        // call是低级调用函数，返回bool表示是否成功
        (bool success, ) = admin.call{value: amount}("");
        // 确保转账成功
        require(success, "Transfer failed");
        
        // 触发提现事件
        emit Withdrawal(amount);
    }
    
    // 查询合约ETH余额的函数
    // view表示这是一个只读函数，不修改状态
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;  // this表示当前合约
    }
    
    // 查询指定用户存款余额的函数
    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }
    
    // 查询前三名存款用户的函数
    // memory表示数据将存储在内存中（而不是区块链上）
    function getTopDepositors() public view returns (Depositor[3] memory) {
        return topDepositors;
    }
}
