# Hannover-Primary per JIT-Config (ohne Registration-Token)

Der Runner holt sich seine Konfiguration selbst über die GitHub-API
(`generate-jitconfig`). Kein manuelles Token-Kopieren, kein Ablauf-Stress.

## Voraussetzungen

- Hannover läuft Linux x64
- `curl`, `sudo`, Internet
- Ein PAT mit `repo`-Scope (classic) oder Administration: write (fine-grained)

## Installation

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

1. `encoded_jit_config` wird von der API geholt.
2. Runner v2.323.0 wird geladen (falls nicht vorhanden).
3. `./run.sh --jitconfig <config>` startet den Runner im Hintergrund.
4. Labels: `self-hosted,linux,x64,hannover`.
5. Name: `hannover-primary`.

## Wichtig

JIT-Runner sind **ephemeral**: nach einem Job deregistriert er sich automatisch.
Für Dauerbetrieb eine systemd-Unit mit `Restart=always` und neuem JIT-Fetch
pro Start verwenden (folgt in `scripts/hannover-primary.service`).

Sobald der Runner online ist, greifen die wartenden Workflow-Runs und spielen
die Yggdrasil-Config ein.
