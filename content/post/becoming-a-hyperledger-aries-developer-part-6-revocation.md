---
title: "Becoming a Hyperledger Aries Developer - Part 6: Revocation"
date: 2020-09-28T11:58:24+05:30
draft: false
summary: Creating a revocation registry, using the tails server and revoking a credential.
image: images/ladakh12.webp
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

In [part 1]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-1-terminology.md" >}}) I gave an introduction to the terms used in the Self-Sovereign Identity space. In [part 2]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-2-development-environment.md" >}}) I explained the tools and command-line arguments for the development environment. In [part 3]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-3-connecting-using-swagger" >}}) I set up two agents, and they connect using the invite and request/response protocol. In [part 4]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-4-connecting-using-go-acapy-client" >}}) I introduced the `go-acapy-client` library that allows you to interact with ACA-py from Go. In [part 5]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-5-issue-credentials" >}}) credentials got issued over the established connection between the agents. In this part I am going to discuss revocation.

## Context

When credentials are issued, credentials can also be revoked. You can think about your driving license being revoked after a judge deciding that you are not allowed to drive anymore.

The Sovrin ledger puts a big focus on privacy. Credentials are never stored in any form or way on the ledger. This also means that the revocation of a credential should not be stored on the ledger. It also means that proving your credential is valid, should be a concern between the prover and the verifier and nobody else. Not even the issuer should be involved.

W3C has a draft document called [Revocation List](https://w3c-ccg.github.io/vc-status-rl-2020/), which according to the subtitle is "A privacy-preserving mechanism for revoking Verifiable Credentials". Sovrin disagrees with the privacy-preserving part and argues in their [What goes on the ledger?](https://sovrin.org/wp-content/uploads/2018/10/What-Goes-On-The-Ledger.pdf) and in [HIPE0011 - Credential Revocation](https://github.com/hyperledger/indy-hipe/tree/master/text/0011-cred-revocation) that:

> Most traditional approaches to revocation require the party verifying the credential, called the verifier or relying party, to check back directly with the issuer or some other central authority to see if the credential is still valid. This approach has three major downsides:
> 1. It places a large technical burden on the credential issuer, who needs to create and maintain an API to provide access to the credential revocation list and provide permission to all those relying parties requiring access to it.
> 2. It requires the relying party to create and maintain calls to all those APIs from every credential issuer around the world.
> 3. It is a massive privacy issue because it provides an ideal way for issuers and relying
  parties to correlate an identity holder’s usage of a credential across domains.

I suggest reading [HIPE0011 - Credential Revocation](https://github.com/hyperledger/indy-hipe/tree/master/text/0011-cred-revocation) to understand the process of revocation Indy and the purpose of the tails file. In the rest of this blog post I assume you have read HIPE0011 and do understand what a tails file is.

In the next blog post I'm going to talk about proving credentials, and for credentials to be proven in Indy, a revocation registry is required as the prover needs to prove a credential is valid by providing a proof of non-revocation.

## Creating a revocation registry with a credential definition

When you create a credential definition, you can specify `supports_revocation: true` and the size of the registry. A revocation registry will automatically be created, and a tails file will be uploaded to the tails server. For this call to work, you need to specify `--tails-base-server http://some-place`. So let's set up a tails server.

Checkout [github.com/bcgov/indy-tails-server](https://github.com/bcgov/indy-tails-server) and run:
```shell script
$ GENESIS_URL=http://localhost:9000/genesis ./docker/manage/start
```

The tails server runs with the docker option `--net=host`, which allows it to communicate with any other service available on your systems' localhost. The tails server connects to Hyperledger Indy nodes, and it does that by using the genesis file of the ledger. It assumes your VON-network webserver is running on `localhost:9000`, but you can override that with the environment variable `GENESIS_URL`.

The tails server has two functions:
1. Upload a tails file
2. Download a tails file

When you create a credential definition with revocation, ACA-py will create a tails file with your specified size. It will then send a message to the ledger with the details of the tails file, for example the file hash, the tails file location (on the tails server) and the accumulator. After that is done, ACA-py will upload two files to the tails server, the genesis file and the tails file. They are stored with a reference to the revocation registry identifier. The tails server will request the revocation registry details from the ledger using the genesis file. Next it will verify that the hash of the tails file is equal to the hash of the tails file which is stored in the ledger.

The tails server imports [indy-vdr](https://github.com/hyperledger/indy-vdr) instead of `indy`. VDR stands for Verifiable Data Registry. The library connects to ledger as well, but with a different purpose: to interact with revocation registries, so a verifier like the tails server can be made. Like `libindy`, `indy-vdr` is written in Rust. There is no pre-built `indy-vdr` package available, so you will need to build it yourself with Rust. There is a Python wrapper available for `indy-vdr`, but for now you cannot `pip install indy_vdr` yet.

## Manually creating a revocation registry

The automatic creation of a revocation registry can also be done manually.

1. Create a credential definition with `support_revocation: false`.  
  POST to `/credential-definitions`
2. Create a revocation registry.  
  POST to `/revocation/create-registry`
3. Set the tails server URI for the revocation registry.
  PATCH to `/revocation/registry/{id}`
4. Send the revocation registry to the ledger.  
  POST to `/revocation/registry/{id}/defition`
5. Upload the tails file to the tails server.
  PUT to `/revocation/registry/{id}/tails-file`
  
## Revoking a credential

In the previous blog post I discussed issuing a credential. If you follow these steps but with enabled support for revocation, then the issuer of the credential can revoke the credential with `/revocation/revoke`. When you revoke a credential you can specify if the result should be published to the ledger immediately. If you don't publish immediately, you can publish them manually using `/revocation/publish-revocations` or can you clear the pending revocations with `/revocation/clear-pending-revocations`.

The reason you might want to wait with publishing, is because it is a transaction in the ledger. Any transaction in the Sovrin ledger costs money. The creation of a revocation registry [costs](https://sovrin.org/issue-credentials/) $20, and the publishing of a revocation update costs $0.10.

## Multiple revocation registries

A revocation registry has a maximum size. The size should be at least 4, and max 32768. Creating a revocation registry with the maximum size results in a tails file of over 8MB. A prover needs to have a copy of the tails in order to prove that their credential has not been revoked. If an agent has a lot of credentials and needs to prove a lot of them in a new situation, the size of the tails files might become a problem.

When a revocation registry reaches its maximum size (that number of credentials have been issued), a new revocation registry can be made for the same credential definition. Remember that this requires another payment.

There is a balance between the size of the revocation registry, and the usability of the file size of the tails file, and this balance will be different per use case.

Update: In [PR735](https://github.com/hyperledger/aries-cloudagent-python/pull/735) functionality gets added to get the revocation registry witness deltas from the ledger, which allows you to prove the non-revocation of a credential. With this, a new endpoint gets added `/credential/revoked/{credential_id}` that allows you to check if the credential has been revoked. 

## Revocation notification

When an issuer revokes a credential, it only communicates with the ledger to update the accumulator. A holder or prover can only find out if their credentials are still valid by taking the latest version of the tails file, build up the accumulator, and verify it with the accumulator stored in the ledger. [Aries RFC0183](https://github.com/hyperledger/aries-rfcs/tree/master/features/0183-revocation-notification) proposes a format for a message to let the holder know that the previously issued credential has been revoked.

## Conclusion

With the tails server and revocation registry set up, let's jump to presenting proof of non-revocation in [part 7]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-7-present-proof.md" >}}). In the meantime I have written a post about [connecting ACA-py to hosted ledgers]({{< relref "/post/connecting-acapy-to-development-ledgers.md" >}}).
 