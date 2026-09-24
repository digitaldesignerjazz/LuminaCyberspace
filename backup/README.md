# Lumina-Stack Backup (öffentlich)

Öffentlicher, secret-freier Snapshot des Lumina/Nexus-Stacks vom Hannover-Knoten.

- **Datum:** 2026-09-24, 22:40 (Europe/Berlin)
- **Ordner:** `lumina-stack-public-20260924-2240/` (54 Dateien: Yggdrasil-Konfigurationen, Startskripte, Roster, Agenten, Nexus/Overlay, systemd-Units)
- **Archiv:** `lumina-stack-public-20260924-2240.tar.gz` (gleicher Inhalt), Prüfsumme in `lumina-stack-public-20260924-2240.tar.gz.sha256`
  - Prüfen: `sha256sum -c lumina-stack-public-20260924-2240.tar.gz.sha256`

## Keine Secrets enthalten

Alle Private Keys (Yggdrasil `PrivateKey`, Overlay-Ed25519-Seeds) und das LAN-Multicast-Passwort
sind durch `<REDACTED>` ersetzt. Zugangsdaten, Tokens und Logs sind nicht enthalten.
Vor dem Commit mit gitleaks, trufflehog und manuell geprüft: keine Funde.

## Wiederherstellung

Zum Wiederherstellen werden **eigene Private Keys** benötigt (bestehende Schlüssel aus dem privaten,
nicht veröffentlichten Backup oder neu mit `yggdrasil -genconf` erzeugen) sowie ein eigenes
Multicast-Passwort. Details siehe `lumina-stack-public-20260924-2240/README.md`.
