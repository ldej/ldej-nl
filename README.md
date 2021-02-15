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

## IntelliJ Proofreading Spellcheck en_GB

Install Hunspell plugin

```shell
$ wget -O en_GB.aff https://cgit.freedesktop.org/libreoffice/dictionaries/plain/en/en_GB.aff
$ wget -O en_GB.dic https://cgit.freedesktop.org/libreoffice/dictionaries/plain/en/en_GB.dic
```

In the `Settings/Preferences` dialog `Ctrl+Alt+S`, select `Editor | Proofreading | Spelling`. To add the new custom dictionary to the list, click the Add button or press Alt+Insert and specify the location of the `en_GB.dic` file.