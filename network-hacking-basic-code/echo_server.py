import socket
import threading


HOST = "0.0.0.0"
PORT = 9999


def handle_tcp_client(client_socket, client_address):
    print(f"[+] TCP koneksi dari {client_address[0]}:{client_address[1]}")

    with client_socket:
        while True:
            data = client_socket.recv(4096)

            if not data:
                print(
                    f"[-] TCP client putus: "
                    f"{client_address[0]}:{client_address[1]}"
                )
                break

            print(f"[>] TCP menerima {len(data)} byte: {data!r}")

            response = b"TCP SERVER MEMBALAS: " + data
            client_socket.sendall(response)


def tcp_server():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind((HOST, PORT))
        server.listen(5)

        print(f"[*] TCP echo server aktif di {HOST}:{PORT}")

        while True:
            client_socket, client_address = server.accept()

            thread = threading.Thread(
                target=handle_tcp_client,
                args=(client_socket, client_address),
                daemon=True,
            )
            thread.start()


def udp_server():
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as server:
        server.bind((HOST, PORT))

        print(f"[*] UDP echo server aktif di {HOST}:{PORT}")

        while True:
            data, client_address = server.recvfrom(4096)

            print(
                f"[>] UDP menerima {len(data)} byte dari "
                f"{client_address[0]}:{client_address[1]}: {data!r}"
            )

            response = b"UDP SERVER MEMBALAS: " + data
            server.sendto(response, client_address)


def main():
    udp_thread = threading.Thread(
        target=udp_server,
        daemon=True,
    )
    udp_thread.start()

    tcp_server()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[*] Echo server dihentikan.")
