---
title: Version 0.2.5 finally released
author: cochrane
layout: default
---

It took long enough, but here is the full release of 0.2.5, a.k.a. the version that fixes all known issues that appeared since 0.2.1, about three years ago.

Please [download it](https://github.com/cochrane/GLLara/releases/tag/v0.2.5) and [tell me what doesn't work](https://github.com/cochrane/GLLara/issues)!

## All the changes

This seems like a good time to go back to the basics and list all the changes since 0.2.2, the last version that was more or less widespread:

-   The app runs on OS X 10.11 (previously there were weird graphics issues here).
-   A multitude of bugs that only appeared on Intel cards are fixed.
-   German localization works again.
-   Setting parameters for single meshes was slow and wonky; for a lot of meshes, it was almost impossible. This is fixed now.
-   A crash when changing shaders is fixed.
-   Some XPS files that could not be loaded before now work.
-   Some shaders didn't work at all or didn't work properly.
-   Disabling of meshes did not work for a while.
-   RAM usage was optimized, so the app now uses far less resources.
-   Drawing was optimized, which should increase frame rate a little bit.
-   Non-working Sparkle installation was removed (a new one may be added later).
-   A lot of cleanup behind the scenes to make code shorter and easier to read.
-   Skeleton drawing did not work for a while.

There's also new features:

-   You can now set anti-aliasing and anisotropic filtering from the settings.
-   You can change whether a mesh is treated as transparent or not. Note that it won't show up as transparent unless it also has a transparent diffuse texture.

Both are mostly meant for playing around.
