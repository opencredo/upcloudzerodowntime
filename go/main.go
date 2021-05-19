package main

import (
	"fmt"
	"html"
	"log"
	"net/http"
	"time"
)

const Version = "1.3"

func main() {
	startedTime := time.Now()

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if time.Since(startedTime) < 2*time.Minute {
			w.WriteHeader(500)
			w.Write([]byte("Server Error"))
			return
		}
		fmt.Fprintf(w, "(%s) Hello, %q", Version, html.EscapeString(r.URL.Path))
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
