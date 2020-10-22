# ldej.nl

![Hugo](https://github.com/ldej/ldej-nl/workflows/Hugo/badge.svg)

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
$ echo 'theme = "pixyll"' >> config.toml
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

## Firebase

https://gohugo.io/hosting-and-deployment/hosting-on-firebase/

https://github.com/marketplace/actions/github-action-for-firebase