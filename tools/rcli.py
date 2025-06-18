#!/usr/bin/env python3
"""Simple Python client for rjsonsrv."""
import sys
import json
import requests

if len(sys.argv) < 2:
    print("Usage: rcli.py CODE [PORT]", file=sys.stderr)
    sys.exit(1)

code = sys.argv[1]
port = int(sys.argv[2]) if len(sys.argv) > 2 else 8080
url = f"http://127.0.0.1:{port}/execute"
resp = requests.post(url, json={"command": code})
print(resp.text)
