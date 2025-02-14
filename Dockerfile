FROM FROM docker.io/library/alpine:3.21 AS build

ARG VERSION=v1.58.0

WORKDIR /workdir

RUN apk add --no-cache \
        ca-certificates-bundle \
        catatonit \
    && mkdir -p app/bin
    && wget -qO- "https://github.com/autobrr/autobrr/releases/download/${VERSION}/autobrr_${VERSION#v}_linux_x86_64.tar.gz" | \
    tar xvz --directory=app/bin


FROM scratch

ENV HOME="/config" \
    XDG_CONFIG_HOME="/config" \
    XDG_DATA_HOME="/config"

WORKDIR /app

VOLUME /config

COPY --from=build /workdir/app/bin/autobrr /workdir/app/bin/autobrrctl /app/bin/
COPY --from=build /usr/bin/catatonit /usr/bin/catatonit
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo

EXPOSE 7474

ENTRYPOINT ["/usr/bin/catatonit", "--", "/app/bin/autobrr", "--config", "/config"]

LABEL org.opencontainers.image.source="https://github.com/autobrr/autobrr"
