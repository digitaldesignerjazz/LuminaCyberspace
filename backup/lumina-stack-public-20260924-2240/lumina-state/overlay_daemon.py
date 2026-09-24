#!/usr/bin/env python3
"""Long-running Lumina Network overlay on local sim + Yggdrasil UDP/4242."""
from __future__ import annotations
import json, os, re, select, socket, subprocess, sys, threading, time
from pathlib import Path

sys.path.insert(0, "/workspace/lumina-network/prototypes")
from nacl.signing import SigningKey
from lumina_node import LuminaNode, MSG_HELLO, MSG_HEARTBEAT, MSG_GOSSIP
from swarm_overlay import ROLE_ELARA, ROLE_LYRA, ROLE_XEN

STATE = Path("/workspace/lumina-state")
KEYDIR = STATE / "overlay-keys"
STATUS = STATE / "overlay-status.json"
YGG_CONF = STATE / "yggdrasil.conf"
LUMINA_PORT = 4242
KEYDIR.mkdir(parents=True, exist_ok=True)

ygg_rx = {"count": 0, "last_from": None, "last_at": None}

def load_key(name: str) -> SigningKey:
    path = KEYDIR / f"{name}.key"
    if path.exists():
        return SigningKey(path.read_bytes())
    key = SigningKey.generate()
    path.write_bytes(bytes(key))
    os.chmod(path, 0o600)
    return key

def ygg_cmd(kind: str) -> str:
    try:
        return subprocess.check_output(
            ["yggdrasilctl", "-endpoint=unix:///var/run/yggdrasil/yggdrasil.sock", kind],
            text=True, timeout=5,
        )
    except Exception as e:
        return f"ERR {e}"

def parse_self(text: str) -> dict:
    out = {}
    for line in text.splitlines():
        if "IPv6 address:" in line:
            out["ipv6"] = line.split(":", 1)[1].strip().strip("│").strip()
        elif "Public key:" in line:
            out["public_key"] = line.split(":", 1)[1].strip().strip("│").strip()
        elif "IPv6 subnet:" in line:
            out["subnet"] = line.split(":", 1)[1].strip().strip("│").strip()
    return out

def parse_peer_ips(text: str) -> list[str]:
    ips = []
    for m in re.finditer(r"\b([0-9a-f]{1,4}:[0-9a-f:]{8,})\b", text, re.I):
        ip = m.group(1)
        if ip.startswith("2") and ip.count(":") >= 4:
            ips.append(ip)
    # unique, skip our own later
    seen, uniq = set(), []
    for ip in ips:
        if ip not in seen:
            seen.add(ip)
            uniq.append(ip)
    return uniq

def write_status(nodes, ygg, sock_ok):
    payload = {
        "updated": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "underlay": {
            "transport": "yggdrasil-udp",
            "port": LUMINA_PORT,
            "bind_ok": sock_ok,
            "ygg": ygg,
            "rx": dict(ygg_rx),
        },
        "nodes": {
            n.name: {
                "id": n.short_id,
                "role": n.role or "hannover",
                "peers": n.known_peers(),
                "swarm": n.swarm.summary(),
            }
            for n in nodes
        },
    }
    STATUS.write_text(json.dumps(payload, indent=2))

def recv_loop(sock: socket.socket):
    while True:
        try:
            r, _, _ = select.select([sock], [], [], 1.0)
            if not r:
                continue
            data, addr = sock.recvfrom(65535)
            ygg_rx["count"] += 1
            ygg_rx["last_from"] = addr[0]
            ygg_rx["last_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        except Exception:
            time.sleep(1)

def main():
    print("Lumina Network overlay daemon v0.3.1  ·  Yggdrasil UDP/4242", flush=True)
    lumia = LuminaNode("Lumia", signing_key=load_key("lumia"), role=ROLE_ELARA)
    lyra = LuminaNode("Lyra", signing_key=load_key("lyra"), role=ROLE_LYRA)
    xen = LuminaNode("Xen", signing_key=load_key("xen"), role=ROLE_XEN)
    hannover = LuminaNode("Hannover", signing_key=load_key("hannover"))
    nodes = (lumia, lyra, xen, hannover)
    print(f"Lumia {lumia.short_id}  Lyra {lyra.short_id}  Xen {xen.short_id}  Hannover {hannover.short_id}", flush=True)
    for n in nodes:
        n.send_hello()
    lumia.announce_agent(); lyra.announce_agent(); xen.announce_agent()

    ygg = parse_self(ygg_cmd("getSelf"))
    bind_ip = ygg.get("ipv6")
    sock = None
    sock_ok = False
    if bind_ip:
        sock = socket.socket(socket.AF_INET6, socket.SOCK_DGRAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            sock.bind((bind_ip, LUMINA_PORT))
            sock_ok = True
            print(f"ygg bind [{bind_ip}]:{LUMINA_PORT}", flush=True)
            threading.Thread(target=recv_loop, args=(sock,), daemon=True).start()
        except OSError as e:
            print(f"ygg bind failed: {e}", flush=True)
            sock.close()
            sock = None

    write_status(nodes, ygg, sock_ok)
    print("overlay online", flush=True)

    while True:
        time.sleep(30)
        for n in nodes:
            n.send_heartbeat()
            n.announce_agent()
        ygg = parse_self(ygg_cmd("getSelf"))
        if sock and sock_ok:
            own = ygg.get("ipv6")
            hello = hannover.create_hello()
            hb = hannover.create_heartbeat()
            for ip in parse_peer_ips(ygg_cmd("getPeers")):
                if ip == own:
                    continue
                try:
                    sock.sendto(hello, (ip, LUMINA_PORT))
                    sock.sendto(hb, (ip, LUMINA_PORT))
                except OSError:
                    pass
        write_status(nodes, ygg, sock_ok)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("overlay shutdown", flush=True)
