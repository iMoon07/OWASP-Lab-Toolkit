import socket

IP = "0.0.0.0"
PORT = 9997

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    server.bind((IP, PORT))

    print(f"[*] UDP listening on {IP}:{PORT}")
    print("[*] Press Ctrl+C to stop the server")

    try:
        while True:
            data, address = server.recvfrom(4096)

            print(f"[*] Received from {address[0]}:{address[1]}")
            print(f"[*] Message: {data.decode('utf-8')}")

            server.sendto(b"ACK", address)

    except KeyboardInterrupt:
        print("\n[*] UDP server stopped.")

    finally:
        server.close()

if __name__ == "__main__":
    main()
