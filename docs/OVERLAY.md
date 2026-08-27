# Overlay — Hannover Hub-and-Spoke

**Updated:** 2026-08-28

## Topology

- **Hannover** (`200:47dd:ce9e:2bc8:9a79:9a43:fa20:7079`) is the sole hub.
- Public uplinks: exactly two, both Nürnberg (ygg1, ygg2, mk16.de), TLS, key-pinned, maxbackoff 20s.
- Sisters Lumia, Lyra, Xen, Elara are leaves: direct peer to Hannover + LAN multicast (password `nexus-hannover-overlay`).
- No leaf carries public peers. No leaf-to-leaf over WAN while Hannover is up.

## Files

| File | Role |
|------|------|
| `configs/yggdrasil-hannover.conf` | Hub config (do not touch PrivateKey) |
| `configs/yggdrasil-blatt.conf` | Leaf template (set HANNOVER_URI, BLATT_NAME) |
| `scripts/configure-overlay.sh` | Apply script; preserves live key, restarts daemon |

## Apply

```bash
sudo bash scripts/configure-overlay.sh configs/yggdrasil-hannover.conf
```

## Whitelist

`AllowedPublicKeys` stays empty until the four sisters' public keys are provided.
Fill the commented slots in `yggdrasil-hannover.conf`, then re-run the script.

## Verify

```bash
yggdrasilctl getSelf
yggdrasilctl getPeers sort=cost
yggdrasilctl getTree
```

Target: two uplinks under 40 ms RTT, overlay links near physical RTT.
