---
title: "IPFS: The Decentralized Web"
date: 2020-08-19T10:49:43+05:30
draft: true
summary:
image: images/ladakh1.webp
tags:
- IPFS
- Decentralization

#reddit:
#  created: 1594708583 
#  url: https://www.reddit.com/r/ldej/comments/hqwgj8/discuss_working_in_the_trenches/
#  title: "Working in the Trenches"
---

The internet is centralized. That is because the internet is build in a client-server world where we request files by their location. This design has brought us to the internet we have right now, but it has reached its expiration date. There are a number of problems with this architecture, and IPFS can bring us an internet that solves these problems.

```text
https:      //www.npmjs.com  /package  /left-pad
^ Protocol  ^ Location       ^ Path    ^ File
```

## The Problems

{{< big-point number="1" title="Inefficiency" >}}

Let's imagine that this is a highly successful blog post, and I reach the top of [/r/programming](https://reddit.com/r/programming) or [Hacker News](https://news.ycombinator.com/). The link posted there will be `https://ldej.nl/post/ipfs-decentralized-web`. Every person following the link will view my blog post the way it is served by Firebase. A page like this requests about 160kb of data from Firebase, with the rest (i.e. the fonts) coming from external domains. With the [Free Tier](https://firebase.google.com/pricing) I get 10GB of data transfer for free. 10GB limit ÷ 160kb per page = 62500 page views. Which means that at some point I'm going to need to start paying for the resources I use. For a static blog like this it is not much of a problem. If I where to start a social medium, a video hosting site, a package repository, a docker hub, a market place for AI data sets, or you name another data hungry website, it's going to be a bit more expensive.

The inefficiency in this case is that it, even though data is going to be copied to many places, the only place the data is going to be requested from is the place where I host it.

{{< big-point number="2" title="Central point of failure" >}}

I finally reach the top Hacker News, hooray. I haven't added my credit card details to Firebase yet, so at some point my website is going to be unreachable as I hit the limit of the Free Tier. This page has been transferred to many machines, but because this one location is unavailable, the people following the link will end up at a "Bandwidth Quota Exceeded" page.

My location is the central point of failure.

Again, not a big problem for this blog, but there are many other reasons a location can become unavailable. A targeted DDoS attack can bring a website down, but also human failure. And of course it can become unavailable on purpose.

In 2016 the developer of the 10 lines long [left-pad](https://www.npmjs.com/package/left-pad) package removed all his packages from npm after a dispute. This package was used either directly or indirectly by many projects. It broke CI/CD pipelines all over the world. A copy of this package was available probably multiple times on most developer's machines and CI build machines, but because it became unavailable on this single location is caused havoc.

{{< big-point number="3" title="Central point of control" >}}

He who owns the location, owns the control. And with this control, comes great responsibility. You can dictate who is allowed to download your data. Maybe after gathering enough momentum you can decide to add a pay-wall to your website. It's not going to happen for this blog, as you don't add any blog posts to this website, but if I control the blog posts of many people.... I can also move the data, or remove it altogether, making any links to it invalid. When I reach the top of Hacker News, I can also replace this blog post with something dangerous, turning the location into a trap.

Domain names are controlled via a centralized multi-level system called DNS. When you resolve a domain name, you want to know at which IP-address the website is available. First you check your local DNS cache, then you check your ISPs DNS, and at some point the lookup ends up at one of the 13 root domain name servers. Governments can and will force ISPs and internet exchange points to block domain names and IP-addresses, sometimes for good reasons, and sometimes for bad.

{{< big-point number="4" title="You can't verify that you receive the correct data" >}}

The location and path of the file you are requesting do not say anything about the data you requested, it is just a name. How do you know that this is the data you wanted? For insecure protocols like HTTP, any party between you and the website can view and modify the data. HTTPS makes this more difficult as the request and response are encrypted. However, governments can force certificate authorities to issue counterfeit certificates allowing for man-in-the-middle surveillance of encrypted connections. This is how [China's Great Firewall intercepted the Javascript module from Facebook login](https://www.theverge.com/2015/4/28/8508117/facebook-connect-great-firewall-great-cannon-censorship), redirecting requests to other servers. China [has done this before](https://www.theverge.com/2015/3/27/8299555/github-china-ddos-censorship-great-firewall) sending a DDoS attack to Github. Unfortunately Github is another centralized party, causing interruptions to many developers and companies worldwide.

{{< big-point number="5" title="Privacy" >}}

If you control a website, you can collect data about everyone who accesses the data, and use that information in whichever way you want it. Maybe you can use the data to create targeted advertisement spots and sell it to the highest bidder, or just straight up sell the data to any interested party.

Governments can track user's behaviour, tracking which sites have been visited. I agree that targeted surveillance of individuals can be used to prevent disasters. However, applying global mass-surveillance is a danger to society. You might say you don't have anything to hide, but believe me you do. It might not be for your current government, but maybe for your next government, or the government of a country you would like to visit. They can have vastly different opinions about your behaviour and opinions. Citizens being tracked in their each and every move can be a danger to society, as it can lead to self-censorship.

As you can tell, there are quite a number of problems with the current internet. Solving all of these at once is difficult and might create other problems in return. VPNs have allowed users to circumvent censorship and privacy problems, although you put all your trust in a VPN provider. Onion routing networks like Tor and I2P have helped people stay anonymous on the internet but of course have also been used for illegal activities.

Any technology is a Pandora's box. It can be used for good, and it can have unforeseen consequences. You can smash somebody's head with a hammer. Does that mean a hammer should never have been invented?

## IPFS: The Decentralized Web

IPFS (InterPlanetary File System) reimagines what the internet could be like. It decentralizes the web by using peer-to-peer technologies. The two main differences between the web as you know it and IPFS are that content is addressed by a hash instead of by a location, and that there are no centralized systems.

### Content Addressing

Where the internet as you know it uses locations and paths, IPFS uses Content Identifiers (CIDs).

```text
https:      //www.npmjs.com  /package  /left-pad
^ Protocol  ^ Location       ^ Path    ^ File
```

Examples of a CID are `QmY7Yh4UquoXHLPFo2XbhXkhBvFoPwmQUSa92pxnxjQuPU` or `zb2rhe5P4gXftAwvA4eXQ5HJwsER2owDyS9sKaQRRVQPn93bA`. As you can see they do not have a clear location or path. The basis for a CID is a hash.

A hash function can take an arbitrary amount of data and create a fixed-size value as a result. An example of a hash function is `sha256`. Let's take a look at the properties of a hash function.

Hash functions are deterministic. This means that performing a hash function on data will always result in the same hash.

```shell script
$ echo "hello" | sha256sum  
5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03 -
$ echo "hello" | sha256sum  
5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03 -
```

Hashes are uncorrelated. A one-letter change results in a completely different hash.

```shell script
$ echo "laurence" | sha256sum
d088e04e3c2101e6050e50f05f3ae23bc149f18f5c3d0918fae47a1c0717bbd8  -
$ echo "Laurence" | sha256sum
8903527528996d893b68fa8ab69afdee89d044b2c9034ac0851dcb31731e29ad  -
```

Hash functions are one-way. You cannot generate the original data from a hash.

```shell script
$ sha256sum ubuntu-20.04-desktop-amd64.iso
e5b72e9cfe20988991c9cd87bde43c0b691e3b67b01f76d23f8150615883ce11 *ubuntu-20.04-desktop-amd64.iso
```

And last but not least, they are unique. Well, practically that is. With the hardware that we have available today, it is infeasible to generate the same hash from two different inputs.

The predecessor of `sha2` is `sha1`. In 2017 [a group of researchers managed to created two different documents that resulted in the same `sha1` hash](https://shattered.io/). The attack requires a substantial amount of computing power, however with the increase of computing power, and the decrease of its costs, it will become easier and easier to replicate by others. Sha-1 has been deprecated for a number of years and is not accepted in any browser anymore. It does show that over time hash functions might need to be replaced with versions that are more difficult to attack.

IPFS is future proof and does allow different hash functions to be used. In fact, the content identifier contains a unique identifier to show which algorithm was used to generate the hash, the length of the hash, and more.

The second iteration of Content Identifiers is called CIDv1, with CIDv0 being the first iteration.

What does a CIDv1 consist of?

```
<base-encoding><version><data-encoding><hash-function><hash-length><hash>
```

Don't worry, I didn't understand it at first as well, but trust me, it all makes sense.

Let's start at the end with `<hash>`. That one is easy, it's a hash as we saw in the examples above. `<hash-length>` is the number of bits that the hash is long. The `<hash-function>` represents, well, the hash function that is used, in our examples about that would be `sha-256`.

Then we get to the `<data-encoding>`. The hash is taken from a certain input, for example a string, an Ubuntu image, or perhaps json. To make it easier to read the actual data the hash is referring to, the encoding of the data is part of the CID as well.

The `<version>` is another easy one, as it refers to the CID version the CID is following, which for now is either 0 or 1.

The last part, or actually the first part of the CID, is the `<base-encoding>`. The base-encoding tells you which encoding has been used for the CID. A common encoding in the world of decentralization is `base58btc`. Btc refers to Bitcoin, as that is where it originated. The 58 refers to the number characters that are used. They are the numbers 1 to 9, the letters a to z and A to Z. The number 0 (zero) and the letters O (capital o), I (capital i) and l (lowercase L) are excluded for obvious reasons.

### Decentralized Network

The IPFS network consists of nodes instead of a centralized server. You can run a node to join the IPFS network as well. The node joins a peer-to-peer network that is based on a Decentralized Hash Table (DHT).

https://storj.io/blog/2019/02/a-brief-overview-of-kademlia-and-its-use-in-various-decentralized-platforms/
