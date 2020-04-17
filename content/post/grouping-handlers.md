---
title: "Two ways to group HTTP handlers in Go"
date: 2020-04-17T17:04:26+05:30
draft: false
tags:
- go
- web
---

# The Standard Library 

https://blog.merovius.de/2017/06/18/how-not-to-use-an-http-router.html

```go
type App struct {
    // We could use http.Handler as a type here; using the specific type has
    // the advantage that static analysis tools can link directly from
    // h.UserHandler.ServeHTTP to the correct definition. The disadvantage is
    // that we have slightly stronger coupling. Do the tradeoff yourself.
    UserHandler *UserHandler
}

func (h *App) ServeHTTP(res http.ResponseWriter, req *http.Request) {
    var head string
    head, req.URL.Path = ShiftPath(req.URL.Path)
    if head == "user" {
        h.UserHandler.ServeHTTP(res, req)
        return
    }
    http.Error(res, "Not Found", http.StatusNotFound)
}

type UserHandler struct {
}

func (h *UserHandler) ServeHTTP(res http.ResponseWriter, req *http.Request) {
    var head string
    head, req.URL.Path = ShiftPath(req.URL.Path)
    id, err := strconv.Atoi(head)
    if err != nil {
        http.Error(res, fmt.Sprintf("Invalid user id %q", head), http.StatusBadRequest)
        return
    }
    switch req.Method {
    case "GET":
        h.handleGet(id)
    case "PUT":
        h.handlePut(id)
    default:
        http.Error(res, "Only GET and PUT are allowed", http.StatusMethodNotAllowed)
    }
}

func main() {
    a := &App{
        UserHandler: new(UserHandler),
    }
    http.ListenAndServe(":8000", a)
}
```

# Inside your service

https://pace.dev/blog/2018/05/09/how-I-write-http-services-after-eight-years.html

> A Server struct is an object that represents the service, and holds all of its dependencies.
>  
>  All of my components have a single server structure that usually ends up looking something like this:

```go
package app

type server struct {
    db     *someDatabase
    router *someRouter
    email  EmailSender
}

func (s *server) routes() {
    s.router.HandleFunc("/api/", s.handleAPI())
    s.router.HandleFunc("/about", s.handleAbout())
    s.router.HandleFunc("/", s.handleIndex())
}
```