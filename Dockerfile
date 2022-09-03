FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.18-alpine as builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

ARG GIT_COMMIT
ARG VERSION

ENV GO111MODULE=on
ENV CGO_ENABLED=0
ENV GOPATH=/go/src/
WORKDIR /go/src/github.com/inlets/connect

COPY main.go    .
COPY go.mod .
COPY go.sum .

RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} CGO_ENABLED=0 go test -cover ./...

# add user in this stage because it cannot be done in next stage which is built from scratch
# in next stage we'll copy user and group information from this stage
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} CGO_ENABLED=0 go build -ldflags "-s -w -X main.GitCommit=${GIT_COMMIT} -X main.Version=${VERSION}" -a -installsuffix cgo -o /usr/bin/inlets-connect

ARG REPO_URL

LABEL org.opencontainers.image.source $REPO_URL

FROM --platform=${BUILDPLATFORM:-linux/amd64} gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=builder /usr/bin/inlets-connect /
USER nonroot:nonroot

EXPOSE 3128

VOLUME /tmp/

ENTRYPOINT ["/inlets-connect"]
CMD ["--help"]
