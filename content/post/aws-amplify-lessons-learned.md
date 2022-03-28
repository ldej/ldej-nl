---
title: "AWS Amplify: Lessons Learned"
date: 2021-08-05T10:02:47+05:30
draft: true
summary:
image: images/ladakh1.webp
tags:
- 

---

In a recent project I got the opportunity to work with AWS Amplify. I had never heard of Amplify before, which meant I had some reading up to do. 

> AWS Amplify is a set of tools and services that can be used together or on their own, to help front-end web and mobile developers build scalable full stack applications, powered by AWS. With Amplify, you can configure app backends and connect your app in minutes, deploy static web apps in a few clicks, and easily manage app content outside the AWS console.
> 
> Amplify supports popular web frameworks including JavaScript, React, Angular, Vue, Next.js, and mobile platforms including Android, iOS, React Native, Ionic, Flutter. Get to market faster with AWS Amplify.

Most of my experience is with developing web applications in Google Cloud Projects using App Engine or Cloud Run. I have briefly used GCP Firebase which would be the closest alternative. My AWS experience is from a numbers of years ago, where I ran dockerized applications on self-managed EC2 instances.

## What is Amplify exactly?

Amplify is a set of tools, which generates AWS CloudFormation templates which can deploy a variety of AWS services including AppSync, DynamoDB tables, API Gateway, Lambda, Cognito User Pools, S3 buckets and SSM. What this means is that you will interact with a vast array of services which may or may not be in your tool belt already. If you have never used any of these, you might be in for a bumpy ride.

## Amplify CLI

The Amplify CLI is a command line tool which allows you to make changes in the CloudFormation templates using a set of questions. 

```shell
$ amplify api update
? Please select from one of the below mentioned services: REST
? Please select the REST API you would want to update api
? What would you like to do Add another path
? Provide a path (e.g., /book/{isbn}): /book/{isbn}
? Choose a Lambda source Create a new Lambda function
? Provide an AWS Lambda function name: books
? Choose the runtime that you want to use: (Use arrow keys)
  .NET Core 3.1 
  Go 
  Java 
❯ NodeJS 
  Python
```

Navigating the CLI takes a bit of practice. In case you can select multiple options, use `<space>` to select and use `<enter>` to continue. There is no way going back to the previous question, in which case you need to cancel `Ctrl+C` the command and start over. Make sure to check if Amplify has not changed the configurations files already, otherwise you might run into trouble. It is recommended to always start with configuration changes in a state without local changes.

## Development workflow

The hardest part of getting started with Amplify, is figuring out the development workflow. The workflow might change between teams and projects, depending on your needs.

An Amplify project consists of two parts: the front-end and the back-end. A JavaScript/React front-end is easy to run locally. A back-end is a bit more tricky. The back-end mostly consists of CloudFormation templates that will deploy services in AWS. The best course of action is usually to deploy changes, as it is rather difficult to run everything locally.

I am used to being able to spin up my whole application locally, possibly interact with some hosted services or use mocked versions otherwise. My natural instinct told me to see if I could run the whole Amplify application locally, without having to interact with any deployed backend. More on that in the section about mocking.

Pull, Push and Envs

## CI/CD

## GraphQL Schema

Amplify directives

Changing multiple keys

## GraphQL vs REST

## Custom resolvers

## Typescript Lambdas

package.json location

## Lambda Layers

## Lambda Environment Variables

## Accessing GraphQL/DynamoDB from a Lambda

## Designing your API Gateway and endpoints

## Testing Lambdas

## Storage

## Performance

## Amplify Mocking

For mocking, Corretto is required.

https://sdkman.io/jdks#Amazon

```shell
$ sdk ls java
$ sdk install java 16.0.2.7.1-amzn
```


Attempting to mutate more than 1 global secondary index at the same time on the PaymentTable table in the Payment stack.
Cause: You may only mutate one global secondary index in a single CloudFormation stack update.
How to fix: If using @key, include one @key at a time. If using @connection, just add one new @connection which is using @key, run `amplify push`, 
