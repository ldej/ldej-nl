---
title: "Go Cloud Spanner Lessons Learned"
date: 2021-05-17T10:09:49+05:30
draft: false
summary: Spanner is a great database if you have the money for it. Interacting with it from Go sometimes takes a bit effort to figure out how things work, but in the end it all makes sense. Testing isn't always that easy, but with instance and database creation and automatic migrations set-up, it's a breeze.
image: images/roadtrip05.webp
tags:
- Google Cloud Platform
- Cloud Spanner
- Go
- Testing
---

In my last project I had the opportunity to work with Google Cloud Spanner in Go. Although Spanner is a fully managed relational database with SQL capabilities, it does require you to work a bit differently sometimes.

## Instances, nodes and replicas

Spanner can operate in one or multiple regions at the same time. You can configure this when you are creating and instance. A single-region instance has 3 read-write replicas which is fixed in the configuration for single-region instances. Within an instance, you can configure how many nodes should be part of it. Adding nodes adds more resources which increases a replica's throughput. Multi-region configurations are distributed across multiple regions, have lower read latencies from multiple geographic locations, but are also more costly to run.

## Setting up for local development

When you develop an application that uses Spanner as a database, you can use the spanner emulator locally. The spanner emulator can be used by either using the `gcloud` command:

```shell
$ gcloud emulators spanner start
```

or by using the docker container:

```shell
$ docker run -d --name cloud-spanner-emulator -p 127.0.0.1:9010:9010 -p 127.0.0.1:9020:9020 gcr.io/cloud-spanner-emulator/emulator:latest
```

The emulator uses in-memory storage, meaning that when the emulator quits, your data will be gone. This is why it makes sense to develop your application in such a way that is easy to recreate your database and data.

After starting the spanner the emulator, you need to create an instance and database just as you would in the hosted Cloud Spanner solution.

Creating an instance and database for your emulator can be done by using the `gcloud` command line tool.

Using `gcloud`:

```shell
$ gcloud config configurations create emulator
  gcloud config set auth/disable_credentials true
  gcloud config set project my-project
  gcloud config set api_endpoint_overrides/spanner http://localhost:9020/
  
$ gcloud spanner instances create my-project \
       --config=emulator-config --description="My project" --nodes=1

$ gcloud spanner database create my-database --instance=my-project
```

You can add these commands to a shell script or Makefile to make your life easier.

Another option to create the instance and database is by using the instance and database admin clients. Below is a convenient piece of code to automatically create an instance and database if they don't exist. It can drop the database if it exists already, which is useful when you want to recreate your database.

```go
package db

import (
    "context"
    "fmt"
    "regexp"
    
    "cloud.google.com/go/spanner"
    database "cloud.google.com/go/spanner/admin/database/apiv1"
    instance "cloud.google.com/go/spanner/admin/instance/apiv1"
    databasepb "google.golang.org/genproto/googleapis/spanner/admin/database/v1"
    instancepb "google.golang.org/genproto/googleapis/spanner/admin/instance/v1"
    "google.golang.org/grpc/codes"
)

func CreateInstanceAndDatabase(ctx context.Context, uri string, drop bool) error {
	if err := createInstance(ctx, uri); err != nil {
		return err
    }
    return createDatabase(ctx, uri, drop)
}

func createInstance(ctx context.Context, uri string) error {
    matches := regexp.MustCompile("projects/(.*)/instances/(.*)/databases/.*").FindStringSubmatch(uri)
    if matches == nil || len(matches) != 3 {
        return fmt.Errorf("invalid instance id %s", uri)
    }
    instanceName := "projects/" + matches[1] + "/instances/" + matches[2]

    instanceAdminClient, err := instance.NewInstanceAdminClient(ctx)
    if err != nil {
        return err
    }
    defer instanceAdminClient.Close()

	_, err = instanceAdminClient.GetInstance(ctx, &instancepb.GetInstanceRequest{
        Name: instanceName,
    })
    if err != nil && spanner.ErrCode(err) != codes.NotFound {
        return err
    }
    if err == nil {
        // instance already exists
        return nil
    }
    _, err = instanceAdminClient.CreateInstance(ctx, &instancepb.CreateInstanceRequest{
        Parent:     "projects/" + matches[1],
        InstanceId: matches[2],
    })
    if err != nil {
        return err
    }
    return nil
}

func createDatabase(ctx context.Context, uri string, drop bool) error {
    matches := regexp.MustCompile("^(.*)/databases/(.*)$").FindStringSubmatch(uri)
    if matches == nil || len(matches) != 3 {
        return fmt.Errorf("invalid database id %s", uri)
    }

    databaseAdminClient, err := database.NewDatabaseAdminClient(ctx)
    if err != nil {
        return err
    }
    _, err = databaseAdminClient.GetDatabase(ctx, &databasepb.GetDatabaseRequest{Name: uri})
    if err != nil && spanner.ErrCode(err) != codes.NotFound {
        return err
    }
    if err == nil {
    	// Database already exists
        if drop {
            if err = c.databaseAdminClient.DropDatabase(ctx, &databasepb.DropDatabaseRequest{Database: uri}); err != nil {
                return err
            }
        } else {
            return nil
        }
    }

    op, err := databaseAdminClient.CreateDatabase(ctx, &databasepb.CreateDatabaseRequest{
        Parent:          matches[1],
        CreateStatement: "CREATE DATABASE `" + matches[2] + "`",
        ExtraStatements: []string{},
    })
    if err != nil {
        return err
    }
    if _, err = op.Wait(ctx); err != nil {
        return err
    }
    return nil
}
```

To use the emulator from your application, you need to set the environment variable `SPANNER_EMULATOR_HOST` to the host where your emulator is running, for example `localhost:9010`. This means that when the environment variable is set, you can assume that you are running locally. So to make local development easier, you can call the `CreateInstanceAndDatabase` function when the environment variable is set.

```go
func main() {
	ctx := context.Background()
	
	if os.Getenv("SPANNER_EMULATOR_HOST") != "" {
		err := CreateDatabaseAndInstance(ctx, "projects/my-project/instances/my-instance/databases/my-db", true)
		// handle error
    }
}
```

## Migrations

Of course creating a database is not enough to get your application working, you would also need tables. The `databasepb.CreateDatabaseRequest` has a field called `ExtraStatements` which allows you to add `CREATE TABLE` statements and other DDL (Data Definition Language) statements. You can also change your database later by using a `databasepb.UpdateDatabaseDdl` statement. However, these DDL changes are not version controlled as you would like to see when applying database migrations. It does not automatically track which migrations have been applied, which means you miss out on features like automatically applying migrations that haven't been applied yet.

There are multiple tools that allow you to track which migrations have been applied, and then apply the rest to make your database up-to-date. [github.com/golang-migrate/migrate](https://github.com/golang-migrate/migrate) is a great tool with support for Spanner. 

```go
package db

import (
	migrate "github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/spanner"
	_ "github.com/golang-migrate/migrate/v4/source/file" // golint: required for importing migration source files
)

func ApplyMigrations(uri string, migrationsFolder string) error {
	s := &spanner.Spanner{}
	d, err := s.Open(uri + "?x-clean-statements=true")	// Clean statements to allow multiple statements per file
    if err != nil {
		return err
	}

	m, err := migrate.NewWithDatabaseInstance("file://"+migrationsFolder, uri, d)
	if err != nil {
		return err
	}

	err = m.Up()
	if err == migrate.ErrNoChange {
		// Already up-tp-date
		return nil
	}
	return err
}
```

The migrations folder should contain `.sql` files with files that contain SQL statements for changing your database structure. Each file should be named like `0001_create_tables.up.sql` where `0001` is the version number of the migration which determines the order in which migrations should be applied, `create_tables` is your description and `up` signifies that this file is used when going `Up()`.

The golang-migrate tool will create a table called `SchemaMigrations` where it will store a record for each version that has been applied.

One feature that is lacking in golang-migrate, is that it is only able to apply DDL statements and not DML (Data Manipulation Language) statements. This means that you can change the structure of your database, but you can't insert data. The database admin client is only concerned with DDL statements. If you want to apply DML statements you need to use the Spanner client:

```go
	spannerClient, err := spanner.NewClient(ctx, uri)
	if err != nil {
		// err
	}
	defer spannerClient.Close()
	
	err = spannerClient.ReadWriteTransaction(ctx, func(ctx context.Context, txn *spanner.ReadWriteTransaction) error {
		txn.Update(ctx, spanner.Statement{
		    SQL: `INSERT INTO Singers (SingerId, FirstName, LastName)
                  VALUES (1, 'Marc', 'Richards'),
                         (2, 'Catalina', 'Smith'),
                         (3, 'Alice', 'Trentor');`
        })  
    })
```

In case you want to apply both DDL and DML statements in a specified order, you can create a function which:

1. Reads files from your migrations folder
2. Based on the version decide in which order the migrations should be applied
3. Based on the name of the file check if it is a DDL or DML statement
4. Apply them in order and create a record in a `migrations` table when applied


## Testing and mocking

In [a previous blog]({{< relref "/post/cloud-spanner-testing-in-go.md" >}}) post I talked about the difficulties in setting up a situation where automated testing is easy with Spanner. In the meantime I have experimented and learned a bit more.

In a good testing situation, you can run your tests in an isolated environment. Preferably in a set up that is as close to production as possible. This means that mocking your database package does not come close to that at all. Running Spanner is expensive, so running your tests against a hosted Spanner instance would be a luxury. Instead, the emulator is the solution that comes closest to production. It means that queries are actually executed and not mocked.

The function for creating an instance and database together with the function for applying migrations will help a lot in this case.

I created a set of integrations tests that are marked with a `+build integration` build tag. For these tests, a Spanner emulator is required.

```go
// +build integration
package db

import (
	"context"
	"os"
	"testing"


	"cloud.google.com/go/spanner"
	"github.com/stretchr/testify/suite"
)

type Suite struct {
	suite.Suite
}

func (s *Suite) SetupSuite() {
	ctx := context.Background()
	if os.Getenv("SPANNER_EMULATOR_HOST") == "" {
		s.T().Skip("no spanner emulator detected")
	}
	uri := "projects/integration/instances/integration/databases/integration"
	err := CreateInstanceAndDatabase(ctx, uri, true)
	s.NoError(err)

	// Apply your migrations

	spannerClient, err := spanner.NewClient(ctx, uri)
	s.NoError(err)

	// Inject your spanner client where you need it
}

func TestIntegrationSuite(t *testing.T) {
	suite.Run(t, new(Suite))
}
```

## Spanner Emulator testing in docker container

In [the previous blog posts]({{< relref "/post/cloud-spanner-testing-in-go.md" >}}) I also explained the difficulties of getting a Spanner emulator up and running in Cloud Build. It turns out that running the emulator in CI can be done a lot easier. For the emulator to run, two files are required from the emulator docker image: `gateway_main` and `emulator_main`. These files can be copied in the build step for docker image:

```dockerfile
FROM gcr.io/cloud-spanner-emulator/emulator:1.2.0 as spanner-emulator

FROM golang:1.16.4 as builder
WORKDIR /build
COPY go.* ./
RUN go mod download
COPY . /build
COPY --from=spanner-emulator gateway_main emulator_main ./bin/
RUN go test -tags=integration ./...
RUN CGO_ENABLED=0 GOOS=linux go build -mod=readonly

FROM gcr.io/distroless/base:latest
COPY --from=builder /build/my-project /my-project
CMD ["/my-project"]
```

In the integration tests, we can start the emulator if it is not detected:

```go
import (
    "context"
    "os"
    "os/exec"

    "github.com/stretchr/testify/suite"
)

type Suite struct {
    suite.Suite
    emulator *exec.Cmd
}

func (s *Suite) SetupSuite() {
    ctx := context.Background()

	if os.Getenv("SPANNER_EMULATOR_HOST") == "" {
		emulator := exec.Command("./bin/gateway_main", "--hostname", "0.0.0.0")
		if err := emulator.Start(); err == nil {
			s.emulator = emulator
		}
		os.Setenv("SPANNER_EMULATOR_HOST", "localhost:9010")
	}
	
	// and so on 
}

func (s *Suite) TearDownSuite() {
    if s.emulator != nil {
        err := s.emulator.Process.Kill()
        s.NoError(err)
    }
}
```

## Architecture

There are many opinions out there on how to structure your Go application. A common pattern for accessing a database is to create [a repository]({{< relref "/post/structuring-go.md" >}}) interface which defines how objects can be stored into your database and retrieved from your database. I'm going to give a similar example for Spanner, based on a single interface.

Let's start by defining a package `db` which will contain our database service. As an example, let's create a functions for retrieving and creating a user.

```go
package db

import (
	"context"

	"cloud.google.com/go/spanner"
)


var _ Service = (*service)(nil)

type User struct {
	UUID string `spanner:"uuid"`
	Name string `spanner:"name"`
}

type Service interface {
	GetUserByUUID(ctx context.Context, uuid string) (User, error)
	CreateUser(ctx context.Context, user User) (User, error)
}

type service struct {
	spannerClient *spanner.Client
}

type NewService(spannerClient *spanner.Client) Service {
	return &service{spannerClient: spannerClient}
}

func (svc *service) GetUserByUUID(ctx context.Context, uuid string) (User, error) {
	txn := svc.spannerClient.ReadOnlyTransaction()
	defer txn.Close()
	
	query := spanner.Statement{
		SQL:    "SELECT * FROM users WHERE uuid=@uuid",
		Params: map[string]interface{}{
			"uuid": uuid,
        },
    }
    
    iter := txn.Query(ctx, query)
    var user User
    err := iter.Do(func(row *spanner.Row) error {
    	return row.ToStruct(&user)
    })
    if err != nil {
    	return User{}, err
    }
    return user, nil
}

func (svc *service) CreateUser(ctx context.Context, user User) (User, error) {
	user.UUID = uuid.New().String() 
		
	_, err := svc.spannerClient.ReadWriteTransaction(func(ctx context.Context, txn *spanner.ReadWriteTransaction) error {
		mutation, err := spanner.InsertStruct("users", user)
		if err != nil {
			return err
        }
        return txn.BufferWrite([]*spanner.Mutation{mutation})
    })
	if err != nil {
		return User{}, err
    }
    return user, nil
}
```

In your application you can create an instance of the spanner client, create an instance of your db service and get going:

```go
package main

func main() {
	ctx := context.Background()
	uri := "projects/my-project/instances/my-instance/databases/my-db"
	spannerClient, err := spanner.NewClient(ctx, uri)
	if err != nil {
		// handle
	}
	defer spannerClient.Close()

	if os.Getenv("SPANNER_EMULATOR_HOST") != "" {
		CreateInstanceAndDatabase(ctx, uri, true)
		ApplyMigrations(ctx, uri)
	}
	
	dbService := db.NewService(spannerClient)
	
	user, err := dbService.CreateUser(ctx, db.User{Name: "Laurence"})
	if err != nil {
		// handle
	}
	user, err = dbService.GetUserByUUID(ctx, user.UUID)
	if err != nil {
		// handle
    }
}
```

## Sequences

A Spanner database works a bit differently from a normal SQL database. Spanner does automatic sharding of data based on the primary keys of your tables. If you use an auto incrementing identifier as is common in SQL database, you might create hotspots in your data, resulting in an uneven spread of your data over the Spanner servers.

Therefore, the advice is to use either:

1. Add a hashed version of your keys as the first field of the primary key
2. Use a UUID as primary key
3. Bit-reverse sequential values

In any SQL database there is the option of having auto-incrementing fields. However, Spanner does not have that concept. Knowing the best practices for designing schemas, there might still be a situation in which you require a sequential field. In that case, you can create your own sequences. As [the examples in the docs](https://cloud.google.com/solutions/sequence-generation-in-cloud-spanner) are all Java, let me post a Go alternative:

```go
import (
    "context"
    
    "cloud.google.com/go/spanner"
    "google.golang.org/grpc/codes"
)

func getSequenceNumber(ctx context.Context, t *spanner.ReadOnlyTransaction, startSequenceNumber int64, name string) (int64, []*spanner.Mutation, error) {
	var mutations []*spanner.Mutation
	var nextValue int64

	row, err := t.ReadRow(ctx, "sequences", spanner.Key{name}, []string{"next_value"})
	if err != nil && spanner.ErrCode(err) != codes.NotFound {
		return -1, nil, err
	}
	// Init sequence if not exists
	if spanner.ErrCode(err) == codes.NotFound {
		nextValue = startSequenceNumber
		seq := Sequence{
			Name:        name,
			NextValue:   startSequenceNumber,
		}
		mutation, err := spanner.InsertStruct("sequences", seq)
		if err != nil {
			return -1, nil, err
		}
		mutations = append(mutations, mutation)
	} else {
		err = row.ColumnByName("next_value", &nextValue)
		if err != nil {
			return -1, nil, err
		}
	}

	sequenceFields := map[string]interface{}{
		"name":         name,
		"next_value":   nextValue + 1,
	}
	mutations = append(mutations, spanner.UpdateMap("sequences", sequenceFields))
	return nextValue, mutations, nil
}
```

## Statements vs Mutations

There are two ways of retrieving and storing data using the spanner Go library: statements and mutations. In the examples so far I have used both of them already. A spanner statement lets you execute SQL statements directly. The `spanner.ReadOnlyTransaction` lets you use read-only statements:

```go
txn := spannerClient.ReadOnlyTransaction()
defer txn.Close()

query := spanner.Statement{
	SQL:    "SELECT * FROM user WHERE uuid=@uuid"
	Params: map[string]interface{}{
		"uuid": "some-uuid"
    }
}

iter := txn.Query(ctx, query)
```

The `spanner.ReadWriteTransaction` lets you `SELECT` as well as `INSERT`, `UPDATE`, `DELETE`.

```go
spannerClient.ReadWriteTransaction(ctx, func(ctx context.Context, txn *spanner.ReadWriteTransaction) error {
	update := spanner.Statement{
		SQL: "INSERT INTO ..."
    }
    _, err := txn.Update(ctx, update)
    
    return err
})
```

Mutations are another way of doing write operations. They cannot be used for `SELECT`ing as that would not be a mutation.

```go
spannerClient.ReadWriteTransaction(ctx, func(ctx context.Context, txn *spanner.ReadWriteTransaction) error {
	user := User{
		Name: "Laurence"
    }
    mutation, err := spanner.InsertStruct("users", user)
    if err != nil {
    	return err
    }
    return txn.BufferWrite([]*spanner.Mutation{mutation})
})
```

The main thing to keep in mind with statements and mutations, is that the result of statements is directly available within the transaction, while the result of the mutations will not be available in the same transaction. So if you want to write first and then read, the write should be a statement and not a mutation.

## Stopping iterators, closing transactions, and closing the client

A small mistake can lock up your database. Never forget to:

```go
txn := spannerClient.ReadOnlyTransaction()
defer txn.Close()

iter := txn.Query(ctx, query)
iter.Stop()

spannerClient := spanner.NewClient()
defer spannerClient.Close()
```

A good solution instead of having to `iter.Stop()` is to use the `iter.Do()` function as it automatically stops the iteration at the end.

## NullInt64, NullFloat64, NullString

Go does not have a concept of `NULL` when it comes to concrete types like `int`, `float` and `string`. If you run a spanner query and the result is `NULL`, then there is no way for spanner to fit that into your concrete type. One way to work around that is by using a pointer:

```go
func someFunc() (int64, error) {
    txn := spannerClient.ReadOnlyTransaction()
    defer txn.Close()
    
    it := txn.Query(ctx, spanner.Statement{
        SQL:    `SELECT SUM(*) WHERE value > 42`, // Something that doesn't exist
    })
    defer it.Stop()
    
    var sum *int64
    err := it.Do(func(row *spanner.Row) error {
        row.Column(0, &sum)
        return 0, nil
    })
    if err != nil {
        return 0, err
    }
    if sum != nil {
        return *sum, nil
    }
    return 0, nil
}
```

However, Spanner provides an easier alternative with `spanner.NullInt64`:

```go
func someFunc() (int64, error) {
    txn := spannerClient.ReadOnlyTransaction()
    defer txn.Close()
    
    it := txn.Query(ctx, spanner.Statement{
        SQL:    `SELECT SUM(*) WHERE value > 42`, // Something that doesn't exist
    })
    defer it.Stop()
    
    var sum spanner.NullInt64
    err := it.Do(func(row *spanner.Row) error {
        row.Column(0, &sum)
        return 0, nil
    })
    if err != nil {
        return 0, err
    }
    return sum.Int64, nil
}
```

The same goes for `spanner.NullFloat64` and `spanner.NullString`

## golang-samples

A good place to get example of how to use Google Cloud services with Go is [github.com/GoogleCloudPlatform/golang-samples](https://github.com/GoogleCloudPlatform/golang-samples). There is a folder with Spanner examples as well. Make a checkout of the repository as that makes it a lot easier to search and navigate through.

## Conclusion

Spanner is a great database if you have the money for it. Interacting with it from Go sometimes takes a bit effort to figure out how things work, but in the end it all makes sense. Testing isn't always that easy, but with instance and database creation and automatic migrations set-up, it's a breeze.