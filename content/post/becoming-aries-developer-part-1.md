---
title: "Becoming an Aries Developer - Part 1"
date: 2020-09-10T16:20:12+05:30
draft: false
summary: Background knowledge for terms in the Self-Sovereign Identity space.
image: images/ladakh1.webp
tags:
- Decentralization
- Self-Sovereign Identities

#reddit:
#  created: 1594708583 
#  url: https://www.reddit.com/r/ldej/comments/hqwgj8/discuss_working_in_the_trenches/
#  title: "Working in the Trenches"
---

Self-Sovereign Identities are one of the most important building blocks of the decentralized web, and therefore the internet as whole. In my master thesis (2015) I have written about the fundamental building blocks of the decentralized web. Identity was the biggest and highest priority item on the list. Now, 5 years later, the landscape looks completely different with many projects in the decentralized identity sphere.

I want to develop applications or libraries that use decentralized identities. I watched a lot of videos, found a lot of good resources online, but was still left with a lot of questions. The best way to get more understanding of how this all should work comes with experimenting with it myself.

The most important part of Self-Sovereign Identities are Decentralized Identifiers, better knows as DIDs. I have written about them in previous blog posts and recommend checking them out. There are two videos I recommend to watch to get a better overview: [The Story of Open SSI Standards](https://www.youtube.com/watch?v=RllH91rcFdE) and [Decentralized Identifiers (DIDs) - The Fundamental Building Block of Self Sovereign Identity](https://www.youtube.com/watch?v=Jcfy9wd5bZI&).

In the meantime I discovered that there are other projects using DIDs as well, but with a different technology stack. Ethereum supports DIDs with the uPort project, and Microsoft ION supports DIDs on the Bitcoin blockchain using the SideTree protocol. And then there are the Open Standards of Blockcerts. There are probably some more projects I need to mention here, but honestly this space is evolving every day, and it's difficult to keep up. My goal is to try to develop an application using these technologies too and see if there is a way they can be united.

To learn more about the Hyperledger identity stack I attended the courses [Introduction to Hyperledger Sovereign Identity Blockchain Solutions: Indy, Aries & Ursa](https://courses.edx.org/courses/course-v1:LinuxFoundationX+LFS172x+3T2019/course/) and [Becoming a Hyperledger Aries Developer](https://courses.edx.org/courses/course-v1:LinuxFoundationX+LFS173x+1T2020/course/) by the Linux Foundation on [edx.org](https://edx.org) and decided to give it a try to develop an application using Aries.

## Background

There are many technologies, protocols and names involved, and it took me some time to understand how it is all connected. So let's start with defining some of them.

Let's start with __Evernym__. Evernym is the company that developed most of what I'll be talking about here. They created the basis of what has become __Hyperledger Indy__ and are still the main contributor. Hyperledger Indy is a blockchain specifically for storing DIDs and some other things related to them. There is a production instance of Hyperledger Indy called __Sovrin__. Sovrin is a permissioned public blockchain. Permissioned in this case means that you need to become a Steward of the __Sovrin Foundation__ to let your node join the network. It is public, meaning everybody is able to interact with the blockchain to verify identities and credentials. Sovrin is managed by the Sovrin Foundation. The Sovrin Foundation is founded by Evernym and currently has [quite a number of stewards](https://sovrin.org/stewards/) that are all running a node. The Sovrin Foundation includes more than just the network, it includes a [governance framework](https://sovrin.org/library/sovrin-governance-framework/). The governance framework is a legal foundation that includes a lot of rules and regulations around the business, legal and technical support of the Sovrin Network. 

Another name you see is __VON-network__. VON stands for Verifiable Organizations Network. It is a portable development level Indy Node network with a Ledger browser. What this means is that you can run the minimal required 4 instances of Indy Nodes, and an application with which you can browse the Ledger, with a single docker-compose command. VON-network has been created by the team that implemented SSI for the __Province of British Columbia (BCGov)__.

To join any Indy network, you need to have the genesis file of the blockchain. As I said before, for the production Sovrin network you need to become a Steward, and then you will receive the genesis file. Also, registering a DID on the Sovrin Network is permissioned and if you want to register DIDs to issue credentials there are [fees](https://sovrin.org/issue-credentials/). There are test networks available to connect to, both for [Sovrin](https://selfserve.sovrin.org/) and for the VON-networks of BCGov.

The Hyperledger identity stack consists of three parts: Ursa, Indy and Aries. It all started as one project called Indy. Ursa is the library that has all the cryptography credentials. Indy contains the distributed ledger technology. 

There are multiple projects that support DIDs. DIDs are usually a hashed form of a public key. The private keys for DIDs are stored in a __wallet__. A wallet is part of an __agent__. An agent is any application the stores and uses DIDs. Agents exist in many forms. Agents can communicate directly with each other. The envelope of the messages between agents has been standardized in the form of the __DIDComm__ protocol. DIDComm describes how messages should be encrypted and decrypted in transport. When you can send messages from one agent to another, what do you send? The language in the messages, the format and the sequence of messages, are called the __Aries__ protocol. Aries is an attempt to standardize the communication between agents.

The whole stack of both technology and governance around SSIs is called the Trust over IP (ToIP) stack.

{{% figure src="/images/Trust_over_IP__ToIP__Technology_Stack.png" alt="Trust over IP Technology stack" %}}

## Technology Stack

I am going to build an application that uses aries-cloudagent-python (__ACA-py__). ACA-py is a framework for building applications that use the Aries protocol for agent-to-agent communication.

ACA-py is a web application that contains the core functionality. You can communicate with ACA-py over HTTP, and it contains API documentation in the form of Swagger. ACA-py uses a library called python3-indy which is a wrapper around a C-callable library called __libindy__ which allows you to `import indy`. libindy provides functionality to work with credentials and proofs. It also exposes operations for communication with Hyperledger Indy ledgers. What it doesn't do is the communication between agents. There is a library called __libvcx__ which handles the communication between agents, it is one of several implementations of the Hyperledger Aries specification. ACA-py uses libindy and not libvcx, and it is compatible with libvcx, meaning it can communicate with applications that use libvcx.

All-in-all this means that there are many standards for the various technologies around DIDs. The specification of DIDs and their related DID documents, verifiable credentials, and so on. Even the communication between agents has been standardize, although it is [hard to find](https://github.com/hyperledger/aries-rfcs/blob/master/concepts/0005-didcomm/README.md#implementations) any other non-Sovrin/Indy projects that use DIDComm and Aries protocols.

A [DIDComm Working Group](https://identity.foundation/working-groups/did-comm.html) has been established by the Decentralized Identify Foundation (DIF) to standardize and promote the use of DIDComm by other agents.

It required a lot of reading to get a feeling for what the state of DIDs currently is. I've mainly focussed on the Hyperledger part, but in the future I'd like to dive into DIDs in other ecosystems too.

In part 2 I'm going to talk about the Go-application I created that communicates with ACA-py.