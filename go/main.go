package main

import (
	"html"
	"net/http"
	"fmt"
	"log"
)

const Version = "1.1"

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "(%s) Hello, %q", Version, html.EscapeString(r.URL.Path))
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
