---
title: "Enterprise Go Architecture"
date: 2020-08-06T10:40:40+05:30
draft: false
summary: "I had the opportunity to work on a platform that is written in Go. I'm going to take a look to see what the structure is like and which libraries are used."
image: images/ladakh5.webp
tags:
- Go
- Web
- Domain-Driven Design
- Liquibase

#reddit:
#  created: 1597301347
#  url: https://www.reddit.com/r/ldej/comments/i8v2qr/enterprise_go_architecture_laurence_de_jong/
#  title: "Enterprise Go Architecture | Laurence de Jong"
---

Recently I had the opportunity to work on a platform that is written in Go. The platform has about 10 (micro)services that are all well-structured and organised. I'm going to take a look to see what the structure is like.

## Folder structure

The root folder structure of one of the smaller services is as follows:

```shell script
$ tree -L 1 --dirsfirst
.
├── <bounded-context>
├── build-scripts
├── config
├── database        // only migrations
├── docs            // swagger
├── infrastructure  // docker
├── go.mod
├── go.sum
├── main.go
├── Makefile
└── README.md
```

The folder names are descriptive and do not need much of an explanation, they describe what they _provide_, not what they _contain_. This service is only available over HTTP and will never be imported as a package or used as a command line script. This explains why the `main.go` is in the root of the project and not in a separate `cmd` folder.

The `main.go` loads the configuration and does a call to initialize the router which is inside the `<bounded-context>`. 

## Bounded Context

The term [Bounded Context comes from Domain-Driven Design]({{< relref "/post/my-domain-driven-design-notes#chapter-5-preserving-model-integrity" >}}). The size of a Bounded Context is rather vague. I have replaced the real name in this article but trust me that if you read it you know exactly what it is about. The `<bounded-context>` folder contains most of the logic, so let's take a look there.

```shell script
$ tree <bounded-context> --dirsfirst 
<bounded-context>
├── clients
│   └── <other-microservice>
│       └── client.go
├── constants
│   └── constants.go
├── controller
│   ├── <foo>_controller.go
│   └── ...
├── db
│   └── database.go
├── error
│   ├── api_error.go
│   └── custom_error.go
├── mocks
│   ├── <foo-repository>_repository_mock.go
│   ├── <foo-service>_service_mock.go
│   ├── <other-microservice>_client_mock.go
│   └── ...
├── models
│   ├── request
│   │   ├── <api-endpoint>_request.go
│   │   └── ...
│   ├── response
│   │   ├── <api-endpoint>_response.go
│   │   └── ...
│   ├── <foo-models>.go
│   ├── <bar-models>.go
│   └── ...
├── repository
│   ├── <foo-respository>_repository.go
│   └── ...
├── router
│   └── routes.go
├── service
│   ├── <foo-service>_service.go
│   └── ...
└── utils
    └── ...
```

### `router`

The router ties all dependencies together. It creates a database instance and a gin router with custom middlewares for logging, cors, tracing, csrf, caching and oauth. Then the repositories, services and controllers are instantiated and are injected as dependencies where they are required. After that the router registers the paths with the functions on the controllers.

```go
fooRepository := repository.NewFooRepsitory(db)
fooService := service.NewFooService(fooRepository)
fooController := service.NewFooController(fooService)

fooRouter.GET("/get-foo-path", fooController.GetFoo)
```

Let's work our way inwards by starting at the controllers.

### `controller`

The controller contains the HTTP endpoints. The constructor takes the service as an argument. The controller can then call functions on the service in the endpoints. It takes care of translating JSON to request objects and response objects to JSON.

```go
type FooController struct {
    fooService service.FooService
}

func NewFooController(fooService service.FooService) PayeeController {
    return FooController{fooService: fooService}
}

func (fc FooController) AddFoo(c *gin.Context) {
    var fooRequest request.FooRequest
    err := c.ShouldBindJSON(&fooRequest)
    if err != nil {
        // handle error
    }
    
    fooResponse, err := fc.fooService.AddFoo(c, fooRequest)
    if err != nil {
        // handle error
    }
    c.JSON(http.StatusOK, fooResponse)
}

// other endpoints go here
```

The controller package does not contain interfaces for the controllers as they don't need to be mocked for testing. It is only the dependencies of the controller that need to be mocked.

### `service`

The service contains the business logic. It takes request objects, checks for constraints, and returns a response object. The service can have multiple dependencies like for example a mail service or another microservice. The service interface and it's implementation are in the same file.

```go
type FooService interface {
    AddFoo(c *gin.Context, fooRequest request.FooRequest) (*response.FooResponse, error)
    GetFoo(c *gin.Context, identifier string) (*response.FooResponse, error)
    DeleteFoo(c *gin.Context, identifier string) error
}

type fooService struct {
    fooRepository  repository.FooRepository
    // add other dependencies
}

func NewFooService(fooRepo repository.FooRepository, /* other dependencies */) FooService {
    return fooService{
        fooRepository:  fooRepo,
        // other dependencies
    }
}

func (fs fooService) AddFoo(c *gin.Context, fooRequest request.FooRequest) (*response.FooResponse, error) {
    
    // check things, for example if foo isn't duplicate
    // maybe call an external service

    newFoo := models.Foo{
        Bar: fooRequest.Bar,
        Baz: fooRequest.Baz
    }
    
    err = fs.fooRepository.CreateFoo(c, newFoo)
    if err != nil {
        // return an error
    }

    return &response.FooResponse{
        Status: "success",
    }, nil
}

// GetFoo and DeleteFoo go here
```

### `repository`

The repository package contains an interface describing what you can do with it. It also contains the repository type that implements the interface.

```go
type FooRepository interface {
    GetFoo(c *gin.Context, identifier string) (models.Foo, bool, error)
    CreateFoo(c *gin.Context, foo models.Foo) error
    DeleteFoo(c *gin.Context, identifier string) error
}

type fooRepository struct {
    db *sqlx.DB
}

func NewFooRepository(db *sqlx.DB) FooRepository {
    return fooRepository{db: db}
}

func (fr fooRepository) GetFoo(c *gin.Context, identifier string) (models.Foo, bool, error) {
    // imagine database interaction here
}
// imagine the other functions here
``` 

The repository takes care of storing models in the database and retrieving them. Only domain models go in and out, the repository takes care of the mapping.

{{< tip title="What should a repository return?" >}}
Let's say you implement `GetFoo`, but you need to take care of the case where Foo was not found. You can either:

1. return a special error signifying it was not found
2. return a pointer and check `if foo == nil`
3. explicitly return a `bool` that signifies that Foo was found

In this case the explicit solution of option 3 is chosen. When you call `GetFoo`, first check `if err != nil`, then check `if !fooFound`. 

Returning a pointer for 'performance improvements' is usually ill-advised and might [cause the opposite effect](https://medium.com/@meeusdylan/when-to-use-pointers-in-go-44c15fe04eac).
{{< /tip >}}

The controller, service and repository packages do not contain any subpackages. Each of the packages contains a file per service. Not having any subpackages means that there is no stutter in names. In case the number of services becomes too big, you can create another bounded-context. Perhaps the bounded-context has different requirements and validates the creation of a new microservice.

### `models`

In this application the number of models is rather low. Each model has its own separate files. In the `models` package there are the `request` and `response` packages which contain the request and response types used in the controllers and services.

The models contain struct tags for easier mapping of database results to objects. The models also contain struct tags for json in case they are mashalled to json directly in an endpoint. Whenever the HTTP endpoints response is different from the model, a response type is made in the `response` package, and the mapping is done in the service. 

### `db`

The `db` package only initializes the database connection and sets the configuration for the number of open connections and the connection lifetime.

### `clients`

The `clients` package contains clients that can interact with other services in the platform over HTTP. A client contains an interface describing its functionality, so it can be mocked for tests. The implementation of the interface is in the same file.

### `constants`

The `constants` package contains the values that are constant throughout the application. These constants are like the [Constraints in Domain-Driven Design]({{< relref "/post/my-domain-driven-design-notes#chapter-4-refactoring-toward-deeper-insight" >}}). By putting them in one package, they are very easy to discover.

That almost concludes the `<bounded-context>` folder. The `error` package contains a custom wrapper around `error` to add extra information when raising an error from a service to the controller. 

Then there is the `utils` package which contains, well `utils`. The package name does not describe what it _provides_, only what it _contains_. However, when you open the utils package you know exactly what it provides as the file names are loud and clear.

The `mocks` package contains the mocks, but more on that later.

## Configuration

Getting configuration right and reliable is always a difficult task. I think this project solved configuration beautifully.

The `config` folder contains the following files:

```shell script
$ tree config 
config
├── app_config.json
├── config.go
└── schema.json
```

The file `config.go` contains a number of `const` variables. The consts are strings with either `ALL_CAPS` or `all_lowercase` letters. The lowercase strings refer to fields in `app_config.json`. The uppercase strings refer to environment variables which are defined in `.envrc` in the root of the project.

The values in `app_config.json` include urls for connecting to other services, timeout limits, feature toggles, and other environment specific configurations.

The `.envrc` variables contain usernames, passwords and keys.

It uses [github.com/spf13/viper](https://github.com/spf13/viper) to access any of these configuration constants transparently:

```go
// config.go

const (
    Environment        = "environment"          // defined in app_config.json
    MyConfigurableItem = "MY_CONFIGURABLE_ITEM" // defined in .envrc 
)

// someFile.go
viper.GetString(config.Environment)
viper.GetString(config.MyConfigurableItem)
``` 

The repository only contains one `app_config.json` which contains the configuration for the local development environment. The configuration for the other environments is stored in a repository which contains the configurations for all services, for all environments. That repository is used for deploying the services with the correct configuration to different environments.

You might be wondering, how do you know if the configuration in the other repository contains the right information for the service? This is where `schema.json` comes in. It contains the validation scheme of the configuration. For example:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema",
  "type": "object",
  "required": [
    "environment",
    "my_configurable_item"
  ],
  "properties": {
    "$schema": {
      "type": "string"
    },
    "environment": {
      "type": "string"
    },
    "my_configurable_item": {
      "type": "string"
    }
  }
}
```

When you start the application, the first thing it will do is validate the loaded configuration against the schema defined in `schema.json`. When the application runs, the configuration is valid. This is automated for the configurations of all environments in CI pipelines.

## Testing & Mocking

Each file in service, repository, controller and clients has a testing file next to it ending with `_test.go`. The fact that the application has clearly separated layers (controller, service, repository) with injected dependencies makes it easy to test the layers separately using mocks.

The mocks for service and repository are generated using [github.com/golang/mock](https://github.com/golang/mock).

```go
package repository

// mockgen -source=<bounded-context>/repository/foo_repository.go  -destination=<bounded-context>/mocks/foo_repository_mock.go  -package=mocks FooRepository

type FooRepository interface {
    // omitted
}
```

The repository needs extra mocking though, it needs mocking for sql. For that it uses [github.com/DATA-DOG/go-sqlmock](https://github.com/DATA-DOG/go-sqlmock). 

All test are made with the Behaviour-Driven Development (BDD) testing framework [github.com/onsi/ginkgo](https://github.com/onsi/ginkgo). 

## Swagger

Documenting endpoints is done using [github.com/swaggo/swag](https://github.com/swaggo/swag). Unlike in other languages where the whole documentation can be rendered, in Go you need to give some hints to make it work.

```go
// foo_controller.go

// AddFoo godoc
// @Tags Foo
// @Summary Adds a new foo
// @Description Adds a new foo to the database
// @Accept  json
// @Produce  json
// @Param FooRequest body request.FooRequest true "Request Body"
// @Success 200 {object} response.FooResponse
// @Failure 400 {object} error.ErrorResponse
// @Failure 500 {object} error.ErrorResponse
// @Router /api/v1/foo [post]
func (fc FooController) AddFoo(c *gin.Context) {
    // omitted
}
```

## Database Migrations

The database migrations are completely independent of Go. They are created and applied by [Liquibase](https://www.liquibase.org/). I don't understand how I have never heard of this tool before. It reminds me of the Python package [Alembic by SQLAlchemy](https://alembic.sqlalchemy.org/en/latest/) and that makes me very happy.

Liquibase can generate a changelog from your database if you have one already. When you make changes it will detect these changes and create a migration script for it. Liquibase will create a table in your database where it tracks which migrations have been applied already.

The migration files are part of the repository in the `database` folder in the root of the application.

## Web Framework

The web framework that is chosen for this application is [github.com/gin-gonic/gin](https://github.com/gin-gonic/gin). Gin is used as a router, for binding json requests to objects and for getting path and query parameters. None of Gin's middleware is used.

Gin should be limited to usage in the router and controller. However, a Gin endpoint accepts one parameter `*gin.Context`. This means that whenever you want to pass your context to the next layer, it's going to need to import the gin package as well. Because of this, the gin package is imported in most of the files in the application. Having this Gin context available in all layers of your application can tempt developers to access values from the context anywhere in the application. Do you need the page number for your database query? You can just get it from the query params!

A router that doesn't take over the context with a custom context would prevent this. Helper functions can be made for binding json, or a json validator like go-playground/validator could be used for more elaborate validation.

## Utils / Kit

The system includes a dozen or services in total. These services share a substantial amount of code in the form of a utils library that is imported. The utils contain middleware, clients for interacting with sms/email services, logging and tracing. This repository is similar to the [Kit idea of William Kennedy]({{< relref "/post/structuring-go#william-kennedy" >}})

## External services over ESB

Allowing any service to make calls to anywhere on the internet could have unwanted consequences. In this system the applications running in docker containers have limited outside access. They can only interact with services within the system. Communication with external systems is done via an Enterprise Service Bus (ESB). It acts as the edge node for the network.

The ESB has HTTP endpoints that accept json. Each service that wants to communicate with the ESB implements a client that sends data in the right format.

## Libraries

I have named a number of libraries already, but there are other interesting ones that deserve to be named.

When I hear Kafka I think about Scala/Java projects. However, Kafka can also be used from Go as I learned. In this project [github.com/Shopify/sarama](https://github.com/Shopify/sarama) is used, but there are a couple more clients including one by Confluent. In this project it is mostly used for tasks that can run in the background.

Logging is done using the [github.com/sirupsen/logrus](https://github.com/sirupsen/logrus) library, and [go.opencensus.io/trace](https://pkg.go.dev/go.opencensus.io/trace?tab=doc) is used for tracing the logs through the services. As of now I don't know which backend is used to view the traced logs.

## Conclusion

Creating a well-structured Go application, or in this case platform, can be a tricky task as Go does not demand any structure. This project has multiple teams working independently across multiple services, that makes it even more important to keep consistency over all services. These repositories are easy to navigate and understand. It makes me happy when everything is structured likes this and when mocking and testing is done well.