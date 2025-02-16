// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 定义完整的IERC20接口
interface IERC20 {
    // 转账相关函数
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    // 授权相关函数
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    
    // 查询函数
    function balanceOf(address account) external view returns (uint256);
    
    // 基本信息
    function totalSupply() external view returns (uint256);
    
    // 事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenBank {
    // Token合约接口
    IERC20 public token;
    
    // 用户存款余额映射
    mapping(address => uint256) public balances;
    
    // 事件
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    
    constructor(address _token) {
        require(_token != address(0), "Token address cannot be zero");
        token = IERC20(_token);
    }
    
    // 存款函数
    function deposit(uint256 _amount) public {
        // 基本检查
        require(_amount > 0, "Deposit amount must be greater than 0");
        require(
            token.balanceOf(msg.sender) >= _amount,
            "Insufficient token balance"
        );
        
        // 转移Token到合约
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );
        
        // 更新余额
        balances[msg.sender] += _amount;
        
        // 触发事件
        emit Deposit(msg.sender, _amount);
    }
    
    // 取款函数
    function withdraw(uint256 _amount) public {
        // 基本检查
        require(_amount > 0, "Withdraw amount must be greater than 0");
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance in bank"
        );
        
        // 更新余额（先更新状态，防止重入攻击）
        balances[msg.sender] -= _amount;
        
        // 转移Token给用户
        require(
            token.transfer(msg.sender, _amount),
            "Transfer failed"
        );
        
        // 触发事件
        emit Withdraw(msg.sender, _amount);
    }
    
    // 查询余额
    function getBalance(address _user) public view returns (uint256) {
        return balances[_user];
    }
    
    // 查询合约总余额
    function getTotalBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}

// 测试合约
contract TokenBankTest {
    TokenBank public bank;
    IERC20 public token;
    
    constructor(address _token) {
        token = IERC20(_token);
        bank = new TokenBank(_token);
    }
    
    // 测试存款
    function testDeposit(uint256 amount) public {
        // 先将Token转移到测试合约
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer to test contract failed"
        );
        
        // 授权银行合约
        require(
            token.approve(address(bank), amount),
            "Approve failed"
        );
        
        // 存款
        bank.deposit(amount);
        
        // 验证
        require(
            bank.getBalance(address(this)) == amount,
            "Deposit amount mismatch"
        );
    }
    
    // 测试取款
    function testWithdraw(uint256 amount) public {
        // 先存款
        testDeposit(amount);
        
        // 记录取款前余额
        uint256 balanceBefore = token.balanceOf(address(this));
        
        // 取款
        bank.withdraw(amount);
        
        // 验证
        require(
            token.balanceOf(address(this)) == balanceBefore + amount,
            "Withdraw amount mismatch"
        );
    }
} 
