import base64
import socket
import threading
import time
import encryption
import m_constant
import requests
import json

SERVER_HOST = '0.0.0.0'
pubkey = ''
prikey = ''

client_sk = []
client_addr = []
client_key = {}
message_stack = []
message_history = '服务器' + m_constant.split_flag + '历史消息---------\n'


def handle_client(client_socket, address):
    global client_sk
    global client_key
    global client_addr
    global message_stack
    global message_history

    client_key[str(address)] = '0'
    while True:
        data = client_socket.recv(2048)

        if not data:
            break

        # 客户初次连接
        if client_key[str(address)] == '0':
            received_byte = base64.decodebytes(data)
            if received_byte.decode(encoding='utf-8') == 'get_key':
                client_socket.sendall(('key:' + pubkey).encode('utf-8'))
                client_key[str(address)] = '1'
            else:
                # 不正常请求，中断服务
                del client_key[str(address)]
                client_socket.close()
        # 等待客户发送密钥
        elif client_key[str(address)] == '1':
            keyText = encryption.descryption(data.decode(), prikey)
            client_key[str(address)] = keyText.split(':', 1)[1]
            client_sk.append(client_socket)
            client_addr.append(address)
            client_socket.sendall(
                encryption.AESEncryptUtil.encrypt_aes(m_constant.server_command_text,
                                                      client_key[str(address)], client_key[str(address)]).encode())
        else:
            decodeText = encryption.AESEncryptUtil.decrypt_aes(encrypted_str=data.decode(),
                                                               key_str=client_key[str(address)],
                                                               iv_str=str(client_key[str(address)]).encode(
                                                                   encoding='utf-8').decode()).replace('：', ':')
            # 指令判断区域
            code = decodeText.split(m_constant.split_flag, 1)[1]
            if code == '$getAll':
                encrypted_message = encryption.AESEncryptUtil.encrypt_aes(message_history + '-------------\n',
                                                                          client_key[str(address)],
                                                                          client_key[str(address)])
                client_socket.sendall(encrypted_message.encode())
            # Q绑查询
            elif code[:4] == '$QQ:':
                message_stack.append(decodeText)
                message_stack.append('服务器'+m_constant.split_flag+'请稍等')
                qq = code.split(':', 1)[1]
                response = requests.get(url='https://api.xywlapi.cc/qqcx2023?qq=' + qq)
                res = json.loads(response.text)
                if res['status'] == 200:
                    message_stack.append(
                        '服务器' + m_constant.split_flag + '\n查询:' + qq + '\n结果:' + res['message'] + '\n电话:' +
                        res[
                            'phone'] + '\n归属地:' + res['phonediqu'])
                else:
                    message_stack.append('服务器' + m_constant.split_flag + '查询失败，没有找到')
            # 星座查询
            elif code[:4] == '$星座:':
                message_stack.append(decodeText)
                message_stack.append('服务器'+m_constant.split_flag+'请稍等')
                xingzuo = code.split(':', 1)[1]
                response = requests.get('https://xiaoapi.cn/API/xzys.php?msg=' + xingzuo)
                message_stack.append('服务器' + m_constant.split_flag + response.text)
            else:
                splitText = decodeText.split(m_constant.split_flag, 1)
                if len(splitText) > 1:
                    message_history = message_history + splitText[0] + ':' + splitText[1] + '\n'
                else:
                    message_history = message_history + splitText[0] + ':\n'
                message_stack.append(decodeText)

    # 这里是客户端断开连接的处理区域
    for i in range(0, len(client_sk)):
        if client_socket == client_sk[i]:
            del client_sk[i]
            del client_key[str(client_addr[i])]
            del client_addr[i]
            break

    message_stack.append('服务器' + m_constant.split_flag + str(address) + '离开')
    client_socket.close()


def server_send():
    while True:
        time.sleep(0.5)
        if len(message_stack) != 0:
            while len(message_stack) > 0:
                for client_i in range(0, len(client_sk)):
                    # 将客户端地址元组转换为字符串
                    client_addr_str = str(client_addr[client_i])
                    # 使用字符串形式的地址来获取密钥
                    client_aes_key = client_key[client_addr_str]
                    # 确保IV是一个适当的长度（例如16字节对于AES）
                    iv = client_aes_key[:16]
                    # 使用正确的密钥和IV来加密消息
                    encrypted_message = encryption.AESEncryptUtil.encrypt_aes(message_stack[0], client_aes_key, iv)
                    client_sk[client_i].sendall(encrypted_message.encode())
                # 删除已处理的消息
                with open('log.txt', 'a', encoding='utf-8') as f:
                    nickname = message_stack[0].split(m_constant.split_flag, 1)[0]
                    msg = message_stack[0].split(m_constant.split_flag, 1)[1] if len(
                        message_stack[0].split(m_constant.split_flag, 1)) > 1 else ''
                    print(nickname, ':', msg)
                    f.write(nickname + ':' + msg + '\n')
                    f.close()
                del message_stack[0]


def run_server():
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((SERVER_HOST, m_constant.SERVER_PORT))
    server_socket.listen(100)
    sendThread = threading.Thread(target=server_send, args=())
    sendThread.start()
    print('启动完成')
    while True:
        client_socket, address = server_socket.accept()
        client_thread = threading.Thread(target=handle_client, args=(client_socket, address))
        client_thread.start()


if __name__ == "__main__":
    print('正在生成密钥……')
    prikey, pubkey = encryption.generateRSAkey()
    print('生成完成,正在启动服务器')
    run_server()
