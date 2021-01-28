---
title: "Becoming a Hyperledger Aries Developer - Part 3: Connecting using DIDComm Exchange"
date: 2021-01-25T10:05:19+05:30
draft: false
summary: Starting two ACA-py instances with the right parameters and establishing a connection between them.
image: images/agra5.webp
tags:
- Decentralization
- Self-Sovereign Identities
- Hyperledger Aries
- aries-cloudagent-python
- ACA-py
- DIDComm Exchange

---

In [part 1]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-1-terminology.md" >}}) I gave an introduction to the terms used in the Self-Sovereign Identity space. In [part 2]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-2-development-environment.md" >}}) I explained the tools and command-line arguments for the development environment. In this part I'm going to set up two agents, and they are going to connect using the invite and request/response protocol. The [first version]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-3-connecting-using-swagger" >}}) of this blog post described how ACA-py agents can connect using the RFC0160 Connection Protocol. I did not use the Out-of-Band protocol as I did not see how that would add anything. In this blog post I will use the Out-of-Band protocol and RFC0023 DID Exchange because a first version of DID Exchange has been implemented in ACA-py v0.6.0.

The work on connecting two agents to create a connection and exchange messages is ongoing. This means that whatever I write here might be outdated tomorrow.

## DID Exchange v1 and Out-of-Band messaging

Whenever two agents want to connect with each other, they do a connection-dance, a series of messages that go back and forth to establish a connection and exchange information. The first iteration of this connection protocol is described in [HIPE-0031](https://github.com/hyperledger/indy-hipe/tree/master/text/0031-connection-protocol) and has been adopted into [Aries RFC0160](https://github.com/hyperledger/aries-rfcs/blob/master/features/0160-connection-protocol/README.md). When it became clear that communication between Indy agents required a separate form of standardization, the Indy RFCs were adopted into Aries RFCs. Aries RFC0160 has been implemented in ACA-py for quite some time now and works perfectly well for connecting two agents.

A next iteration of the protocol**s** is nearing completion. Yes, plural, because RFC0160 will be split into [Aries RFC0023](https://github.com/hyperledger/aries-rfcs/tree/master/features/0023-did-exchange), which describes DID Exchange v1, and [Aries RFC0434](https://github.com/hyperledger/aries-rfcs/blob/master/features/0434-outofband/README.md) which describes Out-of-Band messaging.

{{% tip title="Googling DID Exchange" %}}

Googling DID Exchange brings you [another definition (Direct Inward Dialing Exchange)](https://medium.com/@a.jamous/why-do-we-need-another-did-exchange-in-2019-2b6308e834ff) which is unrelated and should be ignored.

{{% /tip %}}

ACA-py is currently adding support in v0.6.0 for DID Exchange which will allow for communication between ACA-py agents and other agents that implement it, for example [github.com/hyperledger/aries-framework-go](https://github.com/hyperledger/aries-framework-go).

The DID Exchange protocol is used for communication using DIDComm between two agents to establish a connection. However, when a connection is made between two agents, how do they know where to find each other, and how do they communicate this with each other? To solve that problem, the Out-of-Band protocol has been made.

An agent can create an invitation for another agent to connect with it. The other agent receives the invitation, for example as a link in an email or by scanning a QR-code, and starts the connection-dance.

Basically, the `/connections/create-invitation` and `/connections/receive-invitation` endpoints have been replaced with the Out-of-Band endpoints `/out-of-band/create-invitation` and `/out-of-band/receive-invitation`. Similarly, the `/connections/{conn_id}/accept-invitation` and `/connections/{conn_id}/accept-request` endpoints have been replaced with the DID Exchange endpoints `/didexchange/{conn_id}/accept-invitation` and `/didexchange/{conn_id}/accept-request`. This makes that the other `/connections` endpoints are just there to manage connections.

## Starting two ACA-py clients

Let's say there are two clients: Alice and Bob. They are both going to start their ACA-py instances and connect.

To start an ACA-py client, you first need to have a DID. You can register a DID by going to your VON-network browser at [localhost:9000](http://localhost:9000/) and enter a Wallet seed (for example your first name), and an alias (for example your full name). You can leave the DID field blank.

After registering you will see something like:
```text
Seed: Laurence000000000000000000000000
DID: 6i7GFi2cDx524ZNfxmGWcp
Verkey: 47TycWXT1C6UQAuKaDnqvmViY4sqPjTqGuyQcYryomzK
``` 

The value of Seed is required as command line argument `--seed Laurence000000000000000000000000` when running your ACA-py instance. Because of this dependency (you need to have a DID before you can start ACA-py), the demo agents in ACA-py and the [example agent](https://github.com/ldej/go-acapy-client/tree/master/examples/connecting) in `go-acapy-client` will run `aca-py` for you in the background. They first do a call to `localhost:9000/register` and then use the values to start ACA-py.

During development, it is a good idea to randomize the wallet seed value when registering a DID, so you can start with a clean slate every run. The same goes for `--wallet-name`. When ACA-py starts it will check the DID in the wallet to see if it matches with the provided seed. If it doesn't match it will give an error an exit: 

```text
aries_cloudagent.config.base.ConfigError: New seed provided which doesn't match the registered public did 6i7GFi2cDx524ZNfxmGWcp
```

You can override this behaviour with `--replace-public-did`, after which it will update the DID in the wallet with the DID that matches the provided seed. Another option is to randomize the wallet name.

With the release of ACA-py v0.6.0, the provisioning of a wallet has changed. In general, ACA-py has two main commands: `start` and `provision`. The provision command is there to separate the creation of wallets and the usage of wallets. In a production application, you do not want to create or overwrite a wallet by accident. Your wallet contains the keys for using a specific DID, and a DID is registered in an Indy blockchain for real money. That's why there are separate steps. On the other hand, for development it is convenient to not have to do two separate steps. That's why a new command-line parameter (`--auto-provision`) has been added that automatically provisions a wallet in case it does not exist.

Let's start two clients:

{{< filename "Alice" >}}
```shell script
$ aca-py start \
  --label Alice \
  -it http 0.0.0.0 8000 \
  -ot http \
  --admin 0.0.0.0 11000 \
  --admin-insecure-mode \
  --genesis-url http://localhost:9000/genesis \
  --seed Alice000000000000000000000000000 \
  --endpoint http://localhost:8000/ \
  --debug-connections \
  --auto-provision \
  --wallet-type indy \
  --wallet-name Alice \
  --wallet-key secret

::::::::::::::::::::::::::::::::::::::::::::::
:: Alice                                    ::
::                                          ::
::                                          ::
:: Inbound Transports:                      ::
::                                          ::
::   - http://0.0.0.0:8000                  ::
::                                          ::
:: Outbound Transports:                     ::
::                                          ::
::   - http                                 ::
::   - https                                ::
::                                          ::
:: Public DID Information:                  ::
::                                          ::
::   - DID: UpFt248WuA5djSFThNjBhq          ::
::                                          ::
:: Administration API:                      ::
::                                          ::
::   - http://0.0.0.0:11000                 ::
::                                          ::
::                           ver: 0.6.0-pre ::
::::::::::::::::::::::::::::::::::::::::::::::

Listening...
```

The admin interface and Swagger documentation for Alice is available at [localhost:11000](http://localhost:11000/).

{{< filename "Bob" >}}
```shell script
$ aca-py start \
  --label Bob \
  -it http 0.0.0.0 8001 \
  -ot http \
  --admin 0.0.0.0 11001 \
  --admin-insecure-mode \
  --genesis-url http://localhost:9000/genesis \
  --seed Bob00000000000000000000000000000 \
  --endpoint http://localhost:8001/ \
  --debug-connections \
  --auto-provision \
  --wallet-type indy \
  --wallet-name Bob \
  --wallet-key secret


::::::::::::::::::::::::::::::::::::::::::::::
:: Bob                                      ::
::                                          ::
::                                          ::
:: Inbound Transports:                      ::
::                                          ::
::   - http://0.0.0.0:8001                  ::
::                                          ::
:: Outbound Transports:                     ::
::                                          ::
::   - http                                 ::
::   - https                                ::
::                                          ::
:: Public DID Information:                  ::
::                                          ::
::   - DID: Huv5gcSXhcpfCpymHKhiXV          ::
::                                          ::
:: Administration API:                      ::
::                                          ::
::   - http://0.0.0.0:11001                 ::
::                                          ::
::                           ver: 0.6.0-pre ::
::::::::::::::::::::::::::::::::::::::::::::::

Listening...
```

The admin interface and Swagger documentation for Bob is available at [localhost:11001](http://localhost:11001/).

## Connecting

Let's go through the steps of connecting two agents.

{{% big-point number="1" title="Alice creates an invitation" %}}

Use the endpoint `/out-of-band/create-invitation`.
A valid body to post is:
```json
{
    "include_handshake": true,
    "use_public_did": false
}
```
It is required to have either `include_handshake` or `attachments` or both in the body. I have not managed to get any `attachments` example to work, so let's stick to `include_handshake`.
The field `use_public_did` signifies that the public DID will be used in invites, more on that in the tip below.

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

The `serviceEndpoint` has the value that you have set with `--endpoint`.

{{% /tip %}}

Other than that, there are two query parameters:
- `auto_accept` will automatically accept the connection request from Bob in step 5.  
- `multi_use` signifies that an invitation can be used multiple times.

The response of `/out-of-band/create-invitation` will look something like this:

{{< filename "Alice" >}}
```json
{
  "state": "initial",
  "invi_msg_id": "613fbf3e-6eef-4b55-a2ce-f4df734591ca",
  "auto_accept": false,
  "multi_use": false,
  "invitation_id": "20e5d140-8cff-4dce-8e2b-abd120fff8a9",
  "invitation": {
    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/out-of-band/1.0/invitation",
    "@id": "613fbf3e-6eef-4b55-a2ce-f4df734591ca",
    "label": "Alice",
    "handshake_protocols": [
      "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/didexchange/v1.0"
    ],
    "service": [
      {
        "id": "#inline",
        "type": "did-communication",
        "recipientKeys": [
          "did:​key:z6MkvmumtZ958wnRi4qC7qvhjXAk73tRTKoiMDmZTnnPdwmi"
        ],
        "serviceEndpoint": "http://localhost:8000/"
      }
    ]
  },
  "created_at": "2021-01-25 10:17:56.043779Z",
  "updated_at": "2021-01-25 10:17:56.043779Z",
  "invitation_url": "http://localhost:8000/?oob=eyJAdHlwZSI6ICJkaWQ6c292OkJ6Q2JzTlloTXJqSGlxWkRUVUFTSGc7c3BlYy9vdXQtb2YtYmFuZC8xLjAvaW52aXRhdGlvbiIsICJAaWQiOiAiNjEzZmJmM2UtNmVlZi00YjU1LWEyY2UtZjRkZjczNDU5MWNhIiwgImxhYmVsIjogIkFsaWNlIiwgImhhbmRzaGFrZV9wcm90b2NvbHMiOiBbImRpZDpzb3Y6QnpDYnNOWWhNcmpIaXFaRFRVQVNIZztzcGVjL2RpZGV4Y2hhbmdlL3YxLjAiXSwgInNlcnZpY2UiOiBbeyJpZCI6ICIjaW5saW5lIiwgInR5cGUiOiAiZGlkLWNvbW11bmljYXRpb24iLCAicmVjaXBpZW50S2V5cyI6IFsiZGlkOmtleTp6Nk1rdm11bXRaOTU4d25SaTRxQzdxdmhqWEFrNzN0UlRLb2lNRG1aVG5uUGR3bWkiXSwgInNlcnZpY2VFbmRwb2ludCI6ICJodHRwOi8vbG9jYWxob3N0OjgwMDAvIn1dfQ==",
  "trace": false
}
```

{{% big-point number="2" title="Bob receives the invitation" %}}

Use the `/out-of-band/receive-invitation` endpoint. The body should be only the invitation object. For example:

{{< filename "Bob" >}}
```json
{
    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/out-of-band/1.0/invitation",
    "@id": "613fbf3e-6eef-4b55-a2ce-f4df734591ca",
    "label": "Alice",
    "handshake_protocols": [
      "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/didexchange/v1.0"
    ],
    "service": [
      {
        "id": "#inline",
        "type": "did-communication",
        "recipientKeys": [
          "did:​key:z6MkvmumtZ958wnRi4qC7qvhjXAk73tRTKoiMDmZTnnPdwmi"
        ],
        "serviceEndpoint": "http://localhost:8000/"
      }
    ]
}
```
The request also accept two query parameters:
- `alias` is the name that Bob will give to this connection, so in this case Alice.
- `auto_accept` the invitation can be automatically accepted, if you set this to `false`, then Bob needs to accept the invitation in next step.

If you run two ACA-py instances next to each other you can just copy and paste the invitation. In the real world the invitation of Alice will usually go to Bob either as a QR-code or as link.

{{% big-point number="3" title="Bob accepts the invitation" %}}

Use the `/didexchange/{id}/accept-invitation` endpoint.  
The `{id}` should be the `connection_id` from the response of `/out-of-bounds/receive-invitation`. You can also find the `connection_id` by using the `/connections` endpoint.

Again you can provide an `alias`, it's still from Bob's perspective, so it should be 'Alice'. You can leave the `my_endpoint` query parameter empty, it will use the value of `--endpoint`. 

{{% big-point number="4" title="Bob responds with a connection request" %}}

This happens automatically when Bob accepts the invitation. The request will directly go from Bob's ACA-py instance to Alice's ACA-py instance.

Even though Alice started this interaction by creating an invitation, it is actually Bob that sends a connection request to Alice, therefore Bob is called the _requester_. Alice is called the _responder_.

{{% big-point number="5" title="Alice receives the connection request" %}}

This happens automatically as Bob's instance knows how to reach Alice's instance. The information is either in the `serviceEndpoint` field in case of non-public invite, or it is part of the DIDDoc in the ledger for the public DID of Alice.

{{% big-point number="6" title="Alice accepts the connection request" %}}

Use the `/didexchange/{id}/accept-request` endpoint. The `{id}` should be the `connection_id` that got created when Alice received the connection request. If you have `--debug-connections` enabled you can see it in Alice's ACA-py logs:
```shell
Received connection request from invitation
    connection: {'rfc23_state': 'request-received', 'state': 'request', 'their_role': 'invitee', 'invitation_msg_id': '613fbf3e-6eef-4b55-a2ce-f4df734591ca', 'routing_state': 'none', 'connection_id': 'f1b999c9-130c-454c-8167-d8f8eab3cd48', 'invitation_mode': 'once', 'their_did': '2cFBeu8oRnZmj12aGQ9Ges', 'request_id': '629361bf-26a6-439f-9325-2c0b5c73ffe2', 'accept': 'manual', 'their_label': 'Alice', 'invitation_key': 'HKejJJtdoQHxbZzVSGxrtRckHUca3SZMfCrddWpNiizL', 'created_at': '2021-01-25 10:17:56.038677Z', 'updated_at': '2021-01-25 10:23:46.248549Z'}
```

Alice can also find the `connection_id` by querying `/connections`. 

{{% big-point number="7" title="Alice sends a connection response" %}}

This happens automatically at the moment Alice accepts Bob's request.

In Alice's ACA-py console you will see:
```shell
Creating connection response
    connection_id: f1b999c9-130c-454c-8167-d8f8eab3cd48

Created connection response
    connection: {'rfc23_state': 'response-sent', 'state': 'response', 'their_role': 'invitee', 'invitation_msg_id': '613fbf3e-6eef-4b55-a2ce-f4df734591ca', 'routing_state': 'none', 'connection_id': 'f1b999c9-130c-454c-8167-d8f8eab3cd48', 'invitation_mode': 'once', 'their_did': '2cFBeu8oRnZmj12aGQ9Ges', 'my_did': 'QzyjxFCNjWkcgcchmVMz7P', 'request_id': '629361bf-26a6-439f-9325-2c0b5c73ffe2', 'accept': 'manual', 'their_label': 'Alice', 'invitation_key': 'HKejJJtdoQHxbZzVSGxrtRckHUca3SZMfCrddWpNiizL', 'created_at': '2021-01-25 10:17:56.038677Z', 'updated_at': '2021-01-25 10:50:42.286179Z'}
    response: <DIDXResponse(_message_id='064fa4a5-2d21-4388-af3e-2455403a7e85', _message_new_id=True, _message_decorators=<DecoratorSet{~thread: <ThreadDecorator(_thid='629361bf-26a6-439f-9325-2c0b5c73ffe2', _pthid='613fbf3e-6eef-4b55-a2ce-f4df734591ca', _sender_order=None, _received_orders=None)>}>, did='QzyjxFCNjWkcgcchmVMz7P', did_doc_attach=<AttachDecorator(ident='190eca42-ad75-490e-9fe9-f45217377057', description=None, filename=None, mime_type='application/json', lastmod_time=None, byte_count=None, data=<AttachDecoratorData(base64_='eyJAY29udGV4dCI6ICJodHRwczovL3czaWQub3JnL2RpZC92MSIsICJpZCI6ICJkaWQ6c292OlF6eWp4RkNOaldrY2djY2htVk16N1AiLCAicHVibGljS2V5IjogW3siaWQiOiAiZGlkOnNvdjpRenlqeEZDTmpXa2NnY2NobVZNejdQIzEiLCAidHlwZSI6ICJFZDI1NTE5VmVyaWZpY2F0aW9uS2V5MjAxOCIsICJjb250cm9sbGVyIjogImRpZDpzb3Y6UXp5anhGQ05qV2tjZ2NjaG1WTXo3UCIsICJwdWJsaWNLZXlCYXNlNTgiOiAiRTVnQkp0bjFSWVJldlZYREZmZU55MVl4RkdwVzRabzFYeDlWS1VRMXNSTWsifV0sICJhdXRoZW50aWNhdGlvbiI6IFt7InR5cGUiOiAiRWQyNTUxOVNpZ25hdHVyZUF1dGhlbnRpY2F0aW9uMjAxOCIsICJwdWJsaWNLZXkiOiAiZGlkOnNvdjpRenlqeEZDTmpXa2NnY2NobVZNejdQIzEifV0sICJzZXJ2aWNlIjogW3siaWQiOiAiZGlkOnNvdjpRenlqeEZDTmpXa2NnY2NobVZNejdQO2luZHkiLCAidHlwZSI6ICJJbmR5QWdlbnQiLCAicHJpb3JpdHkiOiAwLCAicmVjaXBpZW50S2V5cyI6IFsiRTVnQkp0bjFSWVJldlZYREZmZU55MVl4RkdwVzRabzFYeDlWS1VRMXNSTWsiXSwgInNlcnZpY2VFbmRwb2ludCI6ICJodHRwOi8vbG9jYWxob3N0OjgwMDAvIn1dfQ==', jws_=<AttachDecoratorDataJWS(header=<AttachDecoratorDataJWSHeader(kid='did:​key:z2DgjiZwG3oxb45n7aVGs37jjiMWX8AbmHmHGvhcq2H7UKi')>, protected='eyJhbGciOiAiRWREU0EiLCAia2lkIjogImRpZDprZXk6ejJEZ2ppWndHM294YjQ1bjdhVkdzMzdqamlNV1g4QWJtSG1IR3ZoY3EySDdVS2kiLCAiandrIjogeyJrdHkiOiAiT0tQIiwgImNydiI6ICJFZDI1NTE5IiwgIngiOiAiOG9JYkpEaHJhSG5hel9uLTM5UGQ0TmdXam5hUGV3UXJibTV0Wl9GYkRCayIsICJraWQiOiAiZGlkOmtleTp6MkRnamlad0czb3hiNDVuN2FWR3MzN2pqaU1XWDhBYm1IbUhHdmhjcTJIN1VLaSJ9fQ', signature='J2lhYsJgdkUS7LJiXpPbTOKzCKvXIhdpsE2bpM-7VrvzAKU4zN5u8yra-uGbpb3VcWLjSi09Z9vnQkkZKxdgAQ', signatures=None)>)>)>)>
```

{{% big-point number="8" title="Bob receives the connection response" %}}

This happens automatically when Alice sends the connection response.

In Bob's ACA-py console you will see:

```shell
Accepted connection response
    connection: {'connection_id': 'ba8c3c22-c9f7-4219-9ea3-5c435439db30', 'their_role': 'inviter', 'their_label': 'Alice', 'request_id': '629361bf-26a6-439f-9325-2c0b5c73ffe2', 'routing_state': 'none', 'state': 'response', 'accept': 'manual', 'their_did': 'QzyjxFCNjWkcgcchmVMz7P', 'updated_at': '2021-01-25 10:50:42.311502Z', 'rfc23_state': 'response-received', 'invitation_msg_id': '613fbf3e-6eef-4b55-a2ce-f4df734591ca', 'invitation_mode': 'once', 'created_at': '2021-01-25 10:20:43.340606Z', 'my_did': '2cFBeu8oRnZmj12aGQ9Ges', 'invitation_key': 'HKejJJtdoQHxbZzVSGxrtRckHUca3SZMfCrddWpNiizL'}
```

{{% big-point number="9" title="Alice and Bob established a connection" %}}

When Bob receives the connection response, his ACA-py will report:

```shell
Sent connection complete
    connection: {'connection_id': 'ba8c3c22-c9f7-4219-9ea3-5c435439db30', 'their_role': 'inviter', 'their_label': 'Alice', 'request_id': '629361bf-26a6-439f-9325-2c0b5c73ffe2', 'routing_state': 'none', 'state': 'completed', 'accept': 'manual', 'their_did': 'QzyjxFCNjWkcgcchmVMz7P', 'updated_at': '2021-01-25 10:50:42.324968Z', 'rfc23_state': 'completed', 'invitation_msg_id': '613fbf3e-6eef-4b55-a2ce-f4df734591ca', 'invitation_mode': 'once', 'created_at': '2021-01-25 10:20:43.340606Z', 'my_did': '2cFBeu8oRnZmj12aGQ9Ges', 'invitation_key': 'HKejJJtdoQHxbZzVSGxrtRckHUca3SZMfCrddWpNiizL'}
```

Bob's ACA-py will notify Alice that the connection has been established. Alice's ACA-py will report:

```shell
Received connection complete
    connection: {'rfc23_state': 'completed', 'state': 'completed', 'their_role': 'invitee', 'invitation_msg_id': '613fbf3e-6eef-4b55-a2ce-f4df734591ca', 'routing_state': 'none', 'connection_id': 'f1b999c9-130c-454c-8167-d8f8eab3cd48', 'invitation_mode': 'once', 'their_did': '2cFBeu8oRnZmj12aGQ9Ges', 'my_did': 'QzyjxFCNjWkcgcchmVMz7P', 'request_id': '629361bf-26a6-439f-9325-2c0b5c73ffe2', 'accept': 'manual', 'their_label': 'Alice', 'invitation_key': 'HKejJJtdoQHxbZzVSGxrtRckHUca3SZMfCrddWpNiizL', 'created_at': '2021-01-25 10:17:56.038677Z', 'updated_at': '2021-01-25 10:50:42.439456Z'}
    
Connection promoted to active
    connection: {'rfc23_state': 'completed', 'state': 'active', 'their_role': 'invitee', 'invitation_msg_id': '613fbf3e-6eef-4b55-a2ce-f4df734591ca', 'routing_state': 'none', 'connection_id': 'f1b999c9-130c-454c-8167-d8f8eab3cd48', 'invitation_mode': 'once', 'their_did': '2cFBeu8oRnZmj12aGQ9Ges', 'my_did': 'QzyjxFCNjWkcgcchmVMz7P', 'request_id': '629361bf-26a6-439f-9325-2c0b5c73ffe2', 'accept': 'manual', 'their_label': 'Alice', 'invitation_key': 'HKejJJtdoQHxbZzVSGxrtRckHUca3SZMfCrddWpNiizL', 'created_at': '2021-01-25 10:17:56.038677Z', 'updated_at': '2021-01-25 10:50:42.434136Z'}
```

{{% big-point number="10" title="Alice and Bob can send basic messages" %}}

Use the `/connections/{id}/send-message` endpoint. The `{id}` is the `connection_id` for Alice's connection to Bob. For Bob there is a different `connection_id` for the connection with Alice. Unfortunately the basic messages are not printed in the ACA-py terminal. For you to be notified about a basic message coming in, we need to take a look at [webhooks]({{< relref "/post/aries-cloudagent-python-webhooks.md" >}}).
    
## Automatic accepting

ACA-py support command line options to automatically accept invites and requests when they come in. This allows you to skip step 3 to 8. This is useful for development, but of course should not be used for production. The command line flags are `--auto-accept-invites` and `--auto-accept-requests`. The same parameters can be overridden in step 1 for Alice to automatically accept Bob's request in step 5. Similarly, Bob can specify auto-accept in step 2 so step 3 will be done automatically.
    
## Conclusion

It takes some effort to understand with which parameters to start the ACA-py instances and how to connect two agents. In the end the connecting of two agents can be done entirely via Swagger. In [part 4]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-4-connecting-using-go-acapy-client" >}}) I will discuss how you can do this using my `go-acapy-client` library.