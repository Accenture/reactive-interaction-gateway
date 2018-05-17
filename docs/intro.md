---
id: intro
title: What is RIG?
sidebar_label: What is RIG?
---

(If you're in a hurry you can skip this part and go directly to [setting up your development environment](getting-started.md).)

## The ugly part of web apps: handling asynchronous events

Do you already use asynchronous events in your app? If you don't, you probably should. Just think of a website that shows game stats of your favorite sports team while they're on the field. I bet you'd expect the scores to be updated in real-time - you definitely don't want to refresh the page every 10 seconds. But how would you implement something like that in your app?

### Why polling is not the answer

The obvious thing to do is polling, which basically means hitting the server for updates, again and again. This is easy to implement and has the advantage of working everywhere, regardless of how old the browser or strange the firewall setup may be. However, there are also some downsides to it.

Imaging youself in a project where you're building a website that's composed of many smaller (React) components, and most of them show a different part of the state tree. Some of them might even present the same data in different ways. How would you make sure the UI always shows the _most recent_ data, just like on the sports website outlined above? There is a trade-off here: either you have the top-level component updat _all_ the data every few seconds (which might _still_ be too slow), or each component fetches the data it needs individually. Both approaches are less than ideal: fetching everything all the time causes loads of traffic. Most likely, you'll be overfetching, because some of the data you request will probably never change at all. Having each component fetch their own data sounds good at first, but it will cost you a lot in terms of performance and complexity (think loading indicators, handling debouncing, connection timeouts, synchronizing view state among components, ...).

From an architectural standpoint, your app generates a lot of unnecessary load that must be handled by the server, which means that your app cannot scale well with the number of users. Finally, each connection attempt may affect battery life when running on a mobile device.

### A better approach

The good news is: you can do a lot better with very little effort: leverage the Reactive Interaction Gateway to distribute events in an easy, scaleable way. It works like this: your app (frontend) subscribes to one or more _topics_ with RIG, where a topic could be a specific sports game, for example. Your game server (backend) simply POSTs new game events to RIG's internal endpoint and RIG will make sure the event is delivered to all frontends subscribed to that game (topic). This means your game server doesn't need any code to handle connections - it doesn't even need to have any state at all!

Having RIG handle frontend connections also makes it easier to scale-out and scale-in your services, simply because you don't loose any connections in the process. Less complexity, more scalability, happier customers.

To make life even easier, RIG comes with a basic API gateway implementation, which allows you to communicate both ways between your (micro)services and your frontends.
