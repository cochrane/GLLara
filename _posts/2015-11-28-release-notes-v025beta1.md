---
title: Beta 1 of Version 0.2.5 released
author: cochrane
layout: default
---

This is a test release for people on Intel GPUs that had weird issues with lighting not working properly. People who don't have an Intel GPU should notice fewer changes, but there is a bug with normal maps that has been resolved.

Please [download it](https://github.com/cochrane/GLLara/releases/tag/v0.2.5_beta1) and [tell me what doesn't work](https://github.com/cochrane/GLLara/issues)!

## The technical stuff

This solves two distinct but related bugs, both in the vertex array optimizations I mentioned [last time](https://cochrane.github.io/GLLara/2015/11/27/optimizations-in-v024.html).

The first was something simple: The stride (size per vertex) was calculated wrong and thus too large. Thankfully, this was done in the same wrong way in all places, so the only effect was using four (rarely eight, even more rarely zero) bytes more than necessary. This was less of a bug and more a thing I found annoying; it had no visual effect on anything.

The other part was rather more involved: Due to a similar calculation bug, the offset that was told OpenGL for the tangents was not identical to the offset that was actually used; the tangents were instead overlapping another vertex attribute. Some discrete graphics cards seemed to shrug this off (I don't know how), but the Intel ones would genrate incorrect values for the tangents. That in turn threw off the rest of the lighting calculations, and made the models always seem unlit.

It's the latter bug that I think caused some of the issues that were reported to me. And since I only have an Intel HD 3000 (as alternate card in my MacBook Pro), not the 4000 that seems to be generating all the errors, I cannot really test it other than make a release and hope people scream at me. The 3000 also has some other fun issues that I cannot make sense of, but as long as they don't appear on the more popular cards, I will just ignore them.
