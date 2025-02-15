/ SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;        

// 定义Bank接口，接口就像是一个规范，规定了必须要实现的功能
interface IBank {
    // 定义必须实现的事件（事件用于记录重要操作，可以被前端捕获）
    event Deposit(address indexed depositor, uint256 amount);        // 存款事件
    event Withdrawal(uint256 amount);                               // 提现事件
    event TopDepositorUpdated(address indexed depositor, uint256 amount, uint256 rank);  // 排行榜更新事件
    
    // 定义必须实现的函数
    function deposit() external payable;              // 存款函数
    function withdraw(uint256 amount) external;       // 提现函数
    function getContractBalance() external view returns (uint256);   // 查询合约余额
    function getBalance(address user) external view returns (uint256);  // 查询用户余额
}

// 基础Bank合约
contract Bank is IBank{
    address public admin;
    mapping(address => uint256) public balances;
    
    struct Depositor {
        address userAddress;
        uint256 amount;
    }
    
    Depositor[3] public topDepositors;
    uint256 public totalDeposits;
    
    // event Deposit(address indexed depositor, uint256 amount);
    // event Withdrawal(uint256 amount);
    // event TopDepositorUpdated(address indexed depositor, uint256 amount, uint256 rank);
    
    constructor() {
        admin = msg.sender;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    
    receive() external payable {
        deposit();
    }
    
    function deposit() public virtual payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        updateTopDepositors(msg.sender, balances[msg.sender]);
        
        emit Deposit(msg.sender, msg.value);
    }
    
    function updateTopDepositors(address depositor, uint256 amount) private {
        for (uint i = 0; i < 3; i++) {
            if (topDepositors[i].userAddress == depositor) {
                topDepositors[i].amount = amount;
                sortTopDepositors();
                return;
            }
        }
        
        if (amount > 0) {
            for (uint i = 0; i < 3; i++) {
                if (amount > topDepositors[i].amount) {
                    for (uint j = 2; j > i; j--) {
                        topDepositors[j] = topDepositors[j-1];
                    }
                    topDepositors[i] = Depositor(depositor, amount);
                    emit TopDepositorUpdated(depositor, amount, i + 1);
                    break;
                }
            }
        }
    }
    
    function sortTopDepositors() private {
        for (uint i = 0; i < 2; i++) {
            for (uint j = i + 1; j < 3; j++) {
                if (topDepositors[j].amount > topDepositors[i].amount) {
                    Depositor memory temp = topDepositors[i];
                    topDepositors[i] = topDepositors[j];
                    topDepositors[j] = temp;
                }
            }
        }
    }
    
    function withdraw(uint256 amount) public virtual onlyAdmin {
        require(amount <= totalDeposits, "Insufficient contract balance");
        
        totalDeposits -= amount;
        
        (bool success, ) = admin.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(amount);
    }
    
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }
    
    function getTopDepositors() public view returns (Depositor[3] memory) {
        return topDepositors;
    }
}

// BigBank合约，继承自Bank并实现IBank接口
// is 关键字表示继承，这里BigBank继承了Bank的所有功能，并实现了IBank接口
contract BigBank is Bank{
    // 定义最小存款金额常量
    // constant 表示这是一个常量，不能被修改
    // 0.001 ether 表示0.001个以太币
    uint256 public constant MIN_DEPOSIT = 0.001 ether;
    
    // 定义管理员转移事件
    event AdminTransferred(
        address indexed previousAdmin,    // 前任管理员地址
        address indexed newAdmin         // 新管理员地址
    );
    
    // 定义检查最小存款金额的修饰器
    // 修饰器用于在函数执行前进行条件检查
    modifier minDeposit() {
        // 检查存款金额是否大于最小要求
        require(msg.value >= MIN_DEPOSIT, "Deposit amount must be greater than 0.001 ether");
        _; // 继续执行被修饰的函数
    }
    
    // 重写父合约的deposit函数，添加最小存款限制
    // override 关键字表示这是对父合约函数的重写
    function deposit() public payable virtual override minDeposit {
        super.deposit();  // 调用父合约的deposit函数
    }
    
    // 重写父合约的withdraw函数，添加最小存款限制
    function withdraw(uint256 amount) public override onlyAdmin {
        super.withdraw(amount);
    }
    
    // 转移管理员的函数
    // onlyAdmin 修饰器确保只有当前管理员可以调用此函数
    function transferAdmin(address newAdmin) public onlyAdmin {
        // 确保新管理员地址不是零地址
        require(newAdmin != address(0), "New admin cannot be zero address");
        // 触发管理员转移事件
        emit AdminTransferred(admin, newAdmin);
        // 更新管理员地址
        admin = newAdmin;
    }
}

// Admin合约：用于管理Bank合约
contract Admin {
    // 声明Admin合约的拥有者地址
    address public owner;
    
    // 定义从Bank提取资金的事件
    event WithdrawFromBank(
        address indexed bank,    // Bank合约地址
        uint256 amount         // 提取金额
    );
    
    // 构造函数：在合约部署时执行
    constructor() {
        owner = msg.sender;  // 将合约部署者设置为owner
    }
    
    // 定义只有owner可以调用的修饰器
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _; // 继续执行被修饰的函数
    }
    
    // 从Bank合约提取资金的函数
    // external 表示只能从外部调用
    // onlyOwner 确保只有owner可以调用
    function adminWithdraw(IBank bank) external onlyOwner {
        // 获取Bank合约的余额
        uint256 balance = bank.getContractBalance();
        // 确保Bank合约有余额可提取
        require(balance > 0, "Bank has no balance");
        
        // 调用Bank合约的withdraw函数提取所有资金
        bank.withdraw(balance);
        
        // 触发提现事件
        emit WithdrawFromBank(address(bank), balance);
    }
    
    // receive函数：允许合约接收ETH
    // 当向合约直接发送ETH时会调用此函数
    receive() external payable {}
}

