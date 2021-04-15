FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.15-alpine as builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS=linux
ARG TARGETARCH=arm

ARG GIT_COMMIT
ARG VERSION

ENV GO111MODULE=on
ENV CGO_ENABLED=0
ENV GOPATH=/go/src/
WORKDIR /go/src/github.com/inlets/connect

COPY main.go    .
COPY go.mod .

# add user in this stage because it cannot be done in next stage which is built from scratch
# in next stage we'll copy user and group information from this stage
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} CGO_ENABLED=0 go build -ldflags "-s -w" -a -installsuffix cgo -o /usr/bin/connect \
    && addgroup -S app \
    && adduser -S -g app app

FROM scratch

ARG REPO_URL

LABEL org.opencontainers.image.source $REPO_URL

COPY --from=builder /etc/passwd /etc/group /etc/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/bin/connect /usr/bin/

USER app
EXPOSE 80

VOLUME /tmp/

ENTRYPOINT ["/usr/bin/connect"]
CMD ["--help"]
