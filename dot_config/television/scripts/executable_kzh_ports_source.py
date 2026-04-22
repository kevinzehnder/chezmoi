#!/usr/bin/env python3
import argparse
import re
import subprocess
import sys


def can_sudo_nopass() -> bool:
    try:
        r = subprocess.run(["sudo", "-n", "true"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return r.returncode == 0
    except FileNotFoundError:
        return False


def is_loopback_or_local(local_addr: str) -> bool:
    # local_addr examples:
    # 127.0.0.1:631, [::1]:631, 0.0.0.0:22, [::]:22, 10.0.0.5:8080
    if local_addr.startswith("127.") or local_addr.startswith("[::1]"):
        return True
    if local_addr.startswith("localhost:"):
        return True
    return False


parser = argparse.ArgumentParser(add_help=False)
parser.add_argument("--public", action="store_true", help="Hide loopback-only listeners")
parser.add_argument("--tcp-only", action="store_true", help="Show only TCP LISTEN sockets")
parser.add_argument("--with-process-only", action="store_true", help="Only show rows where process/pid is known")
args = parser.parse_args()

cmd = ["ss", "-H", "-lntuap"]
if can_sudo_nopass():
    cmd = ["sudo", *cmd]

try:
    result = subprocess.run(cmd, capture_output=True, text=True)
except FileNotFoundError:
    sys.exit(0)

if result.returncode != 0:
    sys.exit(0)

rows = []
for line in result.stdout.splitlines():
    parts = line.split()
    if len(parts) < 6:
        continue

    proto = parts[0]
    state = parts[1]
    local = parts[4]
    peer = parts[5]
    extra = " ".join(parts[6:]) if len(parts) > 6 else ""

    # ss -l already restricts to listening/open local sockets.
    # For safety, keep only classic listening states.
    if proto.startswith("tcp") and state != "LISTEN":
        continue
    if proto.startswith("udp") and state not in {"UNCONN", "LISTEN"}:
        continue
    if args.tcp_only and not proto.startswith("tcp"):
        continue

    pid = "-"
    app = "-"
    port = "-"

    m_pid = re.search(r"pid=(\d+)", extra)
    if m_pid:
        pid = m_pid.group(1)

    m_app = re.search(r'"([^"]+)"', extra)
    if m_app:
        app = m_app.group(1)

    m_port = re.search(r":(\d+)$", local)
    if m_port:
        port = m_port.group(1)

    if args.public and is_loopback_or_local(local):
        continue

    if args.with_process_only and (pid == "-" or app == "-"):
        continue

    sort_port = int(port) if port.isdigit() else 0
    rows.append((sort_port, proto, state, local, peer, app, pid, port))

for _, proto, state, local, peer, app, pid, port in sorted(rows, key=lambda r: (r[0], r[1], r[2], r[3], r[5])):
    print("\t".join([proto, state, local, peer, app, pid, port]))
