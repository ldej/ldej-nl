---
title: "Becoming a Hyperledger Aries Developer - Part 4: Connecting using go-acapy-client"
date: 2020-09-16T11:04:04+05:30
draft: false
summary: Connecting two clients using `go-acapy-client`
image: images/ladakh1.webp
tags:
- Decentralization
- Self-Sovereign Identities
- Hyperledger Aries

#reddit:
#  created: 1594708583 
#  url: https://www.reddit.com/r/ldej/comments/hqwgj8/discuss_working_in_the_trenches/
#  title: "Working in the Trenches"
---

In [part 1]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-1-terminology.md" >}}) I gave an introduction to the terms used in the Self-Sovereign Identity space. In [part 2]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-2-development-environment.md" >}}) I explained the tools and command-line arguments for the development environment. In [part 3]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-3-connecting-using-swagger" >}}) I set up two agents, and they connect using the invite and request/response protocol. In this part I introduce the `go-acapy-client` library that allows you to interact with ACA-py from Go.

## Set up

You can find the source of `go-acapy-client` at [github.com/ldej/go-acapy-client](https://github.com/ldej/go-acapy-client).

You can install the package using:

```shell script
$ go get github.com/ldej/go-acapy-client
```

Initialize the client:
```go
package main 

import "github.com/ldej/go-acapy-client"

func main() {
    var ledgerURL = "http://localhost:9000"
    var acapyURL = "http://localhost:8000"
    client := acapy.NewClient(ledgerURL, acapyURL)
}
```

## Example: Connecting

In the [github.com/ldej/go-acapy-client/examples](https://github.com/ldej/go-acapy-client/examples) directory you can find an implementation of an example where two agents can be set up and connect to each other. The example requires a ledger to be available, for example the VON-network ledger. It registers a new DID with a randomized seed and then starts an ACA-py instance as a sub process.

Check out the documentation of the example for more information.

## ACA-py client functionality

As of version v0.1-alpha, the only endpoints that are supported are the `/connections/` endpoints.

```go
var ledgerURL = "http://localhost:9000"
var acapyURL = "http://localhost:8000"
client := acapy.NewClient(ledgerURL, acapyURL)

didResponse, err := client.RegisterDID(alias string, seed string, role string)

// start ACA-py with the newly registered DID

invitationResponse, err := client.CreateInvitation(alias string, autoAccept bool, multiUse bool, public bool)

receiveInvitationResponse, err := client.ReceiveInvitation(invitationJson []byte)

connection, err := client.AcceptInvitation(connectionID string)

connection, err := client.AcceptRequest(connectionID string)

thread, err := client.SendPing(connectionID string)

err := client.SendBasicMessage(connectionID string, message string)

connection, err := client.GetConnection(connectionID string)

connections, err := client.QueryConnections(params acapy.QueryConnectionsParams)

err := client.RemoveConnection(connectionID string)
``` 

## Webhooks

The ACA-py client supports webhooks for events that happen in ACA-py and that your controller might want to know about. For example a connection request has come in, or a basic message has been received. `go-acapy-client` supports a convenient way of passing on the these messages to a function of your choosing:

```go
package main

import (
    "fmt"
    "github.com/gorilla/mux"
    "github.com/ldej/go-acapy-client"
)

func main() {
    app := App{} // define your own App struct and attach the go-acapy-client

	r := mux.NewRouter()
	webhooksHandler := acapy.Webhooks(
		app.ConnectionsEventHandler,
		app.BasicMessagesEventHandler,
		app.ProblemReportEventHandler,
	)

	r.HandleFunc("/webhooks/topic/{topic}/", webhooksHandler).Methods(http.MethodPost)
}

func (app *App) ConnectionsEventHandler(event acapy.ConnectionsEvent) {
	fmt.Printf("\n -> Connection %q (%s), update to state %q\n", event.Alias, event.ConnectionID, event.State)
}

func (app *App) BasicMessagesEventHandler(event acapy.BasicMessagesEvent) {
	connection, _ := app.GetConnection(event.ConnectionID)
	fmt.Printf("\n -> Received message from %q (%s): %s\n", connection.Alias, event.ConnectionID, event.Content)
}

func (app *App) ProblemReportEventHandler(event acapy.ProblemReportEvent) {
	fmt.Printf("\n -> Received problem report: %+v\n", event)
}
```

## Conclusion

You can now build a controller for ACA-py in go using the `go-acapy-client` library. Please submit issues and pull-requests in case of questions and feature requests. In [part 5]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-5-issue-credentials" >}}) I will issue a credential using the connected clients.
