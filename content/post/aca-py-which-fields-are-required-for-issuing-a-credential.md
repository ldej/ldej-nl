---
title: "ACA-py: Which fields are required for issuing a credential?"
date: 2021-02-04T12:27:53+05:30
draft: false
summary: How I found out that you only need a connection id and credential attributes.
image: images/agra7.webp
tags:
- Decentralization
- Self-Sovereign Identities
- Hyperledger Aries
- aries-cloudagent-python
- ACA-py

---

I've been working on the aca-py library for a couple of months now, and I've created a couple of the examples to become familiar with the API endpoints and the general flow of issuing credentials. I recently started to build an actual ACA-py controller that will be issuing credentials. This made me take a good look at the client library I created and at the requirements for the endpoints of ACA-py.

## The body of `/issue-credential/send`

I looked at the method I had created to use the endpoint `/issue-credential/send`. The endpoint has a body with a number of fields, too many fields to fit comfortably as arguments in a function. Instead. I had created a `struct` you could pass in which contained all the fields.

The body example value shown in the OpenAPI docs is:
```json
{
  "auto_remove": true,
  "comment": "string",
  "connection_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "cred_def_id": "WgWxqztrNooG92RXvxSTWv:3:CL:20:tag",
  "credential_proposal": {
    "@type": "issue-credential/1.0/credential-preview",
    "attributes": [
      {
        "mime-type": "image/jpeg",
        "name": "favourite_drink",
        "value": "martini"
      }
    ]
  },
  "issuer_did": "WgWxqztrNooG92RXvxSTWv",
  "schema_id": "WgWxqztrNooG92RXvxSTWv:2:schema_name:1.0",
  "schema_issuer_did": "WgWxqztrNooG92RXvxSTWv",
  "schema_name": "preferences",
  "schema_version": "1.0",
  "trace": false
}
```

In my examples I started filling all the fields, and it seemed to work, great!

When I started working on creating an actual controller, I got a bit frustrated with all the fields that needed to be filled out. Why do you need a `schema_id` AND a `cred_def_id`? The credential definition is made from the schema. Maybe if I query the credential definition, I can also find the `schema_id`? The endpoint `/credential-definitions/{cred_def_id}` returns

```json
{
  "credential_definition": {
    "ver": "1.0",
    "id": "SH1nXsjoV1kAH8f52urkNr:3:CL:889:default",
    "schemaId": "889",
    "type": "CL",
    "tag": "default",
    "value": {}
  }
}
```

This has a `schemaId`, but that is not the format of a `schema_id` that I expected. On the Hyperledger Chat, Jiachuan Li (username `lijiachuan`) [asked how to find the schema based on the credential definition `schemaId`](https://chat.hyperledger.org/channel/aries-cloudagent-python?msg=mLoRdXzMyWSsxZ5Ry), and that gave some insightful answers.

The `schemaId` you see there is the sequence number of the transaction in which the schema got created. As `sklump` explained, the easiest way would be to query the ledger by transaction number, but unfortunately that is not available in ACA-py. A way to do it in ACA-py is by querying `/schemas/created` to retrieve the schema ids, and then iterate over them, get the details with `/schemas/{schema_id}` until you find the one where the `seqNo` matches with `schemaId` from the credential definition.

Update 19-02-2021: As mentioned in [this thread](https://chat.hyperledger.org/channel/aries-cloudagent-python?msg=PGtAJyhW3kicm9M8B):
> You can get the schema by transaction number with GET /schemas/{schema_id}; it will take a sequence number as the id here. [reference](https://github.com/hyperledger/aries-cloudagent-python/blob/db5330211d4d61ad2e71da1d6184700b9d954b76/aries_cloudagent/messaging/schemas/routes.py#L98)

This works, but is incredibly awkward. Actually, this only works in cases where your controller is the one who created the schema! It costs money to create a schema, therefore reuse of schemas is promoted. You **do not** need to own a schema to create a credential definition. You **do** need to own a credential definition to issue a credential.

So I have created a credential definition from somebody else's schema, will I not be able to retrieve the `schema_id`? Do I need to store `schema_id`s myself, so I can retrieve them later?

## Looking at the required fields

Instead of looking at the json example body, you can also check the `Model` of the request and response in OpenAPI. It turns out that from all the fields in the body, only `connection_id`, `credential_proposal.attributes.name` and `credential_proposal.attributes.value` are required. This means that the minimal body that gets accepted is:

```json
{
  "connection_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "credential_proposal": {
    "attributes": [
      {
        "name": "favourite_drink",
        "value": "martini"
      }
    ]
  }
}
```

There is no need for querying credential definitions and schemas at all!

But wait, how does ACA-py (or Indy) know which credential definition to use? The fields `cred_def_id`, `issuer_did`, `schema_id`, `schema_issuer_did`, `schema_name` and `schema_version` are only used to help ACA-py (or Indy), find a credential that matches the fields that are specified in proposal. It searches for all credential definitions and uses the provided fields (`cred_def_id`, `issuer_did`, etc..., but also the proposal attributes names!) as filters, then it selects the first credential definition that matches. In case multiple credential definitions are found, it seems to pick the newest one (the one with the highest sequence number).

When `lijiachuan` [asked in Hyperledger Chat](https://chat.hyperledger.org/channel/aries-cloudagent-python?msg=mLoRdXzMyWSsxZ5Ry):
> May I know where can I know what are the required properties I need to provide there?

`sklump` replied:
> It depends: you must specify enough for the issuer to identify exactly one cred def that matches.
> 
> Example:
> If the issuer has created multiple cred defs on the same schema id, a schema id becomes insufficient.
> 
> Example:
> If the issuer has issued exactly one cred def id throughout its life, the issuer DID alone will do.
>
> OK?
> We should tweak the documentation, but this level of understanding risks alienating the target audience for a README. I don't want to create a wall of text for 10% more precision.

If you are reading this, you are probably requiring the 10% more precision, and please send me an email in case this helped.

The easiest way to make sure you always use the right credential definition, is by specifying the credential definition ID.

## Where can I find other peoples schemas?

As I said before, in the production version of the Sovrin ledger it [costs money](https://sovrin.org/issue-credentials/) to register a schema. This is a way of limiting the creation and increasing the reuse of schemas. So where can you find them?

BCoverin ledgers have a browser for querying schemas: [test.bcovrin.vonx.io/browse/domain](http://test.bcovrin.vonx.io/browse/domain?page=1&query=&txn_type=101)

Sovrin ledgers have the Indyscan browser for querying schemas: [indyscan.io/txs/SOVRIN_BUILDERNET/domain](https://indyscan.io/txs/SOVRIN_BUILDERNET/domain?page=1&pageSize=50&filterTxNames=[%22SCHEMA%22]&sortFromRecent=true)

Here's an idea: create a website where you can easily search schemas created on production ledgers!

## Conclusion

It turned out to be way easier to issue a credential than I initially thought. I'll be adjusting the `go-acapy-client` to allow for optional parameters.