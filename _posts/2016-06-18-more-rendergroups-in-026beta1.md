---
title: v0.2.6 Beta - More rendergroups
author: cochrane
layout: default
---

I decided to try loading some files with GLLara, found they didn't work, and set to fixing it. That led to fixing stuff, changing approaches, shaving a proverbial yak… but now the first beta of version 0.2.6 is available.  [Give it a try!](https://github.com/cochrane/GLLara/releases/tag/v0.2.6_beta1)

The fundamental change here is that more different shaders available in XPS are now supported here as well. This means some (not all) models that didn't work before (some or most parts didn't show up) will work now. XNALara and XPS call these shaders "render groups"; of these, numbers 38 up to 43 are now supported. 34 and 35 are disallowed, and anything below 33 was already supported, so only 36 and 37 are missing now. I'm not sure if I'll include them before the final release for 0.2.6 or put that in a different version.

To support so many new shaders quickly, I did something I had been planning for a long time and rearranged the shaders. Previously, every shader for every group was hand-coded (actually for every other render group; two render groups are typically the same, but one supports blending and one does not). That meant a lot of stuff was duplicated, and sometimes there were little bugs that I had fixed in half the shaders but not the others.

Now, there's one shader, and for every render group I can configure which features it uses and which one it does. That way all bug fixes happen in one place, and I can add new shaders very quickly. For some of them, I didn't even need to add any new code; they were just a new combination of existing features that I had to turn on.

Along the way I discovered a number of bugs in shaders that mean some things will look different from before now. Most importantly, the ambient color was sometimes ignored. Now it isn't, but that means the default value is too bright. If everything in your scene looks gray, simply check the ambient color and turn it to black or very dark gray. I'll probably change the default for this for the final version.

Such a big change means a lot of things may be broken, of course. If you have any examples where the same scene (or ideally just the same model) looks different in 0.2.6 beta 1 and 0.2.5, besides the gray thing, please [let me know!](https://github.com/cochrane/GLLara/issues). The same goes for any other issues as well, of course.
