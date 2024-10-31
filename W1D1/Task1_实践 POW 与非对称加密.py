'''
通过python代码来实践区块链的 POW 机制，
编写程序用我的昵称 Cobb + nonce，不断修改nonce 进行 sha256 Hash 运算：
直到满足 4 个 0 开头的哈希值，并打印出花费的时间、Hash 的内容及Hash值。
再次运算直到满足 5 个 0 开头的哈希值，并打印出花费的时间、Hash 的内容及Hash值。
'''

import hashlib  # 导入hashlib库，用于计算哈希值
import time  # 导入time库，用于计算时间

def mine_hash(name, target_zeros):
    """
    挖矿函数，用于找到一个特定的哈希值，该哈希值以指定数量的前导零开头。

    参数:
    name (str): 输入的名字或字符串。
    target_zeros (int): 需要的前导零的数量。

    返回:
    dict: 包含找到的nonce、哈希内容、哈希值和耗时的字典。
    """
    target = '0' * target_zeros  # 设置目标前导零的数量
    nonce = 0  # 初始化nonce为0
    start_time = time.time()  # 记录开始时间

    while True:
        # 组合字符串，将name和nonce拼接在一起
        data = f"{name}{nonce}"
        # 计算组合字符串的SHA256哈希值
        hash_result = hashlib.sha256(data.encode()).hexdigest()

        # 检查哈希值是否以目标前导零开头
        if hash_result.startswith(target):
            end_time = time.time()  # 记录结束时间
            time_spent = end_time - start_time  # 计算总耗时
            # 返回结果字典
            return {
                'nonce': nonce,  # 找到的nonce值
                'hash_content': data,  # 哈希内容
                'hash_value': hash_result,  # 哈希值
                'time_spent': time_spent  # 耗时
            }
        nonce += 1  # nonce递增，继续尝试下一个值


def main():
    """
    主函数，用于调用挖矿函数并打印结果。
    """
    name = "Cobb"  # 设置输入的名字

    # 计算4个前导零
    print("开始挖矿 (4个前导零)...")
    result_4 = mine_hash(name, 4)  # 调用挖矿函数，目标为4个前导零
    print(f"\n找到满足条件的哈希值！")
    print(f"Nonce: {result_4['nonce']}")  # 打印找到的nonce值
    print(f"Hash内容: {result_4['hash_content']}")  # 打印哈希内容
    print(f"Hash值: {result_4['hash_value']}")  # 打印哈希值
    print(f"耗时: {result_4['time_spent']:.2f} 秒")  # 打印耗时

    print("\n" + "=" * 50 + "\n")  # 分割线

    # 计算5个前导零
    print("开始挖矿 (5个前导零)...")
    result_5 = mine_hash(name, 5)  # 调用挖矿函数，目标为5个前导零
    print(f"\n找到满足条件的哈希值！")
    print(f"Nonce: {result_5['nonce']}")  # 打印找到的nonce值
    print(f"Hash内容: {result_5['hash_content']}")  # 打印哈希内容
    print(f"Hash值: {result_5['hash_value']}")  # 打印哈希值
    print(f"耗时: {result_5['time_spent']:.2f} 秒")  # 打印耗时


if __name__ == "__main__":
    main()  # 如果脚本直接运行，则调用主函数

