# What have I done

## Hugo
Install hugo
```shell script
$ go get -u github.com/gohugoio/hugo@v0.66.0
```
Start new site
```shell script
$ cd ~/projects/
$ hugo new site ldej-nl
$ cd ldej-nl
$ git init
```
Add theme
```shell script
$ git submodule add https://github.com/azmelanar/hugo-theme-pixyll.git themes/pixyll
$ echo 'theme = "ananke"' >> config.toml
```
Create post
```shell script
$ hugo new post/first-post.md
```
Serve
```shell script
$ hugo server -D
```
Build static pages
```shell script
$ hugo -D
```

## Google Cloud

[Create a project](https://console.cloud.google.com/projectcreate)

[Go to the service accounts page](https://console.cloud.google.com/iam-admin/serviceaccounts)

Note down the email address

Press the three dots at the end and create a key with key type JSON

Base 64 encode the key
```shell script
$ cat ~/Downloads/key.json | base64
```

Enable the App Engine Admin API
`https://console.developers.google.com/apis/library/appengine.googleapis.com?project=<project-name>`

## Github

Create a repository

Go to the secrets page

`https://github.com/<username>/<repo>/settings/secrets`

Add a secret with name SA_EMAIL and as value the service account email address

Add a secret with name SA_KEY and as value the base64 encoded key

## Firebase

https://gohugo.io/hosting-and-deployment/hosting-on-firebase/

https://github.com/marketplace/actions/github-action-for-firebase

## Nice highlighting

```go {linenos=table,hl_lines=[8,"15-17"],linenostart=199}
package main

import (
    "fmt"
    "math/rand"
    "time"
)

type Moo struct {
    Cow   int
    Sound string
    Tube  chan bool
}

// A cow will moo until it is being milked
func cow(num int, mootube chan Moo) {
    tube := make(chan bool)
    for {
        select {
        case mootube <- Moo{num, "moo", tube}:
            fmt.Println("Cow number", num, "mooed through the mootube")
            <-tube
            fmt.Println("Cow number", num, "is being milked and stops mooing")
            mootube <- Moo{num, "mooh", nil}
            fmt.Println("Cow number", num, "moos one last time in relief")
            return
        default:
            fmt.Println("Cow number", num, "mooed through the mootube and was ignored")
            time.Sleep(time.Duration(rand.Int31n(1000)) * time.Millisecond)
        }
    }
}

// The farmer wants to turn on all the milktubes to stop the mooing
func farmer(numcows int, mootube chan Moo, farmertube chan string) {
    fmt.Println("Farmer starts listening to the mootube")
    for unrelievedCows := numcows; unrelievedCows > 0; {
        moo := <-mootube
        if moo.Sound == "mooh" {
            fmt.Println("Farmer heard a moo of relief from cow number", moo.Cow)
            unrelievedCows--
        } else {
            fmt.Println("Farmer heard a", moo.Sound, "from cow number", moo.Cow)
            time.Sleep(2e9)
            fmt.Println("Farmer starts the milking machine on cow number", moo.Cow)
            moo.Tube <- true
        }
    }
    fmt.Println("Farmer doesn't hear a single moo anymore. All done!")
    farmertube <- "yey!"
}

// The farm starts out with mooing cows that wants to be milked
func runFarm(numcows int) {
    farmertube := make(chan string)
    mootube := make(chan Moo)
    for cownum := 0; cownum < numcows; cownum++ {
        go cow(cownum, mootube)
    }
    go farmer(numcows, mootube, farmertube)
    farmerSaid := <-farmertube
    if farmerSaid == "yey!" {
        fmt.Println("All cows are happy.")
    }
}

func main() {
    runFarm(4)
    fmt.Println("done")
}
```