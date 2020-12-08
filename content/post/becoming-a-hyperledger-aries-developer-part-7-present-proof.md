---
title: "Becoming a Hyperledger Aries Developer - Part 7: Present Proof"
date: 2020-12-08T06:32:27+05:30
draft: false
summary: Creating a presentation request, a presentation proof and verifying the proof.
image: images/agra3.webp
tags:
- Decentralization
- Self-Sovereign Identities
- Hyperledger Aries
- aries-cloudagent-python
- ACA-py

#reddit:
#  created: 1594708583 
#  url: https://www.reddit.com/r/ldej/comments/hqwgj8/discuss_working_in_the_trenches/
#  title: "Working in the Trenches"
---

In [part 1]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-1-terminology.md" >}}) I gave an introduction to the terms used in the Self-Sovereign Identity space. In [part 2]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-2-development-environment.md" >}}) I explained the tools and command-line arguments for the development environment. In [part 3]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-3-connecting-using-swagger" >}}) I set up two agents, and they connect using the invite and request/response protocol. In [part 4]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-4-connecting-using-go-acapy-client" >}}) I introduced the `go-acapy-client` library that allows you to interact with ACA-py from Go. In [part 5]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-5-issue-credentials" >}}) credentials got issued over the established connection between the agents. In [part 6]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-6-revocation" >}}) I discussed revocation. In this part I am going to create a proof presentation of an issued credential and verify it.

## Context

You have received credentials, for example a driver's license, a passport or your degree. These credentials are not just useful to have, they are useful because your can prove that they are yours. The party that wants to verify your credentials can verify the signatures of the credentials are correct as well.

## The Present Proof dance

There are two parties involved: the prover and the verifier

1. Prover sends proposal (verifier receives proposal) (this step is optional)
2. Verifier sends request (prover receives request)
3. Prover sends presentation proof (verifier receives presentation proof)
4. Verifier verifies presentation proof
5. Verifier sends presentation proof acknowledgement (prover receives presentation proof acknowledgement)

You can read more about the protocol at [RFC0037](https://github.com/hyperledger/aries-rfcs/tree/master/features/0037-present-proof).

## Present Proof with `go-acapy-client`

Presenting proof is the most difficult part of Aries, at least in my opinion. There seem to be many possibilities, but the documentation for it is rather scarce.

In part 5 I explained how to issue credentials, and in part 6 I talked about revocation. For presenting proof to work out, you need to create credentials that have the option to be revoked. If the issuer has not set up a revocation registry when the credential definition got created, then the holder cannot send a presentation. When the holder tries to send a presentation, the following error will occur:

`400: Error when constructing proof: Error: Invalid structure. Caused by: Revocation Registry Id not found. CommonInvalidStructure.`

With that out of the way, let's take a look at step 2 in the dance, creating a 'request for presentation'.

### Presentation Proposal

```go
request := acapy.PresentationRequestRequest{
    ConnectionID: connectionID,
    Comment:      comment,
    ProofRequest: acapy.NewProofRequest(
        "Please prove to me that you have these",
        "1234567890",
        requestedPredicates,
        requestedAttributes,
        "1.0",
        acapy.NonRevoked{
            From: time.Now().Add(-time.Hour * 24 * 7).Unix(),
            To:   time.Now().Unix(),
        },
    ),
}
client.SendPresentationRequest(request)
```

Let's go over the fields. `ConnectionID` is the connection you want to request a presentation proof from. `Comment` is the text you can send with the request that can be displayed to the user.

The `ProofRequest` is constructed using a name ("Please prove to me that you have these"), a nonce ("1234567890"), the requested predicates, the requested attributes, a version number, and a time interval within which the attributes should be valid.

What the value of the nonce should be, or how to generate it, is not yet clear to me.

The requested attributes are constructed like:

```go
requestedAttributes := map[string]acapy.RequestedAttribute{
    "score": acapy.RequestedAttribute{
        Restrictions: []Restrictions{{ // Required in case of Names
            CredentialDefitionID: "some-cred-def-id"
        }},
        Name:  "score", // XOR with Names
        Names: ["score"], // XOR with Name
        NonRevoked: acapy.NonRevoked{
            From: time.Now().Add(-time.Hour * 24 * 7).Unix(),
            To:   time.Now().Unix(),
        },
    }
}
```

A couple of things to note here. **First**, you can either use `Name`, or `Names`, but not both. When you use `Names`, you are required to add `Restrictions`. The `Restrictions` can have a couple of values. So far I have found:

```json
[
    {
      "cred_def_id": "...",
      "issuer_did": "...",
      "schema_name": "...",
      "schema_id": "...",
      "schema_issuer_did": "...",
      "schema_version": "...",
      "attr::attr1::value": "my-value"
    }
]
```

The Swagger documentation describes:
```text
If present, credential must satisfy one of given restrictions: specify schema_id, schema_issuer_did, 
schema_name, schema_version, issuer_did, cred_def_id, and/or attr::<attribute-name>::value 
where <attribute-name> represents a credential attribute name
```

The `go-acapy-client` library supports all the keys except for the last one. The last key looks like [WQL](https://ldej.nl/post/becoming-a-hyperledger-aries-developer-part-5-issue-credentials#wql-some-query-language), but I have yet to confirm if that is enforced.

These restrictions are sent to the prover, who can find credentials that match the restrictions, and based on those send a proof. So far it doesn't look like the prover is checking these restrictions, it might be that the verifier will verify the restriction.

**Second**, the keys used in the `requestedAttributes`, can be chosen freely. These are the keys that the prover will use when he responds with a presentation.

**Third**, both the `acapy.ProofRequest` and the individual requested attributes have a `NonRevoked` field. When a proof presentation is created by the prover, it will check for each attribute if it is valid in the specified `NonRevoked` time interval. It will first check if the individual requested attribute has a `NonRevoked` field, if it has not, it will use the `ProofRequest.NonRevoked` value. If both don't have a `NonRevoked` specified, then no time interval is taken into account.

**Fourth**, if the `NonRevoked` time interval is before the revocation registry has been created, then the prover will face an error when constructing a proof:

```text
Error: Exception parsing rev reg delta response (interval ends before rev reg creation?): 
Error: Item not found on ledger. Caused by: 
Structure doesn't correspond to type. Most probably not found. Caused by: 
data did not match any variant of untagged enum Reply. LedgerNotFound.
```

That's about it for the requested attributes, now let's take a look at the **requested predicates**.

```go
requestedPredicates := map[string]acapy.RequestedPredicates{
    "age": acapy.RequestedPredicate{
        Restrictions: []Restrictions{{ // Required in case of Names
            CredentialDefitionID: "some-cred-def-id"
        }},
        Name:   "score", // XOR with Names
        Names:  ["score"], // XOR with Name
        PType:  acapy.PredicateLT,
        PValue: 18,
        NonRevoked: acapy.NonRevoked{
            From: time.Now().Add(-time.Hour * 24 * 7).Unix(),
            To:   time.Now().Unix(),
        },
    }
}
```

Again the same rules apply to using `Name` exclusive or with `Names`, and `Restrictions` being required when using `Names`. The same rules about `NonRevoked` overriding the `NonRevoked` of the presentation request itself.

There are two extra fields here, the `PType` and the `PValue`. They can be used for requesting attributes with rules for the value. For example, a predicate can define that the attribute 'age' should have a value greater than or equal to '18'. There are four predicate-types available:

```go
type PredicateType string

const (
	PredicateLT  PredicateType = "<"
	PredicateLTE PredicateType = "<="
	PredicateGT  PredicateType = ">"
	PredicateGTE PredicateType = ">="
)
```

### Constructing a Presentation Proof

After receiving a presentation request, a presentation proof can be constructed.

```go
proof := acapy.NewPresentationProof(
    requestedAttributes,
    requestedPredicates,
    selfAttestedAttributes,
)
client.SendPresentationByID(presentationExchangeID, proof)
```

The attributes that go into a presentation proof are directly linked to the presentation request. For example, if the presentation request has a restriction on the `CredentialDefinitionID`, then the prover needs to find a credential in its wallet that matches the `CredentialDefinitionID`.

```go
requestedAttributes := map[string]acapy.PresentationProofAttribute{}

credentials, _ := app.client.GetCredentials(10, 0, "")

for attrName, attr := range app.presentationExchange.PresentationRequest.RequestedAttributes {
    credentialDefinitionID := attr.Restrictions[0].CredentialDefinitionID

    var referent string
    for _, credential := range credentials {
        if credential.CredentialDefinitionID == credentialDefinitionID && credential.Attributes[attr.Names[0]] != "" {
            referent = credential.Referent
            break
        }
    }

    requestedAttributes[attrName] = acapy.PresentationProofAttribute{
        Revealed:     true,
        Timestamp:    time.Now().Unix(),
        CredentialID: referent,
    }
}
```

Matching credentials can also be retrieved by using the third parameter (`wql`) of `client.GetCredentials(10, 0, "")`. You can read more about WQL in [a previous blog post](https://ldej.nl/post/becoming-a-hyperledger-aries-developer-part-5-issue-credentials#wql-some-query-language).

The `Revealed` value needs to be `true` to reveal the value in the proof. When the attribute is not revealed, the following error will show up:

```text
2020-12-07 17:34:33,660 aries_cloudagent.indy.sdk.verifier 
ERROR Presentation on nonce=1023415730075370979973368 cannot be validated: 
missing essential components [Missing requested attribute group '0_name_uuid']
```

I haven't looked into the predicates and self-attested attributes yet, [Aries RFC0037](https://github.com/hyperledger/aries-rfcs/tree/master/features/0037-present-proof) describes a lot more detail that I haven't used yet. I'll take a look into that in a later stage.

### Verifying Presentation Proof

The verification of a presentation proof is relatively straight-forward:

```go
presentationExchange, err := app.client.VerifyPresentationByID(presentationExchangeID)
```

When the presentation is verified, an update will be sent to the prover that the presentation has been acknowledged.

## Development and debugging

There are a couple of parameters available to automate the steps in this process. They are `--auto-respond-presentation-proposal`, `--auto-respond-presentation-request` and `--auto-verify-presentation`. They automated the steps that I described. The parameter `--debug-presentations` can be used to print extra output for debugging the presentations.

## Connectionless present proof

These proofs require a connection to be established beforehand. But what if there is no connection yet? Let's say you are at a bar and need to prove that you are above the legal drinking age? In that case a connectionless proof presentation can be made.

To do that, first a request has to be created using: `client.CreatePresentationRequest(...)`. The resulting json should be base64 encoded and attached in a request at `request_presentation~attach[0].data.base64`. The `~service` object is required for the verifier to know how to contact the prover.


```json
{
    "@id": "3b67c4bf-3953-4ace-94ef-28e0969288c5",
    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/present-proof/1.0/request-presentation",
    "request_presentations~attach": [
        {
            "@id": "libindy-request-presentation-0",
            "mime-type": "application/json",
            "data": {
                "base64": "eyJuYW1lIjo..."
            }
        }
    ],
    "comment": null,
    "~service": {
        "recipientKeys": [
            "F2fFPEXABoPKt8mYjNAavBwbsmQKYqNTcv3HKqBgqpLw"
        ],
        "routingKeys": null,
        "serviceEndpoint": "https://my-url.test.org"
    }
}
```

This object needs to be transformed into a QR code which can be scanned by the verifier. One problem with that is that the base64 encoded proof can become quite large, and there is a limit to the amount of data that can be represented in a QR code. There are two solutions to this. 

The first option is, instead of creating a QR code that contains the data, a URL can be constructed with the connectionless proof data as a base64 encoded query parameter: 

```text
https://example.com/?data=eyd7f3k9adjj2HH88...
```

The second option is to store the data in a database and to make it accessible using a unique identifier. Accessing the URL would retrieve the data from the database and return it as json.

[Aries RFC0434](https://github.com/hyperledger/aries-rfcs/tree/master/features/0434-outofband#url-shortening) describes the process of using these out-of-band messages. It also raps about url shortening as described in the second option.

There is no functionality for connectionless proofs or other out-of-bound messages in `go-acapy-client` yet.

## Conclusion

Constructing a presentation proposal and a presentation proof is not the most straight-forward part of Aries. I have described a simple process with simple attributes and need to discover the other parts later on. Please shoot me a message in case you have any queries or tips.

This is going to be the last blog post in this series, however I will write about the other parts of presenting a proof, new features added to `go-acapy-client`, and an issuer and verifier that I'm creating using `go-acapy-client` in the future.