---
title: "Structuring Go"
date: 2020-07-21T11:07:11+05:30
draft: true
summary: "There are many opinions on how to structure your Go code. I'm going over a number of them to compare them."
tags:
- Go
- Web

#reddit:
#  created: 1594708583 
#  url: https://www.reddit.com/r/ldej/comments/hqwgj8/discuss_working_in_the_trenches/
#  title: "Working in the Trenches"
---

I've been making web applications in Go for the past three years. I've seen different structures and used different structures myself. But, what is a good structure?

https://golangweekly.com/

## Jon Calhoun

https://www.calhoun.io/structuring-web-applications-in-go/
Context is king

https://www.calhoun.io/flat-application-structure/
All code in one single package
Key takeaways:
- You can stop worrying about how to organize things and get on with solving problems
- Makes it easier to learn, how to code in general, your application's needs, your domain
- No cyclical dependencies
- Naming collisions can be awkward
- Create packages when the application grows
- Won't work forever, but probably longer than you think

> What this all means is that you should pick the structure that best suites your situation. If you are unsure of how complicated your application is going to be or are just learning, a flat structure can be a great starting point. Then you can refactor and/or extract packages once you have a better understanding of what your app needs. This is a point that many developers love to ignore - without building out an application it can often be hard to understand how it should be split up. This problem can also pop up when people jump to microservices too quickly. 
>  On the other hand, if you already know your application is going to be massive - perhaps you are porting a large application from one stack to another - then this might be a bad starting point because you already have a lot of context to work from.

https://www.calhoun.io/using-mvc-to-structure-go-web-applications/
Option 1: layer based
Option 2: resouce based
MVC feel familiar and allows us to make one less decision
Key takeaways:
- not everything is a model, view or controller. For example: middleware
- don't combine option 1 and option 2: models tend to be relational, cyclic dependencies
- if you face cyclical dependencies, there is a good chance you have broken things up too much
- you don't have to stick to the models, views and controller names
- don't blindly copy other languages
  - models should not contain json tags, so you need to define resources more than once
  - the controller can map model type to a view type and vice versa
- don't do globals, requests are handled in goroutines, so you can get race conditions
- global database connections are ill-advised, inject db connections into handlers
- don't embed sql connections into models 

models/sql:
- models should usually not import any other packages in your application
- database related logic, retrieve relational data
- no html or http status codes
views/html:
- html/xml/json rendering
controllers/http:
- http handlers that parse incoming data
- call methods from the models

https://www.calhoun.io/moving-towards-domain-driven-design-in-go/
- DDD is for writing software that can evolve over time
- Find a balance between:
  - coupling
  - writing more and more code for adapters and plugging
- define domain types (maybe a domain package), write implementations that depend on these types

- You don't have a reasonable starting point for how to organize your code. With DDD you probably need to spend a great deal of time upfront deciding what your domain should be.
- Probably works better with a larger team and larger applications
- Defining a domain model before using it is challenging
- For a project that isn't evolving, you likely don't need to spend all the time decoupling your code
- We very rarely swap out our database implementation, and if we do, we probably need to rethink a bit more
- Probably don't start decoupled, let our code evolve over time

## Mat Ryer

https://pace.dev/blog/2018/05/09/how-I-write-http-services-after-eight-years.html



## James Dudley

https://www.dudley.codes/posts/2020.05.19-golang-structure-web-servers/

Comes from C#. Focus on discoverability, applications can live a long time in production.

- Describes much of the decoupling as described in the DDD examples of Calhoun.
- Feels like it works well for microservices
- Binds routing in one file/function routebinds.go:BindRoutes()
- Puts endpoints for routes in separate files

- Needs more investigation

https://github.com/marcusolsson/goddd
https://medium.com/wtf-dial
https://www.ardanlabs.com/blog/2017/02/design-philosophy-on-packaging.html
https://github.com/golang-standards/project-layout
https://github.com/bxcodec/go-clean-arch
https://bencane.com/stories/2020/07/06/how-i-structure-go-packages/
https://engineering.kablamo.com.au/posts/2020/testing-go
https://eli.thegreenplace.net/2019/simple-go-project-layout-with-modules/
https://changelog.com/gotime/94
https://github.com/katzien/go-structure-examples
https://itnext.io/structuring-a-production-grade-rest-api-in-golang-c0229b3feedc
https://www.youtube.com/watch?v=KCyMtx5ev80&list=PLtoVuM73AmsKnUvoFizEmvWo0BbegkSIG&index=17&t=0s
https://www.youtube.com/watch?v=YfLPZOpJQjY&feature=youtu.be
https://aaf.engineering/go-web-application-structure-pt-1/
https://medium.com/@benbjohnson/structuring-applications-in-go-3b04be4ff091
https://www.sohamkamani.com/blog/2017/09/13/how-to-build-a-web-application-in-golang/
https://tutorialedge.net/golang/go-project-structure-best-practices/
http://josebalius.com/posts/go-app-structure/
https://www.wolfe.id.au/2020/03/10/how-do-i-structure-my-go-project/
https://cgansen.github.io/sxsw-go-talk/#/
https://www.perimeterx.com/tech-blog/2019/ok-lets-go/
https://peter.bourgon.org/go-best-practices-2016/#repository-structure
https://blog.learngoprogramming.com/code-organization-tips-with-packages-d30de0d11f46
https://blog.learngoprogramming.com/special-packages-and-directories-in-go-1d6295690a6b