import 'dart:convert';
import 'dart:core';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

//rsa加密
class RSAEncryptUtil {
  // Rsa加密最大长度(密钥长度/8-11)
  static const int MAX_ENCRYPT_BLOCK = 245;
  //公钥分段加密
  static Future encodeString(String content, String publicPem) async {
    //创建公钥对象
    RSAPublicKey publicKey = RSAKeyParser().parse(publicPem) as RSAPublicKey;
    //创建加密器
    final encrypter = Encrypter(RSA(publicKey: publicKey));

    //分段加密
    // 原始字符串转成字节数组
    List<int> sourceBytes = utf8.encode(content);
    //数据长度
    int inputLength = sourceBytes.length;
    // 缓存数组
    List<int> cache = [];
    // 分段加密 步长为MAX_ENCRYPT_BLOCK
    for (int i = 0; i < inputLength; i += MAX_ENCRYPT_BLOCK) {
      //剩余长度
      int endLen = inputLength - i;
      List<int> item;
      if (endLen > MAX_ENCRYPT_BLOCK) {
        item = sourceBytes.sublist(i, i + MAX_ENCRYPT_BLOCK);
      } else {
        item = sourceBytes.sublist(i, i + endLen);
      }
      // 加密后对象转换成数组存放到缓存
      cache.addAll(encrypter.encryptBytes(item).bytes);
    }
    return base64Encode(cache);
  }
}


/// AES加密算法
class AESEncryptUtil {
  static String encryptAes({
    required String plainText,
    required String keyStr,
    required String ivStr,
    AESMode? mode = AESMode.cbc,
  }) {
    final key = Key.fromUtf8(keyStr);
    final iv = IV.fromUtf8(ivStr);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return encrypted.base64;
  }

  static String decryptAes(
      {required String encryptedStr,
        required String keyStr,
        required String ivStr,
        AESMode? mode = AESMode.cbc}) {
    final key = Key.fromUtf8(keyStr);
    final iv = IV.fromUtf8(ivStr);

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final decrypted = encrypter.decrypt64(encryptedStr, iv: iv);

    return decrypted;
  }
}