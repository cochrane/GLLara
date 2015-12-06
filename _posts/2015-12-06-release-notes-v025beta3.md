---
title: Beta 3 of Version 0.2.5 released
author: cochrane
layout: default
---

This is a test release for now, but should be pretty close to the main release of 0.2.5 unless anybody complains soon. **This release fixes the problems on OS X 10.11 "El Capitan".**

Please [download it](https://github.com/cochrane/GLLara/releases/tag/v0.2.5_beta3) and [tell me what doesn't work](https://github.com/cochrane/GLLara/issues)!

## What happened to Beta 2?

It's out there, under releases, I just forgot to make a blog post for it. But I have already [talked about](/GLLara/2015/11/29/house-cleaning.html) [the biggest improvements](/GLLara/2015/11/30/managing-kvo.html) anyway. The big take-away is that the german localization works again and that a lot of things that were weird, slow or crashy, or all three, now work flawlessly.

## The changes

The big one is "El Capitan" compatibility, which was all down to something I could fix in a single line. The main problem was that depth test didn't work, and also the clear color, which came all down to the wrong OpenGL context being set when I set up that state. Made for some interesting pictures, though:

![No depth test meant that stuff had an about even chance of appearing inside out, which was very weird.](/GLLara/screenshots/v025_beta3_pic1.jpg)


The other big change is user settings. Under "GLLara/Preferences", there is now a preference window that allows you to play with render settings. You can now play with anisotropy:

![This changes how blurry textures get when they are on a surface that is at a tilted angle, such as a floor.](/GLLara/screenshots/v025_beta3_anisotropy_off.jpg)
![Turning it on drastically increases the quality.](/GLLara/screenshots/v025_beta3_anisotropy_on.jpg)

And also with anti-aliasing, also known as multi-sampling.

![The difference is in the edges. Without anti-aliasing, they look jagged.](/GLLara/screenshots/v025_beta3_msaa_off.jpg)
![With it turned on, they are much smoother.](/GLLara/screenshots/v025_beta3_msaa_on.jpg)

Note: Anti-aliasing is not supported for rendering to a picture file. Just render at a larger size and calculate it down with Photoshop, that should do the trick. Also, don't be surprised if you don't see the difference between 2x MSAA and 8x MSAA. It's incredibly subtle. If you have a Mac with retina display, anti-aliasing may be entirely pointless.
