import hashlib
import time
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import serialization

def generate_rsa_keys():
    """
    生成RSA公私钥对
    
    Returns:
        tuple: (private_key, public_key) RSA私钥和公钥对象
    """
    # 生成私钥，使用标准的 65537 作为公钥指数，密钥长度为 2048 位
    # 65537 是一个常用的公钥指数，因为它既大到足够安全，又小到能快速计算
    private_key = rsa.generate_private_key(
        public_exponent=65537,  # e值，用于公钥加密
        key_size=2048  # 密钥长度，2048位是目前推荐的安全长度
    )
    # 从私钥中提取公钥
    public_key = private_key.public_key()
    return private_key, public_key

def sign_message(private_key, message):
    """
    使用RSA私钥对消息进行签名
    
    Args:
        private_key: RSA私钥对象
        message (str): 要签名的消息
    
    Returns:
        bytes: 签名结果
    """
    # 使用PSS填充方案进行签名
    # PSS (Probabilistic Signature Scheme) 是一个现代的填充方案，比老的PKCS#1 v1.5更安全
    signature = private_key.sign(
        message.encode(),  # 将消息转换为字节串
        padding.PSS(
            mgf=padding.MGF1(hashes.SHA256()),  # 使用SHA256作为掩码生成函数
            salt_length=padding.PSS.MAX_LENGTH  # 使用最大盐长度增加安全性
        ),
        hashes.SHA256()  # 使用SHA256作为哈希算法
    )
    return signature

def verify_signature(public_key, message, signature):
    """
    使用RSA公钥验证签名
    
    Args:
        public_key: RSA公钥对象
        message (str): 原始消息
        signature (bytes): 签名数据
    
    Returns:
        bool: 验证是否成功
    """
    try:
        # 验证签名，使用与签名相同的参数
        public_key.verify(
            signature,
            message.encode(),
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()),
                salt_length=padding.PSS.MAX_LENGTH
            ),
            hashes.SHA256()
        )
        return True
    except:
        # 如果验证失败会抛出异常
        return False

def mine_hash(name, target_zeros):
    """
    进行POW挖矿，寻找符合条件的nonce值
    
    Args:
        name (str): 用户昵称
        target_zeros (int): 目标前导零的数量
    
    Returns:
        dict: 包含挖矿结果的字典
    """
    start_time = time.time()
    nonce = 0
    target = '0' * target_zeros
    
    while True:
        # 组合昵称和nonce
        hash_content = f"{name}{nonce}"
        # 计算SHA256哈希
        hash_value = hashlib.sha256(hash_content.encode()).hexdigest()
        
        # 检查是否满足前导零要求
        if hash_value.startswith(target):
            end_time = time.time()
            return {
                'nonce': nonce,
                'hash_content': hash_content,
                'hash_value': hash_value,
                'time_spent': end_time - start_time
            }
        nonce += 1

def main():
    """
    主函数：实现完整的POW挖矿和RSA签名验证流程
    """
    name = "Cobb"
    
    # 第一步：生成RSA密钥对
    print("生成RSA密钥对...")
    private_key, public_key = generate_rsa_keys()
    
    # 第二步：进行POW挖矿
    print("开始挖矿 (4个前导零)...")
    result_4 = mine_hash(name, 4)
    print(f"\n找到满足条件的哈希值！")
    print(f"Nonce: {result_4['nonce']}")
    print(f"Hash内容: {result_4['hash_content']}")
    print(f"Hash值: {result_4['hash_value']}")
    print(f"耗时: {result_4['time_spent']:.2f} 秒")
    
    # 第三步：对挖矿结果进行签名
    message = result_4['hash_content']  # 使用 "昵称Cobb + nonce" 作为签名内容
    print("\n对挖矿结果进行签名...")
    signature = sign_message(private_key, message)
    print(f"签名长度: {len(signature)} 字节")
    
    # 第四步：验证签名
    print("\n验证签名...")
    is_valid = verify_signature(public_key, message, signature)
    print(f"签名验证结果: {'成功' if is_valid else '失败'}")

if __name__ == "__main__":
    main()
