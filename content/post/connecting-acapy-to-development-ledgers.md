---
title: "Connecting ACA-py to Development Ledgers"
date: 2020-10-18T10:02:14+05:30
draft: false
summary: Register a public DID and develop against the BCoverin Dev ledger or the Sovin BuilderNet ledger.
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

## Provisioning

To register a public DID, ACA-py provides a special provisioning mode:

```shell script
$ aca-py provision
```

In provisioning mode, a public DID can be registered in the ledger, and the wallet will be configured for that ledger. It requires a couple of command line parameters:

```shell script
$ aca-py provision \
  --endpoint https://<your-acapy-public-url>/ \
  --genesis-file ./pool_transactions_builder_genesis \
  --wallet-type indy \
  --wallet-name <your-wallet-name> \
  --wallet-key <your-wallet-key> \
  --seed 000000000000000000000000Trustee1
Created new wallet
Wallet type: indy
Wallet name: <your-wallet-name>
Created new public DID: V4S...
Verkey: GJ1...
```

- `--endpoint` This is the public url your ACA-py instance is available on for other agents to connect to. This is __NOT__ the admin endpoint for controlling ACA-py.
- `--genesis-file` As with every blockchain, to join it you require the genesis-file.
- `--wallet-type indy` For now, you require an Indy wallet to connect to a Hyperledger Indy network.
- `--wallet-name` This is the name of your wallet. In case you are not using a Postgres backend for your wallet, it is the name of the folder where your wallet information will be stored. For example `~/.indy_client/wallet/<your-wallet-name`
- `--wallet-key` This is the key required to unlock your wallet. It is a value you can decide yourself, but you need to keep it secret.
- `--seed 000000000000000000000000Trustee1` This is the seed of the node that lets you write a new public DID onto the ledger. You can read more about it in [this stackoverflow post](https://stackoverflow.com/questions/59089178/hypelerdger-indy-node-seed-value).

Running the same command twice will not cause any problems, as the provision tool will verify that you have the private keys for the public DID in your wallet and that nothing needs to be done.

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

## Genesis file

In order to write to a ledger, you require the genesis file. For the Sovrin ledgers you can find the genesis file in their github repo: [github.com/sovrin-foundation/sovrin](https://github.com/sovrin-foundation/sovrin/tree/stable/sovrin).

With the BCoverin ledgers you have two options. You can download the genesis file and load it with `--genesis-file`, or you can give the direct url as `--genesis-url`.

- http://dev.bcovrin.vonx.io/genesis
- http://test.bcovrin.vonx.io/genesis
- http://prod.bcovrin.vonx.io/genesis

## SelfServe

Another options for registering a DID is by going to https://selfserve.sovrin.org/. There is a link to a Google Document that explains how you can register a DID using `indy-cli`. These steps are more involved than using ACA-py provisioning.

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

Now that we have created a public DID and configured ACA-py to connect to a hosted ledger, it is time to create a controller that can issue credentials. More on that in the next blog post.