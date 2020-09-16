---
title: "Becoming an Aries Developer - Part 3: Connecting using Swagger"
date: 2020-09-15T06:05:19+05:30
draft: false
summary: Starting two ACA-py instances with the right parameters and establishing a connection between them.
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

In [part 1]({{< relref "/post/becoming-aries-developer-part-1-terminology.md" >}}) I gave an introduction to the terms used in the Self-Sovereign Identity space. In [part 2]({{< relref "/post/becoming-aries-developer-part-2-development-environment.md" >}}) I explained the tools and command-line arguments for the development environment. In this part I'm going to set up two agents, and they are going to connect using the invite and request/response protocol.

The work on connecting two agents to create a connection and exchange messages is ongoing. This means that whatever I write here might be outdated tomorrow.

First of all, let's address where you can find the most up-to-date documentation for connecting two agents. There are two specification that are required to understand how agents connect. First, the [DIDComm Messaging](https://identity.foundation/didcomm-messaging/docs/spec/) protocol and second the [DID Exchange](https://github.com/hyperledger/aries-rfcs/tree/master/features/0023-did-exchange) protocol.

At the moment of writing DIDComm Messaging contains sections about Out Of Band (OOB) messaging and Connections, but they are [about to be removed](https://github.com/decentralized-identity/didcomm-messaging/pull/73). DIDComm is the protocol that specifies basic structure for secure messaging between the agents. It is a Draft specification at this moment and contains numerous TODOs.

With DIDComm allowing for secure messaging between agents, DID Exchange is the protocol that allows to make a connection between the two agents. DID Exchange specifies the messages that the requester and the responder send to establish the connection. DID Exchange replaces [Connection Protocol](https://github.com/hyperledger/aries-rfcs/blob/master/features/0160-connection-protocol/README.md), so need to look there. Googling DID Exchange brings you [another definition (Direct Inward Dialing Exchange)](https://medium.com/@a.jamous/why-do-we-need-another-did-exchange-in-2019-2b6308e834ff) which is unrelated and should be ignored.

DID Exchange currently has a specification of OOB messages, but they are moved out to [Out-of-Band Protocols](https://github.com/hyperledger/aries-rfcs/blob/master/features/0434-outofband/README.md).

The latest version of both DID Exchange and OOB Protocols are currently not implemented in ACA-py. But ACA-py does have an implementation of the Connection protocol, so two instances can connect.

Let's say there are two clients: Alice and Bob. They are both going to start their ACA-py instances and connect.

## Starting two ACA-py clients

To start an ACA-py client, you first need to have a DID. You can register a DID by going to your VON-network browser at [localhost:9000](http://localhost:9000/) and enter a Wallet seed (for example your first name), and an alias (for example your full name). You can leave the DID field blank.

After registering you will see something like:
```text
Seed: Laurence000000000000000000000000
DID: 6i7GFi2cDx524ZNfxmGWcp
Verkey: 47TycWXT1C6UQAuKaDnqvmViY4sqPjTqGuyQcYryomzK
``` 

The value of Seed is required as command line argument `--seed Laurence000000000000000000000000` when running your ACA-py instance. Because of this dependency (you need to have a DID before you can start ACA-py), the demo agents in ACA-py and the example agent in go-acapy-client will run `aca-py` for you in the background. They first do a call to `localhost:9000/register` and then use the values to start ACA-py.

During development, it is a good idea to randomize the wallet seed value when registering a DID, so you can start with a clean slate every run. The same goes for `--wallet-name`. When ACA-py starts it will check the DID in the wallet to see if it matches with the provided seed. If it doesn't match it will give an error an exit: 

```text
aries_cloudagent.config.base.ConfigError: New seed provided which doesn't match the registered public did 6i7GFi2cDx524ZNfxmGWcp
```

You can override this behaviour with `--replace-public-did`, after which it will update the DID in the wallet with the DID that matches the provided seed. Another option is to randomize the wallet name.

Let's start two clients:

```shell script
$ # Alice
$ aca-py start \
  --label Alice \
  -it http 0.0.0.0 8000 \
  -ot http \
  --admin 0.0.0.0 8001 \
  --admin-insecure-mode \
  --genesis-url http://localhost:9000/genesis \
  --seed Alice000000000000000000000000000 \
  --endpoint http://localhost:8000/ \
  --debug-connections \
  --public-invites \
  --wallet-type indy \
  --wallet-name Alice
```

The admin interface and Swagger documentation for Alice is available at [localhost:8001](http://localhost:8001/).

```shell script
$ # Bob
$ aca-py start \
  --label Bob \
  -it http 0.0.0.0 8002 \
  -ot http \
  --admin 0.0.0.0 8003 \
  --admin-insecure-mode \
  --genesis-url http://localhost:9000/genesis \
  --seed Bob00000000000000000000000000000 \
  --endpoint http://localhost:8002/ \
  --debug-connections \
  --public-invites \
  --wallet-type indy \
  --wallet-name Bob
```

The admin interface and Swagger documentation for Bob is available at [localhost:8003](http://localhost:8003/).

## Connecting

Let's go through the steps of connecting two agents.

1. Alice creates an invitation.
    Use the endpoint `/connections/create-invitation`.  
    The Alias field is the name of the invitation, so you can find it later. It is common to use the receivers name, in this case Bob.  
    Auto-accept will automatically accept the connection request from Bob in step 5.  
    Multi-use signifies that an invitation can be used multiple times.  
    Public signifies that the public DID will be used in invites.
   
{{% tip title="Public vs non-public invites" %}}

A public invites contains a DID for other agents to connect with. For a public invite, the ledger needs to know at which endpoint an agent can be reached. This means that it requires a lookup in the ledger by the invited agent. A non-public invite does not use a public DID, instead it contains a service endpoint url, so the invited agent can connect to inviter directly.

Example of a public invite:

```json
{
    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/connections/1.0/invitation",
    "@id": "3b3bf176-6871-40d2-9b55-28da981c4833",
    "label": "Alice",
    "did": "did:sov:6i7GFi2cDx524ZNfxmGWcp"
}
```

Example of a non-public invite:
```json
{
    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/connections/1.0/invitation",
    "@id": "13e2cf1b-3d1f-41c9-b9bb-bb75b431775b",
    "recipientKeys": [
        "CrWjhZLLrggVN53PFUeiGvYHCPb4QtjRBXEdcje8Pypx"
    ],
    "label": "Alice",
    "serviceEndpoint": "http://localhost:8000/"
}
```

{{% /tip %}} 
   
2. Bob receives the invitation.  
    Use the `/connections/receive-invitation` endpoint.  
    The body should be only the invitation object, there are two examples in the tip above here.  
    Alias is the name that Bob will give to this connection, so in this case Alice.
3. Bob accepts the invitation.  
    Use the `/connections/{id}/accept-invitation` endpoint.  
    The `{id}` should be the `connection_id` from the response of `/connections/receive-invitation`.  
    Again you can provide an alias, but this time it's from Bob's perspective, so it should be 'Alice'.
4. Bob responds with a connection request.  
    This happens automatically when Bob accepts the invitation. The request will directly go from Bob's ACA-py instance to Alice's ACA-py instance.
5. Alice receives the connection request.  
    This happens automatically as Bob's instance knows how to reach Alice's instance.
6. Alice accepts the connection request.  
    Use the `/connections/{id}/accept-request` endpoint.
    The `{id}` should be the `connection_id` from the response of `/connections/create-invitation`.
7. Alice sends a connection response.  
    This happens automatically at the moment Alice accepts Bob's request.  
8. Bob receives the connection response.  
    This happens automatically when Alice sends the connection response.
9. Alice and Bob established a connection.  
    In the Connection protocol, a message needs to be sent and then the connection will be marked as 'Active'.
10. Alice sends a basic message to Bob.  
    Use the `/connections/{id}/send-message` endpoint.  
    The `{id}` is the `connection_id` for Alice's connection to Bob. For Bob there is a different `connection_id` for the connection with Alice.  
    
## Conclusion

It takes some effort to understand with which parameters to start the ACA-py instances and how to connect two agents. In the end the connecting of two agents can be done entirely via Swagger. In the next part I will discuss how you can do this using my `go-acapy-client` library.