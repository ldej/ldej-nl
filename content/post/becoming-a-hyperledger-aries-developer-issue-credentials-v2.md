---
title: "Becoming a Hyperledger Aries Developer: Issue Credentials V2"
date: 2021-02-24T10:22:06+05:30
draft: false
summary: A follow up of part 5 which explains the new v2 endpoints and gives examples using curl.
image: images/roadtrip3.webp
tags:
- Decentralization
- Self-Sovereign Identities
- Hyperledger Aries
- aries-cloudagent-python
- ACA-py
---

This post is a follow up of [part 5]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-5-issue-credentials" >}}), where I explain how to create a schema, a credential definition and issue a credential using ACA-py. In the meantime ACA-py v0.6.0 is about to be released which features new endpoints for issuing credentials according to [Aries RFC0453](https://github.com/hyperledger/aries-rfcs/tree/master/features/0453-issue-credential-v2). Let's take a look at the new endpoints and create clearer examples than in part 5.

## Creating a schema and credential definition

The schema and credential definition parts have not changed since the last blog post, so I recommend reading the post to get some more details. However, let's add some examples for using the endpoints here.

Creating a schema is straight-forward by posting to the `/schemas` endpoint:

{{< filename "issuer" >}}
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

You can retrieve the schema using the `/schemas/{id}` endpoint. The `id` can be either the `schema_id` or the `seqNo` values that the `POST` to `/schemas` returned:

{{< filename "issuer" >}}
```shell
$ curl http://localhost:11000/schemas/M6HJ1MQHKr98nuxobuzJJg:2:my-schema:1.0
> {
  "schema": {
    "ver": "1.0",
    "id": "M6HJ1MQHKr98nuxobuzJJg:2:my-schema:1.0",
    "name": "my-schema",
    "version": "1.0",
    "attrNames": [
      "age",
      "name"
    ],
    "seqNo": 1006
  }
}
```

{{< filename "issuer" >}}
```shell
$ curl http://localhost:11000/schemas/1006    
> {
  "schema": {
    "ver": "1.0",
    "id": "M6HJ1MQHKr98nuxobuzJJg:2:my-schema:1.0",
    "name": "my-schema",
    "version": "1.0",
    "attrNames": [
      "age",
      "name"
    ],
    "seqNo": 1006
  }
}
```

The last call, based on the `seqNo` will come in useful later.

Now let's create a credential definition based upon the just created schema:

{{< filename "issuer" >}}
```shell
$ curl http://localhost:11000/credential-definitions \
  -H 'Content-Type: application/json' \
  -d '{
    "revocation_registry_size": 4,
    "schema_id": "M6HJ1MQHKr98nuxobuzJJg:2:my-schema:1.0",
    "support_revocation": true,
    "tag": "default"
  }'
> 400: tails_server_base_url not configured
```

As you can see, the request failed because I haven't configured a tails server base url. This tails server is required in case you want to support revocation. You can read more about revocation and the tails server in [part 6]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-6-revocation" >}}).

For now, let's ignore revocation and create a credential definition without it.

{{< filename "issuer" >}}
```shell
$ curl http://localhost:11000/credential-definitions \
  -H 'Content-Type: application/json' \
  -d '{
    "schema_id": "M6HJ1MQHKr98nuxobuzJJg:2:my-schema:1.0",
    "tag": "default"
  }'
> {"credential_definition_id": "M6HJ1MQHKr98nuxobuzJJg:3:CL:1006:default"}
```

You can retrieve the credential definition by using the `/credential-definitions/{id}` endpoint, where the `id` is the `credential_definition_id` that the `POST` to `/credential-definitions` returned.

{{< filename "issuer" >}}
```shell
$ curl http://localhost:11000/credential-definitions/M6HJ1MQHKr98nuxobuzJJg:3:CL:1006:default
> {
  "credential_definition": {
    "ver": "1.0",
    "id": "M6HJ1MQHKr98nuxobuzJJg:3:CL:1006:default",
    "schemaId": "1006",
    "type": "CL",
    "tag": "default",
    "value": {
      <omitted>
    }
  }
```

The interesting thing to note here is that a credential definition contains a `schemaId` in the form of a `seqNo` that we saw before. This `schemaId` can be used the retrieve the schema using `/schemas/{id}` endpoint as shown before.

You can use other peoples schemas to create a credential definition as well. You can find schemas at [indyscan.io](https://indyscan.io/) for the Sovrin ledgers, or at [test.bcovrin.vonx.io](http://test.bcovrin.vonx.io/browse/domain?page=1&query=&txn_type=101), [dev.bcovrin.vonx.io](http://dev.bcovrin.vonx.io/browse/domain?page=1&query=&txn_type=101) and [prod.bcovrin.vonx.io](http://prod.bcovrin.vonx.io/browse/domain?page=1&query=&txn_type=101) for the BCovrin ledgers. Make sure your ACA-py is configured for the right ledger in case you want to use a schema from one of them. Check [connecting ACA-py to hosted ledgers]({{< relref "/post/connecting-acapy-to-development-ledgers.md" >}}) for more details.

With the credential definition set up, it's time to issue credentials.

## The Issue Credential dance

Just as with a [tango](https://en.wikipedia.org/wiki/Tango), there are two parties involved when issuing a credential. There is the issuer and the holder.

There are three flows for issuing credentials, based on which party (issuer, holder) initiates the dance and with what. When you, as a holder, start the dance, you start with sending a proposal to the issuer (step 1). The proposal contains what you would like to receive from the issuer. Based on that the issuer can send an offer to the holder. When the issuer starts the dance, it starts with sending an offer to the holder (step 2). The holder can also start by directly sending a request to the issuer, thereby skipping the proposal and offer steps.

The flow for issuing credentials is:

1. Holder sends a proposal to the issuer (issuer receives proposal)
2. Issuer sends an offer to the holder based on the proposal (holder receives offer)
3. Holder sends a request to the issuer (issuer receives request)
4. Issuer sends credential to holder (holder receives credentials)
5. Holder stores credential (holder sends acknowledge to issuer)
6. Issuer receives acknowledge

These steps are the same as in the first version of issuing credentials, the only difference is that the names of the states the holder or issuer are in [are different](https://github.com/hyperledger/aries-rfcs/tree/master/features/0453-issue-credential-v2#states).

## Issuing a credential

For the following examples to work for you, make sure you have two ACA-py instances running at the same time on different ports, and with different wallets. You can check out [connecting using DIDComm Exchange]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-3-connecting-using-didcomm-exchange" >}}) to see how to set up to instances and create a connection between them. In these examples I assume `localhost:11000` to be an issuer, and `localhost:11001` to be a holder.

{{% big-point number="1" title="The holder starts with sending a proposal" %}}

When the holder starts with sending a proposal, it can use the `/issue-credential-2.0/send-proposal` endpoint.

{{< filename "holder" >}}
```shell
$ curl -X POST http://localhost:11001/issue-credential-2.0/send-proposal \
 -H "Content-Type: application/json" -d '{
  "comment": "I want this",
  "connection_id": "6c5c55ae-a5c9-4a8f-b095-adc88846d8f3",
  "credential_preview": {
    "@type": "issue-credential/2.0/credential-preview",
    "attributes": [2.0/send
      {
        "mime-type": "plain/text",
        "name": "name", 
        "value": "Bob"
      },
      {
        "mime-type": "plain/text",
        "name": "age", 
        "value": "30"
      }
    ]
  },
  "filter": {
    "dif": {},
    "indy": {
      "cred_def_id": "WgWxqztrNooG92RXvxSTWv:3:CL:20:tag",
      "issuer_did": "WgWxqztrNooG92RXvxSTWv", 
      "schema_id": "WgWxqztrNooG92RXvxSTWv:2:schema_name:1.0",
      "schema_issuer_did": "WgWxqztrNooG92RXvxSTWv",
      "schema_name": "preferences", 
      "schema_version": "1.0"
    }
  }
}'
```

The holder can specify any (or none) of the fields in `filter` to let the issuer know what he is looking for. The fields in `filter.indy` are not required, but the `filter.dif` and `filter.indy` objects are required, so you can leave them empty.

The `connection_id` is different for the issuer and the holder, so please make sure you use the `connection_id` that the holder uses to identify the issuer.

The smallest proposal I could send is:

{{< filename "holder" >}}
```shell
$ curl -X POST http://localhost:11001/issue-credential-2.0/send-proposal \
 -H "Content-Type: application/json" -d '{
  "comment": "I want this",
  "connection_id": "6c5c55ae-a5c9-4a8f-b095-adc88846d8f3",
  "credential_preview": {
    "@type": "issue-credential/2.0/credential-preview",
    "attributes": [
      {
        "name": "name", 
        "value": "Bob"
      },
      {
        "name": "age", 
        "value": "30"
      }
    ]
  },
  "filter": {
    "dif": {},
    "indy": {}
  }
}'
> {
  "role": "holder",
  "auto_offer": false,
  "auto_issue": false,
  "auto_remove": true,
  "cred_preview": {
    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/2.0/credential-preview",
    "attributes": [
      {
        "name": "name",
        "value": "Bob"
      }
    ]
  },
  "cred_ex_id": "0ea86878-4369-41e8-8212-e4af42304f3d",
  "conn_id": "6c5c55ae-a5c9-4a8f-b095-adc88846d8f3",
  "state": "proposal-sent",
  "updated_at": "2021-02-24 06:13:35.921424Z",
  "created_at": "2021-02-24 06:13:35.921424Z",
  "initiator": "self",
  "cred_proposal": {
    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/2.0/propose-credential",
    "@id": "d263c3a9-95b7-42ce-bfce-58d10b256809",
    "comment": "I want this",
    "filters~attach": [
      {
        "@id": "0",
        "mime-type": "application/json",
        "data": {
          "base64": "e30="
        }
      },
      {
        "@id": "1",
        "mime-type": "application/json",
        "data": {
          "base64": "e30="
        }
      }
    ],
    "credential_preview": {
      "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/2.0/credential-preview",
      "attributes": [
        {
          "name": "name",
          "value": "Bob"
        }
      ]
    },
    "formats": [
      {
        "attach_id": "0",
        "format": "dif/credential-manifest@v1.0"
      },
      {
        "attach_id": "1",
        "format": "hlindy-zkp-v1.0"
      }
    ]
  },
  "thread_id": "d263c3a9-95b7-42ce-bfce-58d10b256809"
}
```

The result you get back is a Credential Exchange Record. It is a record that contains the state of the credential dance. These records are stored in ACA-py and can be retrieved using the `/issue-credentials-2.0/records/{id}` endpoint where the `id` is the `cred_ex_id` in the result.

The issuer receives the proposal and can respond with an offer using the `/issue-credential-2.0/records/{id}/send-offer` endpoint. Note here that the `id` that the issuer uses is different from the `cred_ex_id` that the holder got. Each ACA-py instance creates its own identifiers.

If the holder specified fields in `filter.indy`, the issuer will try to find a credential definition that matches those criteria and send an offer based on it. If no credential definition can be found, the issuer will be greeted with an error:

```text
Error: Issuer has no operable cred def for proposal spec 
{
  'cred_def_id': 'WgWxqztrNooG92RXvxSTWv:3:CL:20:tag',
  'issuer_did': 'WgWxqztrNooG92RXvxSTWv',
  'schema_id': 'WgWxqztrNooG92RXvxSTWv:2:schema_name:1.0',
  'schema_issuer_did': 'WgWxqztrNooG92RXvxSTWv',
  'schema_name': 'preferences',
  'schema_version': '1.0'
}.
```

In that case, the holder will receive a problem report which can only be retrieved as a [webhook]({{< relref "/post/aries-cloudagent-python-webhooks.md" >}}).

It could also be that the issuer does have a matching credential definition, but that the attributes do not match the requested attributes. In that case the error will be:

```text
Error: Preview attributes {'name'} mismatch corresponding schema attributes {'age', 'name'}.
```

In case the issuer does have a suitable credential definition, the request and response will look like:

{{< filename "issuer" >}}
```shell
$ curl -X POST http://localhost:11000/issue-credential-2.0/records/c4cfe54b-db4b-43d5-94ca-2d2d629bc72b/send-offer
> {
  "role": "issuer",
  "conn_id": "a8cd3520-0cd7-49a7-b31c-568618e668e7",
  "cred_preview": { ...
```

The result is again the updated Credential Exchange Record.

After the offer has been received by the holder, the holder can send a request for a credential.

{{< filename "holder" >}}
```shell
$ curl -X POST http://localhost:11001/issue-credential-2.0/records/bac31f8c-660d-4ac4-b9a1-4ed7de47746a/send-request
> { <Credential Exchange Record> }
```

Then the issuer can issue the credential.

{{< filename "issuer" >}}
```shell
$ curl -X POST http://localhost:11000/issue-credential-2.0/records/c4cfe54b-db4b-43d5-94ca-2d2d629bc72b/issue \
  -H "Content-Type: application/json" -d '{"comment": "Please have this"}'
> { <Credential Exchange Record> }
```

And finally the holder can store the received credential.

{{< filename "holder" >}}
```shell
$ curl -X POST http://localhost:11001/issue-credential-2.0/records/bac31f8c-660d-4ac4-b9a1-4ed7de47746a/store \
  -H "Content-Type: application/json" -d '{}'
> { <Credential Exchange Record> }
```

The holder can retrieve the stored credential by using:

{{< filename "holder" >}}
```shell
$ curl -X GET "http://localhost:11001/credentials"
> {
  "results": [
    {
      "referent": "5b4804f8-68ef-44b3-81aa-04f926a9d949",
      "attrs": {
        "age": "30",
        "name": "Bob"
      },
      "schema_id": "VWurumK1quXfsWU527ZW5f:2:Hi:1.0",
      "cred_def_id": "VWurumK1quXfsWU527ZW5f:3:CL:1013:tag",
      "rev_reg_id": null,
      "cred_rev_id": null
    }
  ]
}
```

If you made it this far: congratulations! Please take a break and don't forget to hydrate.

{{% big-point number="2" title="The issuer starts with sending an offer" %}}

This flow is very similar, but instead starts with the issuer offering a credential to the holder.

{{< filename "issuer" >}}
```shell
$ curl -X POST http://localhost:11000/issue-credential-2.0/send-offer \
  -H "Content-Type: application/json" -d '{
  "comment": "I can send you this credential",
  "connection_id": "a8cd3520-0cd7-49a7-b31c-568618e668e7", 
  "credential_preview": {
    "@type": "issue-credential/2.0/credential-preview", 
    "attributes": [
    {
      "name": "name", 
      "value": "Bob"
    },{
      "name": "age",
      "value": "30"
    }]
  },
  "filter": {
    "dif": {}, 
    "indy": {}
  }
}'
> { <Credential Exchange Record> }
```

After this offer, the flow continues with the holder responding with a request.

{{% big-point number="3" title="The holder starts with sending a request for a credential" %}}

This flow is described in [Aries RFC0453](https://github.com/hyperledger/aries-rfcs/tree/master/features/0453-issue-credential-v2#choreography-diagram), but there is no endpoint for a holder to start with sending a request independent of a Credential Exchange Record in ACA-py.

## Automating the issue credential flow

There is one last endpoint that we haven't discussed, which is `/issue-credential-2.0/send`. Which is the same as `/issue-credential-2.0/send-offer` from the issuer viewpoint, but which sets the flag `auto_offer` and `auto_issue` to true. If the holder automatically accepts offers and turns them into requests, then this would completely automate the issuing of credentials.

## Development and debugging

For development purposes you can automate a large part of the flow. To make debugging easier, you can provide `--debug-credentials` to ACA-py which will log information in the console.

The flow of issuing credentials can be automated using:
- `--auto-respond-credential-proposal`
- `--auto-respond-credential-offer`
- `--auto-respond-credential-request`
- `--auto-store-credential`

If you have read this blog post so far, then these command line options should speak for themselves. Of course these are for development and debugging, so never enable these for production usage.

When you create a credential proposal or a credential offer, the credential exchange record will be automatically removed after the issuing of the credential has completed. The automatic removal can be disabled by providing `--preserve-exchange-records` to ACA-py.

## Connection-less issuing of credentials

There is one last item to discuss, which is the issuing of credentials without having a prior connection. You can imagine scanning a QR-code somewhere that will automatically add a credential to your wallet.

This functionality is not available yet, but a start of the implementation can be found in ACA-py already. 

## Conclusion

The issuing of credentials with the v2.0 endpoints is straight-forward and doesn't require too many intricate details.

If this blog post helped you, or if you have any questions, please feel free to reach out to me.
