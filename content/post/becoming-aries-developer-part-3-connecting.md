---
title: "Becoming an Aries Developer - Part 3: Connecting"
date: 2020-09-14T10:05:19+05:30
draft: true
summary:
image: images/ladakh1.webp
tags:
- Decentralization
- Self-Sovereign Identities

#reddit:
#  created: 1594708583 
#  url: https://www.reddit.com/r/ldej/comments/hqwgj8/discuss_working_in_the_trenches/
#  title: "Working in the Trenches"
---

In [part 1]({{< relref "/post/becoming-aries-developer-part-1-terminology.md" >}}) I gave an introduction to the terms used in the Self-Sovereign Identity space. In [part 2]({{< relref "/post/becoming-aries-developer-part-2-development-environment.md" >}}) I part I explained the tools and command-line arguments for the development environment. In this part I'm going to set up two agents, and they are going to connect using the invite and request/response protocol.

The work on connecting two agents to create a connection and exchange messages is ongoing. This means that whatever I write here might be outdated tomorrow.

First of all, let's address where you can find the most up-to-date documentation for connecting two agents. There are two specification that are required to understand how agents connect. First, the [DIDComm Messaging](https://identity.foundation/didcomm-messaging/docs/spec/) protocol and second the [DID Exchange](https://github.com/hyperledger/aries-rfcs/tree/master/features/0023-did-exchange) protocol.

At the moment of writing DIDComm Messaging contains sections about Out Of Band (OOB) messaging and Connections, but they are [about to be removed](https://github.com/decentralized-identity/didcomm-messaging/pull/73). DIDComm is the protocol that specifies basic structure for secure messaging between the agents. It is a Draft specification at this moment and contains numerous TODOs.

With DIDComm allowing for secure messaging between agents, DID Exchange is the protocol that allows to make a connection between the two agents. DID Exchange specifies the messages that the requester and the responder send to establish the connection. DID Exchange replaces [Connection Protocol](https://github.com/hyperledger/aries-rfcs/blob/master/features/0160-connection-protocol/README.md), so need to look there. Googling DID Exchange brings you [another definition (Direct Inward Dialing Exchange)](https://medium.com/@a.jamous/why-do-we-need-another-did-exchange-in-2019-2b6308e834ff) which is unrelated and should be ignored.

DID Exchange currently has a specification of OOB messages, but they are moved out to [Out-of-Band Protocols](https://github.com/hyperledger/aries-rfcs/blob/master/features/0434-outofband/README.md).

The latest version of both DID Exchange and OOB Protocols are currently not implemented in ACA-py. But ACA-py does have an implementation of the Connection protocol, so two instances can connect. 

Let's go through the steps of connecting two agents. Let's say there is a client called Alice, and one called Bob.

Alice starts an ACA-py instance on port 11000 and connects to it with `go-acapy-client`
```go
client := acapy.NewClient("http://localhost:9000", "http://localhost:11000")
```
Bob starts an ACA-py instance on port 11001 and connects to it:
```go
client := acapy.NewClient("http://localhost:9000", "http://localhost:11001")
```
They are both connecting to the same ledger, which is the VON-network browser.

1. Alice creates an invitation.
    An invitation can be created with a POST to `/connections/create-invitation`.
    With `go-acapy-client`:
    ```go
    invitation := client.CreateInvitation("Bob", false, false, true)
    ```
   The invitation contains an `InvitationURL` which is a base64urlencoded version of `invitation.Invite`
2. Bob receives the invitation.
    He can receive the invitation with the client:
    ```go
    client.ReceiveInvitation(invite)
    ```
3. Bob accepts the invitation
4. Bob responds with a connection request
5. Alice receives the connection request
6. Alice accepts the connection request
7. Alice sends a connection response
8. Bob receives the connection response
9. Alice and Bob established a connection


 



    An invitation can be created with the endpoint `/connections/create-invitation`.



