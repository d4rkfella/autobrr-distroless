FROM cgr.dev/chainguard/wolfi-base:latest@sha256:78adc0075d239ee722b5d6ba0ca23e1cd40a30f23aac2e38d48f61a014151277 AS build

# renovate: datasource=github-releases depName=autobrr/autobrr
ARG AUTOBRR_VERSION=v1.59.0
# renovate: datasource=github-releases depName=openSUSE/catatonit
ARG CATATONIT_VERSION=v0.2.1

WORKDIR /rootfs

RUN apk add --no-cache \
        tzdata \
        curl \
        gpg \
        gpg-agent \
        gnupg-dirmngr && \
    mkdir -p app/bin usr/bin etc && \
    echo 'autobrr:x:65532:65532::/nonexistent:/sbin/nologin' > etc/passwd && \
    echo 'autobrr:x:65532:' > etc/group && \
    curl -fsSLO --output-dir /tmp "https://github.com/openSUSE/catatonit/releases/download/${CATATONIT_VERSION}/catatonit.x86_64{,.asc}" && \
    gpg --keyserver keyserver.ubuntu.com --recv-keys 5F36C6C61B5460124A75F5A69E18AA267DDB8DB4 && \
    gpg --verify /tmp/catatonit.x86_64.asc /tmp/catatonit.x86_64 && \
    mv /tmp/catatonit.x86_64 usr/bin/catatonit && \
    chmod +x usr/bin/catatonit && \
    curl -fsSL "https://github.com/autobrr/autobrr/releases/download/${AUTOBRR_VERSION}/autobrr_${AUTOBRR_VERSION#v}_linux_x86_64.tar.gz" | \
    tar xvz --exclude='LICENSE' --exclude='README.md' --directory=app/bin

FROM scratch

ENV HOME="/config" \
    XDG_CONFIG_HOME="/config" \
    XDG_DATA_HOME="/config"

WORKDIR /app

VOLUME /config

COPY --from=build /rootfs /
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo

USER autobrr:autobrr

VOLUME /config
EXPOSE 7474

ENTRYPOINT ["catatonit", "--", "/app/bin/autobrr"]
CMD ["--config", "/config"]

LABEL org.opencontainers.image.source="https://github.com/autobrr/autobrr"
