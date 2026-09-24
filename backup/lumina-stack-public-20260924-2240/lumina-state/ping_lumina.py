import socket, sys
from pathlib import Path
sys.path.insert(0, "/workspace/lumina-network/prototypes")
from nacl.signing import SigningKey
from lumina_node import LuminaNode

key = SigningKey(Path("/workspace/lumina-state/overlay-keys/hannover.key").read_bytes())
node = LuminaNode("Hannover-ping", signing_key=key)
src = "200:47dd:ce9e:2bc8:9a79:9a43:fa20:7079"
targets = [
    "200:c9c6:5d35:faea:21bb:7015:575e:d190",  # Lyra
    "206:88fd:8f69:6358:d51b:f718:4ea4:60cf",  # Xen
    "202:aae7:c08e:1e06:5f67:8e30:8c0c:e6f7",  # Lumia
    "202:a46a:fc6c:1ef6:3c54:7f40:b3b1:14d0",  # Elara
]
s = socket.socket(socket.AF_INET6, socket.SOCK_DGRAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind((src, 4243))
s.settimeout(2)
hello = node.create_hello()
replies = []
for ip in targets:
    s.sendto(hello, (ip, 4242))
    print("sent hello to", ip, flush=True)
try:
    while True:
        data, addr = s.recvfrom(65535)
        replies.append(addr[0])
        print("reply from", addr[0], "bytes", len(data), flush=True)
except socket.timeout:
    pass
print("reply_count", len(replies), flush=True)
s.close()
