# inlets-connect

inlets-connect is a proxy that supports HTTPS and the CONNECT method. It can be deployed as a side-car or stand-alone to proxy to a single address using TCP pass-through.

The use-case is for TLS pass-through for a HTTPS service via an inlets PRO tunnel. With this technique, the `kubernetes.default.svc` address can be used with a valid TLS SAN name, when forwarded into a remote cluster via inlets PRO.

## Usage

### Kubernetes

For usage on Kubernetes, see: [artifacts](artifacts)

### Local

```bash
go build && ./inlets-connect --upstream 192.168.0.15:443 --port 3128

curl https://192.168.0.15 -x http://127.0.0.1:3128
```

Assuming that you want to proxy to `https://192.168.0.15`, you can start a HTTPS proxy and then use curl to access it.

This example allows the proxy running on `127.0.0.1:3128` to accept a CONNECT request and forward traffic to the `--upstream` i.e. `192.168.0.15:443`.

From within Kubernetes, the `--upstream` is likely to be `kubernetes.default.svc` and the proxy is likely to be run in a Pod.

### Within Docker

```bash
docker run -p 3128:3128 -ti ghcr.io/alexellis/inlets-connect:0.0.2 -port 3128 -upstream ghost:443
2021/04/15 10:48:49 Version: 0.0.2      Commit: 3ec88704b162263511b46f33ee23f1c72f773d56
2021/04/15 10:48:49 Listening on 3128, allowed upstream: ghost:443

curl https://ghost -x http://127.0.0.1:3128
```

