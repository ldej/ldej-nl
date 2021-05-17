---
title: "Becoming a Hyperledger Aries Developer: Present Proof V2"
date: 2021-03-15T10:29:48+05:30
draft: true
summary:
image: images/ladakh1.webp
tags:
- 

---

TODO: Add update message to V1

```shell
$ aca-py start \
  --label Alice \
  -it http 0.0.0.0 8000 \
  -ot http \
  --admin 0.0.0.0 11000 \
  --admin-insecure-mode \
  --genesis-url http://localhost:9000/genesis \
  --seed Alice000000000000000000000000000 \
  --endpoint http://localhost:8000/ \
  --debug-connections \
  --debug-credentials \
  --debug-presentations \
  --public-invites \
  --auto-provision \
  --auto-accept-invites \
  --auto-accept-requests \
  --auto-ping-connection \
  --auto-respond-credential-proposal \
  --auto-respond-credential-offer \
  --auto-respond-credential-request \
  --auto-store-credential \
  --wallet-type indy \
  --wallet-name Alice \
  --wallet-key secret
```

```shell
$ aca-py start \
  --label Bob \
  -it http 0.0.0.0 8001 \
  -ot http \
  --admin 0.0.0.0 11001 \
  --admin-insecure-mode \
  --endpoint http://localhost:8001/ \
  --genesis-url http://localhost:9000/genesis \
  --debug-connections \
  --debug-credentials \
  --debug-presentations \
  --auto-provision \
  --auto-accept-invites \
  --auto-accept-requests \
  --auto-ping-connection \
  --auto-respond-credential-proposal \
  --auto-respond-credential-offer \
  --auto-respond-credential-request \
  --auto-store-credential \
  --wallet-local-did \
  --wallet-type indy \
  --wallet-name Bob1 \
  --wallet-key secret
```

```shell
$ curl -X POST http://localhost:11000/credential-definitions \
  -H 'Content-Type: application/json' \
  -d '{
    "supports_revocation": true,
    "revocation_registry_size": 10,
    "schema_id": "M6HJ1MQHKr98nuxobuzJJg:2:my-schema:1.0",
    "tag": "default"
  }'
```

```shell
$ curl -X POST http://localhost:11000/issue-credential-2.0/send \
  -H 'Content-Type: application/json' \
  -d '{
  "comment": "Please have this credential",
  "connection_id": "22f8766a-1004-462a-8b90-bed09c6d49f2",
  "credential_preview": {
    "@type": "issue-credential/2.0/credential-preview",
    "attributes": [
      {
        "mime-type": "text/plain",
        "name": "name",
        "value": "Bob"
      },
      {
        "mime-type": "text/plain",
        "name": "age",
        "value": "30"
      }
    ]
  },
  "filter": {
    "dif": {},
    "indy": {
      "cred_def_id": "UpFt248WuA5djSFThNjBhq:3:CL:1006:default2"
    }
  }
}'
```

// Used for connection-less proof
```shell
$ curl -X POST http://localhost:11000/present-proof-2.0/create-request \
  -H 'Content-Type: application/json' \
  -d '{
  "comment": "Can you prove this?",
  "presentation_request": {
    "dif": {},
    "indy": {
      "name": "Proof request",
      "non_revoked": {
        "to": 1615783832
      },
      "nonce": "1234567890",
      "requested_attributes": {
        "0_attrs_uuid": {
          "names": [
            "name",
            "age"
          ],
          "non_revoked": {
            "to": 1615783832
          },
          "restrictions": [
            {
              "cred_def_id": "UpFt248WuA5djSFThNjBhq:3:CL:1006:default2"
            }
          ]
        }
      },
      "requested_predicates": {},
      "version": "1.0"
    }
  }
}'
```

```shell
$ curl -X POST http://localhost:11001/present-proof-2.0/send-proposal \
  -H 'Content-Type: application/json' \
  -d '{
  "comment": "I can prove this",
  "connection_id": "3f9e9137-b051-4c10-b3d2-86a2554f9bd6",
  "presentation_proposal": {
    "dif": {},
    "indy": {
      "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/present-proof/2.0/presentation-preview",
      "requested_attributes": {
      },
      "requested_predicates": {
      }
    }
  }
}'
```

```shell
$ curl -X POST http://localhost:11000/present-proof-2.0/send-request \
  -H 'Content-Type: application/json' \
  -d '{
  "comment": "Can you prove this?",
  "connection_id": "22f8766a-1004-462a-8b90-bed09c6d49f2",
  "presentation_request": {
    "dif": {},
    "indy": {
      "name": "Proof request",
      "non_revoked": {
        "to": 1615783832
      },
      "nonce": "1234567890",
      "requested_attributes": {
        "0_attrs_uuid": {
          "names": [
            "name",
            "age"
          ],
          "non_revoked": {
            "to": 1615783832
          },
          "restrictions": [
            {
              "cred_def_id": "UpFt248WuA5djSFThNjBhq:3:CL:1006:default2"
            }
          ]
        }
      },
      "requested_predicates": {},
      "version": "1.0"
    }
  }
}'
```

```shell
$ curl -X POST http://localhost:11000/present-proof-2.0/records/19cfad8c-23ed-4dc7-a96d-b41220d4f062/send-request \
  -H 'Content-Type: application/json' \
  -d '{"trace": false}'
```

```shell
$ curl -X POST http://localhost:11001/present-proof-2.0/records/80ef31e3-04d5-4cc9-a639-175aa4415c32/send-presentation \
  -H 'Content-Type: application/json' \
  -d '{
  "indy": {
    "requested_attributes": {
      "0_name_uuid": {
        "cred_id": "9efd8304-e2ad-4a23-a7cb-2ce4656c3a42",
        "revealed": true
      }
    },
    "requested_predicates": {},
    "self_attested_attributes": {},
    "trace": false
  }
}'
```

```shell
$ curl -X POST "http://0.0.0.0:11000/present-proof-2.0/records/19cfad8c-23ed-4dc7-a96d-b41220d4f062/verify-presentation" -H "accept: application/json"
```

