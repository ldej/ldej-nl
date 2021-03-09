---
title: "Building an ACA-py Controller: Accounts and Connection-less Credentials/Proofs"
date: 2021-09-01T12:53:28+05:30
draft: false
summary: How to implement accounts using verifiable credentials.
image: images/roadtrip01.webp
tags:
- Decentralization
- Self-Sovereign Identities
- Hyperledger Aries
- aries-cloudagent-python
- ACA-py
---

A common feature of a website where you can do something is to have accounts for your users. The traditional way is letting the user provide a username and password which are stored in your database. The next generation of accounts is federated, where an identity provider like Google or Facebook stores the information for you, and you can use that account to log in to other websites. What would accounts look like when you use Verifiable Credentials?

## Looking at Trinsic.id

Trinsic.id provides a system where you can create an account and log in later by scanning a QR-code.

When you register at Trinsic.id, you provide your name and email address. At that moment you are immediately logged-in. In your mail you receive a QR-code. When you scan the QR-code with your wallet app, a credential is added to your wallet. 

When you log out and want to log in again, you need to scan a QR-code with the Trinsic.id Wallet App.

What is the technology behind it?

{{% big-point number="1" title="Register" %}}

When you enter your name and email address, a user is created for you in the database. It contains your name, email, and a randomly generated UUID.

At that moment, a mail will be sent to your email address.

{{% big-point number="2" title="Get credential" %}}

The email contains a QR-code. When you scan the QR-code with a barcode scanner, you can see what data it contains. In this case it's a URL:

https://trinsic.studio/url/dc50d919-0e20-41f6-b015-...

When you follow the link, you get forwarded to a URL that looks like:

https://trinsic.studio/link/?d_m=eyJjb21tZW50IjpudWxsLCJjcmVkZ...

The value of the query parameter `d_m` is a base64 encoded value. When you decode that value, it looks like:

```json
{
  "comment": null,
  "credential_preview": {
    "attributes": [
      {
        "name": "Full Name",
        "mime-type": "text/plain",
        "value": "Laurence de Jong"
      },
      {
        "name": "Email",
        "mime-type": "text/plain",
        "value": "info@ldej.nl"
      },
      {
        "name": "Account ID",
        "mime-type": "text/plain",
        "value": "..."
      }
    ],
    "@id": null,
    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/1.0/credential-preview"
  },
  "offers~attach": [
    {
      "@id": "libindy-cred-offer-0",
      "mime-type": "application/json",
      "data": {
        "base64": "eyJzY2h..."
      }
    }
  ],
  "@id": "ea139094-80cc-4c5f-...",
  "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/1.0/offer-credential",
  "~service": {
    "recipientKeys": [
      "2Y4yagQw2Jdit6uTETpuVc9YTyPKnjyHuwzdbKZYABDi"
    ],
    "routingKeys": [
      "D41hyNHYtdyCSuMvERwDi8JS3UaSEtfVFXJ4ybWxnut8"
    ],
    "serviceEndpoint": "https://api.portal.streetcred.id/agent/oEc16OI82IF5wm4nMr66Xs9P5c40x6S3"
  }
}
```

As you can see, this is a credential offer that contains the information you entered while registering. Note here that the `@type` fields are version 1.0 types, for example: `did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/1.0/offer-credential`. This means that Trinsic.id uses the version 1.0 protocols.

Usually, a credential would be offered using an existing connection. You don't have a connection yet, so in this case a `~service` block is attached to the offer. The `~service` block contains information for your wallet app to know where it can connect to.

You receive your QR-code on your email address. If you are able to scan the QR-code, you must have access to that email address. Therefore, this is a way to verify your email address.

The `offers~attach.data` field contains a base64 encoded field again. Decoding that gives you:

```json
{
  "schema_id": "3pRGFwNi74rhnpGF4Qw7Nn:2:Trinsic Login:1.1",
  "cred_def_id": "3pRGFwNi74rhnpGF4Qw7Nn:3:CL:54564:default",
  "key_correctness_proof": {
    "c": "...",
    "xz_cap": "...",
    "xr_cap": [
      [
        "email",
        "..."
      ],
      [
        "master_secret",
        "..."
      ],
      [
        "fullname",
        "..."
      ],
      [
        "accountid",
        "..."
      ]
    ]
  },
  "nonce": "..."
}
```

This is the actual credential offer. It contains references to the schema and credential definition used to generate the offer.


{{% big-point number="3" title="Logging in" %}}

When you are logged out and want to log in, you need to scan a QR-code again. This QR-code contains a URL again:

https://trinsic.studio/url/0f7a77be-ebbc-4e50-...

When you follow the URL, you get redirected to a URL that looks like:

https://trinsic.studio/link/?d_m=eyJyZXF1Z...

Base64 decoding the `d_m` parameter gives you:

```json
{
  "request_presentations~attach": [
    {
      "@id": "libindy-request-presentation-0",
      "mime-type": "application/json",
      "data": {
        "base64": "eyJuYW1l..."
      }
    }
  ],
  "@id": "ac95c932-fc6d-4b06-8837-...",
  "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/present-proof/1.0/request-presentation",
  "~thread": {
    "thid": "ac95c932-fc6d-4b06-8837-...",
    "sender_order": 0,
    "received_orders": {}
  },
  "~service": {
    "recipientKeys": [
      "2Y4yagQw2Jdit6uTETpuVc9YTyPKnjyHuwzdbKZYABDi"
    ],
    "routingKeys": [
      "D41hyNHYtdyCSuMvERwDi8JS3UaSEtfVFXJ4ybWxnut8"
    ],
    "serviceEndpoint": "https://api.portal.streetcred.id/agent/oEc16OI82IF5wm4nMr66Xs9P5c40x6S3"
  }
}
```

It is a presentation request! Let's take a look at the `request_presentations~attach.data` field and decode it:

```json
{
  "name": "Trinsic Login",
  "version": "1.1",
  "nonce": "66051878861...",
  "requested_attributes": {
    "Valid Login Credential": {
      "names": [
        "Full Name",
        "Account ID",
        "Email"
      ],
      "restrictions": [
        {
          "schema_id": "3pRGFwNi74rhnpGF4Qw7Nn:2:Trinsic Login:1.1",
          "cred_def_id": "3pRGFwNi74rhnpGF4Qw7Nn:3:CL:54564:default"
        }
      ]
    }
  },
  "requested_predicates": {},
  "non_revoked": {
    "from": 0,
    "to": 1612759919
  }
}
```

Trinsic.id has sent you a request to prove that you own a Login credential which has been issued by them to you email address. Your wallet will look for a credential which has been made with their schema and their credential definition and a construct a proof with it.

When Trinisic.id verifier the proof, you will be logged in to your account on the website.

## Implementing with ACA-py V1 protocols

When you want to recreate this flow with ACA-py, you have to take a couple of hurdles. 

As noted before, Trinsic.id uses the version 1.0 protocols as defined in Aries [RFC0160](https://github.com/hyperledger/aries-rfcs/blob/master/features/0160-connection-protocol/README.md), [RFC0023](https://github.com/hyperledger/aries-rfcs/blob/master/features/0023-did-exchange/README.md) and [RFC0037](https://github.com/hyperledger/aries-rfcs/tree/master/features/0037-present-proof). The V2 protocols are defined in [RFC0434](https://github.com/hyperledger/aries-rfcs/tree/master/features/0434-outofband), [RFC0453](https://github.com/hyperledger/aries-rfcs/tree/master/features/0453-issue-credential-v2) and [RFC0454](https://github.com/hyperledger/aries-rfcs/tree/master/features/0454-present-proof-v2). ACA-py has implemented the first two and is working on the last one.

### V1 Connection-less credential offer

Unfortunately, ACA-py does not expose an API to create a connection-less credential (the QR-code in your email). In the issue credential V1 endpoints there is function called [`credential_exchange_create_free_offer`](https://github.com/hyperledger/aries-cloudagent-python/blob/0b4834fcbf06494475b221139b668d9bf352d60a/aries_cloudagent/protocols/issue_credential/v1_0/routes.py#L650) which will add a `oob_url` to a credential offer. However, this endpoint is not exposed via any Admin endpoint, so there is no way of getting to it.

Issue credential V1 contains [a similar function](https://github.com/hyperledger/aries-cloudagent-python/blob/1d0cf3c3210595e21dab2558426c8329731134f2/aries_cloudagent/protocols/issue_credential/v2_0/routes.py#L710) which is also not exposed via an endpoint.

However, we can create the offer ourselves.

Let's start with creating a schema:

```shell
$ curl -X POST http://localhost:11000/schemas \
  -H 'Content-Type: application/json' \
  -d '{
    "attributes": [
      "name",
      "age"
    ],
    "schema_name": "my-schema",
    "schema_version": "1.0"
}'
> {
  "schema_id": "M6HJ1MQHKr98nuxobuzJJg:2:my-schema:1.0",
  "schema": {
    "ver": "1.0",
    "id": "M6HJ1MQHKr98nuxobuzJJg:2:my-schema:1.0",
    "name": "my-schema",
    "version": "1.0",
    "attrNames": [
      "name",
      "age"
    ],
    "seqNo": 1006
  }
}
```

Then lets create a credential definition:

```shell
$ curl -X POST http://localhost:11000/credential-definitions \
  -H 'Content-Type: application/json' \
  -d '{
    "schema_id": "M6HJ1MQHKr98nuxobuzJJg:2:my-schema:1.0",
    "tag": "default"
  }'
> {"credential_definition_id": "M6HJ1MQHKr98nuxobuzJJg:3:CL:1006:default"}
```

Now we need to create a credential exchange record using `/issue-credential/create`. I know the description in the Swagger docs says

> Send holder a credential, automating entire flow

but that is a lie. It is a copy-paste mistake from the `/issue-credential/send` endpoint :)

```shell
$ curl -X POST http://localhost:11000/issue-credential/create \
  -H 'Content-Type: application/json' \
  -d '{
  "comment": "string",
  "cred_def_id": "M6HJ1MQHKr98nuxobuzJJg:3:CL:1006:default",
    "credential_proposal": {
    "@type": "issue-credential/1.0/credential-preview",
    "attributes": [
      {
        "mime-type": "text/plain",
        "name": "name",
        "value": "Bob"
      },
      {
        "mime-type": "text/plain",
        "name": "age",
        "value": "30"
      },
    ]
  },
}'
> <Credential Exchange Record>
```

Second, create a new connection invitation using `/connections/create-invitation`.

```shell
$ curl -X POST "http://localhost:4457/connections/create-invitation" \
  -H "Content-Type: application/json" -d "{}"
> {
  "connection_id": "4337bb1b-9ce5-4838-a309-bb8fec156053",
  "invitation": {
    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/connections/1.0/invitation",
    "@id": "e9cfd37c-cd4f-4a50-bd89-c4cb1765a04a",
    "label": "Alice",
    "recipientKeys": [
      "x8joUnHj7zAtzJZQkzqrbHGvqprmfa9q7cJwG97nCTV"
    ],
    "serviceEndpoint": "http://localhost:11000/"
  },
  "invitation_url": "http://localhost:11000/?c_i=eyJAdHlwZSI6ICJkaWQ6c292OkJ6Q2JzTlloTXJqSGlxWkRUVUFTSGc7c3BlYy9jb25uZWN0aW9ucy8xLjAvaW52aXRhdGlvbiIsICJAaWQiOiAiZTljZmQzN2MtY2Q0Zi00YTUwLWJkODktYzRjYjE3NjVhMDRhIiwgImxhYmVsIjogIkFsaWNlIiwgInJlY2lwaWVudEtleXMiOiBbIng4am9VbkhqN3pBdHpKWlFrenFyYkhHdnFwcm1mYTlxN2NKd0c5N25DVFYiXSwgInNlcnZpY2VFbmRwb2ludCI6ICJodHRwOi8vbG9jYWxob3N0OjQ0NTYvIn0="
}
```

To construct the connection-less credential, you should create this structure:

```json
{
  "@type": "...",
  "comment": "...",
  "credential_preview": {
    ...
  },
  "offers~attach": [
    ...
  ],
  "~service": {
    "recipientKeys": [...],
    "routingKeys": [...],
    "serviceEndpoint": "...",
  }
}
```

From the credential exchange record copy
- `credential_offer_dict.type` to the `@type` field
- `credential_offer_dict.credential_preview` to the `credential_preview` field
- `credential_offer_dict.offers~attach` to the `offers~attach` field

From the connection invitation copy
- `invitation.recipientKeys` to `~service.recipientKeys`
- `invitation.routingKeys` to `~service.routingKeys`
- `invitation.serviceEndpoint` to `~service.serviceEndpoint`

Great, now we have a connection-less credential. How do we get it to our users?

### QR-codes and links

As explored before, you can make a QR-code from the connection-less credential and try to scan it with the wallet app. Unfortunately there is a limit to the amount of data that can be encoded in a QR-code, and a basic connection-less credential goes over that limit. This is why Trinsic.id is not creating a QR-code directly from the credential.

Instead, the credential should be stored in a database and be accessible via a randomly generated identifier. This is what a URL like `https://trinsic.studio/url/dc50d919-0e20-41f6-b015-...` represents. When the Trinsic.id wallet scans the QR-code, it follows the URL. The URL gets redirected to URL in the form of
`https://trinsic.studio/link/?d_m=eyJyZXF1Z...` where the `d_m` parameter is the base64 encoded version of the connection-less credential that is stored in the database.

The Trinsic.id wallet reads the URL and looks for the `d_m` query parameter. It base64 decodes the parameter and adds the credential to the wallet.

### Using a connection-less credential with ACA-py

Unfortunately, there is no endpoint to receive a connection-less credential with ACA-py. This means that, in order to test if your credential works, you need to deploy your ACA-py instance to a publicly available location where the Trinsic.id wallet app can connect with your ACA-py instance that created the credential. If you do this, don't forget to switch your Trinsic.id wallet network to the ledger that you used when issuing the credential. This means that you need to have your ACA-py set up to run against the publicly available development ledgers that are supported by the Trinsic.id wallet.

### A connection-less proof request

Similarly, a connection-less proof request can be constructed.

First, create a proof request:

```shell
$ curl -X POST "http://localhost:4457/present-proof/create-request" \
 -H "Content-Type: application/json" -d '{
  "comment": "Prove this",
  "proof_request": {
    "name": "Proof request",
    "non_revoked": {
      "to": 1615274037
    },
    "nonce": "1234567890",
    "requested_attributes": {
      "0_name_uuid": {
        "name": "name",
        "non_revoked": {
          "to": 1615274037
        },
        "restrictions": [
          {
            "cred_def_id": "H1TRVrvDwKTBtu4YLdDVMe:3:CL:1089:tag"
          }
        ]
      },
      "0_age_uuid": {
        "name": "age",
        "non_revoked": {
          "to": 1615274037
        },
        "restrictions": [
          {
            "cred_def_id": "H1TRVrvDwKTBtu4YLdDVMe:3:CL:1089:tag"
          }
        ]
      }
    },
    "requested_predicates": {}
  },
  "version": "1.0",
  "trace": false
}'
> <Proof Request Record>
```

For the connection-less proof request, create a structure like:

```json
{
  "request_presentations~attach": [...],
  "@id": "ac95c932-fc6d-4b06-8837-...",
  "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/present-proof/1.0/request-presentation",
  "~service": {
    "recipientKeys": [...],
    "routingKeys": [...],
    "serviceEndpoint": "..."
  }
}
```

The `~service` properties can be copied in the same way as we did for the connection-less credential. The `request_presentations~attach` field should be filled with the `presentation_request` field from the Proof Request Record.

Again, there is no endpoint for receiving a connection-less presentation proof.

## Implementing with ACA-py V2 protocols

What it means for the issuing of credentials or presenting a proof without connection, is that this communication is out-of-band. Meaning there is no prior connection between the issuer and holder or holder and verifier. With the introduction of the next iteration of protocols including [RFC0434](https://github.com/hyperledger/aries-rfcs/tree/master/features/0434-outofband) came to life. It describes the Out-of-Band communication of invitations as well as issuing credentials and presenting proof.

Creating an Out-of-Band credential-offer or presentation-request should become a lot easier than it was in V1. However, receiving a credential offer is not yet supported in the Out-of-Band endpoint, and wallet apps do not support the new protocols yet.

## Conclusion

It looks like implementing connection-less credentials and proofs are a bit messy to implement using the V1. Testing them with a wallet app is even more of a challenge due to the required infrastructure.

You can expect a follow-up post whenever Out-of-Band implements full support.
