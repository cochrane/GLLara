---
title: Nightly Builds
author: cochrane
layout: default
---

Despite what it may look like, I do still work on GLLara every now and then, and I'm currently preparing version 0.3. It'll still be some months (maybe I'll manage to make a blog post about all the changes in it soonish), but if you want to give it a try, here's a new thing: You can now download automatically built test versions.

These test versions are available at the [Github actions page of the GLLara repository](https://github.com/cochrane/GLLara/actions/workflows/objective-c-xcode.yml). Click on the latest one, then scroll down to "Artifacts", and you can download it there. Note that Github does not keep them around forever; after ninety days, each version is gone forever.

## Warnings

These versions are created automatically whenever I change the code. They may not work at all, or work badly. They may damage your existing scene files by writing nonsense in them. There is literally no checks at all when you download such a nightly build; anything might happen. If that scares you, good.

As a result of all of this, there is no support for these at all. There is no support for GLLara at all anyway, but in particular for these versions, I won't even try to help you.

As a special note, these are not signed or notarized (meaning Apple hasn't checked them for malware), because I couldn't be bothered to implement these things. As a result, Mac OS will try to keep you from running them with lots of scary warnings. If you really want to do this anyway, right-click on the app and select "Open", then select "Open" in the dialog that pops up.

And finally, GLLara now requires Mac OS 12.3 (Monterey) or higher. I will bump this up to 13 (Ventura) fairly soon after that operating system is released.

## Conclusion

I've implemented these nightly builds largely to see whether I could. They are useful for really curious people, but don't rely on such a version. I will write more about the future of GLLara soonish, but in short: It's still around, as a hobby for me, and I'll update it whenever I feel like it.
