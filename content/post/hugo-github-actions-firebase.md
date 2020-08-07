---
title: "Deploy your Hugo website to Firebase using Github Actions"
date: 2020-07-20T11:28:00+05:30
draft: false
summary: "How to deploy automatically build and deploy a Hugo website to Firebase using Github Actions."
image: /images/ladakh2.webp
tags:
- Hugo
- Firebase
- Github Actions
- Web

reddit:
  created: 1595246336
  url: https://www.reddit.com/r/ldej/comments/hujzir/deploy_your_hugo_website_to_firebase_using_github/
  title: "Deploy your Hugo website to Firebase using Github Actions"
---

I have used [Hugo](https://gohugo.io) to create my website, and I decided to deploy it to Firebase. I automated the deployment using Github Actions. The documentation of all of these is perfect, but when I tried to piece them together I needed to search a bit more to get it working. I created this guide to make it easier for everybody else.

## Create a Hugo website

To create your static website, you need to have Hugo installed. You can easily install Hugo using [various methods](https://gohugo.io/getting-started/installing) depending on your operating system and preferences.

I've got Go installed, the language that Hugo is written in and uses for its templates, so I'm using Go's dependency management:

```zsh
$ mkdir -p ~/projects/my-site
$ cd ~/projects/my-site
$ go mod init github.com/ldej/my-site
$ go get github.com/gohugoio/hugo
```

You can verify it's installed correctly by running:

```shell script
$ hugo version
Hugo Static Site Generator v0.74.2 linux/amd64 BuildDate: unknown
```

Create a new site by running:
```shell script
$ hugo new site . --force
```

Use `--force` because:
```shell script
$ hugo new site .
Error: ~/projects/my-site already exists and is not empty. See --force.
```

Pick a theme from [themes.gohugo.io](https://themes.gohugo.io/). Add it to the themes directory:
```shell script
$ git init
$ git submodule add https://github.com/lxndrblz/anatole.git themes/anatole
```

Add the theme to the site configuration:
```shell script
$ echo 'theme = "anatole"' >> config.toml
```

Create your first content:
```shell script
$ hugo new post/my-first-post.md
```

{{% tip title="Not all content is created equal" %}}
Each theme has its own names of content for which there are templates. [Hugo's quickstart](https://gohugo.io/getting-started/quick-start/) mentions **posts** because that is what their example theme requires. The anatole theme I'm using for this guide requires **post**.

Read the documentation of your theme carefully!
{{% /tip %}}

Add a line of content and change toggle `draft` to `false`:
```yaml
---
title: "My First Post"
date: 2020-07-20T11:56:41+05:30
draft: false
---

You can find about this project on [ldej.nl](https://ldej.nl/post/hugo-github-actions-firebase/).
```

Start the Hugo server:
```shell script
$ hugo server -D
```
Visit [https://localhost:1313/](https://localhost:1313/) and view your website.

{{% tip title="What is -D doing?" %}}
Content marked as `draft: true` will not be included by default. However, you still want to be able to see your draft content, either locally or in a test/staging environment. When you add the `-D` parameter, content marked as draft will be included too.
{{% /tip %}}

## Set up Firebase

Firebase is Googles Backend-as-a-Service (BaaS). It has great integrations with all kinds of services, and the free tier includes hosting of static content, like your Hugo website. I like using Firebase as it gives me the opportunity to use Cloud Firestore and Cloud Functions as well as Authentication. Another great benefit is the easy setup of Analytics.

If you haven't already, create an account and head over to [console.firebase.google.com](https://console.firebase.google.com/).

Create a project and choose a good name for your project. The project name you choose is where your website will be available, for example [my-site-ldej-nl.web.app](https://my-site-ldej-nl.web.app). You can change the display name later, but you cannot change the url, so choose carefully. Of course, you can always add your own custom domain name.

Once your project has been created, let's get your environment ready for deployment.

First install the Firebase tools:
```shell script
$ npm install -g firebase-tools
```

Log in to Firebase:
```shell script
$ firebase login
```

In the root of your project run `firebase init`. It is going to ask you a number of questions:
```console {hl_lines=[18]}
$ firebase init

     ######## #### ########  ######## ########     ###     ######  ########
     ##        ##  ##     ## ##       ##     ##  ##   ##  ##       ##
     ######    ##  ########  ######   ########  #########  ######  ######
     ##        ##  ##    ##  ##       ##     ## ##     ##       ## ##
     ##       #### ##     ## ######## ########  ##     ##  ######  ########

You're about to initialize a Firebase project in this directory:

  ~/projects/my-site

Which Firebase CLI features do you want to set up for this folder? Press Space
 to select features, then Enter to confirm your choices. 
 ◯ Database: Deploy Firebase Realtime Database Rules
 ◯ Firestore: Deploy rules and create indexes for Firestore
 ◯ Functions: Configure and deploy Cloud Functions
❯◉ Hosting: Configure and deploy Firebase Hosting sites
 ◯ Storage: Deploy Cloud Storage security rules
 ◯ Emulators: Set up local emulators for Firebase features
```

1. Select the Hosting option.
1. Then choose `Select an existing project`.
1. Then select the project you just created.
1. Keep the `public` directory as your public directory.
1. When it asks if you want to configure as a single-page app, choose `N`.

Now the Firebase configuration is finished, and it's time to configure Hugo.

## Configure Hugo for multiple environments

Your project's root folder will contain a configuration file called `config.toml`. It contains:
```toml
baseURL = "http://example.org/"
languageCode = "en-us"
title = "My New Hugo Site"
theme = "anatole"
```
The `baseURL` is used for constructing urls, for example for loading your css files. On localhost this url should be empty, and on Firebase it has to be your projects url (i.e. https://my-site-ldej-nl.web.app). To accommodate for this, let's create a folder called `config`. In there, create three folders named `_default`, `development` and `production`. Each of these folders will contain a `config.toml`:
```shell script
$ tree config
config
├── _default
│   └── config.toml
├── development
│   └── config.toml
└── production
    └── config.toml
```

- In `_default/config.toml`, add the `languageCode`, `title` and `theme`.
- In `development/config.toml`, add `baseURL = ""`.
- In `production/config.toml`, add `baseURL = "https://my-site-ldej-nl.web.app`, but replace the url with your own project's url.

Remove the `config.toml` file from the root of your project.

{{% tip title="Hugo is smart" %}}
Whenever you run `hugo server`, Hugo will automatically use the configuration for the development environment. It will use all configuration in `_default` and merge `development`'s on top of it. When you run `hugo` it will automatically do the same for `production`. Read more about [how to configure Hugo](https://gohugo.io/getting-started/configuration/).
{{% /tip %}}

## Deploy to Firebase

Build Hugo's production static files by running:
```shell script
$ hugo
```
The static files end up in the `public` directory.

Deploy your application with:
```shell script
$ firebase deploy
```

Congratulations, you have just deployed your website to Firebase!

## Automate deployment using Github Actions

First, head over to [github.com/new](https://github.com/new) and create a repository for your project.

You don't have to run `git init` anymore as you did this when adding a theme to Hugo.

Add `public/` to the `.gitignore` file.

Run the commands that Github is suggesting:
```shell script
$ git add .
$ git commit -m "First commit"
$ git remote add origin git@github.com:<your-github-id>/<your-project>.git
$ git push -u origin master
```

Now you have a choice, either you use the Github Actions web interface, or you create the files yourself.

{{% figure src="/images/github-actions.png" alt="Github Actions" %}}

When you set up a workflow via the web interface, you can search in the [marketplace](https://github.com/marketplace) to find all the actions you might want to include in your project.

If you prefer to stay within your IDE, create a folder called `.github/workflows/` and add a file called `hugo.yaml`.

The build and deployment script is going to need to following steps:

1. Checkout the repository and the submodule in the themes folder 
```yaml
- name: Check out code into the Go module directory
  uses: actions/checkout@v2
  with:
    submodules: true  # Fetch Hugo themes (true OR recursive)
    fetch-depth: 0    # Fetch all history for .GitInfo and .Lastmod
```
2. Set up and make the command `hugo` available
```yaml
- name: Hugo setup
  uses: peaceiris/actions-hugo@v2.4.12
  with:
      # The Hugo version to download (if necessary) and use. Example: 0.58.2
      hugo-version: latest # optional, default is latest
      # Download (if necessary) and use Hugo extended version. Example: true
      extended: false # optional, default is false
```
3. Build the static files
```yaml
- name: Build
  run: hugo
```
4. Deploy to Firebase
```yaml
- name: Deploy to Firebase
  uses: w9jds/firebase-action@master
  with:
    args: deploy --only hosting
  env:
    FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
```
Putting it all together, it should look like:
```yaml
name: Hugo
on: [push]
jobs:

  build:
    name: Build
    runs-on: ubuntu-latest
    steps:

      - name: Check out code into the Go module directory
        uses: actions/checkout@v2
        with:
          submodules: true  # Fetch Hugo themes (true OR recursive)
          fetch-depth: 0    # Fetch all history for .GitInfo and .Lastmod

      - name: Hugo setup
        uses: peaceiris/actions-hugo@v2.4.12
        with:
          # The Hugo version to download (if necessary) and use. Example: 0.58.2
          hugo-version: latest # optional, default is latest
          # Download (if necessary) and use Hugo extended version. Example: true
          extended: false # optional, default is false

      - name: Build
        run: hugo

      - name: Deploy to Firebase
        uses: w9jds/firebase-action@master
        with:
          args: deploy --only hosting
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
```

The last step uses `${{ secrets.FIREBASE_TOKEN }}`. You don't want to insert your Firebase token directly into your Github repository as it will allow others to deploy to your project. Instead, you can configure secrets per repository.

Let's first generate a Firebase deployment token using:
```shell script
$ firebase login:ci
```
Keep this token private, so do not add it to your public repository.

In your Github repository, go to Settings, select Secrets in the left-hand menu and then click on New secret on the right.

The name of your secret should be `FIREBASE_TOKEN` and the value should be the token you just generated.

When you have added the secret, you can commit your workflow file via the interface or commit and push directly.

Your Github Action workflow should start automatically and deploy your website to Firebase.

## Conclusion

Creating a website using Hugo is super easy. I haven't talked about any configuration or customizations yet, more on that in future posts. Firebase is an ideal hosting place to start with, as long as you stay within the free tier. Using Firebase allows for usage of more great services of the Google Cloud Platform. With Github you can create private repositories and Github Actions make it incredibly easy to build and deploy anything you want to.

You can find the Github repository here: https://github.com/ldej/my-site-example

You can find the deployed end-result here: https://my-site-ldej-nl.web.app/
