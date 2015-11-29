---
title: House cleaning
author: cochrane
layout: default
---

It's been about three years since I last did any real work on this app, so a lot of stuff has accumulated that isn't necessary and/or doesn't work anymore. Now it's finally gone.

First of all, localization. I'm a big fan of it and GLLara is and will continue to be available in german and english. The problem was that the german version didn't work. This was in turn because I used DMLocalization, a non-standard system with individual string files and manual fix-up methods afterwards. It worked well while it lasted, but needed updating for newer OS X.

But in the meantime, Apple introduced base localizations, which work essentially exactly the same as DHLocalization, down to using the same type of string files, except for some minor differences that some Regexp use could take care of. This is done now, so starting in version 0.2.6 (or 0.2.5 final? I have no idea what version numbering to use), GLLara will appear fully in German once more. If you want your own language to appear, contact me and I'll write a guide on how to do it. Or if you're really curious, just poke around in the code (look for folders called `de.lproj` and `en.lproj` and compare them) and see for yourself. It's not hard

After that, it was Sparkle. Sparkle is a tool for automatic app updating; in theory very useful here, but in practice I configured something wrong and it never worked. One of these days I'll give it another shot, but for now, I've removed all traces of it.

As a result of both cleanups, the whole submodule thing is gone, and not a moment to soon. These are not the best feature of Git.

Finally, links to this blog in the credits and in the help system. With all that cruft out of the way, it's time for some real work on parts I always wanted to address. I'll talk more about that tomorrow.
