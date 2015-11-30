---
title: Managing Key-Value Observing
author: cochrane
layout: default
---

Does anyone still remember the good old days of the mid-2000s? Back then Intel Macs were first a rumor, then a hot new thing (but you couldn't drop support for PowerPC just yet). The iPod had just exploded and the iPhone was nothing but a persistent rumor - and only the authors of joke sites predicted that it would only have one button. And on the development side, we still thought the highly dynamic nature of Objective-C, and the things it enabled, were a feature, not a bug, and that there was value in having a small versatile language instead of one with a special case for every last thing, down to a `guard-let-where-else` construct to "make code easier to understand." No I'm not annoyed with Swift at all…

Okay, I am, but I'm also somewhat unfair. The truth is most of that dynamic nature often hurt more than it helped, something that e.g. [Brent Simmons knew][inessentialkvo] way before Swift. And while you may disagree with him, he's not someone you can just dismiss. For many problems, it was simply the wrong tool. Nobody ever used `NSProxy`. Higher Order Messaging was a giant mess, and for-in loops and blocks are better in every situation. People had realized that you shouldn't type your variables as `id` without a very good reason long before I started programming. To a large degree, Swift is the logical conclusion of a development from theoretically interesting freedom to a strict, structured thing that actually lets you get work done, and that development started long before. 

GLLara doesn't do anything crazy with dynamic Objective-C, except for the one thing that did go mainstream, but that's also maybe the most crazy of them all; the one Brent Simmons complained about in the post I linked to: Bindings and Key-Value Observing. Awesome technological achievements that make a lot of stuff very easy, but also things that will entangle your code flow to no end, cause all sorts of trouble and performance issue. It's no surprise that some key elements of the system (the controller classes) never made it to iOS, and probably never will now.

The part that caused problems for me was always the meshes view in the settings window. It never worked reliably, because it had a lot of weird stuff to do: The tables don't represent lists, but named placeholders, each of which edits the same attribute on all of the selected objects. Doing that with NSArrayController required a lot of hacking. Think `+[NSString stringWithFormat:]` to find key paths to bind to. This should scare you. There were also massive performance issues when selections got large, due to observers registering and deregistering.

The solution now is a bit roundabout, but works. Each binding now takes place through a special placeholder class. This placeholder class has a `value` property that can be bound to (we're not monsters here, I keep using bindings for things where it makes sense). It also has a selection that it observes for changes. And it listens for DidUndo/DidRedo notifications.

Updating is simple: Go through selection, get the value for every object (using an accessor method that's overriden in subclasses), if you get two different ones simply use the default multiple value marker. When a new value is set through the property, simply force it on all objects in the selection. The update is triggered by undo, redo and selection changes.

This means the new class only works if all mutations go through it or through undo/redo. Otherwise its value will be stale. Enforcing this requirement is easy, though, because there's only one relevant UI element and not a lot of other options for the value to change.

The result: All the crashes when changing shaders are gone. Changing a color value for a thousand meshes works instantly. There are still a few minor things to adjust, but it seems like 0.2.6 should be ready for release some time this week and bring a lot of improvements here.

[inessentialkvo]: http://inessential.com/2007/04/25/thoughts_about_large_cocoa_projects