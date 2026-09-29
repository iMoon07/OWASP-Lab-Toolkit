import argparse
import select
import socket
import threading


def hexdump(data, length=16):
    if isinstance(data, str):
        data = data.encode()

    for offset in range(0, len(data), length):
        chunk = data[offset:offset + length]

        hexa = " ".join(f"{byte:02X}" for byte in chunk)
        printable = "".join(
            chr(byte) if 32 <= byte <= 126 else "."
            for byte in chunk
        )

        print(f"{offset:04X}   {hexa:<{length * 3}}   {printable}")


def request_handler(data):
    """
    Process client data before forwarding it to the remote server.
    """
    return data


def response_handler(data):
    """
    Process remote server data before forwarding it to the client.
    """
    return data


def forward_tcp_data(source, destination, direction):
    data = source.recv(4096)

    if not data:
        try:
            destination.shutdown(socket.SHUT_WR)
        except OSError:
            pass

        return False

    print(f"\n[TCP {direction}] {len(data)} bytes")
    hexdump(data)

    if direction == "CLIENT -> SERVER":
        data = request_handler(data)
    else:
        data = response_handler(data)

    if data:
        destination.sendall(data)

    return True


def tcp_proxy_handler(
    client_socket,
    client_address,
    remote_host,
    remote_port,
    receive_first,
):
    remote_socket = None

    try:
        remote_socket = socket.create_connection(
            (remote_host, remote_port),
            timeout=5,
        )

        print(
            f"\n[+] TCP client connected: "
            f"{client_address[0]}:{client_address[1]}"
        )

        print(
            f"[+] TCP remote server: "
            f"{remote_host}:{remote_port}"
        )

        if receive_first:
            remote_socket.settimeout(5)

            try:
                banner = remote_socket.recv(4096)

                if banner:
                    print(
                        f"\n[TCP SERVER -> CLIENT] "
                        f"{len(banner)} bytes"
                    )

                    hexdump(banner)

                    banner = response_handler(banner)

                    if banner:
                        client_socket.sendall(banner)

            except socket.timeout:
                print(
                    "[!] TCP receive-first timeout: "
                    "remote server sent no banner"
                )

            finally:
                remote_socket.settimeout(None)

        sockets = [client_socket, remote_socket]

        while sockets:
            readable, _, _ = select.select(sockets, [], [])

            for source in readable:
                if source is client_socket:
                    destination = remote_socket
                    direction = "CLIENT -> SERVER"
                else:
                    destination = client_socket
                    direction = "SERVER -> CLIENT"

                connection_open = forward_tcp_data(
                    source,
                    destination,
                    direction,
                )

                if not connection_open:
                    sockets.remove(source)
                    source.close()

    except OSError as error:
        print(f"[!] TCP proxy error: {error}")

    finally:
        if client_socket:
            client_socket.close()

        if remote_socket:
            remote_socket.close()

        print("[-] TCP connection closed")


def tcp_server_loop(
    local_host,
    local_port,
    remote_host,
    remote_port,
    receive_first,
):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
        server.setsockopt(
            socket.SOL_SOCKET,
            socket.SO_REUSEADDR,
            1,
        )

        server.bind((local_host, local_port))
        server.listen(10)

        print(f"[*] TCP proxy listening: {local_host}:{local_port}")
        print(
            f"[*] TCP forwarding target: "
            f"{remote_host}:{remote_port}"
        )

        while True:
            client_socket, client_address = server.accept()

            thread = threading.Thread(
                target=tcp_proxy_handler,
                args=(
                    client_socket,
                    client_address,
                    remote_host,
                    remote_port,
                    receive_first,
                ),
                daemon=True,
            )

            thread.start()


def udp_proxy_handler(
    proxy_socket,
    client_data,
    client_address,
    remote_host,
    remote_port,
    timeout,
):
    try:
        print(
            f"\n[UDP CLIENT -> SERVER] "
            f"{len(client_data)} bytes from "
            f"{client_address[0]}:{client_address[1]}"
        )

        hexdump(client_data)

        client_data = request_handler(client_data)

        if not client_data:
            return

        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as remote_socket:
            remote_socket.settimeout(timeout)
            remote_socket.connect((remote_host, remote_port))

            remote_socket.send(client_data)
            response = remote_socket.recv(4096)

        print(
            f"\n[UDP SERVER -> CLIENT] "
            f"{len(response)} bytes"
        )

        hexdump(response)

        response = response_handler(response)

        if response:
            proxy_socket.sendto(response, client_address)

    except socket.timeout:
        print("[!] UDP timeout: remote server did not respond")

    except OSError as error:
        print(f"[!] UDP proxy error: {error}")


def udp_server_loop(
    local_host,
    local_port,
    remote_host,
    remote_port,
    timeout,
):
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as server:
        server.bind((local_host, local_port))

        print(f"[*] UDP proxy listening: {local_host}:{local_port}")
        print(
            f"[*] UDP forwarding target: "
            f"{remote_host}:{remote_port}"
        )

        while True:
            client_data, client_address = server.recvfrom(4096)

            thread = threading.Thread(
                target=udp_proxy_handler,
                args=(
                    server,
                    client_data,
                    client_address,
                    remote_host,
                    remote_port,
                    timeout,
                ),
                daemon=True,
            )

            thread.start()


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="TCP and UDP proxy with hex dump output"
    )

    parser.add_argument(
        "--mode",
        choices=["tcp", "udp", "both"],
        default="both",
        help="Proxy mode: tcp, udp, or both",
    )

    parser.add_argument(
        "--local-host",
        required=True,
        help="Local IP address for the proxy listener",
    )

    parser.add_argument(
        "--local-port",
        required=True,
        type=int,
        help="Local proxy port for TCP and UDP",
    )

    parser.add_argument(
        "--remote-host",
        required=True,
        help="Remote server IP address",
    )

    parser.add_argument(
        "--remote-tcp-port",
        type=int,
        default=9999,
        help="Remote TCP server port",
    )

    parser.add_argument(
        "--remote-udp-port",
        type=int,
        default=9997,
        help="Remote UDP server port",
    )

    parser.add_argument(
        "--receive-first",
        action="store_true",
        help="Receive TCP server banner before client data",
    )

    parser.add_argument(
        "--udp-timeout",
        type=int,
        default=5,
        help="UDP response timeout in seconds",
    )

    return parser.parse_args()


def main():
    args = parse_arguments()

    if args.mode == "udp":
        udp_server_loop(
            args.local_host,
            args.local_port,
            args.remote_host,
            args.remote_udp_port,
            args.udp_timeout,
        )

    elif args.mode == "tcp":
        tcp_server_loop(
            args.local_host,
            args.local_port,
            args.remote_host,
            args.remote_tcp_port,
            args.receive_first,
        )

    else:
        udp_thread = threading.Thread(
            target=udp_server_loop,
            args=(
                args.local_host,
                args.local_port,
                args.remote_host,
                args.remote_udp_port,
                args.udp_timeout,
            ),
            daemon=True,
        )

        udp_thread.start()

        tcp_server_loop(
            args.local_host,
            args.local_port,
            args.remote_host,
            args.remote_tcp_port,
            args.receive_first,
        )


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[*] Proxy stopped")