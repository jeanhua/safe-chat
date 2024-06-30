from Crypto.PublicKey import RSA
import base64
from Crypto.Cipher import PKCS1_v1_5
from Crypto import Random
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.padding import PKCS7


def generateRSAkey():
    rsa_key = RSA.generate(2048)
    pub_key = rsa_key.publickey().export_key("PEM")
    pri_key = rsa_key.export_key("PEM")
    return pri_key.decode(), pub_key.decode()


def descryption(text_encrypted_base64: str, private_key: str):
    # 字符串指定编码（转为bytes）
    text_encrypted_base64 = text_encrypted_base64.encode('utf-8')
    # base64解码
    text_encrypted = base64.b64decode(text_encrypted_base64)
    # 构建私钥对象
    cipher_private = PKCS1_v1_5.new(RSA.importKey(private_key.encode()))
    # 解密（bytes）
    text_decrypted = cipher_private.decrypt(text_encrypted, Random.new().read)
    # 解码为字符串
    text_decrypted = text_decrypted.decode()
    return text_decrypted


class AESEncryptUtil:
    @staticmethod
    def encrypt_aes(plain_text: str, key_str: str, iv_str: str, mode: str = 'cbc') -> str:
        # 确保密钥和初始向量的长度正确
        if len(key_str) != 16 and len(key_str) != 24 and len(key_str) != 32:
            raise ValueError("AES key must be either 16, 24, or 32 bytes long")
        if len(iv_str) != 16:
            raise ValueError("AES IV must be 16 bytes long")

        key = key_str.encode('utf-8')
        iv = iv_str.encode('utf-8')

        if mode == 'cbc':
            cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
        else:
            raise ValueError("Unsupported AES mode")

        encryptor = cipher.encryptor()
        padder = PKCS7(128).padder()
        padded_data = padder.update(plain_text.encode('utf-8')) + padder.finalize()
        encrypted = encryptor.update(padded_data) + encryptor.finalize()
        return base64.b64encode(encrypted).decode('utf-8')

    @staticmethod
    def decrypt_aes(encrypted_str: str, key_str: str, iv_str: str, mode: str = 'cbc') -> str:
        key = key_str.encode()
        iv = iv_str.encode()

        if mode == 'cbc':
            cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
        else:
            raise ValueError("Unsupported AES mode")

        decryptor = cipher.decryptor()
        encrypted_data = base64.b64decode(encrypted_str)
        decrypted = decryptor.update(encrypted_data) + decryptor.finalize()

        unpadder = PKCS7(128).unpadder()
        unpadded_data = unpadder.update(decrypted) + unpadder.finalize()

        return unpadded_data.decode('utf-8')


# print('str:test','key:1234567890123456')
# enText = AESEncryptUtil.encrypt_aes('test','1234567890123456','1234567890123456')
# deText = AESEncryptUtil.decrypt_aes(enText,'1234567890123456','1234567890123456')
# print('加密：',enText)
# print('解密：',deText)