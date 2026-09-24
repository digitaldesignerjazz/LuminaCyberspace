# Lumina Cyberspace – Alpha 1.0 container image
# Public, secret-free snapshot of the Lumina/Nexus stack + Yggdrasil 0.5.14.
FROM debian:bookworm-slim

ARG YGGDRASIL_VERSION=0.5.14
ARG IMAGE_VERSION=1.0.0-alpha

LABEL org.opencontainers.image.source="https://github.com/digitaldesignerjazz/LuminaCyberspace" \
      org.opencontainers.image.title="Lumina Cyberspace" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.description="Lumina Cyberspace Alpha 1.0 – öffentlicher Snapshot des Lumina/Nexus-Stacks mit Yggdrasil ${YGGDRASIL_VERSION} (ohne Secrets) / public secret-free snapshot of the Lumina/Nexus stack with Yggdrasil ${YGGDRASIL_VERSION}"

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends python3 ca-certificates iproute2 curl; \
    curl -fsSL -o /tmp/yggdrasil.deb \
      "https://github.com/yggdrasil-network/yggdrasil-go/releases/download/v${YGGDRASIL_VERSION}/yggdrasil-${YGGDRASIL_VERSION}-amd64.deb"; \
    apt-get install -y --no-install-recommends /tmp/yggdrasil.deb; \
    rm -f /tmp/yggdrasil.deb; \
    apt-get purge -y --auto-remove curl; \
    rm -rf /var/lib/apt/lists/*; \
    yggdrasil -version

COPY backup/lumina-stack-public-20260924-2240/ /opt/lumina/
COPY docker/entrypoint.sh /usr/local/bin/lumina-info
RUN chmod +x /usr/local/bin/lumina-info

WORKDIR /opt/lumina
CMD ["/usr/local/bin/lumina-info"]
