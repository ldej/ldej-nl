---
title: "Becoming a Hyperledger Aries Developer - Part 7: Present Proof"
date: 2020-09-23T10:32:27+05:30
draft: true
summary:
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

In [part 1]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-1-terminology.md" >}}) I gave an introduction to the terms used in the Self-Sovereign Identity space. In [part 2]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-2-development-environment.md" >}}) I explained the tools and command-line arguments for the development environment. In [part 3]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-3-connecting-using-swagger" >}}) I set up two agents, and they connect using the invite and request/response protocol. In [part 4]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-4-connecting-using-go-acapy-client" >}}) I introduced the `go-acapy-client` library that allows you to interact with ACA-py from Go. In [part 5]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-5-issue-credentials" >}}) credentials got issued over the established connection between the agents. In [part 6]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-6-revocation" >}}) I discussed revocation. In this part I am going to create a proof presentation of an issued credential and verify it.

## Context

You have received credentials, for example a driver's license, a passport or your degree. These credentials are not just useful to have, they are useful because your can prove that they are yours. The party that wants to verify your credentials can verify the signatures of the credentials are correct as well.

## The Present Proof dance

There are two parties involved: the prover and the verifier

1. Prover sends proposal (verifier receives proposal)
2. Verifier sends request (prover receives request)
3. Prover sends presentation (verifier receives presentation)
4. Verifier verifies presentation
5. Verifier sends presentation acknowledgement (prover receives presentation acknowledgement)

You can read more about the protocol at [RFC0037](https://github.com/hyperledger/aries-rfcs/tree/master/features/0037-present-proof).

If the issuer has not set up a revocation registry when the credential definition got created, then the holder cannot send a presentation. When the holder tries to send a presentation, the following error will occur:

`400: Error when constructing proof: Error: Invalid structure. Caused by: Revocation Registry Id not found. CommonInvalidStructure.`

## Present Proof with `go-acapy-client`

Presenting proof is the most difficult part of Aries, at least in my opinion. There seem to be many possibilities, but the documentation for it is rather scarce.



`{"attr::name::key": "Bob"}`


## Development and debugging

`--auto-respond-presentation-proposal`
`--auto-respond-presentation-request`
`--auto-verify-presentation`

`--debug-presentations`

## Connectionless present proof

## Conclusion