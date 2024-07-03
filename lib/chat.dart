import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:safe_chat/encryption.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.pushData});
  final Map pushData;
  @override
  _ChatPageState createState() => _ChatPageState(pushData: pushData);
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textEditingController = TextEditingController();
  final List<String> _messages = [];
  final ScrollController _scrollController = ScrollController();

  late void Function(Socket, Uint8List) current;

  _ChatPageState({required this.pushData});
  Map pushData;
  bool isConnect = false;

  void _sendMessage() {
    if (_textEditingController.text.isNotEmpty) {
      // 向服务器发送消息
      if (isConnect && pushData['socket'] != null) {
        String message;
        if (_textEditingController.text == '\$getAll') {
          setState(() {
            _messages.clear();
          });
        }
        message =
            '${pushData['nickname']}\$split\$${_textEditingController.text}';

        String encodeStr = AESEncryptUtil.encryptAes(
            plainText: message,
            keyStr: pushData['AES_key'],
            ivStr: pushData['AES_key']);
        pushData['socket'].write(encodeStr);
        _textEditingController.clear();
        _scrollToBottom();
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('错误'),
              content: const Text(
                '未正常连接!',
                style: TextStyle(fontSize: 20),
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(); // 关闭对话框
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  void login() {
    // 创建socket连接
    Socket.connect(pushData['ip'], int.parse(pushData['port']))
        .then((socket) async {
      // socket connected
      socket.write(base64.encode(utf8.encode('get_key')));

      socket.listen(
        // handle data
        (data) async {
          current(socket, data);
        },
        // handle socket being closed
        onDone: () {
          isConnect = false;
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('错误'),
                content: const Text(
                  '服务器断开连接!',
                  style: TextStyle(fontSize: 20),
                ),
                actions: <Widget>[
                  ElevatedButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop(); // 关闭对话框
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    });
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 300, //这里+300是为了防止多行滑动不到底部
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> datagen1(socket, data) async {
    String text = String.fromCharCodes(data);
    List<String> splitText = text.split(":");
    if (splitText.length > 1) {
      if (splitText[0] == 'key') {
        String pubKey = splitText[1];
        // 发送密钥
        String keyText = 'AESkey:${pushData['AES_key']}';
        socket.write(await RSAEncryptUtil.encodeString(keyText, pubKey));
        current = datagen2;
        pushData['socket'] = socket;
        isConnect = true;
      }
    }
  }

  void datagen2(socket, data) {
    setState(() {
      String rcvData = AESEncryptUtil.decryptAes(
          encryptedStr: utf8.decode(data),
          keyStr: pushData['AES_key'],
          ivStr: pushData['AES_key']);
      _messages.add(rcvData);
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isConnect) {
      current = datagen1;
      login();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chat Connect',
          style: TextStyle(color: Colors.black54),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey, Colors.white38],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                controller: _scrollController,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: RichText(
                      text: TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: '${_messages[index].split('\$split\$')[0]}：',
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              color: _messages[index].split('\$split\$')[0] ==
                                      pushData['nickname']
                                  ? Colors.black
                                  : (_messages[index].split('\$split\$')[0] ==
                                          '服务器'
                                      ? Colors.red
                                      : Colors.blue),
                              letterSpacing: 1.2,
                              fontStyle: FontStyle.normal,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.red,
                              decorationThickness: 2.0,
                              decorationStyle: TextDecorationStyle.dashed,
                            ),
                          ),
                          TextSpan(
                            text: _messages[index].split('\$split\$').length < 2
                                ? ''
                                : _messages[index].split('\$split\$')[1],
                            style: const TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.normal,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey, Colors.white30],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textEditingController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        _sendMessage();
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
