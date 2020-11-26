---
title: Version 0.2.10 - Bug fix
author: cochrane
layout: default
---

[Version 0.2.10](https://github.com/cochrane/GLLara/releases/tag/v0.2.10) is out and ready for download.

The only change in this release is that model files that contain bones that are set as their own parents no longer cause the app to crash; if the bone is marked as "unused", it is simply ignored. Quite why anybody would create such files is a mystery to me, to be honest, but they do exist.

Doing this release took over a year because I couldn't upload the file to Apple for notarisation, which was ultimately caused by an [old folder existing that shouldn't anymore](https://stackoverflow.com/questions/58383508/xcode-11-using-organizer-to-upload-ipa-fails/58552091#58552091). I'm mainly telling you this as a hint in case you ever get similar issues.