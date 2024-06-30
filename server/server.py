import base64
import socket
import threading
import requests
import encryption

debug = True

SERVER_HOST = '0.0.0.0'
SERVER_PORT = 8888
pubkey = ''
prikey = ''

client_sk = []
client_addr = []
client_key = {}
message_stack = []


def handle_client(client_socket, address):
    client_key[str(address)] = '0'
    if debug: print('客户进入:' + str(address))

    while True:
        data = client_socket.recv(2048)

        if not data:
            break

        if client_key[str(address)] == '0':
            received_byte = base64.decodebytes(data)
            if received_byte.decode(encoding='utf-8') == 'get_key':
                client_socket.sendall(('key:' + pubkey).encode('utf-8'))
                if debug: print('服务器发送公钥至' + str(address))
                client_key[str(address)] = '1'
        elif client_key[str(address)] == '1':
            keyText = encryption.descryption(data.decode(), prikey)
            if debug: print('服务器收到密钥' + str(address) + ' ' + keyText)
            client_key[str(address)] = keyText.split(':', 1)[1]
            client_sk.append(client_socket)
            client_addr.append(address)
        else:
            print('收到未解密的消息:' + data.decode(), '解密密钥:' + client_key[str(address)],'解密IV:'+client_key[str(address)],'iv长度:',len(client_key[str(address)]))
            decodeText = encryption.AESEncryptUtil.decrypt_aes(encrypted_str=data.decode(),
                                                               key_str=client_key[str(address)],
                                                               iv_str=str(client_key[str(address)]).encode(encoding='utf-8').decode())
            if debug: print('收到消息', decodeText)
            message_stack.append(decodeText)

    # 这里是客户端断开连接的处理区域
    for i in range(0, len(client_sk)):
        if client_socket == client_sk[i]:
            del client_sk[i]
            del client_key[str(client_addr[i])]
            del client_addr[i]

    message_stack.append('服务器$split$' + str(address) + '离开')
    client_socket.close()


def server_send():
    while True:
        if len(message_stack) != 0:
            print('转发消息')
            for any_message in message_stack:
                for client_i in range(0, len(client_sk)):
                    # 将客户端地址元组转换为字符串
                    client_addr_str = str(client_addr[client_i])
                    # 使用字符串形式的地址来获取密钥
                    client_aes_key = client_key[client_addr_str]
                    # 确保IV是一个适当的长度（例如16字节对于AES）
                    iv = client_aes_key[:16]
                    # 使用正确的密钥和IV来加密消息
                    encrypted_message = encryption.AESEncryptUtil.encrypt_aes(any_message, client_aes_key, iv)
                    client_sk[client_i].sendall(encrypted_message.encode())
                # 删除已处理的消息
                del message_stack[0]



def run_server():
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((SERVER_HOST, SERVER_PORT))
    server_socket.listen(100)
    sendthread = threading.Thread(target=server_send,args=())
    sendthread.start()

    while True:
        client_socket, address = server_socket.accept()
        client_thread = threading.Thread(target=handle_client, args=(client_socket, address))
        client_thread.start()


if __name__ == "__main__":
    print('正在生成密钥……')
    prikey, pubkey = encryption.generateRSAkey()
    print('生成完成,正在启动服务器')
    run_server()
    res = requests.get('https://myip.ipip.net', timeout=5).text
    print(res, '开放端口', SERVER_PORT)
