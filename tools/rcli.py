#!/usr/bin/env python3
import argparse, json, os, requests, sys

CFG   = os.path.expanduser('~/.rjson/instances')
PORTS = {l.split(':')[0]: int(l.split(':')[1]) for l in open(CFG)} if os.path.exists(CFG) else {}

def port(label): return PORTS.get(label, int(label))

def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest='cmd')

    e = sub.add_parser('exec');  e.add_argument('label'); e.add_argument('code', nargs='?')
    s = sub.add_parser('status');s.add_argument('label')

    args = p.parse_args()
    if args.cmd == 'exec':
        code = args.code or sys.stdin.read()
        r = requests.post(f'http://127.0.0.1:{port(args.label)}/execute',
                          json={'command': code})
        print(json.dumps(r.json(), indent=2))
    elif args.cmd == 'status':
        r = requests.get(f'http://127.0.0.1:{port(args.label)}/status')
        print(json.dumps(r.json(), indent=2))

if __name__ == '__main__':
    main()
