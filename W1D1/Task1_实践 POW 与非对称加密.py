'''
通过python代码来实践区块链的 POW 机制，
编写程序用我的昵称 Cobb + nonce，不断修改nonce 进行 sha256 Hash 运算：
直到满足 4 个 0 开头的哈希值，并打印出花费的时间、Hash 的内容及Hash值。
再次运算直到满足 5 个 0 开头的哈希值，并打印出花费的时间、Hash 的内容及Hash值。
'''

# 导入所需的库
import hashlib  # 用于计算SHA256哈希值
import time     # 用于计算程序运行时间

def mine_block(name, target_zeros):
    # 根据传入的target_zeros生成目标字符串，例如"0000"或"00000"
    target = '0' * target_zeros
    
    # 初始化nonce值为0
    nonce = 0
    
    # 记录开始时间
    start_time = time.time()
    
    # 开始无限循环，直到找到满足条件的哈希值
    while True:
        # 将名字和nonce组合成待计算的数据
        data = f"{name}{nonce}"
        
        # 计算数据的SHA256哈希值
        # encode()将字符串转换为字节类型
        # hexdigest()将哈希结果转换为16进制字符串
        hash_result = hashlib.sha256(data.encode()).hexdigest()
        
        # 检查哈希值是否以指定数量的0开头
        if hash_result.startswith(target):
            # 如果找到满足条件的哈希值，记录结束时间
            end_time = time.time()
            # 计算总耗时
            time_spent = end_time - start_time
            
            # 返回包含所有相关信息的字典
            return {
                'nonce': nonce,          # 成功的nonce值
                'hash': hash_result,     # 找到的哈希值
                'data': data,            # 原始数据
                'time': time_spent       # 耗费的时间
            }
        # 如果未找到，nonce加1继续尝试
        nonce += 1

def main():
    # 设置要使用的名字
    name = "Cobb"
    
    # 第一阶段：寻找4个前导零
    print("开始寻找4个前导零的哈希值...")
    # 调用mine_block函数，要求4个前导零
    result_4 = mine_block(name, 4)
    
    # 打印4个前导零的结果
    print(f"\n找到满足4个前导零的结果：")
    print(f"数据内容: {result_4['data']}")      # 打印原始数据
    print(f"哈希值: {result_4['hash']}")        # 打印哈希值
    print(f"使用的nonce: {result_4['nonce']}")  # 打印使用的nonce
    print(f"耗时: {result_4['time']:.2f} 秒")   # 打印耗费时间，保留2位小数
    
    # 打印分隔线
    print("\n" + "="*50 + "\n")
    
    # 第二阶段：寻找5个前导零
    print("开始寻找5个前导零的哈希值...")
    # 调用mine_block函数，要求5个前导零
    result_5 = mine_block(name, 5)
    
    # 打印5个前导零的结果
    print(f"\n找到满足5个前导零的结果：")
    print(f"数据内容: {result_5['data']}")      # 打印原始数据
    print(f"哈希值: {result_5['hash']}")        # 打印哈希值
    print(f"使用的nonce: {result_5['nonce']}")  # 打印使用的nonce
    print(f"耗时: {result_5['time']:.2f} 秒")   # 打印耗费时间，保留2位小数

# 程序入口点
if __name__ == "__main__":
    main()  # 调用main函数开始执行程序

