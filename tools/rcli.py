#!/usr/bin/env python3
"""Simple cross-platform CLI for r_json_server."""

import argparse
import json
import os
import subprocess
import sys
from typing import Dict, Tuple

import requests

CONFIG_DIR = os.path.expanduser("~/.rjson")
INST_FILE = os.path.join(CONFIG_DIR, "instances")
DEFAULT_PORT = 8080


def load_instances() -> Dict[str, Tuple[int, int]]:
    instances: Dict[str, Tuple[int, int]] = {}
    if os.path.exists(INST_FILE):
        with open(INST_FILE) as fh:
            for line in fh:
                label, port, pid = line.strip().split(":")
                instances[label] = (int(port), int(pid))
    return instances


def save_instances(instances: Dict[str, Tuple[int, int]]) -> None:
    os.makedirs(CONFIG_DIR, exist_ok=True)
    with open(INST_FILE, "w") as fh:
        for label, (port, pid) in instances.items():
            fh.write(f"{label}:{port}:{pid}\n")


def port_of(label: str, instances: Dict[str, Tuple[int, int]]) -> int:
    """Return the port associated with *label* or treat *label* as a port."""
    return instances[label][0] if label in instances else int(label)


def start(label: str, port: int) -> None:
    inst = load_instances()
    proc = subprocess.Popen([
        "Rscript",
        "r_json_server.R",
        "--background",
        "--port",
        str(port),
    ])
    inst[label] = (port, proc.pid)
    save_instances(inst)
    print(f"Started '{label}' on port {port} (PID {proc.pid})")


def stop(label: str) -> None:
    inst = load_instances()
    port = port_of(label, inst)
    try:
        requests.post(f"http://127.0.0.1:{port}/shutdown")
    finally:
        if label in inst:
            inst.pop(label)
            save_instances(inst)
    print(f"Sent shutdown to '{label}' (port {port})")


def status(label: str) -> None:
    inst = load_instances()
    port = port_of(label, inst)
    r = requests.get(f"http://127.0.0.1:{port}/status")
    print(json.dumps(r.json(), indent=2))


def exec_code(label: str, code: str | None) -> None:
    inst = load_instances()
    port = port_of(label, inst)
    if not code:
        code = sys.stdin.read()
        if not code.strip():
            print("Nothing to run; supply code with -e or pipe via stdin", file=sys.stderr)
            sys.exit(1)
    r = requests.post(
        f"http://127.0.0.1:{port}/execute",
        json={"command": code},
    )
    print(json.dumps(r.json(), indent=2))


def list_instances() -> None:
    inst = load_instances()
    for label, (port, pid) in inst.items():
        print(f"{label}:{port}:{pid}")


def main() -> None:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="cmd")

    sp = sub.add_parser("start")
    sp.add_argument("label", nargs="?", default="default")
    sp.add_argument("port", nargs="?", type=int, default=DEFAULT_PORT)

    stop_p = sub.add_parser("stop")
    stop_p.add_argument("label", nargs="?", default="default")

    status_p = sub.add_parser("status")
    status_p.add_argument("label", nargs="?", default="default")

    exec_p = sub.add_parser("exec")
    exec_p.add_argument("label", nargs="?", default="default")
    exec_p.add_argument("-e", dest="code")

    sub.add_parser("list")

    args = parser.parse_args()

    if args.cmd == "start":
        start(args.label, args.port)
    elif args.cmd == "stop":
        stop(args.label)
    elif args.cmd == "status":
        status(args.label)
    elif args.cmd == "exec":
        exec_code(args.label, args.code)
    elif args.cmd == "list":
        list_instances()
    else:
        parser.print_usage()


if __name__ == "__main__":
    main()
