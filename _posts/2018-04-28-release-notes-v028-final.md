---
title: Version 0.2.8 released with new features
author: cochrane
layout: default
---

It's been a while, but a new version is finally here with 0.2.8. This is technically a minor update to 0.2.7, but since I decided to make a new one before announcing 0.2.7 widely, this is really the new major release. Special thanks to [sethk](https://github.com/sethk) who provided some useful bug fixes!

Please [download it](https://github.com/cochrane/GLLara/releases/tag/v0.2.8) and [tell me what doesn't work](https://github.com/cochrane/GLLara/issues)!

This release includes an awful lot of bugfixes, listed in the official release notes above; the most important thing is that many things that were broken now work, and that many models that couldn't be loaded for one reason or another now can. The really interesting things are…

## New Features

There's a lot of them; all minor stuff, but all things that annoyed me and maybe you for years now.

### Optional items

![screenshot of document menu on some model with optional items](/GLLara/screenshots/v028-optionalparts.png)

This has been a long-standing annoyance: Many newer models come with "Optional" parts that can be turned on or off via a menu in XPS. This menu didn't exist in GLLara. You could turn these parts on and off manually, via the meshes, but finding out which ones needed to be set how was error-prone and annoying.

Now, models that have these optional parts get a new entry in the source list, which shows you a list where you can select or deselect them easily, and all the right meshes will be made visible or invisible. You can, of course, still adjust mesh visibility manually.

### Bone UI updates

![screenshot of new bone view](/GLLara/screenshots/v028-bones.png)

Bones that have had their values altered are now shown in bold, so you can quickly see which bones you edited and which are still missing. Very useful for fiddly bits with an awful lot of bones that want adjusting.

In addition to the normal "reset", there is now also a "recursive reset". This resets the bone and all its descendants to default values. You can use this e.g. when you are editing long hairs and then realised that you want something completely different, which requires setting all bones back to normal first.

### Image planes

![screenshot of document menu on some model with optional items](/GLLara/screenshots/v028-imageplanes.jpg)

Images can now be loaded and placed into a scene as a possible, resizable flat plane. This can be used to add special effects, place pictures or similar very quickly. This supports all formats that GLLara supports for textures in general, meaning everything that Preview can open and also most .DDS files.

### Adding models via drag and drop

Models and image planes can be added to a scene by dragging the file in finder and dropping it on the document or render window. This makes trying out a lot of new models a lot easier.

### Show model files in Finder

![screenshot of menu item](/GLLara/screenshots/v028-infinder.png)

This new menu item allows you to open the folder a selected model is in in Finder. This makes it a bit quicker to find things like readme files or alternate texture sets that may be included.

That's it for now. There'll be more updates in the future, but as always, there is zero guarantee on the time frame for this. I'm also thinking about changing the version numbering scheme. At the current pace we'll reach 0.3 some time in 2030 and 1.0 shortly after the sun burns out. That's useless, so I'm thinking the next major release will either be 0.3 or 1.0, regardless of content.