import getpass
import paramiko
import threading

def start_client():
    target_ip = input("Enter Target IP (Ubuntu): ").strip()
    port = int(input("Enter Port: ").strip())
    user = input("Username (default 'moon'): ").strip() or "moon"
    password = getpass.getpass(prompt=f"Password for {user}: ")

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        print(f"[*] Connecting to {target_ip}:{port}...")
        client.connect(
            hostname=target_ip,
            port=port,
            username=user,
            password=password,
            look_for_keys=False,
            allow_agent=False
        )

        chan = client.invoke_shell()
        print("[+] Connected! Type commands, or 'exit' to quit.")

        def receive_thread():
            while True:
                try:
                    data = chan.recv(4096)
                    if not data:
                        break
                    print(data.decode("utf-8", errors="replace"), end="", flush=True)
                except Exception:
                    break

        threading.Thread(target=receive_thread, daemon=True).start()

        while True:
            cmd = input(f"{user}@target:~$ ").strip()

            if not cmd:
                continue

            chan.send(cmd + "\n")

            if cmd.lower() == "exit":
                break

    except Exception as e:
        print(f"[-] Error: {e}")
    finally:
        client.close()

if __name__ == "__main__":
    start_client()
