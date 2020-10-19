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

In [part 1]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-1-terminology.md" >}}) I gave an introduction to the terms used in the Self-Sovereign Identity space. In [part 2]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-2-development-environment.md" >}}) I explained the tools and command-line arguments for the development environment. In [part 3]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-3-connecting-using-swagger" >}}) I set up two agents, and they connect using the invite and request/response protocol. In [part 4]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-4-connecting-using-go-acapy-client" >}}) I introduced the `go-acapy-client` library that allows you to interact with ACA-py from Go. In [part 5]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-5-issue-credentials" >}}) credentials got issued over the established connection between the agents. In [part 6]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-6-revocation" >}}) I discussed revocation. In this part I am going to create a proof presentation of an issue credential and verify it.

## Context


## Steps

There are two parties involved: the prover and the verifier

1. Prover sends proposal (verifier receives proposal)
2. Verifier sends request (prover receives request)
3. Prover sends presentation (verifier receives presentation)
4. Verifier verifies presentation
5. Verifier sends presentation acknowledgement (prover receives presentation acknowledgement)

Sending a presentation requires a revocation registry:
`400: Error when constructing proof: Error: Invalid structure. Caused by: Revocation Registry Id not found. CommonInvalidStructure.`
