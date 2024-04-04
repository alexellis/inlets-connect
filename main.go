package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"strings"
	"time"
)

var (
	GitCommit string
	Version   string
)

func main() {
	var port int
	var validUpstream string

	flag.StringVar(&validUpstream, "upstream", "", "The upstream this proxy is allowed to access i.e. 192.168.0.26:6443")
	flag.IntVar(&port, "port", 3128, "The port to listen on")
	flag.Parse()

	if len(validUpstream) == 0 {
		fmt.Fprintf(os.Stderr, "--upstream is required\n")
		os.Exit(1)
		return
	}
	log.Printf("inlets-connect by Alex Ellis\n\nVersion: %s\tCommit: %s", Version, GitCommit)

	log.Printf("Listening on %d, allowed upstream: %s", port, validUpstream)

	http.ListenAndServe(fmt.Sprintf(":%d", port), http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodConnect {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		defer r.Body.Close()

		if r.Host != validUpstream {
			http.Error(w, fmt.Sprintf("Unauthorized request to %s", r.Host), http.StatusUnauthorized)
			return
		}

		conn, err := net.DialTimeout("tcp", r.Host, time.Second*5)
		if err != nil {
			http.Error(w, fmt.Sprintf("Unable to dial %s, error: %s", r.Host, err.Error()), http.StatusServiceUnavailable)
			return
		}
		w.WriteHeader(http.StatusOK)

		log.Printf("Dialed upstream: %s %s", conn.RemoteAddr(), conn.LocalAddr())

		hj, ok := w.(http.Hijacker)
		if !ok {
			http.Error(w, "Unable to hijack connection", http.StatusInternalServerError)
			return
		}

		reqConn, wbuf, err := hj.Hijack()
		if err != nil {
			http.Error(w, fmt.Sprintf("Unable to hijack connection %s", err), http.StatusInternalServerError)
			return
		}
		defer reqConn.Close()
		defer wbuf.Flush()

		ctx, cancel := context.WithCancel(context.Background())
		go func() {
			defer cancel()
			pipe(reqConn, conn)
		}()
		go func() {
			defer cancel()
			pipe(conn, reqConn)
		}()

		<-ctx.Done()

		log.Printf("Connection %s done.", conn.RemoteAddr())
	}))
}

func pipe(from net.Conn, to net.Conn) error {
	defer from.Close()
	n, err := io.Copy(from, to)
	log.Printf("Wrote: %d bytes", n)
	if err != nil && strings.Contains(err.Error(), "closed network") {
		return nil
	}
	return err
}
