#!/bin/sh
# Lumina Cyberspace – info entrypoint. Prints version, snapshot README and public keys.
VERSION="$(cat /opt/lumina/VERSION 2>/dev/null || echo "${LUMINA_VERSION:-dev}")"
IMAGE="ghcr.io/digitaldesignerjazz/lumina-cyberspace:${VERSION}"
cat <<BANNER
==================================================================
  Lumina Cyberspace – Version ${VERSION}
  https://github.com/digitaldesignerjazz/LuminaCyberspace
==================================================================
BANNER
echo "Version: ${VERSION}"
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
cat <<NOTE
------------------------------------------------------------------
WICHTIG / IMPORTANT
  Dieses Image enthält KEINE Secrets. PrivateKey/Password in den
  Yggdrasil-Configs sind geschwärzt. Erzeuge deinen eigenen Schlüssel:
  This image contains NO secrets. Supply your own Yggdrasil key:

    docker run --rm ${IMAGE} \\
      yggdrasil -genconf > yggdrasil.conf

  Snapshot-Dateien liegen unter /opt/lumina. Shell im Container:
    docker run --rm -it ${IMAGE} sh
  Um Yggdrasil im Container zu betreiben, braucht es z.B.
  --cap-add=NET_ADMIN --device /dev/net/tun und eine eigene Config:
    yggdrasil -useconffile /etc/yggdrasil/yggdrasil.conf
------------------------------------------------------------------
NOTE
