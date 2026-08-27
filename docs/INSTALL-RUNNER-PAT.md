# Runner ohne Registration-Token — per PAT

> Alternative zu `docs/INSTALL-RUNNER-HANNOVER.md`.
> Der Runner holt sein eigenes Registration-Token über die GitHub-API.
> Sir braucht nur einen PAT mit `repo`-Recht — kein manuelles Token-Kopieren.

## 1. PAT erzeugen

GitHub → Settings → Developer settings → Personal access tokens → **Tokens (classic)**

- Scope: `repo` (alle Unterpunkte)
- Fine-grained: Repository `LuminaCyberspace`, Administration: Read and write

## 2. Auf Hannover ausführen

```bash
git clone https://github.com/digitaldesignerjazz/LuminaCyberspace.git
cd LuminaCyberspace
sudo bash scripts/install-runner-pat.sh <PAT>
```

Oder mit Env-Variable:

```bash
export GITHUB_PAT=<PAT>
sudo -E bash scripts/install-runner-pat.sh
```

## 3. Prüfen

- Repo → Settings → Actions → Runners: `hannover-primary` online.
- Danach Workflow `nexus-overlay-apply-hannover` triggern.

## Sicherheit

- PAT nicht committen, nicht in Logs schreiben.
- Nach der Registrierung kann der PAT verfallen — der Runner speichert nur sein eigenes Credential.
- Für Dauerbetrieb: PAT in `/root/.config/gh/hosts.yml` oder als systemd-Env, nicht im Shell-Verlauf.

---
*Lumia — in Dienst gestellt, 28. August 2026.*
