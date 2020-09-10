---
title: "Becoming an Aries Developer - Part 2"
date: 2020-09-10T16:20:12+05:30
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



Requirements:
- docker
- A running Hyperledger Indy network (for example VON-network)
- A running ACA-py

libindy is a C-callable library that provides functionality for interacting with an Indy ledger. libindy is written in Rust and the source code is in indy-sdk.

python3-indy is a Python wrapper around libindy so you can `import indy`

aries-cloudagent-python uses python-indy and includes a webserver to expose the python-indy functionality over HTTP

Your agent can either:
- create your own calls to the C-callable library (hardcore-mode enabled)
- import python3-indy (or a wrapper of another language)
- talk to Aries-CloudAgent-Python (ACA-py) over HTTP

I created a Go client library for ACA-py that communicates over HTTP. After creating the client you can easily perform all actions on ACA-py from Go.

Check out https://github.com/bcgov/von-network
Run `./manage start --logs`
This starts 4 Indy nodes and a von-webserver. The von-webserver has a web interface at http://localhost:9000/ which allows you to browse the transactions in the blockchain.

There are two options for running Aries-CloudAgent-Python (ACA-py):
1. Do-it-yourself
Check out https://github.com/hyperledger/aries-cloudagent-python
Check the documentation for running options: https://github.com/hyperledger/aries-cloudagent-python/blob/master/DevReadMe.md
2. pip3 install aries-cloudagent
You should then be able to run `aca-py`

To run aca-py you need a lot of command line parameters.

The steps for getting your setup running are not for the faint-hearted.

With the Indy production ledger, you can only register a DID by paying. However, we have a test network in docker containers, so how do we register a DID? Registering a DID happens via a special URL of the VON-network webserver (http://localhost:9000/register). Of course this URL is not available on the production ledger.

The DID you receive is the basis for your ACA-py instance. With the DID you also receive a seed. This seed is one of the parameters you need to start your ACA-py instance with.

Create issuer1 + did
Create schema1 for issuer1
Create issuer2 + did
Create schema2 for issuer2
Create a holder + did
Create a verifier

Create VC1 with issuer 1
Create VC2 with issuer 2
Create a VP with Credentials from VC1 & VC2

Verifier verifies VP