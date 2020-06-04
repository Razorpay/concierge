FROM golang:1.14.0-alpine3.11 as concierge
RUN apk add git
WORKDIR /concierge
COPY go.mod go.sum ./
RUN go mod download
RUN export GO111MODULE=on && go get github.com/oauth2-proxy/oauth2-proxy && export GO111MODULE=auto
COPY . .
RUN go build -o concierge main.go 


FROM razorpay/onggi:base-3.7
WORKDIR /app

COPY --from=concierge /concierge/concierge concierge
COPY --from=concierge /concierge/assets assets
COPY --from=concierge /concierge/templates templates
COPY --from=concierge /concierge/docker docker
COPY --from=concierge /concierge/oauth2_proxy oauth2_proxy
COPY --from=concierge /go/bin/oauth2_proxy /usr/local/bin/oauth2_proxy

EXPOSE 8990 3306 4180
ENTRYPOINT ["docker/entrypoint.sh"]