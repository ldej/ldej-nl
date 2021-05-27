---
title: "Generating Swagger Docs From Go"
date: 2021-05-27T10:29:38+05:30
draft: false
summary: You have just created an API in Go and would like to add Swagger/OpenAPI documentation. You find two libraries, Swag and Go-swagger. Which one do you choose?
image: images/roadtrip06.webp
tags: 
- Go
- Swagger/OpenAPI

---

You have just created an API in Go and would like to add Swagger/OpenAPI documentation. You find two libraries: [swag](https://github.com/swaggo/swag) and [go-swagger](https://github.com/go-swagger/go-swagger). Which one do you choose?

There is a [github issue](https://github.com/go-swagger/go-swagger/issues/1794) asking about the differences, and there is a [blog post by Pedram Esmaeeli](https://medium.com/@pedram.esmaeeli/generate-swagger-specification-from-go-source-code-648615f7b9d9) giving a little more detail. I suggest reading the post by Pedram first. However, if after all of this, it is still not clear which one to choose, this post is for you!

If you are disappointed because your Java/Spring or Python/Django framework would automatically do everything for you, but Go doesn't, then let me tell you that you will get used to it :smile:.

## Show me the source!

You can find the working source code for the generation of Swagger docs with both of these libraries at [github.com/ldej/swagger-go-example](github.com/ldej/swagger-go-example).

```shell
$ git clone git@github.com:ldej/swagger-go-example.git
$ cd swagger-go-example
$ # choose your own adventure:
$ cd goswagger # or cd swaggo
$ make install_deps
$ make swagger
$ make run
$ # navigate to localhost:8080/swagger/
$ # or navigate to localhost:8080/swaggerd/ for 
$ # the swaggo dynamic docs but more on that later :)
```

## Features

Swag is a project focussed on generating Swagger documentation from annotated Go source code. Go-swagger has, next to the feature of generating documentation, the options to generate both a client, and a server implementations from Swagger documentation. In this post I'm going to take a look at the generation of Swagger docs, and I'm going to take a look at serving the docs with SwaggerUI.

I have tried to let both libraries generate a similar output. In both cases I tried to use all the features including summary, description, required, examples and formats.

## Pedram Esmaeeli's conclusions

In his [blog post](https://medium.com/@pedram.esmaeeli/generate-swagger-specification-from-go-source-code-648615f7b9d9), he makes a number of conclusions which I will briefly summarize here:

1. Convenience: Swag wins
2. Power: go-swagger wins
3. Readability: go-swagger wins
4. Popularity: go-swagger wins

Let's start by addressing the last point. At the moment of writing, Swag has 4.2k stars, where go-swagger has 6.4k stars. Yes, that makes go-swagger more popular, but are all these stars for the feature of generating docs from Go source code?

## Other measures

Next to Pedram conclusions there are a couple of points I would like to compare the libraries on. They are:

5. Readability of documentation
6. Performance of generation docs
7. Ability to serve SwaggerUI

## The Thing Server API

The API I'm going to generate documentation for has five endpoints, where I'm trying to cover various scenarios.

```go

type ThingResponse struct {
    UUID    string    `json:"uuid"`
    Name    string    `json:"name"`
    Value   string    `json:"value"`
    Updated time.Time `json:"updated"`
    Created time.Time `json:"created"`
}

type ErrorResponse struct {
    Error string `json:"error"`
}

func GetThing(w http.ResponseWriter, r *http.Request) {}

type CreateThing struct {
    Name  string `json:"name"`
    Value string `json:"value"`
}

func CreateThing(w http.ResponseWriter, r *http.Request) {}

type UpdateThing struct {
    Value string `json:"value" validate:"required"`
}

func UpdateThing(w http.ResponseWriter, r *http.Request) {}

func DeleteThing(w http.ResponseWriter, r *http.Request) {}

type ThingsResponse struct {
    Total  int             `json:"total"`
    Page   int             `json:"page"`
    Limit  int             `json:"limit"`
    Things []ThingResponse `json:"things"`
}

func ListThings(w http.ResponseWriter, r *http.Request) {}
```

The endpoints are registered with the following methods:

```go
router.HandleFunc("/api/v1/thing", s.ListThings).Methods(http.MethodGet)
router.HandleFunc("/api/v1/thing/new", s.CreateThing).Methods(http.MethodPost)
router.HandleFunc("/api/v1/thing/{uuid}", s.GetThing).Methods(http.MethodGet)
router.HandleFunc("/api/v1/thing/{uuid}", s.UpdateThing).Methods(http.MethodPut)
router.HandleFunc("/api/v1/thing/{uuid}", s.DeleteThing).Methods(http.MethodDelete)
```

The API consumes `application/json` and returns `application/json`. The `ListThings` endpoint supports two query parameters called `page` and `limit`. Where possible I will return a `404` in case a `Thing` does not exist.

## go-swagger/go-swagger

With go-swagger you need to annotate your functions and structs to add documentation. This is what it looks like for struct that will be returned from your API:

```go
// swagger:model ThingResponse
type ThingResponse struct {
	// The UUID of a thing
	// example: 6204037c-30e6-408b-8aaa-dd8219860b4b
	UUID string `json:"uuid"`

	// The Name of a thing
	// example: Some name
	Name string `json:"name"`

	// The Value of a thing
	// example: Some value
	Value string `json:"value"`

	// The last time a thing was updated
	// example: 2021-05-25T00:53:16.535668Z
	Updated time.Time `json:"updated"`

	// The time a thing was created
	// example: 2021-05-25T00:53:16.535668Z
	Created time.Time `json:"created"`
}
```

And this is what the docs for an endpoint look like:

```go
// swagger:route GET /thing/{uuid} Thing get-thing
//
// This is the summary for getting a thing by its UUID
//
// This is the description for getting a thing by its UUID. Which can be longer.
//
// responses:
//   200: ThingResponse
//   404: ErrorResponse
//   500: ErrorResponse
func (s *Server) GetThing(w http.ResponseWriter, r *http.Request) {
	// Your implementation here
}
```

Both the struct and endpoint comments look quite readable. It takes up quite a bit of space, but with go-swagger the documentation can be placed in any file, so you could move the comments to a separate file.

Unfortunately, this is not enough to document a single endpoint with its response. As you can see there is no mention of our `{uuid}` path parameter yet. The path parameter cannot be added to the comments of the endpoint, instead a new struct needs to be defined:

```go
// swagger:parameters get-thing update-thing delete-thing
type _ struct {
	// The UUID of a thing
	// in:path
	UUID string `json:"uuid"`
}
```

Fortunately, the `UUID` path parameter can be reused for multiple operations including the `update-thing` and `delete-thing` operation. You do need to make sure though that you keep the ids of the operations in line with the ids you have given them!

Talking about parameters, the [go-swagger documentation](https://goswagger.io/use/spec/params.html) for parameters show `swagger:params` in the left menu and the page's title. But don't be fooled, `swagger:params` does not work and needs to be `swagger:parameters`. When you try to use `swagger:params` you will be greeted by the following error:

```shell
$ swagger generate spec -o ./swagger/swagger.json --scan-models
classifier: unknown swagger annotation "params"
```

Next to path parameters, our `ListThing` endpoint supports two query parameters. They also require a separate struct to be documented:

```go
// swagger:parameters list-things
type _ struct {
	// Page
	// in:query
	Page int
	// Limit (max 100)
	// in:query
	Limit int
}
```

The last thing to look at is how to describe a JSON body:

```go
// swagger:model CreateThing
type CreateThing struct {
	// The name for a thing
	// example: Some name
	// required: true
	Name string `json:"name"`
	// The value for a thing
	// example: Some value
	// required: true
	Value string `json:"value"`
}

// swagger:parameters create-thing
type _ struct {
	// The body to create a thing
	// in:body
	// required: true
	Body CreateThing
}
```

Just as with the path and query parameters, the Body also requires a separate struct for documentation. The documentation is spread out over multiple lines with each instruction on a new line.

## swaggo/swag

In the other side of the ring we have Swag. Let's take a look at how structs and endpoints are documented. A struct goes like this:

```go
type ThingResponse struct {
    // The UUID of a thing
	UUID  string `json:"uuid" example:"6204037c-30e6-408b-8aaa-dd8219860b4b"`
	// The Name of a thing
	Name  string `json:"name" example:"Some name"`
	// The Value of a thing
	Value string `json:"value" example:"Some value"`
    // The last time a thing was updated
	Updated time.Time `json:"updated" example:"2021-05-25T00:53:16.535668Z" format:"date-time"`
    // The time a thing was created
	Created time.Time `json:"created" example:"2021-05-25T00:53:16.535668Z" format:"date-time"`
} // @name ThingResponse
```

As you can see, Swag understand struct tags and will read the `example` and `format` struct tags. It also supports the `validate:"required"` struct tag which is used by the [go-playground/validator](https://github.com/go-playground/validator) library. That's two birds with one stone!

On the last line you see `@name ThingResponse`. This is where you can give the name of response/model. By default, Swag gives the name of `package.Struct`, which in this case was `main.ThingResponse`.

Now let's take a look at an endpoint:

```go
// GetThing godoc
// @Summary This is the summary for getting a thing by its UUID
// @Description This is the description for getting a thing by its UUID. Which can be longer,
// @Description and can continue over multiple lines
// @ID get-thing
// @Tags Thing
// @Param uuid path string true "The UUID of a thing"
// @Success 200 {object} ThingResponse
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /thing/{uuid} [get]
func (s *Server) GetThing(w http.ResponseWriter, r *http.Request) {
	// Your implementation here
}
```

The documentation is quite lengthy, and the syntax for describing a parameter looks like a piece of magic. Although, after writing a couple of them you will get the hang of it:

```go
// @Param uuid path string true "The UUID of a thing"
//
// Explanation
// Name: uuid
// Where: path/body/query
// Type: string/int/{object}
// Required: true/false
// Description: "The UUID of a thing"
```

Now let's take a look at query and body parameters:

```go
type CreateThing struct {
    // The name for a thing
	Name  string `json:"name" validate:"required" example:"Some name"`
	// The value for a thing
	Value string `json:"value" validate:"required" example:"Some value"` 
} // @name CreateThing

// CreateThing godoc
// @Summary This is the summary for creating a thing
// @Description This is the description for creating a thing. Which can be longer.
// @ID create-thing
// @Tags Thing
// @Param Body body CreateThing true "The body to create a thing"
// @Success 200 {object} ThingResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /thing/new [post]
func (s *Server) CreateThing(w http.ResponseWriter, r *http.Request) {
	// Your implementation here
}

type ThingsResponse struct {
    Total  int             `json:"total" format:"int64"`
    Page   int             `json:"page"  format:"int64"`
    Limit  int             `json:"limit" format:"int64"`
    Things []ThingResponse `json:"things"`
} // @name ThingsResponse

// ListThings godoc
// @Summary This is the summary for listing things
// @Description This is the description for listing things. Which can be longer.
// @ID list-things
// @Tags Thing
// @Param page query int false "Page"
// @Param limit query int false "Limit (max 100)"
// @Success 200 {object} ThingsResponse
// @Failure 500 {object} ErrorResponse
// @Router /thing [get]
func (s *Server) ListThings(w http.ResponseWriter, r *http.Request) {
// Your implementation here
}
```

## Swagger UI

Both of these libraries are able to generate Swagger docs from source. But, to get the most benefit from your Swagger docs, you would want to view them in Swagger UI. When you take a look at the [swagger-api/swagger-ui](https://github.com/swagger-api/swagger-ui) repository, it might seem confusing how many files there are. At least it looks confusing to me.

Let me help you. The only folder you need is the `dist` folder. The easiest way to get this folder is by making a checkout of the repository, and then copy the `dist` folder to your project. In my case I called that folder `swagger`.

In the folder you will need to edit one file: `index.html`. There is a piece of Javascript that looks like:

```js
      const ui = SwaggerUIBundle({
        url: "https://petstore.swagger.io/v2/swagger.json",
        dom_id: '#swagger-ui',
        deepLinking: true,
        presets: [
          SwaggerUIBundle.presets.apis,
          SwaggerUIStandalonePreset
        ],
        plugins: [
          SwaggerUIBundle.plugins.DownloadUrl
        ],
        layout: "StandaloneLayout"
      });
```

Replace the `url` with `/swagger/swagger.json` and you are set!

Next, we need to serve these files. An agnostic solution is to let your Go router or web framework serve the folder:

```go
    router := mux.NewRouter() // gorilla/mux
	router.PathPrefix("/swagger/").Handler(http.StripPrefix("/swagger", http.FileServer(http.Dir("swagger"))))
```

In both the go-swagger and swag solutions I output the generated files to `/swagger/swagger.json`.

Swag has a feature for serving the docs, but before serving you can change a couple of values. For example, if you are running on localhost, you might want to change the `host` to `localhost:8080` and the `schemes` to `http`. To serve these dynamic changes, you can use the provided handler:

```go

import (
    "github.com/swaggo/http-swagger"
    "github.com/ldej/swagger-go-example/swaggo/swagger"
)

...
	swagger.SwaggerInfo.Title = "A thing server"
	swagger.SwaggerInfo.Description = "This is a dynamically set description."
	swagger.SwaggerInfo.Version = "1.0"
	swagger.SwaggerInfo.Host = "localhost:8080"
	swagger.SwaggerInfo.BasePath = "/api/v1"
	swagger.SwaggerInfo.Schemes = []string{"http", "https"}
	router.PathPrefix("/swaggerd/").Handler(httpSwagger.WrapHandler)
...
```

When you run the example, visit [localhost:8080/swaggerd](http://localhost:8080/swaggerd/) to see the dynamic version.

Go-swagger has a built-in command-line option for serving the docs:
```shell
$ swagger serve ./swagger/swagger.json 
2021/05/26 17:17:40 serving docs at http://localhost:38789/docs
```

This opens a Redoc server to display your generated docs. Pro-tip: you can also serve the docs generated by Swag with this tool.

## Comparison

It looks like both libraries perform well and are mostly feature complete. Both libraries have a whole list of small features that I have never used in any of my projects. If any of those features are a deciding factor for you, please let me know as I will happily add them to the blog post.

The feature of being able to move docs to a separate file is great, although you do have the risk of missing out on updating the docs when required. I think the power of having your Swagger docs at the same place as your code cannot be understated.

When it comes to readability, it mostly comes down to taste. Yes maybe the properties signified with an `@` are not the most beautiful. However, declaring empty structs just for documentation does not win any prizes either. Where Swag wins over go-swagger is the fact that the parameters (body/path/query) can all be declared at the endpoint's documentation, so you don't need to keep operation ids in sync over multiple locations.

For required fields, examples and formats, it comes down to taste whether you prefer to write them in comments, or in struct tags. My gut feeling tells me that struct tags are the most idiomatic way of declaring these properties.

One feature that seems to miss from Swag is the ability to define which content-type is produced and consumed for the whole application. However, if you are going to use `application/json` for all your endpoints, you are in luck as that is the default content type for Swagger.

I've read most of the documentation of both libraries, and have come to the conclusion that the documentation and examples for Swag are more extensive and clearer than the go-swagger counterparts.

There is quite a big gap between the performance of these tools. To generate the documentation for these five endpoints, Swag takes less than half a second on my machine, where go-swagger needs 6 seconds. I can imagine that go-swagger might become quite slow for bigger applications.

## Conclusion

After having written documentation with both tools, I can say that both have their place. My favourite in this case is Swag, as it feels more idiomatic, is faster, and had better documentation and examples.

In the end I have to conclude that writing instructions in comments, either for Swagger or [as an alternative to annotations](https://github.com/MarcGrol/golangAnnotations), is not the best idea. The problem is that editors do not understand what you mean, and therefore it becomes a hassle to keep everything working. There are a couple of plugins for IntelliJ that can help with Swagger annotations in Java, perhaps a Go version for Swag might make our lives a bit easier.

If this blog post helped you decide, let me know!