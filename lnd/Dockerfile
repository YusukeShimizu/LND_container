FROM golang:1.13-alpine as builder

MAINTAINER bruwbird

# Install build dependencies such as git and glide.
RUN apk add --no-cache git gcc musl-dev

WORKDIR $GOPATH/src/github.com/lightningnetwork

# Grab and install the latest version of of lnd and all related dependencies.
RUN git clone https://github.com/lightningnetwork/lnd.git

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Install dependencies and install/build lnd.
RUN apk add --no-cache --update alpine-sdk \
    make \
    &&  cd /go/src/github.com/lightningnetwork/lnd \
    &&  make \
    &&  make install tags="monitoring signrpc walletrpc chainrpc invoicesrpc routerrpc"


ENV CGO_ENABLED=1
ENV CC=gcc
RUN go get -u github.com/cloudflare/cfssl/cmd/cfssl
RUN go get -u github.com/cloudflare/cfssl/cmd/cfssljson

# Start a new, final image to reduce size.
FROM alpine as final

# Expose lnd ports (server, rpc).
EXPOSE 9735

# Copy the binaries and entrypoint from the builder image.
COPY --from=builder /go/bin/lncli /bin/
COPY --from=builder /go/bin/lnd /bin/
COPY --from=builder /go/bin/cfssl /bin/
COPY --from=builder /go/bin/cfssljson /bin/

# Add bash.
RUN apk add --no-cache \
    bash

# Copy the entrypoint script.
COPY "start-lnd.sh" .
COPY ./server.json .
COPY ./config.json .

RUN chmod +x start-lnd.sh
