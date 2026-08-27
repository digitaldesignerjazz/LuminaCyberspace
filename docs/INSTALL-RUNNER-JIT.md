# Hannover-Primary per JIT-Config (Dauerbetrieb)

Der Runner holt sich seine Konfiguration selbst über die GitHub-API
(`generate-jitconfig`). Kein manuelles Token-Kopieren, kein Ablauf-Stress.
Läuft als systemd-Dienst mit `Restart=always` — bei jedem Neustart
frisches JIT-Config, kein ephemeral-Abbruch mehr.

## Voraussetzungen

- Hannover läuft Linux x64
- `curl`, `sudo`, Internet
- Ein PAT mit `repo`-Scope (classic) oder Administration: write (fine-grained)

## Installation (ein Befehl)

```bash
git clone https://github.com/digitaldesignerjazz/LuminaCyberspace.git
cd LuminaCyberspace
sudo bash scripts/install-runner-jit.sh <PAT>
```

Oder mit Env-Variable:

```bash
export GITHUB_PAT=<PAT>
sudo -E bash scripts/install-runner-jit.sh
```

## Was passiert

1. Probe: `encoded_jit_config` wird von der API geholt.
2. Runner v2.323.0 wird geladen (falls nicht vorhanden).
3. PAT wird in `/etc/hannover-runner/env` hinterlegt (chmod 600).
4. `hannover-primary.service` wird installiert und aktiviert.
5. `systemctl restart hannover-primary` — der Dienst holt bei jedem Start
   ein frisches JIT-Config und startet `run.sh --jitconfig`.
6. Labels: `self-hosted,linux,x64,hannover`. Name: `hannover-primary`.

## Dauerbetrieb

```bash
sudo systemctl status hannover-primary
sudo journalctl -u hannover-primary -f
```

Fällt der Prozess, startet systemd ihn nach 10 Sekunden neu — mit
neuem JIT-Config. Kein manueller Eingriff nötig.

Sobald der Runner online ist, greifen die wartenden Workflow-Runs und
spielen die Yggdrasil-Config ein.
