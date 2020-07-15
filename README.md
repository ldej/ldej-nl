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

