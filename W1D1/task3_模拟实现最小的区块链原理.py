"""
用python语言模拟实现最小的区块链原理, 来实践理解区块链的工作量证明及链式结构, 包含两个功能:
1. POW 证明出块，难度为 4 个 0 开头;
2. 每个区块包含previous_hash 让区块串联起来
如下是一个参考区块结构：
block = {
'index': 1,
'timestamp': 1506057125,
'transactions': [
    { 'sender': "xxx", 
    'recipient': "xxx", 
    'amount': 5, } ], 
'proof': 324984774000,
'previous_hash': "xxxx"
}
"""

# hashlib: 提供多种安全哈希算法（如SHA256），用于计算区块的哈希值和工作量证明
import hashlib

# json: 用于将Python对象（如区块、交易）序列化为JSON字符串，确保数据的一致性和可读性
import json

# time: 用于获取时间戳，记录区块的创建时间
import time

# typing: 提供类型提示功能，增强代码的可读性和可维护性
# List: 用于标注列表类型，如交易列表
# Dict: 用于标注字典类型，如区块结构
# Any: 用于标注任意类型的数据
from typing import List, Dict, Any

class Blockchain:
    def __init__(self):
        # 初始化区块链列表和未确认交易列表
        self.chain = []
        self.pending_transactions = []
        
        # 创建创世区块
        self.create_genesis_block()
    
    def create_genesis_block(self) -> None:
        """创建创世区块（区块链的第一个区块）"""
        genesis_block = {
            'index': 0,                     # 区块索引
            'timestamp': time.time(),       # 区块生成时间戳
            'transactions': [],             # 交易列表（创世区块没有交易）
            'proof': 100,                   # 工作量证明（创世区块设为100）
            'previous_hash': '0'            # 前一个区块的哈希值（创世区块设为0）
        }
        # 将创世区块添加到链中
        self.chain.append(genesis_block)

    def add_transaction(self, sender: str, recipient: str, amount: float) -> None:
        """添加新的待确认交易"""
        transaction = {
            'sender': sender,         # 发送者
            'recipient': recipient,    # 接收者
            'amount': amount          # 交易金额
        }
        # 将交易添加到待确认交易列表
        self.pending_transactions.append(transaction)

    def calculate_hash(self, block: Dict[str, Any]) -> str:
        """计算区块的哈希值"""
        # 将区块数据转换为JSON字符串，确保数据一致性
        block_string = json.dumps(block, sort_keys=True).encode()
        # 计算SHA256哈希值
        return hashlib.sha256(block_string).hexdigest()

    def proof_of_work(self, previous_proof: int) -> int:
        """
        工作量证明算法
        寻找一个数字proof，使得与前一个区块的proof组合的哈希值满足特定条件
        """
        proof = 0
        while True:
            # 组合前一个区块的proof和当前猜测的proof
            guess = f'{previous_proof}{proof}'.encode()
            # 计算哈希值
            guess_hash = hashlib.sha256(guess).hexdigest()
            # 检查是否满足难度要求（4个前导零）
            if guess_hash[:4] == "0000":
                return proof
            proof += 1

    def create_block(self) -> Dict[str, Any]:
        """创建新的区块"""
        # 获取链中最后一个区块
        previous_block = self.chain[-1]
        
        # 创建新区块
        block = {
            'index': len(self.chain),                    # 新区块的索引
            'timestamp': time.time(),                    # 当前时间戳
            'transactions': self.pending_transactions,    # 待确认的交易列表
            'proof': self.proof_of_work(previous_block['proof']),  # 计算工作量证明
            'previous_hash': self.calculate_hash(previous_block)    # 前一个区块的哈希值
        }
        
        # 清空待确认交易列表
        self.pending_transactions = []
        # 将新区块添加到链中
        self.chain.append(block)
        return block

    def is_chain_valid(self) -> bool:
        """验证区块链的有效性"""
        for i in range(1, len(self.chain)):
            current_block = self.chain[i]
            previous_block = self.chain[i-1]
            
            # 验证当前区块的previous_hash是否正确
            if current_block['previous_hash'] != self.calculate_hash(previous_block):
                return False
            
            # 验证工作量证明是否有效
            guess = f'{previous_block["proof"]}{current_block["proof"]}'.encode()
            guess_hash = hashlib.sha256(guess).hexdigest()
            if guess_hash[:4] != "0000":
                return False
        
        return True

def main():
    # 创建区块链实例
    blockchain = Blockchain()
    
    # 添加一些测试交易
    print("添加测试交易...")
    blockchain.add_transaction("Alice", "Bob", 50)
    blockchain.add_transaction("Bob", "Charlie", 30)
    
    # 创建新区块
    print("\n开始挖矿...")
    block = blockchain.create_block()
    
    # 打印新区块信息
    print("\n新区块已创建:")
    print(f"区块索引: {block['index']}")
    print(f"时间戳: {block['timestamp']}")
    print(f"交易列表: {json.dumps(block['transactions'], indent=2)}")
    print(f"工作量证明: {block['proof']}")
    print(f"前一个区块哈希值: {block['previous_hash']}")
    
    # 验证区块链
    print(f"\n区块链是否有效: {blockchain.is_chain_valid()}")
    
    # 打印整个区块链
    print("\n完整的区块链:")
    for block in blockchain.chain:
        print(json.dumps(block, indent=2))

if __name__ == "__main__":
    main()
