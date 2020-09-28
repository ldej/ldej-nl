---
title: "Becoming an Aries Developer - Part 5: Issue Credentials"
date: 2020-09-21T12:18:23+05:30
draft: false
summary: Issuing a credential from an issuer to a holder using `go-acapy-client`
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

In [part 1]({{< relref "/post/becoming-aries-developer-part-1-terminology.md" >}}) I gave an introduction to the terms used in the Self-Sovereign Identity space. In [part 2]({{< relref "/post/becoming-aries-developer-part-2-development-environment.md" >}}) I explained the tools and command-line arguments for the development environment. In [part 3]({{< relref "/post/becoming-aries-developer-part-3-connecting-using-swagger" >}}) I set up two agents, and they connect using the invite and request/response protocol. In [part 4]({{< relref "/post/becoming-aries-developer-part-4-connecting-using-go-acapy-client" >}}) I introduced the `go-acapy-client` library that allows you to interact with ACA-py from Go. With the established connection between agents you can issue a credential, which is what I'm going to do in this part.

In self-sovereign identities, credentials are what allow you to hold verified truths. The government can issue your social security number, the driving institute can issue your drivers licence, the university can issue your degree. These credentials are cryptographically signed by the issuer and you, the holder, can prove that they are yours.

There are two main actors in the issuing of credentials: the issuer and the holder. An issuer is required to have a public DID (a DID registered in the blockchain) so that a verifier of a proof of a credential is able to look up the public key (via the DID) in order to validate the proof. The holder can have a private DID that is not registered on the blockchain. [Creating a public DID](https://sovrin.org/issue-credentials/) on the Sovrin ledger currently costs you $10.

After creating a public DID, an issuer needs to have two things before it can issue credentials. They are a schema definition and a credential definition, and both of [these are stored in the ledger](https://sovrin.org/wp-content/uploads/2018/10/What-Goes-On-The-Ledger.pdf):

> A schema definition is a machine-readable definition of a set of attribute data types and formats that can be used for the claims on a credential. For example, a schema for creating passport credentials would include definition of attributes such as given name, family name, date of birth, passport number, etc. A schema definition can be used by many credential issuers and is a way of achieving standardisation across issuers. 
>
> Once a schema definition has been written to the Sovrin ledger, it can now be used by a credential issuer (bank, passport office, university, employer, etc.) to create an issuer-specific credential definition that is also written to the Sovrin ledger. This data structure is an instance of the schema on which it is based, plus the attribute-specific public verification keys that are bound to the private signing keys of the individual issuer. This approach enables an issuer to re-use an existing schema, and enables a verifier who receives a proof containing data from the issuer to look up the issuer’s credential definition on Sovrin, obtain their verification key(s) and verify the origin and integrity of that data.

At the moment of writing, creating a schema on the Sovrin MainNet ledger costs $50, and creating a credential definition sets you back $25. With a credential definition, credentials can be issued for free. This means that issued credentials are not part of the ledger and should be kept safe by the holder.

As the quoted text explains, a schema can be used by many credential issuers. You can search for a schema using the VON-webserver, for example [http://localhost:9000/browse/domain?page=1&txn_type=101](http://localhost:9000/browse/domain?page=1&txn_type=101). I haven't found a way to query schemas directly from the VON-webserver or using ACA-py or libindy. For the Sovrin MainNet, StagingNet and BuilderNet you can use [indyscan.io](https://indyscan.io/) to browse the ledgers and search for schemas. More about moving from local development to using the Sovrin ledgers in a later blog post.

## Schema and credential definition

A schema can be created by POSTing to the `/schemas` endpoint of ACA-py. You can use `RegisterSchema` if you use `go-acapy-client`.

```go
schemaName := "My Schema"
schemaVersion := "1.0"
attributes := []string{"name", "email"}
schema, err := client.RegisterSchema(schemaName, schemaVersion, attributes)
```

You can search for your schemas like so:
```go
params := acapy.QuerySchemaParams{
    SchemaID: "",
    SchemaIssuerDID: "",
    SchemaName: "",
    SchemaVersion: "",
}
schemaIDs, err := client.QuerySchemas(params)
```

You can retrieve a schema from the ledger with its identifier:
```go
schemaID := "WgWxqztrNooG92RXvxSTWv:2:schema_name:1.0"
schema, err := client.GetSchema(schemaID)
```

Once you have a schema, you can create a credential definition.

```go
tag := "myTag"
supportRevocation := false
revocationRegistrySize := 0
schemaID := "WgWxqztrNooG92RXvxSTWv:2:schema_name:1.0"
credentialDefinitionID, err := client.CreateCredentialDefinition(tag, supportRevocation, revocationRegistrySize, schemaID)
```

To support revocation, a revocation registry needs to be created first, more on that in a later blog post.

## The issuing credentials dance

There are two flows for issuing credentials, based on which party (issuer, holder) initiates the dance. When you, as a holder of credentials, start the dance, you start with sending a proposal to the issuer. The proposal contains what you would like to receive from the issuer. Based on that the issuer can send an offer to the holder. When the issuer starts the dance, it starts with sending an offer to the holder.

The flow for issuing credentials is: 

1. Holder sends a proposal to the issuer (issuer receives proposal)
2. Issuer sends an offer to the holder based on the proposal (holder receives offer)
3. Holder sends a request to the issuer (issuer receives request)
4. Issuer sends credential to holder (holder receives credentials)  
    This step requires an active revocation registry if you enabled support for revocation  
    `400: Cred def id 6i7GFi2cDx524ZNfxmGWcp:3:CL:18:default has no active revocation registry.`
5. Holder stores credential (holder sends acknowledge to issuer)
6. Issuer receives acknowledge

These steps and the details of each of the messages going back and forth between the agents are described in [Aries RFC0036](https://github.com/hyperledger/aries-rfcs/tree/master/features/0036-issue-credential).

## Issuing a credential with `go-acapy-client`

To keep track of the dance, both parties are storing credential exchange records. These records hold information about the connection, the state and all possible steps and their data. A credential exchange records is represented in `go-acapy-client` by `acapy.CredentialExchange`.

Holder sends a proposal
```go
// Holder
credentialProposalRequest := CredentialProposalRequest{
    CredentialDefinitionID: "", 
    ConnectionID:           "",
    IssuerDID:              "",
    Comment:                "",
    CredentialPreview:      CredentialPreview{},
    SchemaName:             "",
    SchemaVersion:          "",
    SchemaID:               "",
    SchemaIssuerDID:        "",
    Trace:                  false,
    AutoRemove:             false,
}
credentialExchange, err := client.SendCredentialProposal(credentialProposalRequest)
```

The issuer receives the proposal and creates a credential exchange object to keep track of this credential exchange. The credential exchange records can be queried. A webhook will be triggered to notify the issuer when a proposal has been received.

```go
// Issuer
credentialExchange, err := client.SendCredentialOfferByID(credentialExchangeID)
```

Similarly, the holder will receive the offer, and a webhook will be triggered.

```go
// Holder
credentialExchange, err := client.SendCredentialRequestByID(credentialExchangeID)
```

The issuer responds with the credential when agreed. In Aries RFC0036 it is explained that for example a payment can be done before the actual credential is issued.

```go
// Issuer
credentialExchange, err := client.IssueCredentialByID(credentialExchangeID)
```

When the holder receives the credential, it can store the credential in the wallet. An optional `credentialID` can be provided, which will be the id by which the credential is stored in the wallet. When no credentialID is provided, a random unique identifier will be used to store it.

```go
// Holder
credentialExchange, err := client.StoreCredentialByID(credentialExchangeID, credentialID)
```

A credential can be retrieved from the wallet using:

```go
// Holder
credentials, err := client.GetCredentials(max, index, wql)
// or
credential, err := client.GetCredential(credentialID)
```

One thing to note here is that the retrieved credential using the `/credentials` and `/credential/{credential_id}` endpoints do not match the structure that is described in the Swagger documentation.

Example of a retrieved credential:

```json
{
  "referent": "my-credential-identifier",
  "attrs": {
    "name": "b",
    "email": "a"
  },
  "schema_id": "UpFt248WuA5djSFThNjBhq:2:my-schema:1.0",
  "cred_def_id": "UpFt248WuA5djSFThNjBhq:3:CL:107:my-schema",
  "rev_reg_id": null,
  "cred_rev_id": null
}
```

Expected structure:

```json
{
  "values": {
    "additionalProp1": {
      "raw": "Alex",
      "encoded": "412821674062189604125602903860586582569826459817431467861859655321"
    },
    "additionalProp2": {
      "raw": "Alex",
      "encoded": "412821674062189604125602903860586582569826459817431467861859655321"
    },
    "additionalProp3": {
      "raw": "Alex",
      "encoded": "412821674062189604125602903860586582569826459817431467861859655321"
    }
  },
  "rev_reg": {
    "accum": "21 136D54EA439FC26F03DB4b812 21 123DE9F624B86823A00D ..."
  },
  "signature_correctness_proof": {},
  "witness": {
    "omega": "21 129EA8716C921058BB91826FD 21 8F19B91313862FE916C0 ..."
  },
  "rev_reg_id": "WgWxqztrNooG92RXvxSTWv:4:WgWxqztrNooG92RXvxSTWv:3:CL:20:tag:CL_ACCUM:0",
  "schema_id": "WgWxqztrNooG92RXvxSTWv:2:schema_name:1.0",
  "signature": {},
  "cred_def_id": "WgWxqztrNooG92RXvxSTWv:3:CL:20:tag"
}
```

Maybe I will find out in a later stage why that is :smile:

## Development and debugging

For development purposes you can automate a large part of the flow. First of all, to make debugging easier, you can provide `--debug-credentials` to ACA-py. The flow of issuing credentials can be automated using:
- `--auto-respond-credential-proposal`
- `--auto-respond-credential-offer`
- `--auto-respond-credential-request`
- `--auto-store-credential`

If you have read this blog post so far, then these command line options should speak for themselves. Of course these are for development and debugging, so never enable these for production usage.

When you enable to automation of these steps, you can also use `SendCredential` to automate the flow:

```go
client.SendCredential(acapy.CredentialSendRequest{})
```

When you create a credential proposal or a credential offer, you can specify a flag called `AutoRemove`. This will automatically remove the credential exchange record after the exchange has completed. The automatic removal can also be disabled by providing `--preserve-exchange-records` to ACA-py.

## Conclusion

After having established a connection between agents, we are now able to issue credentials as well.

To see a working example of issuing credentials, check out [Issuing Credentials](https://github.com/ldej/go-acapy-client/tree/master/examples/issue_credential).

In the next part I will discuss credential revocation.