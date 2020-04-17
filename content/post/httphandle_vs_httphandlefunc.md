---
title: "http.Handle vs http.HandleFunc"
date: 2020-04-17T16:49:37+05:30
draft: false
tags:
- go
- web
summary: "`http.HandleFunc` is a helper function to make your function `http.Handle` compatible"
---

# http.Handle vs http.HandleFunc

The Go documentation for [net/http](https://golang.org/pkg/net/http) gives this example:

> Handle and HandleFunc add handlers to DefaultServeMux:
> ```go
> http.Handle("/foo", fooHandler)
> 
> http.HandleFunc("/bar", func(w http.ResponseWriter, r *http.Request) {
> 	fmt.Fprintf(w, "Hello, %q", html.EscapeString(r.URL.Path))
> })
> 
> log.Fatal(http.ListenAndServe(":8080", nil))
> ```

What's the difference?

## `http.Handle`

`http.Handle` registers a `Handler` for an endpoint. `Handler` is an interface:
```go
type Handler interface {
    ServeHTTP(ResponseWriter, *Request)
}
```

You can create your own type which implements the `Handler` interface:
```go
type MyHandler struct {}

func (h MyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
}

func main() {
    http.Handle("/foo", MyHandler{})
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

## `http.HandleFunc`

The second argument of `http.HandleFunc` is your handler function. It is wrapped in an object of type `http.HandlerFunc` (mind the r) which conforms to the `http.Handle` interface. When `ServeHTTP` is called, your function will be called directly.

> // The HandlerFunc type is an adapter to allow the use of
> // ordinary functions as HTTP handlers. If f is a function
> // with the appropriate signature, HandlerFunc(f) is a
> // Handler that calls f.
> type HandlerFunc func(ResponseWriter, *Request)
>  
> // ServeHTTP calls f(w, r).
> func (f HandlerFunc) ServeHTTP(w ResponseWriter, r *Request) {
> 	f(w, r)
> }
