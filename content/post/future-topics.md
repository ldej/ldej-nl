---
title: "Future Topics"
date: 2020-07-21T11:29:48+05:30
draft: true

#reddit:
#  created: 1594708583 
#  url: https://www.reddit.com/r/ldej/comments/hqwgj8/discuss_working_in_the_trenches/
#  title: "Working in the Trenches"
---

- Migrations in Go with Liquibase (https://www.calhoun.io/database-migrations-in-go/)
- Migrations in Go with https://github.com/golang-migrate/migrate and Spanner
- Building the issuer
- libp2p logical clocks

- SSI business side https://sgershuni.medium.com/bullish-case-for-self-sovereign-identity-c2c26857f0ab

- IPFS
- https://github.com/evanw/esbuild
- Hugo extensions
- Go-wasm
- gRPC
- AppEngine
- go-kit
- https://ewanvalentine.io/microservices-in-golang-part-1/
- https://withblue.ink/2019/03/20/hugo-and-ipfs-how-this-blog-works-and-scales.html
- https://lpfann.me/post/decentralized-site/
- https://tarunbatra.com/blog/decentralization/Deploy-your-website-on-IPFS-Why-and-How/
- https://teetotality.blog/posts/how-this-blog-was-made/
- https://medium.com/pinata/what-is-an-ipfs-pinning-service-f6ed4cd7e475
- https://medium.com/textileio/easy-personal-ipfs-pinning-service-with-textile-9d366da4e420
- https://pinata.cloud/


- postgres as a wallet backend for indy-cli and ACA-py

## Postgres

Running aca-py with `--wallet-storage-type postgres_storage`

`OSError: libindystrgpostgres.so: cannot open shared object file: No such file or directory`

```
$ sudo apt install -y cargo libzmq3-dev
$ cd indy-sdk/experimental/plugins/postgres_storage
$ cargo build
$ export LD_LIBRARY_PATH=/home/laurencedejong/projects/aries-developer/indy-sdk/experimental/plugins/postgres_storage/target/debug
```

## Create a new public DID with indy-cli

```
$ sudo apt install -y indy-cli

$ indy-cli --config cliconfig.json
indy> pool create buildernet gen_txn_file=pool_transactions_builder_genesis
(only the first time)

indy> pool connect buildernet
Would you like to read it? (y/n)
(select y)
Would you like to accept it? (y/n)
(select y)

indy> wallet create issuer key=issuer
indy> wallet open issuer key=issuer
indy> did new (seed=<32 character secret seed> optional)
 -> Go to https://selfserve.sovrin.org/ and enter the did and verkey
 -> {"statusCode":200,"headers":{"Access-Control-Allow-Origin":"*"},"body":"{\"statusCode\": 200, \"DjPCcebRjN4XRA2F7gR8hw\": {\"status\": \"Success\", \"statusCode\": 200, \"reason\": \"Successfully wrote NYM identified by DjPCcebRjN4XRA2F7gR8hw to the ledger with role ENDORSER\"}}"}
indy> ledger get-nym did=DjPCcebRjN4XRA2F7gR8hw
indy> did use DjPCcebRjN4XRA2F7gR8hw
indy> ledger schema name=MyFirstSchema version=1.0 attr_names=FirstName,LastName,Address,Birthdate,SSN
```

## Using indy-cli with postgres

```
LD_LIBRARY_PATH=/home/laurencedejong/projects/aries-developer/indy-sdk/experimental/plugins/postgres_storage/target/debug indy-cli --config cliconfig.json
indy> load-plugin library=/home/laurencedejong/projects/aries-developer/indy-sdk/experimental/plugins/postgres_storage/target/debug/libindystrgpostgres.so initializer=postgresstorage_init
indy> wallet create wallet_psx key storage_type=postgres_storage storage_config={"url":"localhost:5432"} storage_credentials={"account":"postgres","password":"mysecretpassword","admin_account":"postgres","admin_password":"mysecretpassword"}
indy> wallet open wallet_psx key storage_credentials={"account":"postgres","password":"mysecretpassword","admin_account":"postgres","admin_password":"mysecretpassword"}
```
