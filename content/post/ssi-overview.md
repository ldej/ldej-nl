---
title: "SSI Overview"
date: 2020-09-03T16:02:44+05:30
draft: true
summary:
image: images/ladakh1.webp
tags:
- 

#reddit:
#  created: 1594708583 
#  url: https://www.reddit.com/r/ldej/comments/hqwgj8/discuss_working_in_the_trenches/
#  title: "Working in the Trenches"
---

https://learnthings.online/course/2020/03/06/becoming-a-hyperledger-aries-developer

SSI
did
diddoc
did-resolution
verifiable credentials https://www.w3.org/TR/vc-data-model/
Verifiable Presentation https://medium.com/@ealtili/self-sovereign-identity-and-distributed-ledger-blockchain-f15937f2b2ed
DIDComm
DKMS https://github.com/hyperledger/aries-rfcs/blob/master/concepts/0051-dkms/dkms-v4.md
Identity hub https://github.com/decentralized-identity/secure-data-store
Presentation Exchange
Hyperledger Ursa, Indy, Aries
Plenum
DID, DIDComm
Trust Over IP
Ethr-DID https://github.com/decentralized-identity/ethr-did-resolver
https://veres.one/
Spherity https://medium.com/spherity/bridging-the-indy-ethereum-gap-with-aries-bac2a7fd8f39
Interoperability https://www.snapperbuzz.com/interoperability-series-sovrin-stewards-achieve-breakthrough-in-wallet-portability/

https://www.blockcerts.org/

## ToIP (Trust over IP)
ToIP is a set of protocols being developed to enable a layer of trust on the Internet, protocols embodied in Indy, Aries and Ursa. It includes self-sovereign identity in that it covers identity, but goes beyond that to cover any type of authentic data.

## VON network

A portable development level Indy Node network, including a Ledger Browser.

## Sovrin Foundation

The foundation

## Sovrin

A single, global instance of Hyperledger Indy. Nodes are operated by a Sovrin Steward.

https://selfserve.sovrin.org/

## Evernym

Creator and Founding Steward of Sovrin. Originator and major contributor to Hyperledger Indy.

## indy-sdk

The indy-sdk repository is the Indy software that enables building components (called agents) that can interact with an Indy ledger and with each other. The core is written in Rust and it is compiled to the C-callable library libindy. The repo contains wrappers in Java, C#, Python, JavaScript around libindy, sothey can be imported in those languages to create Indy agents.

Libvcx, Libnullpay

## indy-node

An indy node

## Aries

Aries is a toolkit designed for initiatives and solutions focused on creating, transmitting, storing and using verifiable digital credentials. At its core are protocols enabling connectivity between agents using secure messaging to exchange information. Aries is all about peer-to-peer interactions between agents controlled by different entities—people, organizations and things. Using the standardized messaging channel, verifiable credentials can be exchanged based on DIDs rooted in different ledgers (based on Indy or other technology) using a range of verifiable credentials implementations.

https://stackoverflow.com/questions/55133748/whats-the-difference-between-hyperledger-indy-sdk-and-libvcx

## Hyperledger Aries Cloud Agent Python (ACA-Py) / aries-cloudagent-python

https://github.com/hyperledger/aries-cloudagent-python

Hyperledger Aries Cloud Agent Python (ACA-Py) is a foundation for building self-sovereign identity (SSI) / decentralized identity services running in non-mobile environments using DIDcomm messaging, the did:peer DID method, and verifiable credentials.

ACA-Py currently supports "only" Hyperledger Indy's verifiable credentials scheme (which is pretty powerful). We are experimenting with adding support to ACA-Py for other DID Ledgers and verifiable credential schemes.

The initial implementation of ACA-Py was developed by the Verifiable Organizations Network (VON) team based at the Province of British Columbia.

Requires python3-indy, which is the python wrapper around libindy, which it also requires.

## aries-framework-go

We implement demonstrations and test cases, that require a ledger system, using DIF Sidetree protocol as this protocol enables generic decentralized ledger systems to operate as a DID network.

Does not work with Indy, and does not rely on libindy.

## DIF Identity Hub

a replicated
mesh of encrypted personal datastores,
composed of cloud and edge instances (like
mobile phones, PCs or smart speakers),
that facilitate identity data storage and
identity interactions

## DIF Universal Resolver

https://github.com/decentralized-identity/universal-resolver

a server
that utilizes a collection of DID Drivers to
provide a standard means of lookup and
resolution for DIDs across implementations
and decentralized systems and that returns
the DID Document Object (DDO) that
encapsulates DPKI metadata associated
with a DID.

https://dev.uniresolver.io/


## DID Agent

applications that
enable real people to use decentralized
identities. User Agent apps aid in creating
DIDs, managing data and permissions,
and signing/validating DID-linked claims. 

## Service endpoints

Requests to Identity Hubs are routed based
on DPKI metadata called Service Endpoints
that’s associated with DIDs.

## Microsoft ION

https://github.com/decentralized-identity/ion

A DID network on top of the bitcoin blockchain using SideTree

## SideTree

https://github.com/decentralized-identity/sidetree
https://identity.foundation/sidetree/spec/

Blockchain agnostic protocol

SideTree DIDs “have to be created by a centralized server, currently hosted by Microsoft.”

When asked whether ION can be considered a fully decentralized project, Smith argued that it is “debatable, but all the main benefits of a decentralized network are present.” Particularly, he specified that “two major components of the ION network make it highly decentralized”:

“The system is set up so that no person or entity can control users’ identifying information and the public key infrastructure is decentralized. This means that the private and public key pairings aren’t managed by one central authority, essentially giving each user secure access to their identifying data. Even though Microsoft has spearheaded this project, they have formed it in a way that allows individuals to remain in charge of their information.”

Further, according to Braendgaard, SideTree DIDs are only useable off-chain in traditional applications, while some other DIDs — including its own — are fully usable both on blockchains and Layer 2 protocols.
