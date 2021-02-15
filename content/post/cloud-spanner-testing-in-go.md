---
title: "Cloud Spanner Testing in Go"
date: 2021-02-12T10:35:30+05:30
draft: false
summary: An adventure in figuring out how to make an application that uses Cloud Spanner testable, even in Cloud Build.
image: images/roadtrip1.webp
tags:
- Google Cloud Platform
- Cloud Spanner
- Cloud Build
- Go
- Testing
- testcontainers-go
- docker
---

Recently I worked on a project where I used Google Cloud Spanner, the fully managed relational database with unlimited scale, strong consistency, and up to 99.999% availability. When started creating tests, I had some difficulty to find out a good testing strategy.

## Mocking

In Go, a common pattern for creating tests around external libraries is to use or define an interface which will be implemented by a mock, and to use the mock in your tests. 

For a sql database, you can use a library like [github.com/DATA-DOG/go-sqlmock](https://github.com/DATA-DOG/go-sqlmock) which defines implementations for the interfaces defined in [databases/sql](https://golang.org/pkg/database/sql/). This means that whenever you use a `sql.DB`, you can replace it with the mock from the `go-sqlmock` library.

Unfortunately, with Cloud Spanner it is not that straight-forward. There are no exported interfaces in the [Spanner library](https://github.com/googleapis/google-cloud-go/tree/master/spanner). I found [an issue](https://github.com/googleapis/google-cloud-go/issues/592) on Github mentioning the exact problem. [This comment](https://github.com/googleapis/google-cloud-go/issues/592#issuecomment-300595579) explains how annoying it is to have to define your own interfaces and wrapper to get to a workable situation. A [couple of comments later](https://github.com/googleapis/google-cloud-go/issues/592#issuecomment-406580071) advice is given: ["Don't overuse mocks."](https://testing.googleblog.com/2013/05/testing-on-toilet-dont-overuse-mocks.html)

## Spanner fake

In [one of the replies](https://github.com/googleapis/google-cloud-go/issues/592#issuecomment-300456345), it is mentioned that:

> As a general rule, the best way to write unit tests with these clients is to use a fake server.

The fake server for Spanner is [spannertest](https://github.com/googleapis/google-cloud-go/tree/master/spanner/spannertest). You get greeted by the friendly message:

> Here's a list of features that are missing or incomplete.

Alright, I get that this is unexplored territory, but let's try to use it anyway.

{{< filename "spanner_test.go" >}}
```go
package shop

import (
	"context"
	"testing"

	"cloud.google.com/go/spanner"
	database "cloud.google.com/go/spanner/admin/database/apiv1"
	"cloud.google.com/go/spanner/spannertest"
	"google.golang.org/api/option"
	databasepb "google.golang.org/genproto/googleapis/spanner/admin/database/v1"
	"google.golang.org/grpc"
	"gotest.tools/assert"
)

func TestSpannerFake(t *testing.T) {
	var ctx = context.Background()
	db := "projects/my-project/instances/my-instance/databases/my-db"
	server, err := spannertest.NewServer(":0")
	assert.NilError(t, err)

	conn, err := grpc.Dial(server.Addr, grpc.WithInsecure())
	assert.NilError(t, err)
	
	spannerDatabaseClient, err := database.NewDatabaseAdminClient(ctx, option.WithGRPCConn(conn))
	assert.NilError(t, err)

	op, err := spannerDatabaseClient.UpdateDatabaseDdl(ctx, &databasepb.UpdateDatabaseDdlRequest{
		Database: "my-db",
		Statements: []string{`CREATE TABLE Items (
			ID STRING(MAX),
			Name STRING(MAX),
		) PRIMARY KEY (ID)
		`},
	})
	assert.NilError(t, err)

	err = op.Wait(ctx)
	assert.NilError(t, err)

	spannerClient, err := spanner.NewClient(ctx, db, option.WithGRPCConn(conn))
	assert.NilError(t, err)

	type Item struct {
		ID   string `spanner:"ID"`
		Name string `spanner:"Name"`
	}

	_, err = spannerClient.ReadWriteTransaction(ctx, func(ctx context.Context, txn *spanner.ReadWriteTransaction) error {
		var mutations []*spanner.Mutation
		var item = Item{
			ID:   "1",
			Name: "first item",
		}
		replaceStruct, err := spanner.ReplaceStruct("items", item)
		assert.NilError(t, err)
		mutations = append(mutations, replaceStruct)
		return txn.BufferWrite(mutations)
	})
	assert.NilError(t, err)
}
```

```shell
$ go test spanner_test.go 
--- FAIL: TestSpannerFake (0.10s)
    spanner_test.go:60: assertion failed: error is not nil: spanner: code = "Unknown", desc = "rpc error: code = Unknown desc = unsupported mutation operation type *spanner.Mutation_Replace"
```

Well, this is awkward. The fake spanner server does not support the `ReplaceStruct` operation yet. Should I rewrite my application to not use these nice features, just because the fake spanner server does not support them? I don't think so.

## Testing against the Emulator

When you develop an application that uses Spanner, you probably develop against a locally running Spanner Emulator. Or course this is in beta too, but it's better than the alpha or experimental packages that seem to be extremely common with Googles products.

The emulator can be started using 
```shell 
$ gcloud beta emulators spanner create
```

or by running a docker container using
```shell
$ docker run -p 127.0.0.1:9010:9010 -p 127.0.0.1:9020:9020 gcr.io/cloud-spanner-emulator/emulator:1.1.1
```

A colleague mentioned having good experiences with [testcontainers/testcontainers-go](https://github.com/testcontainers/testcontainers-go). It is a Go library that lets you interact with docker from Go.

Starting the Spanner Emulator docker container can be done using:

```go
	req := testcontainers.ContainerRequest{
		Image:        "gcr.io/cloud-spanner-emulator/emulator:1.1.1",
		ExposedPorts: []string{"9010/tcp", "9020/tcp"},
		WaitingFor:   wait.ForLog("gRPC server listening at"),
	}
	spannerEmulator, err := testcontainers.GenericContainer(s.context, testcontainers.GenericContainerRequest{
		ContainerRequest: req,
		Started:          true,
	})
	assert.NilError(t, err)

	spannerPort, err := spannerEmulator.MappedPort(s.context, "9010")
	assert.NilError(t, err)
	os.Setenv("SPANNER_EMULATOR_HOST", "localhost:"+spannerPort.Port())
```

It starts the container and checks the logs to wait for that message that the server is listening. The exposed port will be mapped to a random available port, so you should set the `SPANNER_EMULATOR_HOST` environment variable with the right port.

There are some drawbacks to this though. On my machine it takes about 4 seconds for the container to start, so you don't want to start a docker container for each of your tests. However, if you want to run a set of integration tests, than this is a suitable solution. The only thing you need to remember is your tests do not start with a clean database, unless you create methods of either removing the data a test inserted, or by [clearing all records from the database](https://github.com/google/trillian/blob/2053c7648b44d5de45863c3ad12550b511ad6a14/storage/cloudspanner/getdb_test.go#L128) at the start of your tests.

## Testing in Cloud Build

In this project, Cloud Run is used to run the tests and build the docker images. While you can spin up Spanner in Cloud Build, I don't think it's a good idea to spend $700 per month for a single instance to use in your tests.

Let's try to use `testcontainers-go` in our tests in Cloud Run as well. In the tests, we need to interact with the docker daemon to start the Spanner Emulator. Unfortunately, you don't have direct access to the docker daemon, and when you try to mount `/var/run/docker.sock` in your build container, you get an error:

```
generic::invalid_argument: invalid build: build step #1 - "": path "/var/run/docker.sock" is reserved
```

Understandably, you cannot interact with the docker daemon directly. So is there a solution to _this_ problem? What if we could start the Spanner Emulator before running the tests?

The Cloud Build config files make it look as if you are directly interacting with docker, but unfortunately only a few command line arguments is supported, which does not include `-d`, the argument to start a container daemonized.

[This Stackoverflow post](https://stackoverflow.com/a/63792996) shows us that you can use the `docker/compose` build step to start a daemonized container. After tinkering, I came to the following set up:

{{< filename "docker-compose.cloud-build.yml" >}}
```yaml
version: "3.7"

services:
  spanner:
    container_name: spanner
    image: google/cloud-sdk
    ports:
      - '9010:9010'
      - '9020:9020'
    command: ["gcloud", "beta", "emulators", "spanner", "start", "--host-port", "0.0.0.0:9010", "--rest-port", "9020"]

networks:
  default:
    external:
      name: cloudbuild
```

{{< filename "cloudbuild.yaml" >}}
```yaml
steps:
  - name: 'docker/compose'
    args: [
        '-f',
        'cmd/shopd/docker-compose.cloud-build.yml',
        'up',
        '--build',
        '-d'
    ]
    id: 'spanner-emulator-docker-compose'

  - name: 'golang:1.15'
    args: ["go", "test", "./..."]
    env:
      - 'SPANNER_EMULATOR_AVAILABLE=true'
      - 'SPANNER_EMULATOR_HOST=spanner:9010'
```

When running the tests, I check if the environment variable `SPANNER_EMULATOR_AVAILABLE` is set to `true`, when it is the tests can be run. When the environment variable is **not** set, for example when running the tests locally, it will spin up the Spanner Emulator using `testcontainers-go`.

## RPC Replay

Another option mentioned in the [github issue](https://github.com/googleapis/google-cloud-go/issues/592#issuecomment-353162391) is the use of the [RPC replay library](https://pkg.go.dev/cloud.google.com/go/rpcreplay). I have yet to experiment with this tool.

## Conclusion

It is not as straight-forward to test an application that uses Cloud Spanner as I would like it to be. However, I'm happy with the current setup that uses `testcontainers-go`. I will take a look at the RPC Replay if I find the time. Please let me know if this helped you or if you have found a better method.