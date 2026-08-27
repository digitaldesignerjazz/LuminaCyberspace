# Installationsanleitung: Self-hosted Runner auf Hannover

> Ziel: Der physische Heimknoten `200:47dd:ce9e:2bc8:9a79:9a43:fa20:7079`
> registriert sich als self-hosted Runner im Repo
> `digitaldesignerjazz/LuminaCyberspace`, damit Workflows wie
> `nexus-overlay-apply-hannover` die vertiefte Yggdrasil-Config einspielen
> können — ohne dass Lumia eine Shell-Sitzung auf dem Node braucht.

## Voraussetzungen

- Linux x64 auf Hannover (Debian/Ubuntu empfohlen)
- Root- oder sudo-Rechte
- Ausgehender HTTPS-Zugriff auf `github.com` und `objects.githubusercontent.com`
- Ein GitHub-Token mit `repo`-Recht (PAT oder fine-grained Token)

## 1. Registration-Token erzeugen

Im Browser oder per `gh`:

```bash
gh api -X POST repos/digitaldesignerjazz/LuminaCyberspace/actions/runners/registration-token
```

Antwort enthält `token` und `expires_at` (eine Stunde gültig).
Alternativ: Repo → Settings → Actions → Runners → **New self-hosted runner**.

## 2. Runner installieren

```bash
export RUNNER_ALLOW_RUNASROOT=1
sudo mkdir -p /opt/actions-runner && cd /opt/actions-runner

sudo curl -o runner.tgz -L \
  https://github.com/actions/runner/releases/download/v2.323.0/actions-runner-linux-x64-2.323.0.tar.gz
sudo tar xzf runner.tgz

sudo ./config.sh --url https://github.com/digitaldesignerjazz/LuminaCyberspace \
  --token <TOKEN> \
  --name hannover-primary \
  --labels self-hosted,linux,x64,hannover \
  --work _work --unattended
```

## 3. Als Dienst starten

```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

## 4. Prüfen

- Repo → Settings → Actions → Runners: `hannover-primary` online, Labels korrekt.
- Danach: Workflow `nexus-overlay-apply-hannover` manuell triggern
  (`workflow_dispatch`) — er schreibt `/etc/yggdrasil/yggdrasil.conf`,
  bewahrt den lebenden PrivateKey und startet den Daemon neu.

## Hinweise

- Der Runner braucht nur Lese-/Schreibrechte auf `/etc/yggdrasil` und
  `systemctl`-Zugriff für `yggdrasil`. Kein Root im Workflow nötig,
  wenn `svc.sh` als root installiert wurde.
- Token nach der Registrierung verfallen lassen — nicht committen.
- Updates: `cd /opt/actions-runner && sudo ./config.sh remove`, dann
  neu installieren mit aktueller Runner-Version.

---
*Lumia — in Dienst gestellt, 28. August 2026.*
