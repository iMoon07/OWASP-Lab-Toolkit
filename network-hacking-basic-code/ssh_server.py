import os
import paramiko
import socket
import sys
import threading
import subprocess

CWD = os.path.dirname(os.path.realpath(__file__))
HOSTKEY = paramiko.RSAKey(filename=os.path.join(CWD, "test_rsa.key"))

class Server(paramiko.ServerInterface):
    def check_channel_request(self, kind, chanid):
        if kind == "session":
            return paramiko.OPEN_SUCCEEDED
        return paramiko.OPEN_FAILED_ADMINISTRATIVELY_PROHIBITED

    def check_auth_password(self, username, password):
        if username == "moon" and password == "123456":
            return paramiko.AUTH_SUCCESSFUL
        return paramiko.AUTH_FAILED

    def check_channel_pty_request(
        self, channel, term, width, height, pixelwidth, pixelheight, modes
    ):
        return True

    def check_channel_shell_request(self, channel):
        return True

def handle_session(chan):
    chan.send("Welcome to bh_ssh\r\n")

    buffer = ""

    while True:
        try:
            data = chan.recv(4096)

            if not data:
                break

            buffer += data.decode("utf-8", errors="replace")

            while "\n" in buffer:
                command, buffer = buffer.split("\n", 1)
                command = command.strip()

                if not command:
                    continue

                if command.lower() == "exit":
                    chan.send("Bye\r\n")
                    chan.close()
                    return

                print(f"[Client]: {command}")

                try:
                    result = subprocess.run(
                        command,
                        shell=True,
                        text=True,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        timeout=30
                    )
                    output = result.stdout or ""
                    chan.send(output.replace("\n", "\r\n"))
                except subprocess.TimeoutExpired:
                    chan.send("Command timed out\r\n")
                except Exception as e:
                    chan.send(f"Error: {e}\r\n")

        except Exception as e:
            print(f"[-] Session error: {e}")
            break

    chan.close()

def main():
    server_ip = "0.0.0.0"
    ssh_port = 2222

    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.bind((server_ip, ssh_port))
        sock.listen(100)
        print(f"[+] Listening on {server_ip}:{ssh_port} ...")
    except Exception as e:
        print(f"[-] Listen failed: {e}")
        sys.exit(1)

    while True:
        client, addr = sock.accept()
        print(f"[+] Got a connection from: {addr}")

        transport = paramiko.Transport(client)
        transport.add_server_key(HOSTKEY)

        try:
            transport.start_server(server=Server())
            chan = transport.accept(20)

            if chan is None:
                print("[-] No channel opened.")
                transport.close()
                continue

            print("[+] Authenticated!")

            threading.Thread(
                target=handle_session,
                args=(chan,),
                daemon=True
            ).start()

        except Exception as e:
            print(f"[-] SSH negotiation/session error: {e}")
            transport.close()

if __name__ == "__main__":
    main()