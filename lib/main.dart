import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chat.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _ipController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController(text: '\$');

  @override
  void dispose() {
    _ipController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String getRandomString(int length) {
    Random random = Random();
    List<String> digits =
        List.generate(length, (_) => random.nextInt(10).toString());
    return digits.join();
  }

  void _login() {
    if (_passwordController.text == '\$') {
      _passwordController.text = getRandomString(16);
    }
    if (_usernameController.text == '服务器') {
      _usernameController.text = '服务器(user)';
    }
    print('ip:port: ${_ipController.text}');
    print('Username: ${_usernameController.text}');
    print('Password: ${_passwordController.text}');
    if (_ipController.text == "") {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('提示'),
            content: const Text(
              '请输入IP和端口!',
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
      return;
    } else if (_usernameController.text == '') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('提示'),
            content: const Text(
              '请输入昵称!',
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
      return;
    } else if (_passwordController.text == '' ||
        _passwordController.text.length != 16) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('提示'),
            content: const Text(
              'AES key 错误!',
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
      return;
    }
    // 分割IP和端口
    String text = _ipController.text;
    RegExp regex = RegExp(r'(\d+\.\d+\.\d+\.\d+):(\d+)');
    Match? match = regex.firstMatch(text);
    if (match != null) {
      String ip = match.group(1)!;
      String port = match.group(2)!;
      // 跳转到其他页面
      Navigator.of(context).pushAndRemoveUntil(
          new MaterialPageRoute(
              builder: (context) => new ChatPage(pushData: {
                    'ip': ip,
                    'port': port,
                    'nickname': _usernameController.text,
                    'AES_key': _passwordController.text,
                  })),
          (route) => route == null);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('提示'),
            content: const Text(
              'IP和端口不符合规范!',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8FFF85),
              Color(0xFF39A0FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          // 使用 Center widget 来居中整个登录界面
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 居中登录表单
              children: <Widget>[
                const Text(
                  'Safe Chat',
                  style: TextStyle(
                    fontSize: 40.0, // 字体大小
                    fontWeight: FontWeight.bold, // 字体粗细
                    color: Colors.white, // 修改字体颜色以适配渐变背景
                    fontStyle: FontStyle.italic, // 字体样式（斜体）
                    letterSpacing: 2.0, // 字符间距
                    wordSpacing: 4.0, // 单词间距
                    textBaseline: TextBaseline.alphabetic, // 文本基线
                    height: 1.5, // 行高
                    shadows: [
                      // 文本阴影
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 2.0,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    hintText: 'IP:Port',
                    border: OutlineInputBorder(),
                    constraints: BoxConstraints.tightFor(width: 300),
                    hintStyle: TextStyle(color: Colors.white), // 修改提示文字颜色
                  ),
                  style: const TextStyle(color: Colors.white), // 修改输入文字颜色
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    hintText: 'Nickname',
                    border: OutlineInputBorder(),
                    constraints: BoxConstraints.tightFor(width: 300),
                    hintStyle: TextStyle(color: Colors.white), // 修改提示文字颜色
                  ),
                  style: const TextStyle(color: Colors.white), // 修改输入文字颜色
                  maxLength: 10, // 设置最大长度为10个字符
                  maxLengthEnforcement: MaxLengthEnforcement.enforced, // 强制限制长度
                ),
                const SizedBox(height: 10),
                // AES 密钥
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    hintText: 'AES Key(must be 16 integers)',
                    border: OutlineInputBorder(),
                    constraints: BoxConstraints.tightFor(width: 300),
                    hintStyle: TextStyle(color: Colors.white), // 修改提示文字颜色
                  ),
                  style: const TextStyle(color: Colors.white), // 修改输入文字颜色
                  keyboardType: TextInputType.number,
                  maxLength: 16, // 设置最大长度为16个字符
                  maxLengthEnforcement: MaxLengthEnforcement.enforced, // 强制限制长度
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800, // 修改按钮背景颜色
                  ),
                  child: const Text(
                    'Connect',
                    style: TextStyle(
                        fontSize: 30, color: Colors.white), // 修改按钮文字颜色
                  ),
                ),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () {
                    launch('https://github.com/jeanhua/safe-chat');
                  },
                  child: const Text(
                    'github page',
                    style: TextStyle(
                      color: Colors.purple,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
