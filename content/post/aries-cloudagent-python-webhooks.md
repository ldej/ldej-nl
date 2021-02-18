---
title: "Aries Cloud Agent Python (ACA-py) Webhooks"
date: 2021-01-28T10:21:39+05:30
draft: false
summary: An overview of the webhook events that ACA-py sends, with examples of a JSON body for each event.
image: images/agra6.webp
tags:
- Decentralization
- Self-Sovereign Identities
- Hyperledger Aries
- aries-cloudagent-python
- ACA-py
- webhooks
---

ACA-py instances communicate with each other, for example while establishing a connection, when issuing credentials or when presenting proof. Your controller (your application that talks to ACA-py) can retrieve the data of these events by making calls to the HTTP endpoints. However, ACA-py can also notify your controller when an event occurred. It supports webhooks which allow you to immediately get an update of what happened. In this post I'll talk you through the webhooks functionality as the [documentation](https://github.com/hyperledger/aries-cloudagent-python/blob/master/AdminAPI.md#administration-api-webhooks) seems to be lacking.

## Parameter

ACA-py supports a command-line parameter to set up webhooks.

`--webhook-url <url#api_key>` Send webhooks containing internal state changes to the specified URL. Optional API key to be passed in the request body can be appended using a hash separator `#`. This is useful for a controller to monitor agent events and respond to those events using the admin API. If not specified, webhooks are not published by the agent.

If you configure the parameter like `--webhook-url http://localhost:10000/webhooks`, ACA-py will make HTTP `POST` requests to `http://localhost:10000/webhooks/topics/{topic}`. This means that you can decide the path at which your controller will receive the webhook calls, so you can make endpoints that receive the calls.

The body of the `POST` request contains a serialized JSON object that can be deserialized to parse the event.

## Topics

Each topic that is used for a webhook is related to a certain event or update of a record in ACA-py. There is [documentation](https://github.com/hyperledger/aries-cloudagent-python/blob/master/AdminAPI.md#administration-api-webhooks) available for at least four topics, but after experimenting and searching the code I have found 9 topics.

### Out-of-Band Invitation (`oob_invitation`)

The first webhook you can encounter is the `oob_invitation` webhook. The event is triggered when you create en invitation using the `/out-of-band/create-invitation` endpoint. 

The only `state` I have seen for this event is `initial`. This is probably because at the same time a `Connection` record is created, and when the invitation is accepted, the `Connection` record is updated and not the `Invitation` record. There are no endpoints for retrieving `Invitation` records.

Example JSON body:

```json
{
  "invitation": {
    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/out-of-band/1.0/invitation",
    "@id": "86e3dafc-74cd-4c6b-b530-c1e85be99b38",
    "handshake_protocols": [
      "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/didexchange/v1.0"
    ],
    "label": "Alice",
    "service": [
      {
        "id": "#inline",
        "type": "did-communication",
        "recipientKeys": [
          "did:​key:z6Mkqh37jGK9wmsswpHbWAk6E7vX275881CNZfikXsQ5VxTz"
        ],
        "serviceEndpoint": "http://localhost:4456/"
      }
    ]
  },
  "invitation_id": "fcc8d308-84cf-44fd-8dd8-8ddc97dbc364",
  "auto_accept": false,
  "state": "initial",
  "invi_msg_id": "86e3dafc-74cd-4c6b-b530-c1e85be99b38",
  "updated_at": "2021-01-27 06:27:47.721227Z",
  "invitation_url": "http://localhost:4456/?oob=eyJAdHlwZSI6ICJkaWQ6c292OkJ6Q2JzTlloTXJqSGlxWkRUVUFTSGc7c3BlYy9vdXQtb2YtYmFuZC8xLjAvaW52aXRhdGlvbiIsICJAaWQiOiAiODZlM2RhZmMtNzRjZC00YzZiLWI1MzAtYzFlODViZTk5YjM4IiwgImhhbmRzaGFrZV9wcm90b2NvbHMiOiBbImRpZDpzb3Y6QnpDYnNOWWhNcmpIaXFaRFRVQVNIZztzcGVjL2RpZGV4Y2hhbmdlL3YxLjAiXSwgImxhYmVsIjogIkFsaWNlIiwgInNlcnZpY2UiOiBbeyJpZCI6ICIjaW5saW5lIiwgInR5cGUiOiAiZGlkLWNvbW11bmljYXRpb24iLCAicmVjaXBpZW50S2V5cyI6IFsiZGlkOmtleTp6Nk1rcWgzN2pHSzl3bXNzd3BIYldBazZFN3ZYMjc1ODgxQ05aZmlrWHNRNVZ4VHoiXSwgInNlcnZpY2VFbmRwb2ludCI6ICJodHRwOi8vbG9jYWxob3N0OjQ0NTYvIn1dfQ==",
  "trace": false,
  "created_at": "2021-01-27 06:27:47.721227Z",
  "multi_use": false
}
```

### Connection Record Updated (`connections`)

Whenever a `Connection` record is updated, a `connections` webhook will be called. Every state change results in an event. The states for `"state"` that trigger an event are:

- `invitation`
- `request`
- `response`
- `active`
- `completed`

The values for `rfc23_state` are:

- `invitation-sent`
- `invitation-received`
- `request-sent`
- `request-received`
- `response-sent`
- `response-received`
- `completed`

Example JSON body:

```json
{
  "alias": "Alice",
  "connection_id": "f02264d0-f015-492f-b203-20293e6b38e0",
  "their_label": "Alice",
  "rfc23_state": "invitation-received",
  "state": "invitation",
  "updated_at": "2021-01-27 05:33:47.059663Z",
  "routing_state": "none",
  "invitation_mode": "once",
  "created_at": "2021-01-27 05:33:47.059663Z",
  "accept": "manual",
  "their_role": "inviter"
}
```

### Ping (debug) (`ping`)

There is a debug option `--monitor-ping` to receive a webhook call for when a ping message is received. A ping message is originally used in the Aries RFC0160 Connection Protocol to mark a connection as `active`. However, with Aries RFC0023 this is not required anymore. 

Example JSON body:

```json
{
  "comment": "ping",
  "connection_id": null,
  "responded": true,
  "state": "received",
  "thread_id": "6d207908-4adb-4ff3-b2ac-e9b4086fc08d"
}
```

### Basic Message Received (`basicmessages`)

Basic messages can be sent using the `/connections/{id}/send-message` endpoint. The messages will not be stored and can only be received by listening to the `basicmessages` webhook.

Example JSON body:

```json
{
  "connection_id": "281003eb-2d14-4851-8cc5-8dc791db2e4c",
  "message_id": "cd4ea8cb-be71-4fc9-84c0-ef552fce899e",
  "content": "Hi Bob",
  "state": "received"
}
```

### Credential Exchange Record Updated (`issue_credential`)

The `issue_credential` topic is used when an update to a `CredentialExchange` record occurs. With different states more fields of the event will be filled. The `state`s I've seen an event for are:

- `offer_sent`
- `offer_received`
- `request_sent`
- `request_received`
- `credential_issued`
- `credential_received`
- `credential_acked`

Example JSON body:

```json
{
  "credential_proposal_dict": {
    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/1.0/propose-credential",
    "@id": "bdf3e176-f603-4c17-9d00-808a6bb1a81d",
    "credential_proposal": {
      "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/1.0/credential-preview",
      "attributes": [
        {
          "name": "age",
          "mime-type": "text/plain",
          "value": "30"
        },
        {
          "name": "name",
          "mime-type": "text/plain",
          "value": "Bob"
        }
      ]
    },
    "comment": "I can give you this",
    "cred_def_id": "717CTkVDFaxxM9ShojzkDN:3:CL:637:tag"
  },
  "initiator": "self",
  "auto_offer": false,
  "credential_exchange_id": "9e9d171d-c699-4bd5-8a0b-9f798eebc2cc",
  "credential_offer_dict": {
    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/1.0/offer-credential",
    "@id": "4076cdee-8181-46cc-89b3-4d35e7eebd3f",
    "~thread": {},
    "comment": "I can give you this",
    "credential_preview": {
      "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/1.0/credential-preview",
      "attributes": [
        {
          "name": "age",
          "mime-type": "text/plain",
          "value": "30"
        },
        {
          "name": "name",
          "mime-type": "text/plain",
          "value": "Bob"
        }
      ]
    },
    "offers~attach": [
      {
        "@id": "libindy-cred-offer-0",
        "mime-type": "application/json",
        "data": {
          "base64": "eyJzY2hlbWFfaWQiOiAiNzE3Q1RrVkRGYXh4TTlTaG9qemtETjoyOkZvckJvYjoxLjAiLCAiY3JlZF9kZWZfaWQiOiAiNzE3Q1RrVkRGYXh4TTlTaG9qemtETjozOkNMOjYzNzp0YWciLCAia2V5X2NvcnJlY3RuZXNzX3Byb29mIjogeyJjIjogIjc2NzI0MTI3OTMxMjMzNTI1NzM1Nzk2OTAzMjIyODY2Mzk0NzM4NTA3OTYwMDU4NTI3ODExMDI5OTI5OTgwNzk1MTk3NDk1ODQzMDAiLCAieHpfY2FwIjogIjE2NDkyODE5OTY1NzUzNjUzNzQ3MzE1OTc3Njk4ODU5MTk5MjY4MTc5MzM3MTUxMzYwMzIzNjM5MTE4MzMyMTI2MTI0OTI1ODg5MDA0MDE2OTE5Mzk3NjYzNzI1NDQwMjk3NjA4MTUxMjEyMjcwMzYyNTQzODYyOTg0NDIyOTI3NTY3NTQ1NzI1ODI5MjI5OTkwODIzMTc4MTYxMDY1NjE1MzcwMDExMTIzNzg5MDE1NTQ3OTUwMjE0MDQ0Mjk3NTMyODg4NjEzNDYwMDI1MDU0MzE1OTU4MDcxNTQwODc5NDQyMzY1NzExNTkyMTcxNTc5NTk5MzMyNjk4Mjg0Njc5MTU4ODg0MTgyMzA3MTc5MzY0NzI0ODYxNDM5MTg5MDEzMTk4ODg2OTU0Mjc4OTc1MDE0NTg5NzYzNTAyODQ5MTk4OTU1ODAwOTg3NDAxMjk5OTQ1NTk4MTg0NTAwMzM2MzEzMjMwNzE2MDAwMDkwNDQ2OTI5OTU4ODYwMjU3MjY5NTI1NDg2NTMzMjQ3MjM3MjcxMDMxODk4NzY4MjI4MTM5NDU4MDQyMDI3ODUxOTcyMTAyOTU0OTQ4NzE1MjU2MDQ2MDc3Mzg3NjU0MzU4MzM2MzYwNTc1MDEyNDc1MDQwMDk5NDkzMDgyODYxNjk1NTk5ODgwMjgxMTQwOTg3Njc3MDkyMDM1MTQ2Njc5NjIyMzk0NTUwMDc0OTg1ODEwMjIyNzEyMjM5NTk4MTY2NjQ3MjAwNjEzODI4ODUyNjI2NjQ4Mjk2MDAxMzgwNzM3NjE5MjMxMTY0NjA1MDAxMTQ4MjU4MzEyNjk2NzU2NDE0OTUwMjY4ODE2NDI4MTYzMDMxOTAzMjU5Nzg4NTc1NDgxMDUyMzc3MTE4NDc3NjM4NjQ0NDA4NTQzOTM2NDkyMzMiLCAieHJfY2FwIjogW1siYWdlIiwgIjE0MDc1NzYxODMxODA4NzE4NjIyNjYwNTY0OTMwNTg4MTE0Njg5NDg0OTk5OTI2NTEzNjExMTI5NzI5MzE3MzgzOTEzNjEzNTUxMjAwNzQ2NTY0OTI5ODYzMjIwODUwODg3NDY3MDczNDAyNDA3NTA5ODk1NDM5MDA2MTU1NTU4OTYzNTAyMDMxNjgwNjI2MTM2MjEwOTMwMjgxMTU2MjkxMTMyMTc1NTIwMjM3OTY4OTE5Mjg5MzQ4NTM0NjMzMDQyOTAzNDExMjQwMjQyNzgzMDYyMjgyNTE0OTg2NTY5MTA4ODkzNTM5NzIwNTYzMzc2MDE4MjU2NjY2MzYzODEzOTEyMTI1NjQxNjM3MjYwMDMzMTg3NzUyMzYwMDczNjA4NzExNzk5MDQ3MjQ1MDA4NzA0Njc0MjEyNjM1NTI4ODUzMjg3ODYwNjM4NDUxMzQwNjYwOTMzMzg2OTc3MDQ0NzcwODIxMjIyMTgwMDEwNjk3NDAxNDI3ODA2MDExOTIzMjUyMTA2Njg0MDAwNDIxNzM2NzAzMDg2Nzg3NzUyMzY1OTMxOTA4MzQ1MzMwNzgzODI4NjQ1NTk5MDk1NjY3ODY0NDk4MjYwNTgxODEyNzE4NzI5NjkxNDQ5MTQyOTMxMzU3NzEzNjM1NzA4NDcwNDQyMjY0MDI2ODk5NDI5NDI4NTUyNTEyMTY3ODI5MDUxODA4MjA0NDc3ODMyNzQxOTc1MzY1MjY2MzQzMTQ2NDI0MTI0Njc2NjIwMTg4OTYyMjYyODIzNTI4NzQ0MjAyOTY3MTEwMzI4ODI2NTQ3MTI4NDY2MTM3NzUxNTE1MzQ4MTQ4NzY1NDYxMTY4ODE4MTExNDEwNTg4MDg5OTA5NzE5NDk4ODI2NDI2MTA0NTM4MDMzNzU2NjIyMzM3MDI2NDI5OSJdLCBbIm1hc3Rlcl9zZWNyZXQiLCAiNTM4MjYzMDY0NDUxMzk0NzM0MDQ0NTU0ODIyODY1MzA2NjA3NjQ3NTA1MzQ1NDk1MjgxNDQ5NzQ3OTkzOTQwMzU4NDc0NDk0NDc0OTI4MTAyNjM3MDExMzU1OTc4NjgxNjQ2ODA0MzkwNjYyMDIwNDA1Njg0MDI1ODczOTExMjg3NDUwMzMwMDQ0MDA3MDExNTUxMjU5MzMwNjE1MDQ2MDY5NTg5NDAwMTM2MTA4ODUwNjg2ODkxNTU1NzE1ODMwNDU1NTA5MjQwNjA5NTQ5MjYyNjUyNzc0OTY5MDcxMTM1NDkzNzk0NDUwMjg0MDQ3ODMwMDUxMTY5OTk3OTY1NzIxMTc4MzQ2ODUxOTc2Nzg3MDI5NTA4NTY2MzQ2NDc5NzUxMDc5NzM0Nzc5NTA3NjMwMDAxMTMxMDUxODU2Mjg4NjM2ODg3MTY3ODAxNTE1MzIyMDQ1MjQ4MTMxMzc5ODgxMDkxMDM3NjkzMTg5NTgxOTE0OTExMzYwOTg1NDM3OTM1NjkxMzg1OTQxNjk3ODE4NTY5NzcyMTI1NDA4MzMxNTk5MDI2ODU3NDYwMzY0NDc4NDY2MTA2MDMzNTI5MTY5MzY4NzQyMTE1NjMzNDUyNzczMTAxNjU3NTMyMjQyNTg2NjkyODUzNTkzOTc2MDQ3OTExOTY0NzgxMjMwNjQ1NDE2MTY0MjQ3NDMwMzA2NzA3MzA1MDU4NDc1MDQwMTg4MjgwMDgxNzk0OTQ2MTY3NDAyOTkxMzIyMjM3NDYxNzEyMDk2NzE5MTE4MjcwNjEzNjU3NjEwODc4MzQ3MjQwOTU0NTcwMjcyOTA0NzE4NDIyMTc3MzY4OTgwNjAwNzM2Nzg3MjYxNjExMjE4MTI1MDA1Njk3NzE5MDIwNzAxMzUyNTk3NTYwOTg0MDAxNTAyNzYiXSwgWyJuYW1lIiwgIjk4NjczODAyMjc4NzEyNDc4NjExMDg2OTE1NjEzODgxNTA0NzI5NDA3MzczNzAxMjg3MTUyMDA1NzQwODI0MzgzOTAyMTIzNzcyNjUwNDA3MDUxNDY1MTgwNTM2MDg0NTA3MTcwODAxMzE1MTE4NjM3MDc0MDEwMTg2MzAzNDEyMTczNzk1OTI1MDI4Mzc0MTY4Njk1NDAxODA4ODI4NDExMTcxMzU3ODM2MDQ0MzA4ODUzMTIzODMzMDg3NDgzNTgyNDU3MTEyMDc0Mjk3OTgzNjU4NDc1OTM2NzMwNzIxNDIyODEzOTE4OTE3MDAyMTI5OTkxMzI4NTMwNjIyNTg0NzMzOTIxMTM3NDE4ODMwOTQ3MjI5NDQ5NDU0ODU3OTk4NDYxNjIyODI1ODA0Njc4MDc2NDEyNzM3MDQxNDA3OTgwNzQ4ODEyODA1MjQ4MDMxNzg4NTI5NTI5OTk0MzA1NTgyODQ4NTAwMzA1OTgxMzQxNTA0ODk2NjM5NTE5NjI5ODQ0MzQ2NzkxMzcwNTY1Njg4ODM5NzA0MjkwNjE2Mzc3NTEzNTc3MDM2OTU2MjYzMTk0MTUzOTMwNzI5MTY1NDkwOTkzMjkyODk3ODg1MTkyNTEzNTIyNjMzNzAxMDU4MDczMzc5OTExNzkxMDU1MjgyMDgwMDYyNDEzMDUxMDY2MDMxODIxOTI4MzcyNzk2NTI3NzEwODczMDM2Nzk0NDM5NjU0Mjk3OTM4ODYwMjcyMjE5MTMwOTY5MDg3MDcwNzk0MjkzMDkxNDUxOTIzMjk1MTQ3MTE5MTA3ODY3NzA3NDE0Njk1NjQyNjE3NDg0Mjg3NDk2MDYyNjc4ODM4MjA4MjEwOTU0NDM0MDQ3MTAxNTcxMjQ3MjMxNTg4MDQ0MzcwNjMzNzU1NzE5Mzk4ODU1Il1dfSwgIm5vbmNlIjogIjU0ODU1NzQzMTYwNTA0NjkwODcxMTM5MCJ9"
        }
      }
    ]
  },
  "state": "offer_sent",
  "credential_definition_id": "717CTkVDFaxxM9ShojzkDN:3:CL:637:tag",
  "role": "issuer",
  "credential_offer": {
    "schema_id": "717CTkVDFaxxM9ShojzkDN:2:ForBob:1.0",
    "cred_def_id": "717CTkVDFaxxM9ShojzkDN:3:CL:637:tag",
    "key_correctness_proof": {
      "c": "7672412793123352573579690322286639473850796005852781102992998079519749584300",
      "xz_cap": "1649281996575365374731597769885919926817933715136032363911833212612492588900401691939766372544029760815121227036254386298442292756754572582922999082317816106561537001112378901554795021404429753288861346002505431595807154087944236571159217157959933269828467915888418230717936472486143918901319888695427897501458976350284919895580098740129994559818450033631323071600009044692995886025726952548653324723727103189876822813945804202785197210295494871525604607738765435833636057501247504009949308286169559988028114098767709203514667962239455007498581022271223959816664720061382885262664829600138073761923116460500114825831269675641495026881642816303190325978857548105237711847763864440854393649233",
      "xr_cap": [
        [
          "age",
          "140757618318087186226605649305881146894849999265136111297293173839136135512007465649298632208508874670734024075098954390061555589635020316806261362109302811562911321755202379689192893485346330429034112402427830622825149865691088935397205633760182566663638139121256416372600331877523600736087117990472450087046742126355288532878606384513406609333869770447708212221800106974014278060119232521066840004217367030867877523659319083453307838286455990956678644982605818127187296914491429313577136357084704422640268994294285525121678290518082044778327419753652663431464241246766201889622628235287442029671103288265471284661377515153481487654611688181114105880899097194988264261045380337566223370264299"
        ],
        [
          "master_secret",
          "53826306445139473404455482286530660764750534549528144974799394035847449447492810263701135597868164680439066202040568402587391128745033004400701155125933061504606958940013610885068689155571583045550924060954926265277496907113549379445028404783005116999796572117834685197678702950856634647975107973477950763000113105185628863688716780151532204524813137988109103769318958191491136098543793569138594169781856977212540833159902685746036447846610603352916936874211563345277310165753224258669285359397604791196478123064541616424743030670730505847504018828008179494616740299132223746171209671911827061365761087834724095457027290471842217736898060073678726161121812500569771902070135259756098400150276"
        ],
        [
          "name",
          "98673802278712478611086915613881504729407373701287152005740824383902123772650407051465180536084507170801315118637074010186303412173795925028374168695401808828411171357836044308853123833087483582457112074297983658475936730721422813918917002129991328530622584733921137418830947229449454857998461622825804678076412737041407980748812805248031788529529994305582848500305981341504896639519629844346791370565688839704290616377513577036956263194153930729165490993292897885192513522633701058073379911791055282080062413051066031821928372796527710873036794439654297938860272219130969087070794293091451923295147119107867707414695642617484287496062678838208210954434047101571247231588044370633755719398855"
        ]
      ]
    },
    "nonce": "548557431605046908711390"
  },
  "schema_id": "717CTkVDFaxxM9ShojzkDN:2:ForBob:1.0",
  "thread_id": "4076cdee-8181-46cc-89b3-4d35e7eebd3f",
  "created_at": "2021-01-27 09:55:43.639933Z",
  "auto_issue": false,
  "connection_id": "c807d0b6-fbf2-430c-a566-364c3f14fcc6",
  "auto_remove": false,
  "updated_at": "2021-01-27 09:55:43.639933Z",
  "trace": false
}
```

### Issuer Credential Revocation (`issuer_cred_rev`)

When a credential has been issued, an update is done to the revocation registry. The `issuer_cred_rev` event contains the details of the update to the revocation registry for the issued credential. I have seen two `state`s:

- `issued`
- `revoked`

Example JSON body:

```json
{
  "cred_def_id": "4NATxLePbmC7Wu4K1EW9t6:3:CL:669:tag",
  "state": "issued",
  "record_id": "a2c1762d-2799-4299-bdcd-a09ce41062e0",
  "rev_reg_id": "4NATxLePbmC7Wu4K1EW9t6:4:4NATxLePbmC7Wu4K1EW9t6:3:CL:669:tag:CL_ACCUM:e21b66ea-5cba-42df-9234-8ff8ce937e30",
  "updated_at": "2021-01-27 10:33:23.067798Z",
  "cred_ex_id": "74643748-d7ce-43d2-9c4a-5c02cd7bae98",
  "created_at": "2021-01-27 10:33:23.067798Z",
  "cred_rev_id": "1"
}
```

### Credential Exchange Record V2 Updated (`issue_credential_v2_0`)

The `issue_credential` topic is used when an update to a `CredentialExchangeV2` record occurs. With different states more fields of the event will be filled. The `state`s I've seen an event for are:

- `offer-sent`
- `offer-received`
- `request-sent`
- `request-received`
- `credential-issued`
- `done`

Example JSON body:

```json
{
  "cred_issue": {
    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/2.0/issue-credential",
    "@id": "b165c5da-8df8-4dff-80d6-d5a7ef8e59f0",
    "~thread": {
      "thid": "ca7c299b-9289-41e4-acb6-d9c3dd209986"
    },
    "credentials~attach": [
      {
        "@id": "0",
        "mime-type": "application/json",
        "data": {
          "base64": "eyJzY2hlbWFfaWQiOiAiVmJWTHJGbTRycm0xYlJSdnpqZ1pNTDoyOkJvYjoxLjAiLCAiY3JlZF9kZWZfaWQiOiAiVmJWTHJGbTRycm0xYlJSdnpqZ1pNTDozOkNMOjEwMDQ6dGFnIiwgInJldl9yZWdfaWQiOiBudWxsLCAidmFsdWVzIjogeyJuYW1lIjogeyJyYXciOiAiQm9iIiwgImVuY29kZWQiOiAiOTMwMDYyOTAzMjU2Mjc1MDgwMjI3NzYxMDMzODYzOTU5OTQ3MTI0MDE4MDk0Mzc5MzA5NTc2NTIxMTEyMjEwMTU4NzIyNDQzNDUxODUifX0sICJzaWduYXR1cmUiOiB7InBfY3JlZGVudGlhbCI6IHsibV8yIjogIjEwOTM2OTQwODQ2MjM2Mzc0MjQ1NTAxNjgzOTE3MTE1NjU3OTM5MjY4MjIyMzU4NDIyNjUyODEyNzk5MjI0MDU0NTA4ODIwOTIyOTY4MyIsICJhIjogIjk0MTEwOTI1MDM4NzI0NzA1NjE4NDYwMzE0MTgwMTgwOTUwODgwNjA5Mzg5NDY4ODMwOTgxODk5OTU0ODIyMTAzOTUzNDk5MzM4MTQwNjcwNjQzMjUxODU3NDA5OTQwMzIyODk1MDU1MzU4MzM2NjUzOTY3NzM5NzgyMTM2ODAwNjQ1OTIyNzM4ODMzNTU0MjAxMDY3NDkwMjg0MDk0MTgxMDkyNTk1NzU2MjM1NDQ5ODI0MDYwNDQ3NTIzNTUzMDk5NjIwNDMwNTQ4MTI5OTI3MTM5MDgzODc2NzIxMjgwOTcwNjc5ODg2NzY4MDQ1NTg0MDU3MDkzODQ5NDE0MjQwOTA4MjI2MDkwMjIxMjc1NjczODU4NTYyOTgyMDM2NjkzMDI0MzY3MjA0MDU3NDk2Njc2NDc0MDgxMTAwMTMzNDQ0NTI3MTU4NTY2MjE1OTczNDEwMjgwNjgyNjM3ODE0Njc5MTExOTk4MjI3MTE1OTczMzI5NzgwMjY2MTgxNjgyMDk5MjEzMDUwMDY1NjI2Nzg3NDkzODQyOTIwNjUxMDE3NDU3ODkyOTg1MTYzOTI4Mzc3OTIzMjE4ODk4MTAxNDExMTcwMDE2MDMwMDk2NzM4OTE1MTEzMjc5NjI3MzIxNjMyNjcwNjU3MTE3ODE0OTAxNTY0NDQ5MTczMjM3MzI2NzA5ODM4ODM5NTU1NjMzNjY2NTUwMDE0NDYxODk3Mjc1MjQyMzM3ODQzMzU5MTg0NjM3ODE1NDk0MjY1MjQyMTI4MzgxODcwMTg4MzQ1NTE4NzU3MzcyMjg1NzMwNDM5NjE0ODMiLCAiZSI6ICIyNTkzNDQ3MjMwNTUwNjIwNTk5MDcwMjU0OTE0ODA2OTc1NzE5MzgyNzc4ODk1MTUxNTIzMDYyNDk3Mjg1ODMxMDU2NjU4MDA3MTMzMDY3NTkxNDk5ODE2OTA1NTkxOTM5ODcxNDMwMTIzNjc5MTMyMDYyOTkzMjM4OTk2OTY5NDIyMTMyMzU5NTY3NDI5MzAwMDUyNTkzOTI4NjU3NzEwNjU1NjcwMTc3NjQxMzEwMjI4MjciLCAidiI6ICI1NDUwNjMxOTExMzA2OTU2NTA5NTA4NjI4OTg3NjA4NzA3NzEzNzcwMTIzMTY5MDE1MDc1NTE2Njc5NTA0Njk3MTkxODA1NjEwNzE3OTQzMDI4OTI2Mzk1OTY5NDIwMTQwMDY3NzMyNjY5MTEwNjAwNTUwMjg2ODg3NzMwNTIwNDg1NDQxOTIwNzc3MzUzMzYzMzk0NTIwMjQwNjkxMTUwMjk4MDU0NzQwODQ1Mzk4NTY2NjU2MDgzNzgxNTA5MzEyNjMxMDIwMjY5NTUwODI4NjMzMTM0NjcxNjI4NTMzODQ3ODYxMzQxMzcxMzMzNTIzNjc4NTgzMTc2NTM5Mjc0Mzc3ODQ3NTEyOTIzOTM5NTY5ODU0NTE2NDUwMDYzOTk0Njg5OTQ5Mjg0MTgyODM3MjUyNTg2MzM4MzcyNzU3Nzc2Mzk5MjI4MTI3NDk3ODYzNzcwMDYwMTM4MjgyNTgwOTU2MjMyMTQ1MDg4NTM1NDA3NzA2NTM0ODQ2NTk3Njg0ODAzODAyODc1MzExODcwNzUwNTk2NDk4NjYwMzUxOTA5NTE5Mjc4NDE3ODY5MDM0NDU4MDM3MzQwMzUzNzU1MDQwNjU2MTY1NDkwMjk3NzM3NjY3NDY5MzQwNDM3NjI0OTU5NjQxMTQ1MDg1MTU4ODM3MDkyOTUyNTY1NTc0ODExNDEzNDI2MjgyODI2MDA5MzgzNzM0Mjc0MjQ2MDY0NzAwNzk4ODk1NDczNDM0NTU4NjMzMzE2NjQ2OTk3ODY5NTgyOTk1ODU5MjA1OTE5NzM4MjgwNzc1MzA3MzgyNTcxOTE2NDg2NjMwNzQ1NDQ4MTM2Njk4NDI4ODIxOTkzODkyNjY1MTg3MzY4MTAxNTg5OTQzNjQ5NjQwMjk1MzIxNzM3Njc1NjcwNjc3NzY1OTQ5Mzk1MzgwNzQ0MjUwNzg4MDkzMDgxNjAwNTkxMDg2ODYyNTkxNzkwODg3NTQ0NzIzNTQzMzY3ODAxNzQxNzg3NjU1OTYyNjY2MDQ3ODE3NzcxNDM4MjQ5MTMyMjI1OTQ1NDEzMDQyNjY5NDk0MjM0NDgxMzUyMzAwMjE4MTY1NzMyIn0sICJyX2NyZWRlbnRpYWwiOiBudWxsfSwgInNpZ25hdHVyZV9jb3JyZWN0bmVzc19wcm9vZiI6IHsic2UiOiAiNzUwODY5NzE5OTM4NTY4MTg1NDQ1ODc0MjA1MDg4NTQwNTA0OTg2NTI3Njg4NDE4MTA3MzQ2NTUyMDQ1NzYwNjIxNjQyNjg4MDA4Mjg2OTIzNTc2MTI4MTY1MjcxODQ5Njc4MjMyNzg1NDY1MTAyNTcxMzkzMjA2NTk2NDk0NjQ4MzUzMDIzNDUxNTgzOTQ3MDAxMTk2ODMyMTE5MzY2NDM0NzQ0NjA0MTA3MzcyODgzMTY3NDI1Mjg5NzY0MTM5MzYxMjU1NDU1MDUyMDkxNjUxNzY2MDMxNzIwNDA3MTk0MTI3NzQ4NzQ3MjU3NTQ3NTc1NjgyMjQ1NzcyNTgwODM2MDI5MjU1NDI2MDg2Njc3NjI1MDQ5NjY3MDc5NDU4Mjg2Nzk1NDQwMDMwODkwODkwODgzNjM5ODk4NDcyNTAzNzk2NDI0MjIxMjUwMDY5MzMwODczMzQ1NjYyNzg5MjcyMzM3NDM5NzE5Nzc4NDY0Mjc1Njk4MDAxMjg3MjQzNjI4OTU0MzE3OTk3OTUxNzUzOTY2MDkzMjIwOTc0ODQyMjM2Mjk2NDAzMTQ5MjM2NTM4Nzc1NDEzNDkyNzM3NTk2NjI0MjU2ODkzMjMxOTkwMjk0NzMyMTgxMTkyMTczMzE1MTAyMDUxMDkzODA2Nzc3MjY4NzI2MTU1NjY0NDc5ODA5NTYyMDEwMjM5MjM1Njc2MDYzODYxODk2MDI4OTM4MzQ1MjkyNTU3ODM1MDI3NzA2Nzg2NDQxNTIxNDgzNDYzNzc3NzA0MjU3OTY1NzA4NzMwOTQyMjE1ODg0NzExNzE4OTI3OSIsICJjIjogIjQ1ODAwMDAwMDY1Njg2OTE2MDg3NDkyNzg0MDY5NjI1NDQxMTgzNDkzODk2ODk2NTk0NTgzMDY2NTU4MDk2MzA4NTc4ODcyNTkzNTc2In0sICJyZXZfcmVnIjogbnVsbCwgIndpdG5lc3MiOiBudWxsfQ=="
        }
      }
    ],
    "formats": [
      {
        "attach_id": "0",
        "format": "hlindy-zkp-v1.0"
      }
    ],
    "comment": "Have it"
  },
  "trace": false,
  "auto_offer": false,
  "cred_ex_id": "f95a750e-24ac-4fad-bb20-1f2b9210fa0d",
  "cred_preview": {
    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/2.0/credential-preview",
    "attributes": [
      {
        "name": "name",
        "mime-type": "text/plain",
        "value": "Bob"
      }
    ]
  },
  "cred_id_stored": "81b68b04-f29a-4dfe-b7e2-b4f10006e355",
  "auto_remove": true,
  "conn_id": "80c54704-6112-46a8-934d-39450fd063cb",
  "state": "done",
  "initiator": "external",
  "thread_id": "ca7c299b-9289-41e4-acb6-d9c3dd209986",
  "role": "holder",
  "cred_offer": {
    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/2.0/offer-credential",
    "@id": "ca7c299b-9289-41e4-acb6-d9c3dd209986",
    "~thread": {},
    "credential_preview": {
      "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/2.0/credential-preview",
      "attributes": [
        {
          "name": "name",
          "mime-type": "text/plain",
          "value": "Bob"
        }
      ]
    },
    "offers~attach": [
      {
        "@id": "0",
        "mime-type": "application/json",
        "data": {
          "base64": "eyJzY2hlbWFfaWQiOiAiVmJWTHJGbTRycm0xYlJSdnpqZ1pNTDoyOkJvYjoxLjAiLCAiY3JlZF9kZWZfaWQiOiAiVmJWTHJGbTRycm0xYlJSdnpqZ1pNTDozOkNMOjEwMDQ6dGFnIiwgImtleV9jb3JyZWN0bmVzc19wcm9vZiI6IHsiYyI6ICI5NDAyMTEyOTE5MTg4NzE4OTY5OTM5NDk4OTMxMzk2Njk4OTg5NzUyNzYyMzI0Mzg3NDc2ODY2MjcyMDM2NzMzOTI5OTkyNDI1MDEyIiwgInh6X2NhcCI6ICIxODk4ODk0NzQ1NzkwNTI3ODg0ODgwNTkwNjg0ODk5NzM4NTI0ODk0MTQ5MzA3NTE4OTAyMjgyMDA0MzQ3NzM4ODkwMzY1NDkyMjU2MjE1NDU0MzQ4NDI4NzQwMjI3MDkwMzEwMTkzMDkyODg2NzQ3NjM5NjA4OTk4NjQwMjc2MDgzNTMzNzg0MzI4MjMzNjgxMzk5NTQwMTk4MTI0NTM3OTg2OTkyMDQ2MDk4NDU1MDM3NDM1NDg0OTc0OTYxMTI3NzAyODE2NDU3Nzg0MDAyMjA2MTE4Njg4MDE5MTMzMTA1MzIxNDQyODg0MTUyMDg5MTg4NDc4ODU1MTQ1MzY1ODc3NzQxMDYwMjAwMTQ0MzIxNDEzNzg3MzUxNDYwNzQwNDQ0NTMzMTM1NDA1ODY0MTcyNjkyMTk3NDgyMzkzMTg0NjY1Mjk1NDkwMDU0NzgzMjk1NzQyMzgxNTI0Nzg5NDgxNzQ3MjU5MjQwMzUxMjIyNTAyNTgxNDc5NzU4OTU1MjIyNjE3MDY4MTQ0OTI4OTk4MTc4MDY3NTc5Nzc2MTkwOTY3NDU4MzE2MTM5NzE3NDY1ODM1NzA0ODE0NjExNjA5MTk5Nzk4ODAxMDk0MDI4MDg3OTU1NjMxMDg2NzIyNzMxNTQ1Nzg1MjMzMjQ1MDg4NTI1MTcwOTk1NDgzNjY5OTg5OTMwODk2NzgxNjQwMDQ2ODI0MzQ5MDUyMzkzNDk1ODgwMjAwMjYxNTg2MDY0MDQ4OTIyNjc2OTAyODc3MjY2NTc3NjI3NzI4ODI0NDA4MDkwMDI5NDMyODU0MjUyMjI4ODQ5MDM2NDQ3NDAyMzAxNTY1ODM5NzMwMzk0Mzc4MzQzOTgxNTc3Nzk1OTk5OTExOTcwNDMwMDg5Mzc3NTM1NTgzNTc4ODk1NDQxMjIwMzAiLCAieHJfY2FwIjogW1sibmFtZSIsICIxMjIzNjY5NzI4MjczMDgzMTI1MjY3NjkxNTk0NzA1ODk0MjI2ODU4MTEzMjA5NjM1Njk3MTMxMDgzNzMxNzU2MjA2MjMxNDQzMDUwODQwNDk0MjkwMTM0NzcyNzkxNjk3ODE4NDc2OTA5NzYwODg3MDE1Mzc3NTcyNzE1MjE3MDk4MjA2MDc2MjYzMTkyNTQ0MTIwODc1NDU1MzQ1OTIyODI1NzM4NDk3OTAxMDc5MTIwNzEyNjUxMTQ3MDY3NjYwNTE4MzEzMDY1MTQzMzYwODMwMzkyNjIzOTIwNjQ1MTM2NzI3NzQwNTk4MzA2MDgwOTA3MjM1NTUzMjU3ODIxMzUxOTk2MjI2MzE3NTQ0MjEzODY4NTAxNzY5MzMwNjMwOTcwMTg0NzE2MTk5MDgzNTU1MDMyNzIwNTczMTU0MjM2NDQ4MjcyNDk5NjQzMTk1NjQ4OTc1OTk5NzQ3MTEyMDc3MTU3NTA2ODM1MDQxNzM2ODU0Njk2NTQzNDc3OTgwNjgzNDA0ODU2MTY1NjU0NTYyODQ4NzkwMDc4MjQyNTAwODcyNTM5ODE0MDIxNjg4MjIwODc5MjI1NDU1NjcyODg4NDA1ODI3MzY4NDY5MzYzMTQ4OTYyMTc4MDQ5OTExMDIzMzk4ODMyMTA1Nzg2MDUzMzU1Nzc1NzI0ODcyOTIwOTEzMjA3ODA1NTQzNDc1ODA5NDU0NzQ2NDgxNTQzOTk2MTIxNzQwNTMwMzk3NjY5MjAxNDQ2MDIwNzkxNzkxMTgyMjc2NjQ0NjY1NDc2NDI0NTQ3MjU0Nzc2MzI2NjA4NjIzMTAyMzcwNjA1NDUxMzQ5MTIyMjYwNjkyMzg5NTExMzIzMTQyMTU2Mzg2OTY5MzY5MTY4MjYyMTE2NDYxODYzMjQ2MTA2ODU1Nzg3NjU4NTciXSwgWyJtYXN0ZXJfc2VjcmV0IiwgIjE5MDc2OTYxNzc2NDEzMzEwMzc0NTMwNDA3MDYxMTYwODE1Nzk0NDE2NzU4MTc2OTU4MjY3MjEzNTI0MTAwNDMxNDAzODgxMzg4NDgzNTkxODU5NTI1ODk5NzUxMDkyNTE1MTQ2NzAyNjU0OTI4NjczOTkwMTYwMjU3NDkyNDY0Nzc4MjY2NDkxNDU0NTE0NDgzMzM0MjI4OTY0MDE5NTUwMDY4NzE5MTIzNDYwNDEzMjY0MjM5NDc1NTkyNTI1MTg4NjY0Nzc1MTE1NDcyODAzMzMxOTk5NzkyMTI1ODk5NjY4NzI2NjYwNTM4NzQyMzg3NjUzNzQyMzY4MjAzMzM1NDQ4OTUwNjY1MzQyMjA0NTkwMTY4OTU0MjExMDQ3NjM5NjQzNzY1MDAzNjAzNDczMDE5MjI0NDc4MTYwNDEyNTU3MzkxNDY4NzA1MDkwODA0OTI1NDI0OTQ5NzM4MjE2NzM1NjkyODMzNDU1MjU1NDczNTgzMTUzODY1NTcxMzQwNTI5MTY5OTczMjUxMTM1NzY2MTY1MzE4NTc1ODEyNzY5MzkzODA1NDcyMTk3Njg2OTMyMDA0MTUwMDY1MTY4NDE5NzUzNjQyMzQxMjc4MTc2OTc2NDIyMzI1NjU3MDk1ODQxOTU4MDg4OTYxMTk0MzE2ODYzNTUxMDEwODI0NzA1ODY3MTcwNjAyOTEyNzcxNjg5ODg0NTYzNzIxMTg3NDczMjQxMDk2NTQ1MTE0ODYzMDgxMzU0MTQ2MDc2NjczMzYzMTA2NjEyMzUyNDUyNzY1MDM3OTMwMDU3OTI5MDU5MTM0MjUyNjM3NDUyODAwNzM4NzYzMjg1ODgwNTg0ODQyMjg5NDMwMzU4MjEwOTY1ODI4ODk0MDI3ODA5OTM2MDc4MzgyMjU5Njg1ODk4NjM4MSJdXX0sICJub25jZSI6ICI1Mzk1NDQxMzgyNTQ3Mjg3NzUzODEwODEifQ=="
        }
      }
    ],
    "formats": [
      {
        "attach_id": "0",
        "format": "hlindy-zkp-v1.0"
      }
    ],
    "comment": "a"
  },
  "created_at": "2021-02-18 06:25:35.679391Z",
  "cred_proposal": {
    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/2.0/propose-credential",
    "@id": "02911ccb-ef4c-44d8-82bc-c7ae19beb54c",
    "credential_preview": {
      "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/2.0/credential-preview",
      "attributes": [
        {
          "name": "name",
          "mime-type": "text/plain",
          "value": "Bob"
        }
      ]
    },
    "filters~attach": [
      {
        "@id": "0",
        "mime-type": "application/json",
        "data": {
          "base64": "eyJzY2hlbWFfaWQiOiAiVmJWTHJGbTRycm0xYlJSdnpqZ1pNTDoyOkJvYjoxLjAiLCAiY3JlZF9kZWZfaWQiOiAiVmJWTHJGbTRycm0xYlJSdnpqZ1pNTDozOkNMOjEwMDQ6dGFnIn0="
        }
      }
    ],
    "formats": [
      {
        "attach_id": "0",
        "format": "hlindy-zkp-v1.0"
      }
    ],
    "comment": "a"
  },
  "updated_at": "2021-02-18 06:38:49.862857Z",
  "auto_issue": false
}
```

### Credential Exchange Indy Event (`issue_credential_v2_0_indy`)

With the introduction of issue-credentials v2, the Indy and DIF parts have been moved out of the credential exchange and do now have their own webhook event.

```json
{
  "cred_ex_indy_id": "74faf8b6-3fdc-46a1-ae9c-ccce1b88ddeb",
  "created_at": "2021-02-18 06:25:44.996185Z",
  "updated_at": "2021-02-18 06:25:44.996185Z",
  "cred_ex_id": "f95a750e-24ac-4fad-bb20-1f2b9210fa0d",
  "rev_reg_id": "WgWxqztrNooG92RXvxSTWv:4:WgWxqztrNooG92RXvxSTWv:3:CL:20:tag:CL_ACCUM:0",
  "cred_request_metadata": {
    "master_secret_blinding_data": {
      "v_prime": "23506764754388066226969558506213373364652745689877455625304734591812049954570379417682560744791576456838509619858992264552218487073213573012550083162478350340369587835098066297377432713238222218032853205952896239993382325050722023352689877827714251852231614525376402278072614339094840452633754583334222006931971007976198477380690133236334663112093646419594238188554145760502636950415972975001375768659941431452263445531118349590029811108183824875103628802132812168348215855903538473076481684304649896385464903210891517299634297129418435511235721914590322319115940101023764528094025523256349399326861946232816913351808886587705662024637123898",
      "vr_prime": null
    },
    "nonce": "633437605166629575715559",
    "master_secret_name": "Bob57981"
  }
}
```

### Credential Exchange DIF Event (`issue_credential_v2_0_dif`)

With the introduction of issue-credentials v2, the Indy and DIF parts have been moved out of the credential exchange and do now have their own webhook event.

I have yet to receive a DIF event, this will probably work when connecting with an `aries-framework-go` instance as that supports the DIF SideTree Protocol.

```json
{
  "created_at": "2021-02-18 05:33:00Z",
  "cred_ex_dif_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "cred_ex_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "item": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "state": "active",
  "updated_at": "2021-02-18 05:33:00Z"
}
```

### Presentation Exchange Record Updated (`present_proof`)

When a proof of non-revocation is going on, a `PresentationExchange` record is updated. With each of the `state`s of the record more fields will be filled in the body. The states that I have seen a webhook event for are:

- `proposal_sent`
- `proposal_received`
- `request_sent`
- `request_received`
- `presentation_sent`
- `presentation_received`
- `presentation_acked`
- `verified`

Example JSON body:

```json
{
  "initiator": "self",
  "presentation_request": {
    "name": "proof-request",
    "version": "1.0",
    "nonce": "719701719187879643701553",
    "requested_attributes": {
      "0_name_uuid": {
        "names": [
          "name",
          "age"
        ],
        "restrictions": [
          {
            "cred_def_id": "WpCfMLVp2vZSaqgC696j3E:3:CL:679:tag"
          }
        ],
        "non_revoked": {
          "from": 0,
          "to": 1611744008
        }
      }
    },
    "requested_predicates": {}
  },
  "updated_at": "2021-01-27 10:43:15.199484Z",
  "state": "presentation_acked",
  "presentation": {
    "proof": {
      "proofs": [
        {
          "primary_proof": {
            "eq_proof": {
              "revealed_attrs": {
                "age": "30",
                "name": "93006290325627508022776103386395994712401809437930957652111221015872244345185"
              },
              "a_prime": "9513895006022418675554866019488151396085183042859964792173834538410384395124123452763712394625111395982869973291539224621800731126686070322775767532955644206156190746223505741753454966408047198343833759484530860815767659567639896517586058249821323377691804880247454406960185922974050353701093962026522939017319288389985864702923571805752808061197795428779116646084214180203845336463525220877125707508513617034463575748000145858127546619218583638503181844847633069910147208210863895866217290764020359252203639147772357274912763840127345574015575338899752855023817599260983100221835063554271886477432052581378061209300",
              "e": "53149478291219158735403362520017226694455949009615530788153712451004277720189035904502490310215191638394105855731383280418702173024001120",
              "v": "796708819498330228611879290685842177653146671482063690153021449463729872548446598396669573486979705174812640174261113140866944493382989973952753078962781903751230919119232020036539672888139834047245624551193675728412532729349503128413067578110560688963007469831056984065491722941671445529745709741768608522424825645809308028035378356048650682560466840722643652830588174849159079979888129278221710830533912848801012645068961038631539202944911023245066911993871178971516551820097068111001683141772632933325524521273866737466165123703059545228475427961960363365949785624900734652544882102158076411516763667651405879279363152705035557832551467592353040857656673138034722041262640714564863426858169985710780337097442836133988600497710769425490599968079872958980167841005202261996065168670189678013180600833166838555694819291768146241852422036041940681332805566339654817821114987812558050683773947985944410256471510321150629013",
              "m": {
                "master_secret": "5191850623593627132811683770908720406671617753775597702698146438393117927767443992419869850753610353511780578021976630428938760228125256922749670341449063166998121773626969824874"
              },
              "m2": "50756311185433552764250198493567945886513219570142286061467153111709000775792867705199891767770790422099974467585933877961911028957499755539667874357031"
            },
            "ge_proofs": []
          },
          "non_revoc_proof": {
            "x_list": {
              "rho": "1FE4B9B0EF56AE06D2D248425C43A7EC483FC65C7B33B2467A037EBE0D88AE8A",
              "r": "174964E06E5120D1716A5D9E08E04A467D6F45617EF972C994308A86FE705FBE",
              "r_prime": "0A83B71860FED52313A9705E3D85ED7EA0332398825CAD52C9C5DB845E73D5B4",
              "r_prime_prime": "141DB822F391412433A59607CF08DFA29EFD5E97BCFEDC4A13A894B0571A454A",
              "r_prime_prime_prime": "1D7950A3F101E233EEC1AC0534197FD7D90E31EB60DCD4CB45BF5ED210ACDF98",
              "o": "066F9C174A52ABB0B65AE485E46719280FA742053DC66C6E03F507C6F5D376BB",
              "o_prime": "235252FF113A8DDE9D5F189E0B7C28DD5D1399A64EF5F6EF0924ECD9DB490A21",
              "m": "11AA5F0894C63C3DBF7A39C4F16E0161EE3F810EEDE7DCD558A48DCBFD2DA2C7",
              "m_prime": "04ECC79E323B52518C9DF410220676F27339B27E044F361236C6375F17653539",
              "t": "1798B10ABE280447E3A7A862092438899D3986BFD219C0D273F0D16A67CD36E1",
              "t_prime": "10546375570049852E17F27574B958C5592EE2943FA93DA2DD56E5707E25A8F4",
              "m2": "07F52C62A33877DE3D36277442905E09ED35F779BD447127F5C3DEBFFC1AEC86",
              "s": "12AE1CCE7F6B661D797F18AC601AB6BD96BBFB23BFE4916676560A82CC5B9F50",
              "c": "061E4BC353431D99AC85960B64991044DBC056DD515B453AEE5A368F0E3F45BC"
            },
            "c_list": {
              "e": "6 5251A27D889C46CDFED77E452BE6F10A581642495797043B4BB99B9216EC7ADA 4 0CC5565C379322C8940DA33E12CB15843059141F1E316A9A15DDAFBEAE8A4650 4 1A42B5D39A96DE543B4EFBDB56F4E0824DE064237E0E1088D473D5F34AEFDBF8",
              "d": "6 3168ECB6808964AAC2C618087C87952DB3EEFA5EDD0C8DBF0711AA699C863E58 4 28C9BABCEC4ACEC7AD48C35047916513F50B6B64461CC73F5D1015E83147A0EB 4 15C2D8E3685471BAD928F7851539CC9DED2895DBF45862D7FA7408D819AC83A8",
              "a": "6 5D233BFE7C17A9814A0A0DA1D9213576D1C658E1BA2BA189A6AFC8C9F679C574 4 2E552489367494184EE620FDB3AE8380F5A43B10040E431F0B8F617CE87D93F0 4 21C894FC16FFA11F3C15057EA4597F42AE5E68E34C47CDAB1B027BF35A18F202",
              "g": "6 376E3DF9B9DE59E55F4129DC0B6EB2F7F6DDBE11723A92916172A4F796DF5A16 4 2ECF06A16F116357AA1D18416F4F3EE79428188CC090C0C8666031B35B5D39E2 4 25A9BB93C84FF963388735491782E6848CB376E2F06EF3C3EACDEE057972CA9A",
              "w": "21 11C76F8FC98BAFDF67E7ACE2F6182AAEAE87F20234ED97D6FD5A1CE754350C5DC 21 12D6D0645B9486ABDE188A64E0AD62E6A55D8E66F9FC1005235209F4963E3EE3B 6 619847B04ABF449EAD305EC0E51A42F2244863A792B0E5500F7F74B72B4B017B 4 335E7AB6A08E6BEE21105B9F43B191A9FFA183129422D8F97C87A347DB70883B 6 5FBDF9D35A7C26802A58914A5D9962848B38A84CC0943AC6F66202E0B37115DF 4 150BB091BC96063585CC82BC1B894E375735F558C24F5961C70B0D5E5144DEAC",
              "s": "21 123E8BBA03DCFDEBA6228C809706A6B8A9A2F63671C285772CAE8ADEC81120937 21 12DBB0DCDF967ED924881E8C920761A38E77811B14D2F5040FCBA62301ED3592B 6 6AABD757FB41E5A16528E02A7030DF5EE239BD2403BBB89FBDD437D887A20530 4 20A1212E522D50D3F82BA939ED0255FFC9243974F0FAD3CF4EA80A92BFE7C54F 6 677AFBE9705DAAE01F91451E82360EABA766F109C543E12600AAF5BB70372BA1 4 32E717A851177E969DB37E805678423112B5DCAD83AFDD0A508EC90CDDEC460E",
              "u": "21 10C6FB68F6E1608C4E590994F4A2383D5A06E571920126777F7E6E1D7C7CBE9F5 21 124E974F116D3F921BD3F2AB83FD93CBE1195B8ADAA01D090217C4C3615EA14CD 6 67B8536C4665052E4AF3DA1D11C5C580450F8EC7FE246C5E713E81842EF5140A 4 29CA26748BB38F13A9001226307EA029097AEF377B8D970DB3F3F749BE4F5159 6 805D5A54F6BBE507A0212C0975A6755A299FA33FD94BC0B7FE9D26A8BF16FD3B 4 1D8A5DBF9C790768CC9FF1628984C06DB50A2DB0DE8C729C9AA4F26B5F86EB89"
            }
          }
        }
      ],
      "aggregated_proof": {
        "c_hash": "4300905628417492225996209746896948212714980110393463316731764301320120897896",
        "c_list": [
          [4, 11, ...], [4, 30, ...], [4, 19, ...], [4, 5, ...], [31, 73, ...], [4, 53, ...], [3, 134, ...], [75, 93, ...]
        ]
      }
    },
    "requested_proof": {
      "revealed_attrs": {},
      "revealed_attr_groups": {
        "0_name_uuid": {
          "sub_proof_index": 0,
          "values": {
            "age": {
              "raw": "30",
              "encoded": "30"
            },
            "name": {
              "raw": "Bob",
              "encoded": "93006290325627508022776103386395994712401809437930957652111221015872244345185"
            }
          }
        }
      },
      "self_attested_attrs": {},
      "unrevealed_attrs": {},
      "predicates": {}
    },
    "identifiers": [
      {
        "schema_id": "WpCfMLVp2vZSaqgC696j3E:2:ForBob:1.0",
        "cred_def_id": "WpCfMLVp2vZSaqgC696j3E:3:CL:679:tag",
        "rev_reg_id": "WpCfMLVp2vZSaqgC696j3E:4:WpCfMLVp2vZSaqgC696j3E:3:CL:679:tag:CL_ACCUM:d93b07b6-dc69-4876-8648-3b2bcd7cf378",
        "timestamp": 1611743937
      }
    ]
  },
  "presentation_exchange_id": "0068f8a9-978d-4f11-a5d8-c7d7ae6a7c9e",
  "connection_id": "82a9e2a3-4701-4496-96c5-b17152543da1",
  "presentation_proposal_dict": {
    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/present-proof/1.0/propose-presentation",
    "@id": "2cc2be47-4e74-429d-9713-4bf8bea13d36",
    "comment": "I have this",
    "presentation_proposal": {
      "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/present-proof/1.0/presentation-preview",
      "attributes": [
        {
          "name": "name",
          "cred_def_id": "WpCfMLVp2vZSaqgC696j3E:3:CL:679:tag",
          "mime-type": "text/plain",
          "value": "Bob",
          "referent": "da9ee69d-9518-4720-a7bb-aafdd0bb0315"
        },
        {
          "name": "age",
          "cred_def_id": "WpCfMLVp2vZSaqgC696j3E:3:CL:679:tag",
          "mime-type": "text/plain",
          "value": "30",
          "referent": "da9ee69d-9518-4720-a7bb-aafdd0bb0315"
        }
      ],
      "predicates": []
    }
  },
  "created_at": "2021-01-27 10:39:43.468037Z",
  "auto_present": false,
  "role": "prover",
  "trace": false,
  "thread_id": "2cc2be47-4e74-429d-9713-4bf8bea13d36"
}
```

### Revocation Registry Record Updated (`revocation_registry`)

When a credential definition is created with a revocation registry, a `RevocationRegistry` record is created. I have seen the following `state`s trigger an event:

- `init`
- `generated`
- `posted`
- `active`

Example JSON body:

```json
{
  "revoc_def_type": "CL_ACCUM",
  "state": "active",
  "max_cred_num": 10,
  "tails_local_path": "<some-path>/.indy_client/tails/8wK3q2v9G679Bfi7EDhy7Z:4:8wK3q2v9G679Bfi7EDhy7Z:3:CL:659:tag:CL_ACCUM:854a776b-54d4-4aaa-9fa1-784ee4ea8ef5/Fc4nZpow5gVhWHXkKHCtxX85pPmtmUDzTWxkYvoouhM5",
  "created_at": "2021-01-27 10:24:11.238707Z",
  "tails_public_uri": "http://localhost:6543/8wK3q2v9G679Bfi7EDhy7Z:4:8wK3q2v9G679Bfi7EDhy7Z:3:CL:659:tag:CL_ACCUM:854a776b-54d4-4aaa-9fa1-784ee4ea8ef5",
  "record_id": "854a776b-54d4-4aaa-9fa1-784ee4ea8ef5",
  "updated_at": "2021-01-27 10:24:17.278212Z",
  "tails_hash": "Fc4nZpow5gVhWHXkKHCtxX85pPmtmUDzTWxkYvoouhM5",
  "pending_pub": [],
  "revoc_reg_id": "8wK3q2v9G679Bfi7EDhy7Z:4:8wK3q2v9G679Bfi7EDhy7Z:3:CL:659:tag:CL_ACCUM:854a776b-54d4-4aaa-9fa1-784ee4ea8ef5",
  "revoc_reg_def": {
    "ver": "1.0",
    "id": "8wK3q2v9G679Bfi7EDhy7Z:4:8wK3q2v9G679Bfi7EDhy7Z:3:CL:659:tag:CL_ACCUM:854a776b-54d4-4aaa-9fa1-784ee4ea8ef5",
    "revocDefType": "CL_ACCUM",
    "tag": "854a776b-54d4-4aaa-9fa1-784ee4ea8ef5",
    "credDefId": "8wK3q2v9G679Bfi7EDhy7Z:3:CL:659:tag",
    "value": {
      "issuanceType": "ISSUANCE_BY_DEFAULT",
      "maxCredNum": 10,
      "publicKeys": {
        "accumKey": {
          "z": "1 0113B6CA5F509E37A6F298E170EF90BAD5A7A6DDEE436BBF3A2578D7B9524BC6 1 0EF3D535AE31C8D5B216170976CB7E5D1476A7B426FE00AC0FFCCE610557BC76 1 05FBCAF6F953723CAEDF82461FC080C317634C287712C8D22F0AFC9A0917E809 1 18D5D40276437F3D6AB9AF14619BB82B3E470B4377CBD47D57132657022D102B 1 0A13E10190A6C43475310985B77E4A53DA25E9D750EA769DC8544E23CCB9443C 1 047D968BE6B9EB128EB2655EE4ACAD8A1AA8C7014CCA2F724D5CDB31E8250E9E 1 22DDF6D1AB48F6A97B8E3E61BC42FE5EDDB0A48DD0F86E1A64BA4610322DD8CE 1 1C1BC1C0736C20A39B5969E2BB487D72418F102D900938D7DA1946C1AF219A2E 1 06EBF79214F933732CFCCE963D4F923C703B4320A6237D3D12B8BB0BC7E51181 1 1B628B6A354E9195BCDBB0F7B816DFF8D7E3C354C1DFB3E63F62404B6727108F 1 03D904ECDB62167DE5A4EA03850EA6F71A6A6FA929FBD8EB64E9869D6A4E0A0A 1 10C4A923CA25C255DDEA37239C3E464A2CAC20B238FCE9B295E329949828E63C"
        }
      },
      "tailsHash": "Fc4nZpow5gVhWHXkKHCtxX85pPmtmUDzTWxkYvoouhM5",
      "tailsLocation": "http://localhost:6543/8wK3q2v9G679Bfi7EDhy7Z:4:8wK3q2v9G679Bfi7EDhy7Z:3:CL:659:tag:CL_ACCUM:854a776b-54d4-4aaa-9fa1-784ee4ea8ef5"
    }
  },
  "issuer_did": "8wK3q2v9G679Bfi7EDhy7Z",
  "cred_def_id": "8wK3q2v9G679Bfi7EDhy7Z:3:CL:659:tag",
  "tag": "854a776b-54d4-4aaa-9fa1-784ee4ea8ef5",
  "revoc_reg_entry": {
    "ver": "1.0",
    "value": {
      "accum": "21 119A0A050D04669979B35151669D6B9AF6CE613CA2B01BB831EFA9BF755F3FBD6 21 13B0DC06435D2F41CA258D662492194CE03617AA84107413C024853BC1C2A45E7 6 5E9F99F7B5C70C38A9E59384A2578B9F518BA1A7ADFB377BBC437BA5A418CCD1 4 17384C52EE71270CC0C8B469C038AB771D8B41EB005FD7D3C27CE4C593F43D9E 6 534D19E7B7A6363839F7F2D9A11BAB3D6121DDA74647CF3754C64202CAC05892 4 33BAAF558FF4508EA5A450E9C4BAC44D9A8040D2F864A17091BB4B7BBE77BBEE"
    }
  }
}
```


### Problem Report (`problem_report`)

Problem reports are defined in [Aries RFC0035](https://github.com/hyperledger/aries-rfcs/tree/master/features/0035-report-problem) and are used to report problems for example while issuing credentials or presenting proof. The messages between ACA-py clients contain rich messages with for example a description, which items are a problem, who should retry, a hint for fixing and urls for tracking and escalation. When a problem report is received, for example after calling `/issue-credential/records/{cred_ex_id}/problem-report`, the webhook will be triggered. There is no endpoint for creating a problem report for presenting proof (yet). Unfortunately, the body of a problem report event is not rich and contains the bare minimum information. The thread id can be used to query the `CredentialExchange` record, but no mention of the problem report can be found.

Example JSON body:

```json
{
  "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/notification/1.0/problem-report",
  "@id": "5bc63af2-3261-4ded-aaba-255be79fd4b8",
  "~thread": {
    "thid": "b7e0ee42-02cb-41a3-ad3d-0ba81e3e767f"
  },
  "explain-ltxt": "My age is wrong"
}
```