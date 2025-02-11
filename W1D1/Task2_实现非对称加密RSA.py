"""
使用python语言实践非对称加密 RSA:

1.首先生成一个公私钥对
2.然后用私钥对符合 POW 机制的4 个 0 开头的哈希值的 “Cobb + nonce” 进行私钥签名
3.再用公钥验证
"""

# 导入必要的库
import hashlib  # 用于计算哈希值
import time     # 用于计算时间
from cryptography.hazmat.primitives import hashes  # 用于加密相关的哈希函数
from cryptography.hazmat.primitives.asymmetric import rsa, padding  # RSA加密和填充方案
from cryptography.hazmat.primitives import serialization  # 用于密钥序列化

def generate_key_pair():
    """生成RSA密钥对"""
    # 生成RSA私钥
    # public_exponent=65537 是一个常用的公钥指数
    # key_size=2048 表示密钥长度为2048位，这是一个安全的长度
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048
    )
    # 从私钥中提取公钥
    public_key = private_key.public_key()
    return private_key, public_key

def mine_block(name, target_zeros):
    """POW挖矿函数，寻找满足条件的nonce值"""
    # 生成目标前导零字符串
    target = '0' * target_zeros
    # 初始化nonce值
    nonce = 0
    # 记录开始时间
    start_time = time.time()
    
    while True:
        # 组合数据
        data = f"{name}{nonce}"
        # 计算SHA256哈希值
        hash_result = hashlib.sha256(data.encode()).hexdigest()
        
        # 检查是否满足前导零要求
        if hash_result.startswith(target):
            # 计算耗时
            end_time = time.time()
            time_spent = end_time - start_time
            # 返回结果
            return {
                'nonce': nonce,          # 成功的nonce值
                'hash': hash_result,     # 对应的哈希值
                'data': data,            # 原始数据
                'time': time_spent       # 计算耗时
            }
        nonce += 1

def sign_data(private_key, data):
    """使用私钥对数据进行签名"""
    # 使用私钥创建签名
    # padding.PSS 是一种概率签名方案，提供更好的安全性
    # MGF1 是掩码生成函数
    # salt_length 是盐值长度，使用最大长度提供更好的安全性
    signature = private_key.sign(
        data.encode(),  # 将数据转换为字节串
        padding.PSS(
            mgf=padding.MGF1(hashes.SHA256()),
            salt_length=padding.PSS.MAX_LENGTH
        ),
        hashes.SHA256()  # 使用SHA256作为哈希算法
    )
    return signature

def verify_signature(public_key, signature, data):
    """使用公钥验证签名"""
    try:
        # 尝试验证签名
        # 使用与签名时相同的参数
        public_key.verify(
            signature,
            data.encode(),
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()),
                salt_length=padding.PSS.MAX_LENGTH
            ),
            hashes.SHA256()
        )
        return True  # 验证成功
    except Exception as e:
        print(f"验证失败: {e}")  # 打印错误信息
        return False  # 验证失败

def main():
    # 1. 生成RSA密钥对
    print("正在生成RSA密钥对...")
    private_key, public_key = generate_key_pair()
    print("密钥对生成完成！")
    
    # 2. 执行POW挖矿
    print("\n开始POW挖矿过程...")
    name = "Cobb"
    result = mine_block(name, 4)  # 寻找4个前导零
    print(f"挖矿完成！")
    print(f"数据内容: {result['data']}")
    print(f"哈希值: {result['hash']}")
    print(f"使用的nonce: {result['nonce']}")
    print(f"耗时: {result['time']:.2f} 秒")
    
    # 3. 使用私钥签名
    print("\n开始对数据进行签名...")
    signature = sign_data(private_key, result['data'])
    print(f"签名完成！签名长度: {len(signature)} 字节")
    
    # 4. 使用公钥验证签名
    print("\n开始验证签名...")
    is_valid = verify_signature(public_key, signature, result['data'])
    if is_valid:
        print("签名验证成功！数据完整性得到确认。")
    else:
        print("签名验证失败！数据可能被篡改。")

    # 5. 测试签名防篡改能力
    print("\n测试篡改后的数据...")
    tampered_data = result['data'] + "tampered"  # 故意篡改数据
    is_valid = verify_signature(public_key, signature, tampered_data)
    if is_valid:
        print("警告：篡改的数据通过了验证！")
    else:
        print("安全性测试通过：篡改的数据无法通过验证。")

# 程序入口点
if __name__ == "__main__":
    main()
