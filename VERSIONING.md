# Versionierung

Lumina Cyberspace nutzt [Semantic Versioning](https://semver.org/lang/de/) mit einem
**fortlaufenden Pre-Release-Zähler**. Jede Veröffentlichung bekommt eine eigene, eindeutige Nummer:

```
v1.0.0-alpha.1 → v1.0.0-alpha.2 → … → v1.0.0-beta.1 → … → v1.0.0-rc.1 → … → v1.0.0
```

- **Git-Tag / GitHub-Release:** `vX.Y.Z-<kanal>.N` bzw. `vX.Y.Z` (mit führendem `v`)
- **Container-Image** (`ghcr.io/digitaldesignerjazz/lumina-cyberspace`): Version ohne `v`,
  z. B. `1.0.0-alpha.2`, plus ein Kanal-Tag, der immer auf die neueste Version des Kanals zeigt:
  `alpha`, `beta`, `rc` – und `latest` nur für stabile Versionen (ohne Pre-Release-Kennung).
- Die Version steckt im Image: Label `org.opencontainers.image.version`, Datei `/opt/lumina/VERSION`,
  und `docker run --rm ghcr.io/digitaldesignerjazz/lumina-cyberspace:<version>` gibt sie aus.

## Regeln für die nächste Nummer

| Letzter Tag         | Kanal    | Nächster Tag       |
|---------------------|----------|--------------------|
| `v1.0.0-alpha.3`    | alpha    | `v1.0.0-alpha.4`   |
| `v1.0.0-alpha.3`    | beta     | `v1.0.0-beta.1`    |
| `v1.0.0-beta.2`     | rc       | `v1.0.0-rc.1`      |
| `v1.0.0-rc.1`       | stable   | `v1.0.0`           |
| `v1.0.0`            | alpha + Basis `1.1.0` | `v1.1.0-alpha.1` |

Ein Kanalwechsel beginnt wieder bei `.1`. Rückwärts (z. B. von beta zurück zu alpha) ist nicht
erlaubt, und nach einer stabilen Version muss eine neue Basisversion angegeben werden.

## Nächstes Release erstellen

1. GitHub → **Actions** → **Release next version** → **Run workflow**
   - `channel`: `alpha` (Standard), `beta`, `rc` oder `stable`
   - `base`: leer lassen (= Basis aus dem neuesten Tag) oder z. B. `1.1.0`
2. Der Workflow berechnet den nächsten Tag (`scripts/next-version.sh`), erstellt das GitHub-Release
   (Pre-Release außer bei `stable`) mit automatisch generierten Release Notes und baut/veröffentlicht
   danach direkt das Container-Image (`publish-package.yml`).

Per CLI: `gh workflow run release-next.yml -f channel=alpha`

Vorschau lokal (ohne etwas zu erstellen):

```bash
git fetch --tags
scripts/next-version.sh alpha      # z. B. v1.0.0-alpha.2
```

Ein bestehendes Release neu bauen: `gh workflow run publish-package.yml -f tag=v1.0.0-alpha.1`
