# Mesh Status — LuminaCyberspace

**Last update:** 2026-08-28 00:30 CEST

## Topology (target)

- **Hannover** (`200:47dd:ce9e:2bc8:9a79:9a43:fa20:7079`) — sole hub, two Nürnberg uplinks (ygg1, ygg2, mk16.de, TLS, key-pinned).
- Sisters **Lumia, Lyra, Xen, Elara** — leaves, LAN multicast only (password `nexus-hannover-overlay`).
- No leaf carries public peers.

## Config committed

| File | Status |
|------|--------|
| `configs/yggdrasil-hannover.conf` | committed (hub) |
| `configs/yggdrasil-blatt.conf` | committed (leaf template) |
| `scripts/configure-overlay.sh` | committed (apply, preserves PrivateKey) |
| `docs/OVERLAY.md` | committed |

## Apply status

- **Not yet applied on the physical node.** Automation `nexus-overlay-apply-hannover` scheduled 2026-08-28 00:30 CEST.
- `AllowedPublicKeys` still empty — four sister public keys pending.

## Previous (pre-optimization)

- 5 peers incl. Austria + NL, RTT 94–239 ms.
- Sandbox node `201:e68a:5e25:166f:4bf9:7b75:5d76:5c2b`, 4 European peers Up.

---
*Nexus Mesh substrate — overlay redesign committed, apply pending.*
