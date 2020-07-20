---
title: "Go IntelliJ Magic"
date: 2020-07-13T15:24:06+05:30
source: https://www.youtube.com/watch?v=arZiFSerU1k
tags: 
- IntelliJ
- Go
---

1. Adding `.nn` to  `err`. 
```go
err.nn<enter>
```
->
```go
if err != nil {
    
}
```
   
2. Ending a call with `.var` expands to variables at the start of the statement
```go
myFunction(param1, param2).var<enter>
```
->
```go
something, err := myFunction(param1, param2)
```

3. `Ctrl-Shift-E` Gives a list of recent locations you visited
