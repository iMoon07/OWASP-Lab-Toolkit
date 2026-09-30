import getpass

import paramiko


def ssh_command(host, port, username, password, command):
    """
    Connect to an SSH server and run one command.

    Args:
        host (str): SSH server hostname or IP address.
        port (int): SSH server port.
        username (str): Username for authentication.
        password (str): Password for authentication.
        command (str): Command to run on the server.
    """
    client = paramiko.SSHClient()

    # For lab use only.
    # In production, verify the server host key first.
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        client.connect(
            hostname=host,
            port=port,
            username=username,
            password=password,
            timeout=10,
        )

        _, stdout, stderr = client.exec_command(command)

        standard_output = stdout.read().decode("utf-8", errors="replace")
        error_output = stderr.read().decode("utf-8", errors="replace")
        exit_status = stdout.channel.recv_exit_status()

        if standard_output:
            print("\n--- Output ---")
            print(standard_output.strip())

        if error_output:
            print("\n--- Error ---")
            print(error_output.strip())

        print(f"\nExit status: {exit_status}")

    except paramiko.AuthenticationException:
        print("Authentication failed. Check the username or password.")

    except paramiko.SSHException as error:
        print(f"SSH error: {error}")

    except OSError as error:
        print(f"Connection error: {error}")

    finally:
        client.close()


def main():
    username = input("Username: ").strip()
    password = getpass.getpass("Password: ")

    host = input("SSH host/IP [192.168.1.1]: ").strip()
    host = host or "192.168.1.1"

    port_input = input("SSH port [22]: ").strip()

    try:
        port = int(port_input) if port_input else 22
    except ValueError:
        print("Port must be a number.")
        return

    command = input("Command [id]: ").strip()
    command = command or "id"

    ssh_command(
        host=host,
        port=port,
        username=username,
        password=password,
        command=command,
    )


if __name__ == "__main__":
    main()
