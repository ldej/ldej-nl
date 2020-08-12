---
title: "My Domain Driven Design Notes"
date: 2020-08-02T16:32:42+05:30
draft: false
summary: "I recently read the book Domain Driven Design Quickly. I made some notes and decided to put them here as a reference for myself."
image: images/ladakh4.webp
tags:
- Domain-Driven Design 

#reddit:
#  created: 1594708583 
#  url: https://www.reddit.com/r/ldej/comments/hqwgj8/discuss_working_in_the_trenches/
#  title: "Working in the Trenches"
---

I recently read the book Domain Driven Design Quickly. It's the shorter version of Eric Evans book. You can download it for free from http://infoq.com/books/domain-driven-design-quickly. I made some notes and decided to put them here as a reference for myself.

## Chapter 1: What is Domain-Driven Design

Software solves a problem for a specific domain. One must understand the domain to create good software. Talk to domain experts to define and understand the domain.

Software needs to incorporate the core concepts and elements of the domain.

A domain model can be build by talking with the domain experts. A domain model is an abstraction, an idea that can be expressed in many ways including as a diagram, code, or text. We need to communicate the model.

Talk a lot with domain experts. Try to figure out the essential concepts of the domain. Domain experts organize use their knowledge in a specific way, which is not always the best to be implemented in a software system.

## Chapter 2: The Ubiquitous Language

Communication is paramount for the level of success of the project. The model is the common ground between developers and domain experts. Use the language in all communications and in code.

Creating a language is difficult. Experiment with alternative expressions. Refactor code to conform to the new model. Domain experts should object to terms or structures that are awkward or inadequate. Stay focused on the essentials.

Be aware of long documents. Make small diagrams containing subsets of the model. Documents must be up to date.

## Chapter 3: Model-Driven Design

The model and software are highly linked. A change in the model should result in a change in the code, and a change in the code might result in a change in the model. Some concepts cannot be properly expressed in code. Choose a model which can be easily and accurately put into code.

Design a portion of the software system to reflect the domain model in a very literal way, so that mapping is obvious.

Partition a complex program into layers.

| Layer          | Description                                                  |
| -------------- | ------------------------------------------------------------ |
| Interface      | Responsible for presenting information to the user and interpreting user commands. |
| Application    | This is a thin layer which coordinates the application activity. It does not contain business logic. It does not hold the state of the business objects, but it can hold the state of an application task progress. |
| Domain         | This layer contains information about the domain. This is the heart of the business software. The state of business objects is held here. Persistence of the business objects and possibly their state is delegated to the infrastructure layer. |
| Infrastructure | This layer acts as a supporting library for all the other layers. It provides communication between layers, implements persistence for business objects, contains supporting libraries for the user interface layer, etc. |

**Entities** are objects with an identity, which remains the same throughout the states of the software. For these objects the values don't matter, only the identifier. Only create Entities for the most important parts of the domain.

**Value Objects** are objects where we are only interested in it's attributes. They don't have an identity. It is recommended to make Value Objects immutable. Keep Value objects thin and simple.

**Services** provide functionality for the domain. Functionality that cannot be incorporated in Entities or Value Objects because it functions across several objects. Services can appear in each of the layers.

**Modules** are used as a method to organise related concepts and tasks in order to reduce complexity. Modules should be made up of elements which functionally or logically belong together.

An **Aggregate** is a group of associated objects which are considered as one unit with regard to data changes. Each aggregate has a root Entity and that is the only object accessible from the outside. Other object in the aggregate can only be changed by performing actions on the root, never directly on the other objects.

**Factories** can encapsulate the process of complex object creation. They are especially useful to create Aggregates.

**Repositories** encapsulate the logic for storing and retrieving objects. They hide the logic of for example a database, files or communication with an external service and may use for example caching.

## Chapter 4: Refactoring Toward Deeper Insight

Previous chapters described the importance and creation of a model. The code should be a reflection of the model, if not then refactoring of the code is required. Automated tests can help with ensuring that we haven't broken anything. From reading the code, one should be able to tell what the code does, but also why it does it.

Another type of refactoring is related to the domain and its model. 

Start with a coarse, shallow model. Refine it based on a deeper understanding of the domain and the concerns. Each refinement adds more clarity to the design and can lead to a Breakthrough. A Breakthrough often involves a change in thinking, in the way we see the model.

Constraints are a simple way to express an invariant. An invariant is an expression whose value doesn't change during program execution. Make invariants explicit by extracting the constraint in a separate method.

Specifications are used to encapsulate a set of business rules when it would otherwise make a domain object to complex or bloated. The Specification is used to test objects to see if they fulfil some need or if they are ready for some purpose. Specifications should be kept in the domain layer.

## Chapter 5: Preserving Model Integrity

This chapter is about large projects which require the combined efforts of multiple teams. 

It is so easy to start from a good model and progress toward an inconsistent one. 

Preserving the model integrity by striving to maintain one large unified model for the entire enterprise project is not going to work. The solution is not so obvious, because it is the opposite of all we have learned so far. Instead of trying to keep one big model that will fall apart later, we should consciously divide it into several models. Several models well integrated can evolve independently as long as they obey the contract they are bound to. Each model should have a clearly delimited border, and the relationships between models should be defined with precision.

### Bounded Context

A model should be small enough to be assigned to one team. There is no formula to divide one large model into smaller ones.

Explicitly define the context within which a model applies. Explicitly set boundaries in terms of team organization, usage within specific parts of the application, and physical manifestations such as code bases and database schemas.

A Bounded Context encompasses a Module.

### Continuous Integration

Merge and build often. Use automated tests to catch errors early.

### Context Map

An enterprise application has multiple models, and each model has its own Bounded Context. It is advisable to use the context as the basis for team organization. A Context Map is a document which outlines the different Bounded Contexts and the relationships between them. Each Bounded Context should have a name which should be part of the Ubiquitous Language.
