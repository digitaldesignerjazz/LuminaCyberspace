#!/usr/bin/env python3
"""Lumina UDP/4242 responder for a Yggdrasil identity."""
from __future__ import annotations
import argparse, os, socket, sys, time
from pathlib import Path

sys.path.insert(0, "/workspace/lumina-network/prototypes")
from nacl.signing import SigningKey
from lumina_node import LuminaNode, MAGIC

def load_key(name: str) -> SigningKey:
    path = Path("/workspace/lumina-state/overlay-keys") / f"{name}.key"
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        return SigningKey(path.read_bytes())
    key = SigningKey.generate()
    path.write_bytes(bytes(key))
    os.chmod(path, 0o600)
    return key

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--name", required=True)
    ap.add_argument("--bind", required=True)
    ap.add_argument("--port", type=int, default=4242)
    ap.add_argument("--role", default="")
    args = ap.parse_args()
    node = LuminaNode(args.name, signing_key=load_key(args.name.lower()), role=args.role)
    sock = socket.socket(socket.AF_INET6, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind((args.bind, args.port))
    print(f"{args.name} lumina responder [{args.bind}]:{args.port} id={node.short_id}", flush=True)
    while True:
        data, addr = sock.recvfrom(65535)
        if not data.startswith(MAGIC):
            continue
        print(f"{args.name} <- {len(data)}B from {addr[0]}", flush=True)
        try:
            sock.sendto(node.create_hello(), (addr[0], addr[1]))
            sock.sendto(node.create_heartbeat(), (addr[0], addr[1]))
        except OSError as e:
            print(f"{args.name} send fail {e}", flush=True)

if __name__ == "__main__":
    main()
