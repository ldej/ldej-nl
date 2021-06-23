---
title: "Switching From Gmail to ProtonMail"
date: 2021-06-23T10:14:35+05:30
draft: false
summary: I switched from Gmail to ProtonMail and decided to live with the consequences.
image: images/roadtrip07.webp
tags:
- Personal
---

There are many good reasons to switch from Gmail to another e-mail provider. I am very slowly trying to de-Google my life, but I'm not the person to go to the extreme and live with discomfort. One day I will use a phone without Android, hope that DuckDuckGo will support bubbles, and maybe convince the hundreds of YouTube creators I follow to switch to a decentralized alternative. Until then, I am trying my first steps by switching from Gmail to ProtonMail.

I found out about ProtonMail while it was still in beta in 2014. I created an account, looked around and thought: "Yes, this looks like another e-mail provider, but why should I change?"

## Transferring existing e-mails

Changing from e-mail provider can be a hassle, depending on your requirements and set-up. The most important requirement for me is to be able to do a full switch. I do not want to maintain two personal e-mail boxes next to my work e-mail and possibly a clients e-mail box. This means I need to be able to transfer all of my e-mails from Gmail to ProtonMail.

ProtonMail has [an excellent guide](https://ProtonMail.com/support/knowledge-base/transitioning-from-gmail-to-ProtonMail/) on how to migrate from Gmail to ProtonMail. There is an [Import Assistant](https://account.ProtonMail.com/u/0/mail/import-export) to help you transfer your existing e-mails.

While ProtonMail is importing your e-mails, you do not want to miss out on any e-mails that you receive on your Gmail. This is why you should start by configuring e-mail forwarding from your Gmail to ProtonMail first. When you have done that, use the Import Assistant to transfer your e-mails.

When you are using the Import Assistant to import all mails from your Gmail, do not use the Android app until the import finishes. The Android app will feel sluggish and inconsistent. After the Import Assistant finished, I cleared all data from the app, and logged in again. It might take some time (hours, maybe days), for the app to work normally, but eventually it will.

My [Google One Storage](https://one.google.com/storage) indicated that my Gmail uses 2.77 GB of the free 15 GB that you get with your account. After using the Import Assistant, ProtonMail told me that it imported 1.68 GB of data.

{{% figure src="/images/protonmail-import.png" alt="ProtonMail import" %}}

The report about the import contained a couple of e-mails that could not be imported. In 2011, I used a tool that would automatically back-up Whatsapp chats including all pictures and videos into Gmail. There are a couple of these e-mails with more than 150 attachments that could not be imported, the error message reads "Failed to scan email". However, these e-mails do not add up to the more than 1 GB difference in data.

I decided to download a copy of my Gmail from [Takeout](https://takeout.google.com) and see if I can explain the difference. The archive I downloaded is 4.7 GB, which is way more than the 2.77 GB that Google One Storage reported and the 1.68 GB that got imported into ProtonMail. This requires more investigation, probably in a future blog post.

## Inbox or Important?

After having imported your e-mails from Gmail, you find out that a folder has been created called `Gmail/Important`. At some point, Google introduced the smart notification feature. It makes sure that you do not get bugged for every not important e-mail like newsletters, surveys and other automated mails. With the introduction of this feature, they abandoned the main inbox and used a hidden folder called Important. Any e-mail deemed important by Google would be moved to this folder, resulting in a notification on your phone.

This means that after importing your Gmail e-mails, your ProtonMail Inbox contains the e-mails that came into your Gmail Inbox before Google introduced the smart notification feature. And part of what you think should be in your inbox, is now in your Gmail/Important folder in ProtonMail.

In other words, after the import, you will need to reorganize your inbox completely. I removed the Gmail/Important folder in ProtonMail, without removing all the e-mails it contained. Which means my ProtonMail Inbox contained all 31k+ from my 15 years history of Gmail.

I actively maintain my e-mail, and I'm a big user of the archive functionality. My inbox contains only e-mails I need to respond to, want to read, or where I am waiting for the other party to respond. This generally means I've got a maximum of 10 to 15 e-mails waiting for me.

With all mails being in my ProtonMail Inbox, I hoped I would be able to archive all mail, and manually move the 10-15 important e-mails back to my Inbox. Unfortunately, there is no option to archive all e-mails at once. This means you need to select all e-mails, move them to the archive, and go to the next page to do the same. <sup>[[1]](https://protonmail.uservoice.com/forums/284483-protonmail/suggestions/7840971-a-select-all-feature-similar-to-g-mail)</sup>

Thankfully ProtonMail has keyboard shortcuts to alleviate the pain a bit. You can find the shortcuts by typing `?`. My flow consisted going to the All mail section, selecting all mail on the current page (`Ctrl+A`), move them to the archive (`A`), and going to the next page. Unfortunately, there is no keyboard shortcut to the next page, so I left my mouse at the `›` and clicked to go to the next page. 31k e-mails, 50 per page, is 620 clicks. There has got to be a better alternative.

## Custom domain

As almost every software engineer, I too own a domain name. That's what you are reading this blog on right now. With most services where I need to enter an e-mail address, I use some form of `<service>@my.domain`. This has the benefit of being able to track if your e-mail address has been sold (which has definitely happened a handful of times) and making it easier to categorize e-mails. However, in cases where you are talking to an employee, and they ask for your e-mail address, it has resulted in question marks on their faces.

Having a custom domain name makes migrating a lot easier. I did not have to go to hundreds of places to change my e-mail address. ProtonMail [supports](https://protonmail.com/support/knowledge-base/paid-plans/) custom domain names in the Plus plan, but only supports a [Catch-all](https://protonmail.com/support/knowledge-base/catch-all/) email address in the Professional and Visionary plans. In my case, my domain name is registered with [TransIP](https://www.transip.nl/), that is where I use the e-mail catch-all functionality, TransIP forwards all my e-mails to my ProtonMail.

## Living with the consequences

It has been a little over 3 months, and I can now happily report on the good, the bad and the ugly.

## The Good

ProtonMail has progressed a lot since I discovered them while they were in Beta. The web version feels mature and has most of the features I am looking for. ProtonMail is famous for being a good choice in case you are a privacy enthusiast. I am happy to pay for the Plus plan.

While I was switching from Gmail to ProtonMail, I was also exploring the Android app. After the import of mails had completed, I tried to open the Gmail/Important folder in the app, but it crashed the app. How is this in the "Good" section you ask? Well, I e-mailed support to ask what was going on, and they replied within 10 hours. I was trying out the ProtonMail Android app [at the same moment that Google was messing up their Android System WebView](https://9to5google.com/2021/03/23/android-apps-crashing-webview/). ProtonMail explained the problem, and how to fix it. I failed to respond to their e-mail and two days later got another e-mail asking if I managed to solve the problem. The problem got solved, and the ticket could be closed.

## The Ugly

I know you want to read the bad ones first, but I'm going to start with the ugly ones. What I mean with the ugly ones are the things I miss in ProtonMail that I did have in Gmail, but which I do not want ProtonMail to have. Let me explain that.

Gmail has absolutely nailed the sorting of e-mails. Their spam detection is insanely good, and you only realise that when you don't have it anymore. Most of the spam coming into my Gmail is addressed to my actual `@gmail.com` address, which makes filtering it very easy. However, some of my `<service>@my.domain` addresses have either been sold or were part of data breaches. Mails addressed to these addresses would often be recognised by Gmail as spam, but in ProtonMail I will need to do this myself. Good thing that I can easily isolate these mails by the `to` field.

As I said before, Gmail has the Important email box. ProtonMail does not have this feature. This means that all e-mails will come into your Inbox. All newsletters, surveys, and other mails you do not want to be notified about immediately. This means I have been unsubscribing a lot of newsletters, managing e-mail settings in websites, and adding filtering rules to move e-mails to folders automatically. Having said this, I am completely fine with this. It forced my to manage my e-mail even better, and I'm hoping it means that ProtonMail does not snoop as much as Gmail.

The last thing in this category is search. I search in my mail A LOT. Gmail is the best when is comes to searching, as it not only searching your mails, it also searches in all attachments. Full-text and attachment search is not possible in ProtonMail:

> ProtonMail allows you to search by:
> - Keyword (in the subject line only)
> - Location (Inbox, Drafts, Sent, Archive, Spam, Trash, or custom folder)
> - Email address
> - Date message was sent or received
> - Attachments (only if a message has an attachment or not, not the name of the attachment)
> 
> You cannot search the contents of messages because all emails are stored on our servers using zero-knowledge encryption that prevents us from reading message contents.

Source: https://protonmail.com/support/knowledge-base/search/

Not being able to search is quite annoying, and I do find myself hopping over to Gmail in some cases when I know Gmail will be able to find text in content. However, the longer I'll be using ProtonMail, the more e-mails will be part of the realm of mails that cannot be searched. The only alternative is to use an e-mail client on my desktop, connect with the [ProtonMail Bridge](https://protonmail.com/bridge/), download all mails and index them to make them searchable. I'm not a big fan of those, so please let me know if you know a good one.

## The Bad

With "the ugly" being things I don't want ProtonMail to have, "the bad" are the things I wish ProtonMail has and which they can most definitely make without compromising my privacy.

One major downside that needs to be improved is the Android app. If you think about using a different app on your phone for ProtonMail, that is not possible.

First, it does not support grouping of e-mails. Don't overthink it, I just mean that when somebody replies to an e-mail, it will be part of the e-mail thread. Threads do not exist on the Android app. This means that you are looking at the old school subjects like: `RE: RE: FW: RE: Some subject here`, where each mail is listed as a separate email with no ability to jump to the next or previous mail. It also means that, when you send an e-mail, and somebody replies, you will only see the reply in your inbox. Usually the reply contains your original mail as well, but if not, then you need to search through your sent e-mails. <sup>[[2]](https://protonmail.uservoice.com/forums/284483-protonmail/suggestions/19632223-threads-on-android-app)</sup>

It also means that interactions with your mails are different between the desktop and app. When you archive a thread in on your desktop, all mails in that thread will be archived. When you archive an e-mail in the app, it will only archive that single e-mail, and not the thread. It is quite frustrating.

Another frustrating feature is the notifications in Android. As I said before I have tried to manage the incoming e-mails already, but there is this other thing. Let's say you receive an e-mail and see the notification on your phone. I might be sitting at my desktop and decide to read my mail there. In Gmail, the Android notification would disappear when you have marked the mail as read on your desktop. Alright, this might be an advanced feature, however, it gets more annoying. Let's say I swipe away the notification, and another e-mail comes in. The Android notification will show that 2 new mails have been received, even though the first one has been marked as read already. You need to open the Android app for it to realise that there is no unread e-mail anymore. <sup>[[3]](https://protonmail.uservoice.com/forums/284483-protonmail/suggestions/14895333-notification-synchronization)</sup>

One last pet peeve I want to talk about is the auto advance feature, or better, the lack thereof. In Gmail, you can configure to automatically open the next e-mail in case of archiving or deleting. This lets you rapidly go through your unread mails and decide what to do with them. I would love to see this on both desktop and Android.  <sup>[[4]](https://protonmail.uservoice.com/forums/284483-protonmail/suggestions/16823068-auto-select-next-mail-after-move-to-trash)</sup>

## Conclusion

I'm very happy with my switch from Gmail to ProtonMail, it went way smoother than expected. My advice is to use a custom domain everywhere, so you will only have a single place to change when you want to move from one mail provider to another.

I hope the [promised redesign of the mobile app](https://old.reddit.com/r/ProtonMail/comments/nv47xg/the_new_protonmail_web_app_has_launched/h11wiie/) will include mail treads and an optimized notifications.