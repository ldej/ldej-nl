---
title: "Deploy your Hugo website to statichost.eu"
date: 2026-10-09T16:31:57+02:00
draft: true
summary: "How to build and deploy a Hugo website from a git repository to statichost.eu, including the webhook that triggers a build."
image: images/roadtrip09.webp
tags:
- Hugo
- statichost.eu
- Github Actions
- Web
---

A few years ago I wrote about [deploying a Hugo website to Firebase using Github Actions](/post/hugo-github-actions-firebase/). That setup worked, but my website was tied to a Google account, and I never liked depending on a free tier that Google can change whenever it wants. So I moved ldej.nl to [statichost.eu](https://www.statichost.eu/). It runs on European infrastructure, and unlike most "European" hosting it is a European company rather than a European region of an American cloud.

The documentation is good, but it describes one thing at a time. Putting it together took me an afternoon, and two traps took most of that afternoon. This is the guide I would have liked to read.

## How statichost works

statichost has two parts, and it is worth knowing which one you are talking to. A _builder_ clones your git repository, builds your site in a Docker container that you choose, and publishes the output directory. An _edge network_ then serves those files, with a certificate per domain.

There is no integration that builds on push unless you register a webhook yourself. That is the first trap, and there is [a section about it](#trigger-a-build) below.

Your site also gets a managed domain, `<site-name>.statichost.page`, and that name has to be unique among all their customers. Mine is [ldej.statichost.page](https://ldej.statichost.page/), which is what ldej.nl now points at.

## Connect the repository

In the dashboard you add a site and connect a repository.

If your repository is public, use its HTTPS URL, because cloning then needs no credentials: `https://github.com/you/your-site.git`. If it is private, use the SSH URL and paste the site's public key into your repository as a read-only deploy key. I used SSH, because that is what my local remote already was, and it works fine as long as you do not forget the key.

{{% tip title="Submodules are cloned for you" %}}
Git submodules are cloned recursively, which matters when your theme lives in one, as mine does. Public submodules over HTTPS work without extra setup. Private ones need a message to their support.
{{% /tip %}}

## Tell the builder how to build

Build configuration lives in a `statichost.yml` file in the root of your repository:

```yaml
image: hugomods/hugo:0.165.0
command: hugo --environment production --minify
public: public
```

All three keys are optional. `image` is any public Docker image, built for `linux/amd64`. Leave it out and nothing is built, so the `public` directory is published as it is, which is useful if you build in your own CI. `command` runs inside that container, with your repository at `/repo` as the working directory, through `/bin/sh`, so `&&` works. `public` is the directory to publish.

{{% tip title="Pin your build image" %}}
I wish I had done this from the start. My Github Actions workflow asked for `hugo-version: latest` in 2020. By the time I pushed again, the latest Hugo had removed a field that my theme's feed template used, so that push built nothing and deployed nothing, and the failure was only visible if you went looking for it. Pinning `hugomods/hugo:0.165.0` keeps a build reproducible months later, and when it breaks you know who to blame.
{{% /tip %}}

You can reproduce what the builder does on your own machine, which is the fastest way to iterate:

```shell script
$ docker run --rm -v "$PWD":/repo -w /repo hugomods/hugo:0.165.0 \
    hugo --environment production --minify -d /repo/public
```

## Trigger a build

Connecting a repository does not make statichost build on push. You have to send a webhook:

```shell script
$ curl -X POST https://builder.statichost.eu/your-site-name
Started build 3KSff57KRdWV8WD052IEmSGbiPW
```

You can register that URL as a webhook in your git provider. I put it in the repository instead, where it is versioned and where it is obvious which branch deploys:

```yaml
name: Deploy to statichost.eu
on:
  push:
    branches: [main]

jobs:
  trigger:
    name: Trigger build
    runs-on: ubuntu-latest
    steps:
      - name: POST the statichost webhook
        env:
          STATICHOST_API_KEY: ${{ secrets.STATICHOST_API_KEY }}
        run: |
          set -euo pipefail
          token="${STATICHOST_API_KEY:-}"
          headers=(-H "Accept: application/json")
          if [ -n "$token" ]; then
            headers+=(-H "Authorization: Bearer ${token}")
          fi
          response=$(curl -sS -m 60 -X POST "${headers[@]}" \
            https://builder.statichost.eu/your-site-name)
          echo "statichost said: ${response}"
          case "${response}" in
            *"Started build"*) echo "build queued" ;;
            *) echo "::error::statichost did not queue a build"; exit 1 ;;
          esac
```

The last lines exist because of the lesson above. If the response is not the one you expect, the workflow fails. A deploy that does not happen is worse than one that fails loudly.

{{% tip title="Locking down the webhook" %}}
By default the webhook is unauthenticated, so anyone who knows your site name can start a build. The worst they can do is waste some build time. If that bothers you, enable authentication under Settings, Source and build, and send an API key along as a bearer token. You create the key under My account.
{{% /tip %}}

## Point your domain at it

Add the domain in the site settings, then change your DNS. Do it in that order, because the certificate is issued on the first request that arrives with your domain.

- `www.example.org` gets a `CNAME` record pointing at `your-site-name.statichost.page`.
- `example.org` gets an `ALIAS` or `ANAME` record pointing at the same name, if your DNS provider has one, because a root domain cannot be a `CNAME`.

{{% tip title="If your DNS provider has no ALIAS" %}}
Mine is at TransIP, which offers A, AAAA, CNAME, MX, NS, TXT, SRV, SSHFP and TLSA records, but no ALIAS. For a root domain you then use their main server: an A record to `95.217.26.94` and an AAAA record to `2a01:4f9:c01f:8002::`. HTTPS and IPv6 both work, but unlike an ALIAS you are the one who has to notice if those addresses change.
{{% /tip %}}

While you are editing DNS, leave alone everything that is not a web record: your `MX`, the `SPF` and verification `TXT` records, `_dmarc`, and the `autodiscover` and `autoconfig` entries that mail clients use. Moving a website should not move an inbox. Use a TTL of 300 seconds for the first day, so a mistake is cheap to undo, and raise it afterwards.

## Verify the deploy

Two commands tell you whether statichost is really serving the site:

```shell script
$ dig @ns1.your-registrar.net +short A example.org
95.217.26.94

$ curl -sI https://example.org/ | grep -i server
server: statichost.eu
```

{{% tip title="Caching can make a good deploy look broken" %}}
Pages come back with `Cache-Control: public, max-age=0, must-revalidate`, but their edge can still hand you a stale copy, and adding `?v=123` to the URL does not reliably bust it. This is what made me conclude that a working pipeline was broken. Use the request header instead, and give a build a few minutes before you give up on it:

```shell script
$ curl -s -H 'Cache-Control: no-cache' https://example.org/ | grep -i canonical
```
{{% /tip %}}

## Keep the mirror out of search results

Your site stays reachable on `your-site-name.statichost.page` after you add your own domain, so every page exists twice. There is no way to mark only the mirror as `noindex` with a header, because the `_headers` file matches paths and not hosts, which means an `X-Robots-Tag: noindex` there would also deindex the real domain.

A canonical URL is the supported answer for this. Check that yours is absolute, so that the mirror points search engines at the real domain:

```html
<link rel="canonical" href="{{ .Permalink }}" itemprop="url" />
```

My own `meta.html` had `{{ .RelPermalink }}` there, which produces `../about/`, so the mirror was telling search engines that the mirror was the original.

## What modern Hugo broke in my 2020 setup

I did not expect to write this section. Moving my build to a current Hugo broke a few things, and a successful build is no proof that the pages exist.

- A root-level page such as `content/about.md` no longer has its template `type` defaulted to `page`, so it stopped matching `layouts/page/single.html` and disappeared from `public/`, while still being listed in the sitemap. Adding `type: "page"` to the front matter fixed it. Compare your URL set against the live site after every upgrade.
- `.Site.Author` was removed, which broke the feed template in my theme. I override it from my own `layouts/rss.xml` instead of patching a submodule.
- `[indexes]` became `[taxonomies]` and changed which taxonomy pages were built, so an empty `/categories/` disappeared. `languageCode` became `locale`. `.Site.Data` became `hugo.Data`, which on older Hugo drops the page that reads it without an error.

## Conclusion

Statichost is a smaller product than Firebase, and that is why I like it. There is no project to create, no interview with `firebase init`, and no analytics or database services tempting me to couple my website to a platform. It is a git repository, a Docker image, and a directory to publish.

What you have to do yourself is the trigger and the DNS, and then check both. That is one afternoon, once you know that nothing builds on push until you ask it to, and that a stale cache can make a working pipeline look dead.

This website is the example. The source is [github.com/ldej/ldej-nl](https://github.com/ldej/ldej-nl), with the build configuration in `statichost.yml` and the deploy trigger in `.github/workflows/deploy-statichost.yml`.
