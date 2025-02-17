// SPDX-License-Identifier: MIT
// 这是开源协议声明，告诉大家这个代码是开源的

pragma solidity ^0.8.0;
// 指定使用的编程语言版本，就像告诉电脑我们用什么版本的工具

// 定义一个接口，就像是一个规范，告诉其他合约必须实现哪些功能
interface ITokenReceiver {
    // 定义接收代币时的回调函数
    // 当合约收到代币时，这个函数会被自动调用
    function tokensReceived(
        address from,    // 代币从哪里来
        uint256 amount  // 收到多少代币
    ) external returns (bool);
}

// 创建一个增强版的代币合约
contract ExtendedERC20 {
    // 代币的基本信息
    string public name;     // 代币的名字，比如"比特币"
    string public symbol;   // 代币的符号，比如"BTC"
    uint8 public decimals; // 小数位数，比如18表示可以分割到18位小数
    uint256 public totalSupply; // 代币的总供应量
    
    // 记录每个地址拥有多少代币
    mapping(address => uint256) public balances;
    
    // 记录每个地址允许其他地址使用多少代币
    // 比如：A地址允许B地址使用100个代币
    mapping(address => mapping(address => uint256)) public allowances;
    
    // 定义事件，用于记录代币的转移
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 定义事件，用于记录授权
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // 构造函数，在创建合约时执行一次
    constructor(string memory _name, string memory _symbol) {
        name = _name;      // 设置代币名称
        symbol = _symbol;  // 设置代币符号
        decimals = 18;     // 设置小数位数
        // 创建1000个代币（考虑18位小数）
        totalSupply = 1000 * 10**decimals;
        // 将所有代币给到合约创建者
        balances[msg.sender] = totalSupply;
    }
    
    // 查询某个地址有多少代币
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    // 基础的转账功能
    function transfer(address to, uint256 amount) public returns (bool) {
        // 确保不能转账到零地址
        require(to != address(0), "Transfer to zero address");
        // 确保发送者有足够的代币
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // 更新余额：发送者减少，接收者增加
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        // 触发转账事件，记录这笔交易
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    // 带回调功能的转账
    // 如果接收方是合约，会自动调用它的tokensReceived函数
    function transferWithCallback(address to, uint256 amount) public returns (bool) {
        // 检查基本条件
        require(to != address(0), "Transfer to zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // 更新余额
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        // 如果接收方是合约（有代码的地址）
        if (to.code.length > 0) {
            // 调用接收方的tokensReceived函数
            require(
                ITokenReceiver(to).tokensReceived(msg.sender, amount),
                "Callback failed"
            );
        }
        
        // 记录转账事件
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    // 授权其他地址使用代币
    function approve(address spender, uint256 amount) public returns (bool) {
        // 记录授权数量
        allowances[msg.sender][spender] = amount;
        // 触发授权事件
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    // 从其他地址转移代币（需要事先获得授权）
    function transferFrom(
        address from,    // 从哪个地址转出
        address to,      // 转到哪个地址
        uint256 amount  // 转多少代币
    ) public returns (bool) {
        // 检查授权额度是否足够
        require(allowances[from][msg.sender] >= amount, "Insufficient allowance");
        // 检查发送方余额是否足够
        require(balances[from] >= amount, "Insufficient balance");
        
        // 减少授权额度
        allowances[from][msg.sender] -= amount;
        // 更新双方余额
        balances[from] -= amount;
        balances[to] += amount;
        
        // 记录转账事件
        emit Transfer(from, to, amount);
        return true;
    }
}

// 创建升级版的代币银行，继承原来的TokenBank
contract TokenBankV2 is TokenBank, ITokenReceiver {
    // 记录这个银行是否支持回调功能
    bool public supportsCallback;
    
    // 构造函数，设置要接收的代币地址
    constructor(address _token) TokenBank(_token) {
        // 尝试调用代币的回调功能，看是否支持
        try ExtendedERC20(_token).transferWithCallback(address(this), 0) {
            supportsCallback = true;  // 支持回调
        } catch {
            supportsCallback = false; // 不支持回调
        }
    }
    
    // 实现接收代币时的回调函数
    function tokensReceived(
        address from,    // 谁发送的代币
        uint256 amount  // 发送了多少代币
    ) external override returns (bool) {
        // 确保只有代币合约可以调用这个函数
        require(msg.sender == address(token), "Invalid caller");
        
        // 记录用户的存款
        balances[from] += amount;
        
        // 触发存款事件
        emit Deposit(from, amount);
        
        return true;
    }
}

// 测试合约，用于测试新功能是否正常工作
contract TokenBankV2Test {
    ExtendedERC20 public token;  // 代币合约
    TokenBankV2 public bank;     // 银行合约
    
    // 构造函数，部署新的代币和银行
    constructor() {
        // 创建新的代币
        token = new ExtendedERC20("Extended Token", "EXT");
        // 创建新的银行
        bank = new TokenBankV2(address(token));
    }
    
    // 测试直接转账存款功能
    function testDirectDeposit(uint256 amount) public {
        // 先把代币转到测试合约
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer to test contract failed"
        );
        
        // 使用带回调的转账功能存款
        require(
            token.transferWithCallback(address(bank), amount),
            "Direct deposit failed"
        );
        
        // 验证存款是否成功
        require(
            bank.getBalance(address(this)) == amount,
            "Deposit amount mismatch"
        );
    }
}
