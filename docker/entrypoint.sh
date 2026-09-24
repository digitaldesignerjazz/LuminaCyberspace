#!/bin/sh
# Lumina Cyberspace – info entrypoint. Prints the snapshot README and public keys.
cat <<'BANNER'
==================================================================
  Lumina Cyberspace – Alpha 1.0 (1.0.0-alpha)
  https://github.com/digitaldesignerjazz/LuminaCyberspace
==================================================================
BANNER
echo "Yggdrasil: $(yggdrasil -version 2>/dev/null | sed -n "s/^Build version: //p")"
echo
if [ -f /opt/lumina/README.md ]; then
  echo "----- /opt/lumina/README.md -----"
  cat /opt/lumina/README.md
  echo
fi
if [ -f /opt/lumina/PUBLIC-KEYS.md ]; then
  echo "----- PUBLIC-KEYS.md (Zusammenfassung / summary) -----"
  grep -E '^(#|\|)' /opt/lumina/PUBLIC-KEYS.md
  echo
fi
cat <<'NOTE'
------------------------------------------------------------------
WICHTIG / IMPORTANT
  Dieses Image enthält KEINE Secrets. PrivateKey/Password in den
  Yggdrasil-Configs sind geschwärzt. Erzeuge deinen eigenen Schlüssel:
  This image contains NO secrets. Supply your own Yggdrasil key:

    docker run --rm ghcr.io/digitaldesignerjazz/lumina-cyberspace:1.0.0-alpha \
      yggdrasil -genconf > yggdrasil.conf

  Snapshot-Dateien liegen unter /opt/lumina. Shell im Container:
    docker run --rm -it ghcr.io/digitaldesignerjazz/lumina-cyberspace:1.0.0-alpha sh
  Um Yggdrasil im Container zu betreiben, braucht es z.B.
  --cap-add=NET_ADMIN --device /dev/net/tun und eine eigene Config:
    yggdrasil -useconffile /etc/yggdrasil/yggdrasil.conf
------------------------------------------------------------------
NOTE
