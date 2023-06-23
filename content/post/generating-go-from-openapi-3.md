---
title: "Generating Go server code from OpenAPI 3 definitions"
date: 2023-06-23T06:05:19+05:30
draft: false
summary: Define endpoints in OpenAPI 3 and generate server Go code. But which tools should you use?
image: images/roadtrip01.webp
tags:
- Go
- OpenAPI3
---

Two years ago I wrote about [generating swagger docs from Go]({{< relref "/post/generating-swagger-docs-from-go.md" >}}). In the meantime, OpenAPI version 3 has become more popular, and the libraries I used first do not support this latest version. [Swag does not seem to get updated](https://github.com/swaggo/swag/issues/386), and [go-swagger will probably not get updated either](https://github.com/go-swagger/go-swagger/issues/1122#issuecomment-575968499).

I used to be of the opinion that it was good enough to generate Swagger documentation by annotating my Go code. It turns out to be quite some effort to keep this documentation in line with how the API actually works. In a recent project I became familiar with writing OpenAPI documentation first, and then writing the code to match the specification. Now I have now come to realise that it is more important to design my APIs first.

The project I worked on used [github.com/deepmap/oapi-codegen](https://github.com/deepmap/oapi-codegen). I remember when I added a new endpoint to the documentation and generated the new server code. I was so happy to not have to remember the quirky annotations in Go comments for the documentation generators I used before.

While `oapi-codegen` worked perfectly fine, I did see that there were other generators available. What do they have to offer? The grass is always greener on the other side right? Well, I found the time to inspect the grass.

## Show me the source!

You can find the working source code at [github.com/ldej/go-openapi-example](https://github.com/ldej/go-openapi-example).

## Scope

The focus for this blog post is trying to generate server code (or stubs) based on an OpenAPI 3 specification. It is not a comparison of which generator covers the most of the specification, because it is a very big specification. Instead, I will create a basic API with functionality that I generally use.

## The Thing API

The Thing API is designed to interact with Things. It can create things:

```
POST /api/v1/thing {"name": "some"}`
```

Retrieve, update and delete them:

```
GET/POST/DELETE /api/v1/thing/{uuid}
```

And list them:

```
GET /api/v1/thing?page=1&keyword=any
```

The endpoints consume and produce `application/json`. There are more fields defined on a Thing, which allow us to see if the mappings of types are correct and if there is any validation according to our specifications on the input.

Of course most APIs will need to support some kind of authentication or security as well, which is what I have defined as a security schema in openapi:

```yaml
  securitySchemes:
    apiKey:
      type: apiKey
      name: X-Api-Key
      in: header
```

With this definition, the `X-Api-Key` header can be set as a requirement for endpoints. For example, the endpoint to create a Thing has:

```yaml
    post:
      security:
        - apiKey: [thing.create]
      operationId: createThing
```

This means that for this endpoint, I expect that an API key is provided via the `X-Api-Key` header, and that this API key needs to have the scope `thing.create`. Providing scopes in `securitySchemes` is only [officially supported](https://swagger.io/docs/specification/authentication/#scopes) for the `OAuth2` and `OpenId` schemes, but I am curious to find out what the generators make of this.

## Go Server Generators

There are a lot of tools listed on [openapi.tools](https://openapi.tools/), but I am specifically looking for tools that can generate Go server code. There are two promising ones listed there:
- [github.com/deepmap/oapi-codegen](https://github.com/deepmap/oapi-codegen)
- [github.com/OpenAPITools/openapi-generator](https://github.com/OpenAPITools/openapi-generator)

After a bit more research, I found these two as well:
- [github.com/ogen-go/ogen](https://github.com/ogen-go/ogen)
- [github.com/contiamo/openapi-generator-go](https://github.com/contiamo/openapi-generator-go)

There is another generator that peaked my interest, which is [github.com/google/gnostic-go-generator](https://github.com/google/gnostic-go-generator), however that one is recently archived, so I am not going to compare it. 

If you have found any other Go server code generators that you want to be part of this list, please let me know! 

### 1. deepmap/oapi-codegen

[github.com/deepmap/oapi-codegen](https://github.com/deepmap/oapi-codegen)

`oapi-codegen` is the most popular and most recommended Go specific generator and is has been around since 2019.

#### Configuration

The configuration for the `oapi-codegen` generator is straight-forward. You can either provide command line arguments or specify the same arguments in a `yaml` configuration file. In this case I am using:

{{< filename "server.cfg.yaml" >}}
```yaml
package: api
output: api/server.gen.go
generate:
  embedded-spec: true
  strict-server: true
  models: true
  chi-server: true # compatible with net/http
```

The generator supports chi, gin, echo and standard net/http.

#### Generated code

Based upon your openapi specification, `oapi-codegen` will generate interfaces for handlers. Path parameters will be parsed and validated for you, and passed as extra arguments to your handler. The `params` object contains the parsed query parameters. The generated interface looks like:

```go
type ServerInterface interface {
	ListThings(w http.ResponseWriter, r *http.Request, params ListThingsParams)
	CreateThing(w http.ResponseWriter, r *http.Request)
	DeleteThing(w http.ResponseWriter, r *http.Request, uuid openapi_types.UUID)
	GetThing(w http.ResponseWriter, r *http.Request, uuid openapi_types.UUID)
	UpdateThing(w http.ResponseWriter, r *http.Request, uuid openapi_types.UUID)
}
```

However, this means you need to parse your request bodies and encode your responses yourself. The types for the bodies and responses are generated as well, making it easier to that. However, you can make `oapi-codegen` do this for you. When you enable [strict-server](https://github.com/deepmap/oapi-codegen#strict-server-generation), it will generate code that parses request bodies and encodes responses automatically. The interface for your handler will then look like:

```go
type StrictServerInterface interface {
	ListThings(ctx context.Context, request ListThingsRequestObject) (ListThingsResponseObject, error)
	CreateThing(ctx context.Context, request CreateThingRequestObject) (CreateThingResponseObject, error)
	DeleteThing(ctx context.Context, request DeleteThingRequestObject) (DeleteThingResponseObject, error)
	GetThing(ctx context.Context, request GetThingRequestObject) (GetThingResponseObject, error)
	UpdateThing(ctx context.Context, request UpdateThingRequestObject) (UpdateThingResponseObject, error)
}
```

As you can see, you will not have direct access to the request and response rewriter anymore, and instead the body is parsed into the `request` object and you can actually return an object from your handler with the response.

An example of an implemented handler can look like:

```go
func (s *ThingService) GetThing(ctx context.Context, request api.GetThingRequestObject) (api.GetThingResponseObject, error) {
	thing, err := s.store.GetThing(request.Uuid.String())
	if err == helpers.ErrNotFound {
		return api.GetThing404JSONResponse{}, nil
	}
	if err != nil {
		return api.GetThingdefaultJSONResponse{Body: api.Error{Message: err.Error()}, StatusCode: http.StatusInternalServerError}, nil
	}
	return api.GetThing200JSONResponse(mapThingToThingResponse(thing)), nil
}
```

#### Request validation

In the openapi specification, it is possible to add requirements to fields, for example a minimum or maximum length or if a string needs to be an email. These validations can be done automatically as well using the `OapiRequestValidator`. Unfortunately, this validator is mentioned exactly twice in the readme of the repository, making it not so obvious how to use it. However, the `examples` directory in the repository proves to be quite useful, as the [chi example](https://github.com/deepmap/oapi-codegen/blob/master/examples/petstore-expanded/chi/petstore.go) does include the validator:

```go
import 	(
	middleware "github.com/deepmap/oapi-codegen/pkg/chi-middleware"
	"github.com/deepmap/oapi-codegen/examples/petstore-expanded/chi/api"
)

func main() {
	...
	r := chi.NewRouter()
	// Use our validation middleware to check all requests against the OpenAPI schema.
	swagger, _ := api.GetSwagger()
	r.Use(middleware.OapiRequestValidator(swagger))
	...
}
```

#### Security schemes

When a `securityScheme` is provided, the generated code will add the scopes defined in the openapi yaml to the context, which means that in your endpoint you can access the scopes. However, at no point will the generated code check if the `X-Api-Key` header is provided, and neither will it give you the value of the header. Instead, you can create your own middleware to check for this:

```go
func NewSecurityMiddleware() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ctx := r.Context()

			scopes, ok := ctx.Value(api.ApiKeyScopes).([]string)
			if !ok {
				// no scopes required for this endpoint, no X-Api-Key required
				next.ServeHTTP(w, r)
				return
			}

			apiKey := r.Header.Get("X-Api-Key")
			if apiKey == "" {
				w.WriteHeader(http.StatusUnauthorized)
				w.Write([]byte("header X-Api-Key not provided"))
				return
			}

			if apiKey != "test" {
				w.WriteHeader(http.StatusUnauthorized)
				w.Write([]byte("invalid api key provided"))
				return
			}

			// This is where you check if api key has the required scope
			_, _ = apiKey, scopes

			next.ServeHTTP(w, r)
		})
	}
}
```

There is [an open issue](https://github.com/deepmap/oapi-codegen/issues/114) which describes different ways of performing the same functionality.

#### Documentation

The documentation of this generator is rather scarce. The readme in the repository provides some hints, but I found myself checking out the repository and searching through the code and examples for answers regularly. Searching through GitHub is your friend here as well.

### 2. OpenAPITools/openapi-generator

[github.com/OpenAPITools/openapi-generator](https://github.com/OpenAPITools/openapi-generator)

`openapi-generator` is the generator with the most GitHub stars of the generators I am comparing here and it has been around since 2016.

#### Configuration

This generator facilitates the generation of clients and server(stubs) in many languages and for many frameworks. When generating server stubs, you need to provide which generator you want to use. For Go server code there are:

- [go-server](https://openapi-generator.tech/docs/generators/go-server/)
- [go-gin-server](https://openapi-generator.tech/docs/generators/go-gin-server/)
- [go-echo-server](https://openapi-generator.tech/docs/generators/go-echo-server/)

In this experiment I used `go-server` as I prefer to use either `gorilla/mux` or `chi`. You can specify which of these two routers you want to use via configuration:

{{< filename "config.yaml" >}}
```yaml
router: chi
outputAsLibrary: true
onlyInterfaces: true
```

{{< tip title="Use version 7" >}}
As of writing, the latest released version of the openapi-generator is version 6.6.0. When you use this version and use the `go-server` generator, the generated code uses old libraries. For example, the generated `go.mod` file uses `go 1.13` and `gorilla/mux v1.7.3` which is from June 2019. To use version 7 before it is released, make a checkout of the master branch and build the `.jar` yourself.
{{< /tip >}}

#### Generated code

The generated code will include an interface for your handlers to implement:
```go
type ThingAPIServicer interface { 
	CreateThing(context.Context, CreateThingRequest) (ImplResponse, error)
	DeleteThing(context.Context, string) (ImplResponse, error)
	GetThing(context.Context, string) (ImplResponse, error)
	ListThings(context.Context, int32, string) (ImplResponse, error)
	UpdateThing(context.Context, string, UpdateThingRequest) (ImplResponse, error)
}
```

Both path parameters and query parameters are added as arguments for your handler. There is no way to distinguish between them. The return type `ImplResponse` is a struct which has two fields, a `code` and a `body`. The `body` is an interface, so it can accept any struct that you pass into it. This means that you are losing some type safety when it comes to returning responses. It does generate response types as well, so please return the right one for your endpoint.

An example of an implemented handler can look like:

```go
func (s *ThingAPIService) GetThing(ctx context.Context, uuid string) (openapi.ImplResponse, error) {
	thing, err := s.store.GetThing(uuid)
	if err == helpers.ErrNotFound {
		return openapi.Response(http.StatusNotFound, nil), nil
	}
	if err != nil {
		return openapi.Response(http.StatusInternalServerError, nil), err
	}
	return openapi.Response(http.StatusOK, mapThingToThingResponse(thing)), nil
}
```

{{< tip title="Use generated code as a library" >}}
When generating the code, by default it will generate a full skeleton of the application including a `main` function and endpoints that you need implement:

```go
func (s *ThingAPIService) CreateThing(ctx context.Context, createThingRequest CreateThingRequest) (ImplResponse, error) {
	// TODO - update CreateThing with the required logic for this service method.
	// Add api_thing_service.go to the .openapi-generator-ignore to avoid overwriting this service implementation when updating open api generation.

	// TODO: Uncomment the next line to return response Response(200, ThingResponse{}) or use other options such as http.Ok ...
	// return Response(200, ThingResponse{}), nil

	// TODO: Uncomment the next line to return response Response(0, Error{}) or use other options such as http.Ok ...
	// return Response(0, Error{}), nil

	return Response(http.StatusNotImplemented, nil), errors.New("CreateThing method not implemented")
}
```

You can edit this code to add your logic. However, if you update your openapi yaml and generate the code again, it will overwrite the generated code, which is not ideal. They give you the option to not overwrite the file you changed by adding it to the `.openapi-generator-ignore` file. From that point on your directory with code will contain both generated and modified code. My suggestion is to enable `outputAsLibrary` and `onlyInterfaces`, and only use the generated code as a library you import. In your code, implement the interfaces defined in `api.go`, you can use the generated `_service.go` files as an example.
{{< /tip >}}

#### Request validation

The generated code will automatically include functionality that checks if the constraints you set on fields are met. For example, the `CreateThingRequest` contains a field called `rating` which has a `minimum: 0` and `maximum: 5`, which results in the following function:

```go
func AssertCreateThingRequestConstraints(obj CreateThingRequest) error {
	if obj.Rating < 0 {
		return &ParsingError{Err: errors.New(errMsgMinValueConstraint)}
	}
	if obj.Rating > 5 {
		return &ParsingError{Err: errors.New(errMsgMaxValueConstraint)}
	}
	return nil
}
```

This function is called before it enters the `CreateThing` handler that you implemented.

#### Security schemes

The `go-server` generator does not support and kind of generation of security schemes or handlers. What this means is that you need to create your own functionality for checking if the `X-Api-Key` header has been provided and what its value is. That by itself is not a big problem, what is a big problem in my opinion is that you would need to manually make sure that the correct endpoints require the header, and that you need to manually add the right scope requirements to each endpoint. This means that whenever the openapi yaml gets updated, you need to make sure that you need to manually keep track of any changes in the security of your endpoints.

#### Documentation

The documentation for this generator consists of [a single page](https://openapi-generator.tech/docs/generators/go-server/), which is probably not going to answer your questions. You can also take a look at the examples [here](https://github.com/OpenAPITools/openapi-generator/tree/master/samples/server/petstore/go-api-server) and [here](https://github.com/OpenAPITools/openapi-generator/tree/master/samples/server/petstore/go-chi-server) which contain a version of what the generated code will look like of the standard pet store yaml.

### 3. ogen-go/ogen

[github.com/ogen-go/ogen](https://github.com/ogen-go/ogen)

`ogen` is the youngest generator of the bunch with its first commit in 2021. The project supports opentelemetry out of the box. 

#### Configuration

The `ogen` generator required no specific configuration other than some command line arguments:
```shell
ogen -generate-tests -target gen -clean ../openapi3.yaml
```

#### Generated code

The generated code contains the interface for the handler that you should implement. Both path parameters and query parameters are passed to the functions via a `params` argument. The functions return a response object and a error. The generated interface looks like:

```go
type Handler interface {
	CreateThing(ctx context.Context, req OptCreateThingRequest) (*ThingResponse, error)
	DeleteThing(ctx context.Context, params DeleteThingParams) (DeleteThingRes, error)
	GetThing(ctx context.Context, params GetThingParams) (GetThingRes, error)
	ListThings(ctx context.Context, params ListThingsParams) (ListThingsRes, error)
	UpdateThing(ctx context.Context, req OptUpdateThingRequest, params UpdateThingParams) (UpdateThingRes, error)
	NewError(ctx context.Context, err error) *ErrorStatusCode
}
```

An example of an implemented handler can look like:

```go
func (s *ThingService) GetThing(ctx context.Context, params api.GetThingParams) (api.GetThingRes, error) {
	thing, err := s.store.GetThing(params.UUID.String())
	if err == helpers.ErrNotFound {
		return &api.GetThingNotFound{}, nil
	}
	if err != nil {
		return nil, err
	}
	return mapThingToThingResponse(thing), nil
}
```

Each error defined for an endpoint in the openapi yaml results in a different struct (for example `GetThingNotFound`) which is compatible with the `GetThingRes` interface defined in the generated code.

{{< tip title="Read the logs" >}}
When you define your request and responses in `schemas` in your openapi yaml, do not forget to add `type: object` for schemas that are objects. If you do not do this, `ogen` will uses `interface{}` as parameters. It will give you a hint when generating:
```
INFO	schemagen	Type is not defined, using any	{"at": "openapi3.yaml:238:7", "name": "UpdateThingRequest"}
```
In general, this generator has giving great tips for my hand made openapi yaml. Make sure to read all log messages when you generate!
{{< /tip >}}

#### Request validation

The generated code automatically provides `Validate` functions which are called when a request is coming in, meaning that any constraints defined on fields are automatically enforced. The generated code for that is quite lengthy, but you find it [here](https://github.com/ldej/go-openapi-example/blob/master/ogen/gen/oas_validators_gen.go) if you are interested.

#### Security schemes

`ogen` does support all the security schemes that are available, even though there is no documentation for it on the website as of writing. The generated code contains a `SecurityHandler` interface that looks like:

```go
type SecurityHandler interface {
	HandleApiKey(ctx context.Context, operationName string, t ApiKey) (context.Context, error)
}
```

The object `t` contains the value from the `X-Api-Key` header. Unfortunately, my non-standard use case of defining scopes for api key headers does not result in any scopes added to the generated code. This means that you need to manually implement these scopes as they are defined in your openapi yaml, and don't forget to keep them in sync! 

#### Documentation

This generator has a website [ogen.dev](https://ogen.dev/docs/intro) with describes most of the features available, but not all of them (for example the security schemes). The GitHub repository is very active with quick responses to issues and pull-requests. The repository does contain [examples](https://github.com/ogen-go/ogen/tree/main/examples) of generated code from openapi yaml files and there is a fully implemented [example repository](https://github.com/ogen-go/example) which can give insights in how to use the generated code.

### 4. contiamo/openapi-generator-go

[github.com/contiamo/openapi-generator-go](https://github.com/contiamo/openapi-generator-go)

`openapi-generator-go` exists since 2020 and is created because the developers did not enjoy the output ox existing generators.

#### Configuration

No configuration is required other then the command line arguments:

```shell
openapi-generator-go generate --spec ./openapi3-modified.yaml --output ./gen/
```

#### Generated code

Before you can generate your code, you need to add `x-handler-group: <name>` with the name of each group of handlers. If you do not add these fields to your openapi yaml, no code will be generated for your handlers.

The generated code consists of a handler interface which you need to implement:

```go
type ThingsHandler interface {
	CreateThing(w http.ResponseWriter, r *http.Request)
	DeleteThing(w http.ResponseWriter, r *http.Request)
	GetThing(w http.ResponseWriter, r *http.Request)
	ListThings(w http.ResponseWriter, r *http.Request)
	UpdateThing(w http.ResponseWriter, r *http.Request)
}
```

The handler interface passes the request and response writer and does not return any values, which makes it compatible with the `net/http` handlers.

An implementation of a handler can look like:

```go
func (h *ThingsHandler) UpdateThing(w http.ResponseWriter, r *http.Request) {
	var request api.UpdateThingRequest
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	if err := request.Validate(); err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	queryParameters := api.UpdateThingQueryParameters{
		Uuid: chi.URLParam(r, "uuid"),
	}
	if err := queryParameters.Validate(); err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	thing := helpers.Thing{
		UUID:  queryParameters.Uuid,
		Score: request.Score,
	}
	err := h.store.UpdateThing(thing)
	if err != nil {
		writeError(w, http.StatusInternalServerError, err)
		return
	}
	writeResponse(w, http.StatusNoContent, nil)
}
```

The generated code imports `github.com/go-chi/chi` which is version `v1.5.4` from February 2021. When you create your own router, make sure to use the same version because using `router.Mount` from version `v5` is incompatible with version `v1.5.4`.

#### Request validation

For each request body, response a struct is generated with a `Validate` function and a getter and setter for each field. After parsing the body of your request, call the `Validate` function to make sure all constraints defined in your openapi yaml are met.

Path parameters and query parameters are treated equally and are grouped together in a struct which also contains a `Validate` function. It is up to you to fetch the path parameters and query parameters and put them in a struct.

#### Security schemes

There is no support for security schemes.

#### Documentation

The only available documentation is the readme in the repository. Other than that, you might find help in the [testcases](https://github.com/contiamo/openapi-generator-go/tree/master/pkg/generators/models/testdata/cases)

## Comparison

|                                     | deepmap/oapi-codegen                       | OpenAPITools/openapi-generator             | go-ogen/ogen              | contiamo/openapi-generator-go |
|-------------------------------------|--------------------------------------------|--------------------------------------------|---------------------------|-------------------------------|
| Routers                             | chi / echo / gin / gorilla/mux / net/http* | chi / echo / gin / gorilla/mux / net/http* | net/http*                 | chi v1.5.3                    |
| Request parsing / Response encoding | Automatic/Manual**                         | Automatic                                  | Automatic                 | Manual                        |
| Validation                          | Via middleware                             | Integrated                                 | Integrated                | Manual                        |
| Security schemes                    | Supported                                  | Not supported                              | Supported                 | Not supported                 |
| API key scopes***                   | Supported                                  | -                                          | Not supported             | -                             |
| Customization of generated output   | Supported                                  | Not supported                              | Not supported             | Not supported                 |
| Special features                    | -                                          | -                                          | opentelemetry integration | -                             |
| Speed of generation                 | ~45ms                                      | ~2000ms                                    | ~80ms                     | ~20ms                         |

\* a `net/http` based router can be mounted in most other routers<br>
\** can be toggled with the `strict-server` option<br>
\*** not an official feature in the openapi spec

## Conclusion

In an ideal world, I would like to be able to pick features from different generators and combine them. I love the optionality of features in `deepmap/oapi-codegen`, the opentelemetry integration of `go-ogen/ogen` (although you can easily integrate this using middleware), and the speed of `OpenAPITools/openapi-generator` (I mean, who doesn't love getting a break to make a coffee and walk the dog?). For now, I'm going to stick to `deepmap/oapi-codegen`, but I'm keeping an eye on `go-ogen/ogen` because that project is going places.

## Future ideas

This blog post will be expanded over time, I will keep track of the changes at the start of the document.

I'm going to add a second group of handlers where I'm going to add some more exotic features like:
- allOf
- oneOf
- anyOf
- not
- file upload
- regex type validation?
- multiple content types for request and response

Next to that, I'm thinking about adding a test suite that confirms that all endpoints behave as expected. Maybe it's worth looking at generated clients for this?

We have all seen the `/api/v1` paths in API definitions, but when you actually start with your `v2`, how is that going to work out with these generators?

If you have any ideas or comments, feel free to reach out to me.
