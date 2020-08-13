---
title: "Generators in Go"
date: 2020-08-13T12:23:24+05:30
source: https://blog.haardiek.org/generators-in-go
tags:
- Go
---

Sven Haardiek created a beautiful Python-like generator in Go.

```go
package main

import "fmt"

type fibonacciChan chan int

func (f fibonacciChan) Next() *int {
	c, ok := <-f
	if !ok {
		return nil
	}
	return &c
}

func fibonacci(limit int) fibonacciChan {
	c := make(chan int)
	a := 0
	b := 1
	go func() {
		for {
			if limit == 0 {
				close(c)
				return
			}
			c <- a
			a, b = b, a+b
			limit--
		}
	}()
	return c
}

func main() {
	f := fibonacci(20)
	fmt.Printf("%v ", *f.Next())
	fmt.Printf("%v ", *f.Next())
	for r := range f {
		fmt.Printf("%v ", r)
	}
}
```