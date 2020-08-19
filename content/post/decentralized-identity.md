---
title: "Why Decentralized Identities Are Going To Redefine The Web"
date: 2020-08-14T11:02:44+05:30
draft: false
summary: Decentralized identities are going to reshape are online identities by taking control from centralized authorities back to the users.
image: images/bolivia2.webp
tags:
- Decentralization
- IPFS

#reddit:
#  created: 1594708583 
#  url: https://www.reddit.com/r/ldej/comments/hqwgj8/discuss_working_in_the_trenches/
#  title: "Working in the Trenches"
---

My online identity is a mess. My password manager is counting 97 items. Each of these items in my password manager represents an identity on a website. And each of these identities contains personal information like my name, phone number, email address, profile picture, postal address and payment information. My information is copied all over the web, and so is yours. 

I recently moved to India which means I got a new address, a new phone number, and a new online payment method. It is a pain to update my information, and I am sure I forgot a couple of places.

The trail of information we leave behind is incredible, scary, and dangerous. Each account on a website gives access to more data. Think about mails, photos, posts, tweets, game data, late night Amazon buys, financial records, health records, this list can go on and on.

Every time you create an account your data is stored and processed, and privacy and security issues arise.

Governments, banks, online stores, social media, you give them your personal information and trust that they are going to take care of it. Secure it properly, don't sell it to anybody else, and preferably don't get hacked. Unfortunately they cannot handle the responsibilities, as on a regular basis dumps with accounts and private information are spread around the web. Identity theft and loss of privacy are unfortunately common.

It was in 2015 when I wrote my Master Thesis on creating a decentralized version of reddit, where you would own your data. One of the points I made is that the basis for a truly decentralized internet is going to be a decentralized identity. A lot has happened since 2015, which makes me hopeful. 

A decentralized identity is an identity that is not provided by a single company or government, but that is issued independently. Which is completely the opposite from online identities right now, issued by..., well, everybody can become an identity provider. An identity provider can be Google, allowing you to login to their services and other websites using the "sign in with Google" buttons. The same goes for Facebook, Apple, Twitter. Every time you use one of those buttons the identity provider will know where you are going.

Not just the Big Tech companies have an online identity of you, it is every place where you can log in. And in my case that is over 97 places at this moment. Recently I have been Googling my name and have found numerous accounts on long forgotten forums and places where I cannot remember ever having created an account. Luckily I'm still using the same Gmail inbox allowing me to reset the password and delete the account.

My email address, and with that my Google account, has been with me for a long time. It's got all my mails, photos, chats (I used Google Talk a lot). My identity gives access to vast quantities of personal information. I think Google might know me better than I know myself. If Google would cease to exist at this moment, I've got a big problem. And that is a big problem for everybody.

In order to understand what the future of identities is going to be like, we need to separate applications in their component parts. Your account on a website consists of:
- your identity and the credentials with which you prove that it's you
- your profile containing required personal information like your name and birth date
- all data you added to the website, think your photos, posts, thoughts, etc.

A website provides you with an identity which gives you access to your data. It displays the data in a certain way and lets you interact with other identities or data from those entities.

For example, you have a Twitter account, you write your tweets, they are displayed on your profile page, and you can follow other users, and reply and retweet their tweets.

So we have:
1. identity
2. profile
3. data
4. application

Right now, an identity is issued by an identity provider, stored by the identity provider, and verified by the identity provider.

Decentralized identities are going to completely redefine how we use the web by decoupling these parts.

Imagine you have your current postal address stored with your decentralized identity in an encrypted manner. You are going to order something from your favourite web shop. You can give the web shop one-time access to that address allowing it to use that address to ship your packages to.

Imagine your Tweets are securely stored in a decentralized storage network. You can use this data on any of the websites or platforms that you would like to.

Imagine you go to a hospital where you can give access to your medical history.

If you have an online identity that would allow for these use cases, you do not want to be completely dependent upon a single company, entity or authority. This means that you do not want to store this information at a single company. This is why a decentralized identity is important.

If we do not want to store our identity at a single company, then where?

We need to take a look at decentralized technologies. For over 10 years, blockchains have been used as the singular source of truth for cryptocurrencies. Blockchains are not controlled by a single party. Therefore, blockchains have been looked at as a system to register identities in a decentralized manner. But of course blockchains are not without their problems and controversies. Or maybe a system like IPFS can act as the completely decentralized network to communicate and store information.

Now let's assume that a completely decentralized system can take care of storing our identity without having to rely on any central party. In that case we might as well use a decentralized system (maybe IPFS) for storing the data, like our tweets, as well. And if our identity and data are not owned by a single corporation anymore, then we can truly see what the value of the application is. We might be able to create different applications that use the same data, but show it differently or use it in another way.

How is that going to play out? I don't know. Big corporations like Google and Facebook still want to gather as much of your information as possible to create profiles for targeted advertising. But what if you use a different application that doesn't show ads at all? Will they store your data in your profile in such a way that online they are able to decipher it? I don't know. But what I do know is that it will allow other parties to create open systems in which data can be used and reused in different applications. Again, how is this going to play out? I don't know, but I'm hopeful.

Of course, we don't have one identity. Our identity depends on context. I have a certain identity for the government, another when I visit my parents in law, and a completely different one when I am shopping in the supermarket. These are often independent identities, and sometimes we don't want these identities to be linked to each other. You have to be able to create identities whenever you want to, and keep them separated when needed.

A number of companies and organizations are collaborating under the name [Decentralized Identity Foundation](https://identity.foundation/). The names include Microsoft and [IBM](https://www.ibm.com/blockchain/solutions/identity
), but also W3C, IETF, [Hyperledger](https://www.hyperledger.org/
) and a whole list of companies working on decentralized technologies. They are actively working on the standardization of [Decentralized Identifiers (DIDs)](https://www.w3.org/TR/did-core/).

These DIDs are designed with a number of gaols in mind:

1. **Decentralized** You should be able to create globally unique identities while and not be dependent upon centralized authorities.
2. **Control** You should be able to change or update your identity without having to rely on external authorities.
3. **Privacy** You should be able to control which information will be shared, comparable to how apps can ask for permissions when they need them. We all have different identities in different contexts. Sometimes we don't want these identities to be linked to the same person.
4. **Security** Whenever information is stored, transferred or processed, it should be secure and resilient against attacks. Information should be encrypted whenever applicable.
5. **Proof-based** You should be able to prove that the identity is not tampered with, and you should be able to prove that you are currently controlling the identity.
6. **Discoverability** In some cases, identities should be human-friendly. You can think about an email-address, Twitter handle, or URL.
7. **Portability** Your identity should be system-independent, allowing you to use it with any system that supports it.

Of course decentralized identities should use open standards so existing tools can be used, making it easier to understand, implement and deploy. And it should be extensible when possible.

How this is going to work out in practise is not completely clear to me yet. Microsoft has been working on an implementation of DIDs called [ION](https://techcommunity.microsoft.com/t5/azure-active-directory-identity/toward-scalable-decentralized-identifier-systems/ba-p/560168#
). It uses the Bitcoin blockchain, but it is a blockchain agnostic solution, meaning it can also be used with other blockchains. The data for profiles is not stored in the blockchain directly, instead the operations on DIDs (create, update, delete) are put into batches, and hashes of the batches are put into the blockchain. The batches of operations are replicated between nodes and stored via IPFS. In June 2020 the project moved [from the Bitcoin testnet to the mainnet](https://techcommunity.microsoft.com/t5/identity-standards-blog/ion-booting-up-the-network/ba-p/1441552).

To use the ION network right now, you would need to run an ION node which consists of a Bitcoin Core node, an IPFS node, a MongoDB database and of course the ION application itself. Another way to interact with the network is to find a publicly accessible node.

You can create DIDs with a public-private key pair, but you do need to keep your private key safe yourself.

The idea of the ION network is that you will be able to create DIDs that can be used for all sorts of use cases. You can use a DID for example to login to a website or for the registration of domain names. It is up to party implementing to determine what the significance of a DID is.

As a normal everyday user, you would not be running an ION node. Instead, a network of node operators will do that for you. The details of how this is going to be used in practise is still a bit unclear to me. Do websites that want to use DIDs run a node themselves? Will there be a market for nodes? What if the number of node operators becomes very small?

Let's say you want to create a DID via an app on your phone. You are not going to run a full node on your phone because of obvious reasons. You might let the app connect to a preconfigured (or maybe configurable) public node. Or maybe a light-client that will access the IPFS network directly can give you access.

The [uPort](https://www.uport.me/) project is doing very similar but then for the Ethereum blockchain. This project is also part of an contributing to the Decentralized Identity Foundation. Another project to check out is [Blockstack](https://www.blockstack.org/).

To read more about decentralized identities in general I can recommend [this article](https://www.frontiersin.org/articles/10.3389/fbloc.2019.00017/full) byt the frontiers in Blockchain. To read more about the project of the Decentralized Identity Foundation I recommend [this article](https://medium.com/decentralized-identity/overview-of-decentralized-identity-standards-f82efd9ab6c7).