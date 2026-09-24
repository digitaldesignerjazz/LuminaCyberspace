# Lumina / Nexus Stack – Öffentliches Backup (ohne Geheimnisse)

Dieses Archiv ist eine **teilbare** Kopie des Lumina/Nexus-Stacks vom Host *Hannover*.
Es enthält **nur öffentliche Schlüssel**, Code, Skripte und bereinigte Konfigurationen.
**Alle Geheimnisse wurden entfernt** (siehe unten). Zum Wiederherstellen braucht man
eigene Private Keys – oder das separate private Backup des Eigentümers.

## Inhalt

| Pfad | Inhalt |
|---|---|
| `PUBLIC-KEYS.md`, `keys.json` | Alle Knoten: Yggdrasil Public Key, IPv6, Subnetz, Rolle; Overlay-Ed25519-Public-Keys; mk16-Uplinks |
| `yggdrasil/hannover-hub.yggdrasil.conf` | Hub-Konfiguration (live `yggdrasil.conf`), PrivateKey + Multicast-Passwort `<REDACTED>` |
| `yggdrasil/ygg-{lyra,xen,lumia,elara}.conf` | Leaf-Konfigurationen, ebenso bereinigt (Peers, Listen, MulticastInterfaces, AllowedPublicKeys, IfName, NodeInfo bleiben) |
| `yggdrasil/templates/` | Vorlagen: Blatt, Remote-Blatt, Hub-from-onyx |
| `yggdrasil/ygg-identities.txt` | Übersicht der Identitäten (nur öffentlich) |
| `lumina-state/` | `start-stack.sh` (idempotenter Stack-Start), `start-systemd.sh`, `on-boot.sh`, Agenten-Skripte `elara.sh`/`lyra.sh`/`xen.sh`/`orchestrator.sh`, Responder-Wrapper `run-*-responder.sh`, `lumina_responder.py`, `overlay_daemon.py`, `run-overlay.sh`, `ping_lumina.py`, `04-connect-lumina.sh`, `roster.json` (Multicast-Passwort entfernt), `nexus/` (Tailscale-Underlay-Skript ohne Key, Overlay-Konfig + nftables), `github-workflows/ci.yml` |
| `nexus/python/` | Nexus-Orchestrator-Code + Konfig-Vorlagen |
| `lumina-network/` | Kademlia/Swarm-Overlay-Prototypen (`lumina_node.py`, `kademlia.py`, `swarm_overlay.py`) |
| `start_lumina_overlay.py` | Demo-Starter des Overlays |
| `federal-city/` | Code (`src/`), CI-Workflow, `status.json` |
| `agents/ollama-client.sh` | Ollama-Helfer für Agenten (gehört nach `/usr/lib/lumina/agents/`) |
| `systemd/nexus-control.service.template` | Unit-Vorlage (nutzt eine eigene `.env`, nicht enthalten) |

## Topologie

```
                 ygg1.mk16.de   ygg2.mk16.de   ygg7.mk16.de     (öffentliche DE-Peers, TLS :1338)
                        \            |            /
                         \           |           /
                      ┌──────────────────────────────┐
                      │  Hannover (Hub, ygg0)        │  Listen: []  (kein offenes Listen)
                      │  200:47dd:ce9e:2bc8:…:7079   │
                      └──────────────────────────────┘
                     LAN-Multicast (eth/enp/eno, dann wlan; mit Passwort)
                 ┌───────────┬───────────┬───────────┐
               Lyra (tun1)  Xen (tun2)  Lumia (tun3)  Elara (tun4)   ← Blätter, keine Public-Peers
```

- Nur **Hannover** hat öffentliche Weitstrecken-Peers (max. 3, alle mk16 in DE).
- Die 4 Blätter peeren nur lokal (Multicast) bzw. sternförmig zum Hub; `AllowedPublicKeys` erlaubt nur die Schwesterknoten.
- Entferntes Ziel: **Lumina** (LuminaCyberspace-Nexus-Sandbox) `201:e68a:5e25:166f:4bf9:7b75:5d76:5c2b` – kein direkter Peer, Erreichbarkeit über das Mesh (`04-connect-lumina.sh`, `ping_lumina.py`).
- Darüber läuft das **Lumina-Network-Overlay** (Ed25519-signierte Nachrichten, UDP/4242 auf der Hub-Ygg-IPv6).
- Agenten: Elara (Assistent/Orchestrator, nutzt Ollama), Lyra (emotional-kreativ), Xen (technisch-analytisch), Orchestrator.

## GitHub Actions Runner (nur nicht-geheime Fakten)

- Name: `hannover-primary` · Labels: `self-hosted, linux, x64, hannover`
- Repository: `digitaldesignerjazz/LuminaCyberspace` · Pool: `Default` · Runner-Version: `2.337.0`
- Installationsort: `/workspace/lumina-persist/actions-runner` (Symlink `/opt/actions-runner`)
- **Nicht enthalten:** `.runner`, `.credentials`, `.credentials_rsaparams`, `.env`, `_work`, `_diag`, Binaries.
  Zum Wiederherstellen neu registrieren: `./config.sh --url https://github.com/digitaldesignerjazz/LuminaCyberspace --token <NEUER-REG-TOKEN> --name hannover-primary --labels hannover`.

## Wiederherstellung mit eigenen Schlüsseln

1. Yggdrasil 0.5.x installieren (`yggdrasil`, `yggdrasilctl`).
2. Pro Knoten neuen Schlüssel erzeugen: `yggdrasil -genconf > /tmp/new.conf` und die `PrivateKey`-Zeile
   in die jeweilige Datei aus `yggdrasil/` übernehmen (statt `"<REDACTED>"`).
   *Hinweis:* Mit neuen Keys ändern sich Public Key und IPv6 – dann `AllowedPublicKeys` der anderen Knoten,
   `roster.json` und `PUBLIC-KEYS.md` anpassen. Der Eigentümer nutzt stattdessen seine Original-Keys aus dem privaten Backup.
3. Eigenes Multicast-Passwort in `MulticastInterfaces[].Password` (alle Knoten gleich) und in `roster.json` eintragen.
4. Dateien nach `/workspace/lumina-state/` legen (Hub-Datei als `yggdrasil.conf`), Code nach `/workspace/nexus`, `/workspace/lumina-network`, `/workspace/federal-city`.
5. Python-venv `/workspace/lumina-venv` mit `pynacl` anlegen (`pip install -r lumina-network/requirements.txt`).
   Overlay-Keys (`lumina-state/overlay-keys/*.key`) werden beim ersten Start des `overlay_daemon.py` automatisch neu erzeugt (andere Public Keys).
6. Optional Ollama + Modell installieren; `agents/ollama-client.sh` nach `/usr/lib/lumina/agents/`.
7. `bash lumina-state/start-stack.sh` – prüfen mit `yggdrasilctl -endpoint unix:///var/run/yggdrasil/yggdrasil.sock getSelf` / `getPeers`.

## Bewusst ausgeschlossen

- Alle Private Keys (Yggdrasil `PrivateKey`, Overlay-Ed25519-Seeds `overlay-keys/*.key`)
- Multicast-Passwort (LAN-Peering-Geheimnis) → `<REDACTED>`
- Runner-Credentials (`.runner`, `.credentials*`, `.env`), Tokens, PATs, Headscale/Tailscale-Auth-Keys, Passwörter
- Alle Logs (`*.log`, können Tokens/IPs enthalten), Laufzeitstatus (`overlay-status.json`, `agents/*/status`, `orchestrator/*`)
- Backups mit Keys (`yggdrasil.conf.bak-*`, `yggdrasil-hannover.conf`), `_work`/`_diag`, Binaries, Ollama-Modelle, venvs, Docker-Daten
