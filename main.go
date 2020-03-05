package main

import (
	"net/http"
)

func main() {
	http.ListenAndServe("", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}))
}
