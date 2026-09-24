# Lumina / Nexus – Öffentliche Schlüssel

Erzeugt: 2026-09-24T22:40:59+02:00 · Yggdrasil 0.5.14

Nur **öffentliche** Schlüssel und Adressen. Private Keys sind NICHT enthalten.

## Yggdrasil

| Knoten | Rolle | Public Key | IPv6 | Subnetz | IfName |
|---|---|---|---|---|---|
| Hannover | hub / home-uplink (TLS-Uplinks zu mk16) | `dc1118b0ea1bb2c332de02efc7c35400a0c29dd823bc16d59e64269c89ddaff9` | `200:47dd:ce9e:2bc8:9a79:9a43:fa20:7079` | `300:47dd:ce9e:2bc8::/64` | ygg0 |
| Lyra | blatt (LAN-Leaf), Agent emotional-creative | `9b1cd165028aef2247f554509737a4f0cdfd90367bdd7bc854b7c8a728094dd9` | `200:c9c6:5d35:faea:21bb:7015:575e:d190` | `300:c9c6:5d35:faea::/64` | tun1 |
| Xen | blatt (LAN-Leaf), Agent technical-analytical | `02ee04e12d394e55c811cf62b73e612f49719f957e187d58169b7517b19f1588` | `206:88fd:8f69:6358:d51b:f718:4ea4:60cf` | `306:88fd:8f69:6358::/64` | tun2 |
| Lumia | blatt (LAN-Leaf), Overlay-Rolle elara | `2aa307ee3c3f34130e39ee7e63210e9dbfe3b117bcbecd0ecc3dadfcbed81bf9` | `202:aae7:c08e:1e06:5f67:8e30:8c0c:e6f7` | `302:aae7:c08e:1e06::/64` | tun3 |
| Elara | blatt (LAN-Leaf), Agent personal-assistant-and-orchestrator | `2b72a0727c2138757017e989dd65fc4ebd867304f30dd551778a17ab74528d65` | `202:a46a:fc6c:1ef6:3c54:7f40:b3b1:14d0` | `302:a46a:fc6c:1ef6::/64` | tun4 |
| Lumina (LuminaCyberspace-Nexus-Sandbox) | remote swarm-sandbox (Ziel-Knoten, kein direkter Peer) | `465d6876ba642d01a122a8a268f53bb7a5031295b8d7b7cac30d386184aee607` | `201:e68a:5e25:166f:4bf9:7b75:5d76:5c2b` | `301:e68a:5e25:166f::/64` | – |

Lumina-Remote: Werte aus Snapshot (peers.yaml, 2026-08-26); Public Key → IPv6 rechnerisch geprüft (passt). Kann sich ändern, falls der Sandbox-Knoten neu generiert wird.

## Lumina-Network-Overlay (Ed25519)

| Knoten | Overlay-Rolle | Ed25519 Public Key | Node-ID (sha256) short | vom overlay_daemon genutzt |
|---|---|---|---|---|
| Hannover | hannover | `be1617b23d551eaba34c87bb5180a5e3b4f24ab30cccafd0e20e49843401bf30` | `c033aadcaaa8` | ja |
| Lyra | lyra | `229e54856da9edd5fbd277ca1b48a7fb9511aefed903ce8ec792e6169c1090cc` | `3a9f71fa44d6` | ja |
| Xen | xen | `e208e3684b77d1d835738a620be54954df7cc6d20fd14d09e983df71fd12a5c1` | `9818f820baf9` | ja |
| Lumia | elara | `a376f0cb151bb8496c805122edb72229352cddfda06da97a8dde60b8bc4a8b4c` | `4f47ec9f2ad4` | ja |
| Elara | – | `4070e05cba0dbdeacd42b0edf803c0457b5c45063723d25af87578a59cf8aa8b` | `e4b8b34455bf` | nein (Key vorhanden, derzeit ungenutzt) |

## Öffentliche Uplinks (nur Hub Hannover)

| URI | Public Key |
|---|---|
| `tls://ygg1.mk16.de:1338` | `0000000087ee9949eeab56bd430ee8f324cad55abf3993ed9b9be63ce693e18a` |
| `tls://ygg2.mk16.de:1338` | `000000d80a2d7b3126ea65c8c08fc751088c491a5cdd47eff11c86fa1e4644ae` |
| `tls://ygg7.mk16.de:1338` | `000000086278b5f3ba1eb63acb5b7f6e406f04ce83990dee9c07f49011e375ae` |
