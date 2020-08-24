---
title: "Self-Sovereign Identities"
date: 2020-08-21T10:20:18+05:30
draft: false
summary: How Decentralized Identities are the fundamental building block of Self-Sovereign Identities
image: images/ladakh6.webp
tags:
- Decentralization
- Identities

#reddit:
#  created: 1594708583 
#  url: https://www.reddit.com/r/ldej/comments/hqwgj8/discuss_working_in_the_trenches/
#  title: "Working in the Trenches"
---

After writing about [Decentralized Identities]({{< relref "/post/decentralized-identity.md" >}}) I read more articles and watched a couple of videos that cleared up some details. The article [Where to begin?](https://medium.com/decentralized-identity/where-to-begin-b2a55b898b3) by the Decentralized Identity Foundation gave me these useful links. In particular the videos [Decentralized Identities (DIDs) - The Fundamental Building Block of Self Sovereign Identity](https://www.youtube.com/watch?v=Jcfy9wd5bZI) and [Decentralized Key Management (DKMS): An Essential Missing Piece of the SSI Puzzle](https://www.youtube.com/watch?v=NJxaYsAo6pI) by Drummond Reed where this blog post is based on.

## Three models of digital identity

The **first** model is the **Siloed or centralized identity** that all of us are familiar with. You have an account at an organization where you log in using your username and password. 

`You -account-> Org`

You "prove" that you are the owner of the account by entering your username and password. The website will check in their own database if these credentials are correct. This wasn't always a safe solution. Credentials would be sent in plain text over the web, allowing anybody in between you and the website to read your credentials. Standards like https://, SSL and TLS got introduced to encrypt communication, making it harder to steal them. However, if a website got hacked and account data got leaked to the web, the same credentials would be used to try to access other websites.

Two-factor authentication got introduced to secure accounts better. Instead of needing just a password, you would need to have access to the device of the victim as well. A one-time password is required which can be sent as text message to a phone or generated using an authenticator app.

The **second** model is the **third-party or federated identity provider**. We know them as the buttons that allow you to login with your Google, Facebook, Twitter or LinkedIn account. In this case the website where you log in does not store your password, instead they rely on the identity provider to verify that you are you. 

`You -account-> IDP -> Org`

Over the years a number of standards have been created to make integration with identity providers easier. These standards are SAML, OAuth2 and OpenID Connect. With these standards it is also possible for websites to request information from your account from the identity providers. As far as I know this information is usually limited to your name and email address.


## Self-Sovereign Identity (SSI)

The **third** model is the newest one in the family and is called **Self-Sovereign Identity (SSI)** and it is completely different from the other two. Instead of having to rely on a website to issue, verify and protect your credentials, it is managed by a decentralized system made on four open standards.

With SSI, you create your own credentials and a reference to these credentials is stored in a blockchain or a distributed network.

```
        You <- -> Peer
        |           |
        V           V
Distributed Ledger (Blockchain)
```

These credentials will be used to create a _connection_ with every other peer you connect with. A peer can be anything, a company, a person, an application, a device. This connection will be secured by your credentials which consist of public-private key pairs. You will store your keys in a digital wallet.

These keys are your credentials. Credentials can be issued by yourself or can be issued by any other peer. For example the passport office, the drivers license office, your employer, your coffee company. You can create a credential which can be verified with a public key. This public key is stored in the ledger. The **first** standard is for storing the public key in the ledger is [DID](https://www.w3.org/TR/did-core/)(Decentralized Identifier).

The **second** standard is called DKMS (Decentralized Key Management System). This standard will make sure your keys or wallet are not locked into a specific vendor. You can have different wallets on different devices that can all interoperate.

The **third** standard is called DID Auth. This standard covers how you can actually authenticate over a connection.

The **fourth** standard is Verifiable Credentials. This standard covers how you can have interoperable credentials over different wallets.

| Standard                                   | Organizations |
| ------------------------------------------ | ------------- |
| Verifiable Credentials                     | [W3C](https://www.w3.org/TR/did-core/) |
| DID Auth                                   | [DIF](https://identity.foundation/) [IETF](https://www.ietf.org/)      |
| DKMS (Decentralized Key Management System) | [OASIS](https://www.oasis-open.org/)         |
| DID (Decentralized Identifier)             | [W3C](https://www.w3.org/TR/did-core/)           |

Let's dive into more of the details of DIDs.

## What is a DID?

A decentralized identifier is an identifier based on the URN (uniform resource name) schema. A example of a DID is:

`did:sov:3k9dg356sdcj5gf2k9bw8kfg7a`

They are a bit longer than your usual social security number, username or Twitter handle and they are not human-friendly as it is hard to remember. But the great thing about them is that you can prove that you own and control that. That is because it is the address of a public key on a ledger. And you have the private key.

You are not going to remember these addresses. Instead, you are going to use an address book, the same way you don't remember peoples phone numbers. You will have thousands of DIDs. Every connection with every peer will have a different DID. The keys for a connection will only be used for a connection with one person, organization or entity.

There is no central registration authority. You register DIDs directly on a public or private blockchain or distributed network.

A DID is:
1. A permanent (persistent) identifier - it never needs to change
2. A resolvable identifier - you can look it up to get metadata
3. A cryptographically-verifiable identifier - you can prove ownership using cryptography
4. A decentralized identifier - no central registration authority is required

There has never been an identifier in history that has all those four points.

What fundamentally enables this is blockchain technology. DIDs are available for several blockchains, some of them were pre-existing, others were created specifically for the purpose of Self-Sovereign Identities like [Sovrin](https://sovrin.org/).

## What does a DID look like?

We saw a did already in the previous section. A DID consists of three parts. The scheme, which is `did`, the method specification, in this case `sov` and the method-specific identifier.

```text
did:sov:3k9dg356sdcj5gf2k9bw8kfg7a
 |   |              |
 |   |   Method-Specific Identifier
 |  Method Spec
Scheme
```

The method specification, also called method spec, is there so DIDs can work with different blockchains or distributed systems. The `sov` spec in this example refers to the [Sovrin](https://sovrin.org/) network. A method spec tells how to interpret the method-specific identifier that comes after it. 

## What is a DID method spec?

A method spec defines how to read and write a DID on a specific blockchain or distributed network. Each network can have its own specification. There is a [big list of DIDs](https://w3c.github.io/did-spec-registries/#did-methods) available already.

Each of these specs describes what the method-specific identifier is and how it can be constructed. In some cases they are hashes of public keys, and in other cases, for example the [Github DID Method Spec](https://docs.github-did.com/did-method-spec/) the identifier is the same as your username on the websites.

A spec also describes how you can Create, Read, Update and Delete DIDs and their documents.

New specs can be registered via using [these guidelines](https://w3c.github.io/did-spec-registries/).

## What is a DID document?

Blockchains and distributed systems can be seen as global key value stores. The key is the DID and the value is a DID document. So a DID allows you to lookup a document in a blockchain or distributed system. The DID document is a JSON-LD document describing the entity identified by the DID.

The standard elements of a DID document:
1. DID (for self-description)
2. Set of public keys (for verification)
3. Set of auth methods (for authentication)
4. Set of service endpoints (for interaction)
5. Timestamp (for audit history)
6. Signature (for integrity)

If you want to authenticate right now, you tell a website: this is my username. The website will ask you for a password and then it can verify that with the data in its own database. With DIDs you can tell a website: this is my DID. The website can look up your public key and ask you to sign a challenge with your private key. The website can then verify the signature with the public key.

An example DID document:
```json
{
  "@context": "https://www.w3.org/ns/did/v1",
  "id": "did:example:123456789abcdefghi",
  "authentication": [{
    "id": "did:example:123456789abcdefghi#keys-1",
    "type": "Ed25519VerificationKey2018",
    "controller": "did:example:123456789abcdefghi",
    "publicKeyBase58": "H3C2AVvLMv6gmMNam3uVAjZpfkcJCwDwnZn6z3wXmqPV"
  }],
  "service": [{
    "id":"did:example:123456789abcdefghi#vcs",
    "type": "VerifiableCredentialService",
    "serviceEndpoint": "https://example.com/vc/"
  }]
}
```

The document itself does not have to be stored on the ledger itself. You can store a pointer to the document on the ledger and store the document in another network.

## DIDs and Decentralized Identity

We've looked at DIDs and how they are linked to DID documents. What does the stack look like that are used for decentralized identities?

The layer an identity owner is going to interact with is the Edge layer. This can be a wallet in the form of an app on your phone. The app on your phone will connect to the Cloud layer. The communication can happen using the traditional client-server model, but decentralized networks are possible as well. The Cloud layer consists of entities that know how to resolve DIDs to documents. These entities can communicate to each other in a similar fashion as mail servers communicate. The last layer is the DID layer, which is a blockchain or distributed system where the DID documents can be found. 

- Edge Layer (user side clients)
- Cloud Layer (like mail servers)
- DID Layer (blockchain)

Let's say one user wants to make a connection with another user. The edge wallet of the user (at the edge layer) can ask the cloud layer to look up a DID. The DID document can specify another entity in the cloud layer as the service to communicate with. The other entity can signal the other users edge wallet to establish a connection.

Once the connection has been established, communication between peers can happen peer-to-peer. This reduces the number of actions that involve a blockchain.

## DIDs enable digitally signed verifiable claims

All the architecture described to far is there to set up a connection between two parties. This allows for making verifiable claims.

Taking the example of a driver's license institute. The verifiable claim is that you get a driver's license from the institute. Let's call the driver's license institute the issuer as they are going to issue your drivers license. The issuer has a public DID (which refers to a public key) on a blockchain they want to use. When they issue your drivers license they will sign (with their private key) the claim, in this case your divers license, and give it to you, the holder of the claims, to put it in your wallet. The claim will contain a DID (which refers to a public key) that you own. When the holder needs to present the claim to a party who needs to verify it, they counter-sign the claim to show that they are the owner of the DID the claim is made for. The verifier can then verify both the signature that proves that the holder owns the DID and the signature of the issuer that proves that they issued the drivers license to the holder.

The system that makes this interaction possible is the decentralized public-key infrastructure that is built on top of a blockchain.

## DKMS (Decentralized Key Management System)

The standard covers the communication between edge wallets and cloud wallets. Applies to the wallets, and applies to the agents that read from and write to the wallets. It is an open standard that makes sure you never have to worry about security, privacy or vendor lock-in. For users, the wallet is most likely going to be on their phone.

One of the primary reasons for cloud agents is to make it easy for you to have multiple DKMS wallets across different devices. The other primary reason is backup and recovery. Cloud agents continuously store a backup copy of your wallet encrypted with a special recovery key. Your recovery key is going to be part of all your devices. So when you loose a device and want to add a new one, you can use the recovery key to add the new device.

The two main methods for recovery are offline recovery using paper wallets, and social recovery using trustees. If you have no device left, the recovery methods can be a paper recovery key, or a "cold storage" hardware. Metal versions of keys can be made as well. One of the issues with this solution is, how are you going to remember where this key is after a long period of time, let's say 10, 20, 30 years.

The second method is social recovery. It lets you shard your recovery key into pieces that you share with your choice of trustees.