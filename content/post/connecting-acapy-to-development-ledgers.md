---
title: "Connecting ACA-py to Development Ledgers"
date: 2020-10-18T10:02:14+05:30
draft: false
summary: Register a public DID and develop against the BCoverin Dev ledger or the Sovrin BuilderNet ledger.
image: images/agra1.webp
tags:
- Decentralization
- Self-Sovereign Identities
- Hyperledger Aries

---

In previous blog posts I talked about setting up your [development environment]({{< relref "/post/becoming-a-hyperledger-aries-developer-part-2-development-environment.md" >}}) for building your own ACA-py controller. I explained how you can run your own Hyperledger Indy nodes locally using VON-network.

My goal is to create three different applications: an application to issue credentials, an application to hold credentials, and an application to verify credentials.

In this blog post I'm going to talk about connecting ACA-py to one of the existing running ledgers.

There are several ledgers for you to connect to for both development and demo purposes. There are several options for configuring ACA-py to connect to a ledger and for registering a DID.

If you are creating an agent that wants to create schemas, credential definitions and issue credentials, you need to have a public DID registered in a ledger. For the Sovrin production ledger this means you need to request it and pay for actions on the ledger. Connecting to and writing to development ledgers is free, however you still need to register a DID. That's what I'm going to explain in this blog post.

## Genesis file

In order to write to a ledger, you require the genesis file. For the Sovrin ledgers you can find the genesis file in their github repo: [github.com/sovrin-foundation/sovrin](https://github.com/sovrin-foundation/sovrin/tree/stable/sovrin).

With the BCoverin ledgers you have two options. You can download the genesis file and load it with `--genesis-file`, or you can give the direct url as `--genesis-url`.

- http://dev.bcovrin.vonx.io/genesis
- http://test.bcovrin.vonx.io/genesis
- http://prod.bcovrin.vonx.io/genesis

## Create a DID for Sovrin BuilderNet using ACA-py and register it on BuilderNet with SelfServe

You can create a DID using ACA-py. When you start ACA-py in provision mode, it will create a DID and verkey for you based in the `--seed` value that you provide.

Start ACA-py with:

```shell script
$ aca-py provision \
  --endpoint https://<your-acapy-public-url>/ \
  --genesis-file ./pool_transactions_builder_genesis \
  --wallet-type indy \
  --wallet-name <your-wallet-name> \
  --wallet-key <your-wallet-key> \
  --seed <your-32-character-seed>
Created new wallet
Wallet type: indy
Wallet name: <your-wallet-name>
Created new public DID: <new-did>
Verkey: <new-verkey>
```

- `--endpoint` This is the public url your ACA-py instance is available on for other agents to connect to. This is __NOT__ the admin endpoint for controlling ACA-py.
- `--genesis-file` As with every blockchain, to join it you require the genesis-file.
- `--wallet-type indy` For now, you require an Indy wallet to connect to a Hyperledger Indy network.
- `--wallet-name` This is the name of your wallet. In case you are not using a Postgres backend for your wallet, it is the name of the folder where your wallet information will be stored. For example `~/.indy_client/wallet/<your-wallet-name`
- `--wallet-key` This is the key required to unlock your wallet. It is a value you can decide yourself, but you need to keep it secret.
- `--seed` This is the seed value that you can choose.

It will then ask you to accept the transaction author agreement:

```shell script
Please select an option:
 1. Accept the transaction author agreement and store the acceptance in the wallet
 2. Acceptance of the transaction author agreement is on file in my organization
 X. Skip the transaction author agreement
[1]>
```

Before you choose an option, head over to [selfserve.sovrin.org](https://selfserve.sovrin.org/) to register the DID and verkey on BuilderNet. When you have done that, choose option 1.

If you choose option 1 before registering your DID and verkey on SelfServe, you will be greeted with an error message:

```
...
aries_cloudagent.ledger.error.LedgerTransactionError: Ledger rejected transaction request: client request invalid: could not authenticate, verkey for <your-verkey> cannot be found
...
aries_cloudagent.commands.provision.ProvisionError: Error during provisioning
```

## Registering a DID on Sovrin BuilderNet using `indy-cli`

To register a DID at the Builder and Staging ledgers, you can use [selfserve.sovrin.org](https://selfserve.sovrin.org/). At the bottom there is a link which describes how you can create a DID. However, the document is not super clear, so I'm going to describe what I did.

I installed the indy-cli on my Ubuntu 18.04 environment:

```shell script
$ sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 68DB5E88
$ sudo add-apt-repository "deb https://repo.sovrin.org/sdk/deb bionic master"
$ sudo apt-get update
$ sudo apt-get install -y indy-cli
``` 

The document describes that you also need `libsovtoken`, however that seems to not be available on Ubuntu 18.04, and it turned out not to be required. The document also describes how to set-up a payment address, but that is also not required.

Create a file called `cliconfig.json`. The document tells you the content should be:
```json
{
   "plugins":  "/usr/lib/libsovtoken.so:sovtoken_init",
   "taaAcceptanceMechanism": "for_session" 
}
```

However, with `libsovtoken` not being available, the `plugins` line is going to result in an error:

```shell script
$ indy-cli --config cliconfig.json
Plugin not found: "/usr/lib/libsovtoken.so"
"for_session" is used as transaction author agreement acceptance mechanism
indy> 
```

Either ignore the error, or remove the `plugins` line from the cliconfig.json.

Download the genesis file for the ledger you want to connect to from [github.com/sovrin-foundation/sovrin](https://github.com/sovrin-foundation/sovrin/tree/stable/sovrin). For Builder this is `pool_transactions_builder_genesis`.

Start indy-cli and configure the ledger you want to connect to:
```shell script
$ indy-cli --config cliconfig.json
indy> pool create buildernet gen_txn_file=pool_transactions_builder_genesis
(-> only run this the first time)
```

Connect to BuilderNet, it will ask you if you want to view the license, select `y`, and then accept it by choosing `y`:
```shell script
indy> pool connect buildernet
Would you like to read it? (y/n)
(-> select y)
Would you like to accept it? (y/n)
(-> select y)
```

Create a wallet and open it:
```shell script
indy> wallet create <some-name> key=<some-key>
indy> wallet open <some-name> key=<some-key>
```

Generate a DID
```shell script
indy> did new
```

You can also provide a seed value for your DID
```shell script
indy> did new seed=<32 character secret seed>
```

Then go to [selfserve.sovrin.org](https://selfserve.sovrin.org/), select BuilderNet, enter the DID and verkey that you just generated, and leave the payment address empty and submit. At that moment, the DID will be registered in the ledger. You local wallet contains the keys that allow you to do things like register schema's and credential definitions. With the did registered, you can run:

```shell script
indy> ledger get-nym did=<your-did>
```  

Then, you can configure that DID as the public did in your wallet using:
```shell script
indy> did use <your-did>
```

You should then also be able to register a schema:

```shell script
indy> ledger schema name=MyFirstSchema version=1.0 attr_names=FirstName,LastName,Address,Birthdate,SSN
```

## Registering a DID on BCoverin Dev

A DID can only be registered via a DID that has the right permissions to write to the ledger. In the case of the BCoverin ledgers, there is a ledger browser that allows you to register a DID.

The BCoverin project has three environments. At each of these web pages there is an option for you to register a new DID on the ledger.

- http://dev.bcovrin.vonx.io/
- http://test.bcovrin.vonx.io/
- http://prod.bcovrin.vonx.io/

You can register your DID based on a seed that you can decide yourself. Store this seed value as this is what you need to start your aca-py.

## Provisioning

ACA-py has a `provision` argument. This is what they say about provisioning in the "Becoming a Hyperledger Aries Developer" course:

> An agent is a stateful component that persists data in its wallet and to the ledger. When an agent starts up for the very first time, it has no persistent storage and so it must create a wallet and any ledger objects it will need to fulfill its role. When we’re developing an agent, we’ll do that over and over: start an agent, create its state, test it, stop it and delete it. However, when an agent is put into production, we only initialize its state once. We must be able to stop and restart it such that it finds its existing state, without having to recreate its wallet and all its contents from scratch.
> 
> Because of this requirement of a one time “start from scratch” and a many times “start with data,” ACA-Py provides two major modes of operation, provision and start. __Provision is intended to be used one time per agent instance to establish a wallet and the required ledger objects. This mode may also be used later when something new needs to be added to the wallet and ledger, such as an issuer deciding to add a new type of credential they will be issuing__. Start is used for normal operations and assumes that everything is in place in the wallet and ledger. If not, it should error and stop—an indicator that something is wrong.
> 
> The provision and start separation is done for security and ledger management reasons. Provisioning a new wallet often (depending on the technical environment) requires higher authority (e.g. root) database credentials. Likewise, creating objects on a ledger often requires the use of a DID with more access permissions. By separating out provisioning from normal operations, those higher authority credentials do not need to be available on an ongoing basis. As well, on a production ledger such as Sovrin, there is a cost to write to the ledger. You don’t want to be accidentally writing ledger objects as you scale up and down ACA-Py instances based on load. We’ve seen instances of that.
>
> __(emphasis mine)__

To me, it sounds like provisioning should be used to set up a local wallet, a schema and a credential definition. However, only setting up a local wallet seems to be part of the provision mode of ACA-py. This means that registering a schema and credential definition should be part of the provisioning step of your application. More on that in a later post.

If you have set up a wallet using aca-py or indy-cli, your wallet will be configured already and if you use the basic storage mode, you should be able to find your wallet in `~/.indy_client/wallet/<your-wallet-name>`. In that case you can start ACA-py with the same `--wallet-name` and `--wallet-key` as you provided when you registered a DID.

If you have registered a DID using a BCoverin browser, you can use the `provision` mode of ACA-py to create a wallet configured for the BuilderNet ledger with the seed value that the BCoverin browser gave you.

You can use provision mode like:

```shell script
$ aca-py provision \
  --endpoint https://<your-acapy-public-url>/ \
  --genesis-file ./pool_transactions_builder_genesis \
  --wallet-type indy \
  --wallet-name <your-wallet-name> \
  --wallet-key <your-wallet-key> \
  --seed <your-32-character-seed>
Created new wallet
Wallet type: indy
Wallet name: <your-wallet-name>
Created new public DID: <new-did>
Verkey: <new-verkey>
```

Running the same command twice will not cause any problems, as the provision tool will verify that you have the private keys for the public DID in your wallet and that nothing needs to be done.

When you run the provision command, it will ask you to accept an agreement.

## Ledgers to connect

I have found 6 public Hyperledger Indy networks.

The Government of British Columbia has three:

- http://dev.bcovrin.vonx.io/
- http://test.bcovrin.vonx.io/
- http://prod.bcovrin.vonx.io/

And then there are the Sovrin ledgers:

- Sovrin Builder
- Sovrin Staging
- Sovrin Prod

Which of these you want to use for development is up to you. However, if you want to create an agent that issues credentials, and you want to receive and store these credentials with an existing Android/iOS app, then you need to know which apps are compatible with which ledgers.

| Mobile client                     | BCoverin Dev | BCoverin Test      | BCoverin Prod | Sovrin Builder     | Sovrin Staging     | Sovrin Production  |
| --------------------------------- | ------------ | ------------------ | ------------- | ------------------ | ------------------ | ------------------ |
| [Trinsic](https://trinsic.id/)    |              | :heavy_check_mark: |               | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| [Connect.me](https://connect.me/) | ?            | ?                  | ?             | ?                  | ?                  | ?                  |
| [Esatus](https://esatus.com/)     | ?            | ?                  | ?             | ?                  | ?                  | ?                  |
| [Lissi](https://lissi.id/)        | ?            | ?                  | ?             | ?                  | ?                  | ?                  |
| ?                                 |              |                    |               |                    |                    |                    |

## Finding your transaction

Once you have registered a DID, you can find the transaction that registers your DID. For BCoverin you can do that by going to the ledger browser of the respective ledger:
- http://dev.bcovrin.vonx.io/
- http://test.bcovrin.vonx.io/
- http://prod.bcovrin.vonx.io/

Go to "Domain", select Type: "NYM", and enter your DID in the Filter field.

For the Sovrin ledgers, you can go to [indyscan.io](https://indyscan.io/). Select your network, select the Subledger "Domain", select "NYM" and search for your DID.

## Starting ACA-py

After creating a public DID, you can start ACA-py with the same parameters that you used for provisioning. Use the same parameters for `--genesis-file`, `--wallet-type`, `--wallet-name`, `--wallet-key`.

## Conclusion

Now that you have created a public DID and configured ACA-py to connect to a hosted ledger, it is time to create a controller that can issue credentials. More on that in the next blog post.