FROM golang:1.21.0-alpine3.18 as concierge
RUN apk add git
WORKDIR /concierge
COPY go.mod go.sum ./
RUN GO111MODULE=on go mod download
COPY . .
RUN go build -o concierge main.go 


FROM alpine:3.18

ENV GOSU_VERSION="1.10"
ENV ARCH="amd64"
# Cryptography breaks, this is a workaround only for this version.
# Requires rust compiler going forward
ENV CRYPTOGRAPHY_DONT_BUILD_RUST="1"

RUN echo "* Installing deps" && \
    apk add --no-cache \
    bash \
    build-base \
    ca-certificates \
    coreutils \
    curl \
    dumb-init \
    git \
    libxml2-dev \
    libxslt-dev \
    libffi-dev \
    linux-headers \
    openssl \
    openssl-dev \
    py-pip \
    python3 \
    python3-dev && \
    rm -rf ~/.cache/pip/* && \
    echo "* Installing gosu" && \
    curl --location --output /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$ARCH" && \
    chmod +x /usr/local/bin/gosu && \
    addgroup -S appuser && \
    adduser -S appuser -G appuser

WORKDIR /app

COPY --from=concierge /concierge/concierge concierge
COPY --from=concierge /concierge/assets assets
COPY --from=concierge /concierge/templates templates
COPY --from=concierge /concierge/docker docker
COPY --from=concierge /concierge/oauth2_proxy oauth2_proxy
COPY --from=quay.io/oauth2-proxy/oauth2-proxy:v7.4.0-amd64 /bin/oauth2-proxy /usr/local/bin/oauth2-proxy

EXPOSE 8990 3306 4180
ENTRYPOINT ["docker/entrypoint.sh"]
