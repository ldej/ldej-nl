---
title: "Becoming an Aries Developer - Part 5: Issue Credentials"
date: 2020-09-18T12:18:23+05:30
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

There are two actors: issuer and holder

Requirements for issuer:
- A schema needs to be defined for a credential
- A credential definition needs to be created based on the schema
- If the credential definition needs to support revocation, a revocation registry needs to be created

The flow for issuing credentials is: 

1. Issuer sends an offer to the holder (holder receives offer)
2. Holder sends a proposal to the issuer (issuer receives proposal)
3. Issuer sends a request to the holder (holder receives request)
4. Holder responds to the issuer (issuer receives response)
5. Issuer sends credential to holder (holder receives credentials)  
    This step requires an active revocation registry if you enabled support for revocation
    `400: Cred def id 6i7GFi2cDx524ZNfxmGWcp:3:CL:18:default has no active revocation registry.`
6. Holder stores credential (holder sends acknowledge to issuer)
7. Issuer receives acknowledge

