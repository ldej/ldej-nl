---
title: "Becoming a Hyperledger Aries Developer - Part 2: Development Environment"
date: 2020-09-11T13:20:12+05:30
draft: false
summary: Setting up of a development environment with an Indy network and Aries Cloud Agent Python.
image: images/ladakh8.webp
tags:
- Decentralization
- Self-Sovereign Identities
- Hyperledger Aries

#reddit:
#  created: 1594708583 
#  url: https://www.reddit.com/r/ldej/comments/hqwgj8/discuss_working_in_the_trenches/
#  title: "Working in the Trenches"
---

In [part 1]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-1-terminology.md" >}}) I gave an introduction to the terms used in the Self-Sovereign Identity space. In this second part I'm going to talk about the set up of the environment to develop an application using ACA-py.

I'm going to set up a Hyperledger Indy network using VON-network, and then I'm are going to set up ACA-py.

## Start Hyperledger Indy nodes using VON-network

The first step is always easy, let's make a checkout of [github.com/bcgov/von-network](https://github.com/bcgov/von-network). Then run:

```shell script
./manage start --logs
```

This starts 4 Indy nodes and a von-webserver. The von-webserver has a web interface at [localhost:9000](http://localhost:9000) which allows you to browse the transactions in the blockchain.

On that page there are two important parts: Downloading the genesis transaction to join the network and registering a new DID. Just as with most blockchains, in order to join it you need to get the genesis transaction from somewhere, we will use this later. The other action, registering a DID, is different locally from production. In the Sovrin production network you need to pay for adding a DID to the blockchain, but locally you can do it for free of course.

## Aries Cloud Agent Python (ACA-py)

ACA-py depends on libindy. You can install libindy yourself, or you can run a docker container that contains it for you.

First, let's start with making a checkout of [github.com/hyperledger/aries-cloudagent-python](https://github.com/hyperledger/aries-cloudagent-python).

In the `docker` folder you can find a `manage` file that lets you start ACA-py in a docker container. Run `./docker/manage start` to start ACA-py, however it requires some command line arguments to come off the ground. More on that later.

If you want to feel like a real developer of course you want to try to run everything yourself. So let's do that.

First you need to install `libindy`.

If you are running Ubuntu 18.04:

```shell script
$ sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 68DB5E88
$ sudo add-apt-repository "deb https://repo.sovrin.org/sdk/deb bionic master"
$ sudo apt-get update
$ sudo apt-get install -y libindy
```

After installing, you should have the file `/usr/lib/libindy.so`.

Instructions for other operating systems are here: [Installing the SDK](https://github.com/hyperledger/indy-sdk#installing-the-sdk).

Libindy is a C-callable library that is written in Rust. Wrappers are made for libindy for Python, NodeJS, Java, iOS, .NET and Rust. Unfortunately there is no wrapper for Go, so maybe that is something I can look into in the future. You can find the source for libindy and the wappers in [github.com/hyperledger/indy-sdk](https://github.com/hyperledger/indy-sdk). At first, I thought I needed that repository, but so far I haven't used it.

Now that libindy is installed, let's continue with ACA-py. You can either:

```shell script
$ pip3 install aries-cloudagent
```
After which you should be able to run `aca-py`:
```shell script
$ aca-py 
usage: aca-py [-h] [-v] {provision,start} ...

positional arguments:
  {provision,start}
    provision        Provision an agent
    start            Start a new agent process

optional arguments:
  -h, --help         show this help message and exit
  -v, --version      print application version and exit
```

or you can create a virtual environment and install the dependencies from `requirements.txt`, `requirements.indy.txt` and `requirements.dev.txt`. Then you should be able to run:
```shell script
$ ./bin/aca-py 
usage: aca-py [-h] [-v] {provision,start} ...

positional arguments:
  {provision,start}
    provision        Provision an agent
    start            Start a new agent process

optional arguments:
  -h, --help         show this help message and exit
  -v, --version      print application version and exit
```

If you want to run the latest code outside of docker, you can:

```shell script
$ pip3 install --no-cache-dir -e .
```

After that, running `aca-py` will be the version that you have checked out. 

## Running the demo

The ACA-py repository contains a demo which is a Python application that communicates with ACA-py over HTTP. The demo application does not import libindy and does not import from aries-cloudagent.

You will start two applications, agents actually, in two separate terminal windows that can establish a connection between them and send messages:

```
## terminal 1
$ ./demo/run_demo faber
## terminal 2
$ ./demo/run_demo alice
```

The Faber demo agent will output an invitation in JSON format. Copy that JSON and paste it in the Alice agent. A connection between the two will be established and messages can be sent from one agent to the other. It all looks very easy, but a lot of messages are going back and forth, and this is something I'll have to create myself.

The terminology in ACA-py is a bit confusing. ACA-py is a cloud agent, and you will develop your application against this. The application you build is called a controller. However, ACA-py is sometimes called a framework, as you use it to build an application. Sometimes ACA-py and your controller application together are called an agent.

And then there is the term wallet. Wallets have been used in cryptocurrency for time some, they hold your keys. In Indy, it is libindy that actually stores and manages your keys, so libindy has a wallet. However, if you build an app with Indy and Aries where you can manage your credentials, then you might call the whole agent a wallet too.

## Command-line arguments

In order to start ACA-py you need a number of command line arguments. When running the demo applications you don't have to start ACA-py yourself. Instead, the demo starts ACA-py in a sub-process where it will provide all the correct command-line arguments.

When you start developing an application against ACA-py, you are going to need to provide these command line arguments too. You can choose the same solution where you create a sub-process to start ACA-py, or you can start ACA-py manually.

After some experimenting I figured out a set of command-line parameters that work, so let's take a look at them.

```shell script
$ aca-py start \
  --label Laurence \
  --inbound-tranport http 0.0.0.0 8000 \
  --outbound-transport http \
  --admin 0.0.0.0 11000 \
  --admin-insecure-mode \
  --genesis-url http://localhost:9000/genesis \
  --seed Laurence000000000000000000000000 \
  --wallet-type indy \
  --wallet-name Laurence \
  --endpoint http://localhost:8000/ \
  --webhook-url http://localhost:4455/webhooks \
  --public-invites \
  --auto-accept-invites \
  --auto-accept-requests \
  --auto-ping-connection \
  --debug-connections
```

`--label` The name that you give this ACA-py instance that will be used in messages.

`--inbound-transport http 0.0.0.0 8000` __required__ This is the protocol, address and port your ACA-py instance will be reachable at for other ACA-py instances.

`--outbound-transport http` __required__ This is the protocol that your ACA-py instance will use to communicate to other instances. You can also choose `ws` for websockets or add custom transport modules.

`--admin 0.0.0.0 11000` This is the address and port you can connect to with your application/controller. It is also the port where you will be able to access the OpenAPI/Swagger documentation for your ACA-py instance.

`--admin-insecure-mode` Allows you to use the admin web server without api-key. Obviously don't use this in production. Use `--admin-api-key` instead.

`--genesis-url http://localhost:9000/genesis` Points to the VON-network webserver where the genesis file can be found. Other command-line arguments can be used to point to a file on disk for example.

`--seed Laurence000000000000000000000000` Your ACA-py instance will use one public DID which is registered in the ledger. You can create a public DID via the VON-network webserver, it will tell you the seed for the DID you registered. You can also register a DID via [localhost:9000/register](http://localhost:9000/register) and then provide the same seed here.

When you run a production instance of your application, you want this to always be same as that is the seed for your public DID that you paid for to register. When you are developing an application that issues credentials, it is advised to create a new DID every time you start the application as it can cause problems with creating schemas (more on schemas in the next blog post).

`--wallet-type indy` This instructs libindy to create a wallet for you that can communicate with an Indy ledger. If you don't want your agent to communicate with the ledger then you can use `--wallet-type basic`.

`--wallet-name Laurence1` libindy creates a wallet in `~/.indy_client/wallet/<name>` where if you don't provide a name, it will use `default`. If you want to run multiple agents on the same machine, you need to provide unique names to avoid both trying to use `default`.

`--endpoint http://localhost:8000/` This is the URL at which your ACA-py instance will be available for other ACA-py instances to reach. This URL will be used for establishing connections. The protocol, address and port should be the same as for `--inbound-transport`.

`--public-invites` This allows you to use the public DID that is registered in the ledger sending invitations and receiving connection requests.

`--webhook-url http://localhost:4455/webhooks` ACA-py is sending and receiving messages from one instance to another, for example to set up a connection or to issue credentials. Whenever an event in ACA-py happens, a call is done to the webhook URL on different topics, so your application can get live updates and update the interface for example.

`--auto-accept-invites` and `--auto-accept-requests` result in the automatic acceptation of invites, which results in the sending of a connection request, which will be automatically accepted, which results in response after which the connection is established. More on invites and requests in part 3. `--auto-ping-connection` sends a ping message after establishing the connection to mark it as 'active'.

`--debug-connections` When you manually go through the steps of invites and requests, it's a good idea to enable this flag as it gives clear output of what is going on. You can also debug for credentials and presentations.

## Conclusion 

With a development environment like this you can start developing an application that uses ACA-py against a locally running Indy ledger network.

To create an application, you can take different routes, you can:
- create your own calls to the C-callable library (hardcore-mode enabled)
- import python3-indy (or a wrapper of another language) and implement agent-to-agent communication yourself
- talk to ACA-py over HTTP

I am creating a Go client library for ACA-py that communicates over HTTP. After creating the client you can easily perform all actions on ACA-py from Go.

In the In [part 3]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-3-connecting-using-swagger" >}}) I am going to start two agents and create a connection between them.