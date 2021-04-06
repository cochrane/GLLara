---
title: Version 0.2.11 - Bug fix
author: cochrane
layout: default
---

[Version 0.2.11](https://github.com/cochrane/GLLara/releases/tag/v0.2.11) is out and ready for download.

This is another bug fix release, dealing with minor issues I've encountered. Both are about loading certain model files.

First of all, the "Shadeless" shader now works again. Previously, any meshes using it would turn out black because I simply forgot about it during some refactoring.

The second one is more interesting from a technical point of view, though for users the only important part is that some TGA files now show up properly.

The issue has to do with alpha blending and how that is stored in textures and in memory. If you have a transparent surface in computer graphics, the texture will contain an "opacity" value, called alpha in technical terms. This can range from 0 to 1 (or 0 to 100%). The formula for calculating the color if you put this over something else is simply:

new color = new alpha * new pixel + (1 - new alpha) * old pixel

for each R, G and B channels. Since you're always going to compute the "new alpha * new pixel" part, you can actually do that multiplication once ahead of time, during texture loading, and use that as the color value. This is called premultiplication, and with it the formula is simply:

new color = new premultiplied pixel + (1 - new alpha) * old pixel

That is very common in 2D graphics, but far less so in 3D graphics, where you might have reasons for having the alpha channel mean something else, or you want to disable this calculation and just use the original "new pixel" value in some contexts. GLLara, for example, doesn't use such premultiplied values. One reason, among all the others, is that it supports compressed DDS textures from the Windows world, and those are generally not premultiplied - and since the compression is handled directly by the graphics card (not even the driver), you can't really premultiply it while loading without a lot of hassle.

For normal image formats, and some weird ones (GLLara supports PDF textures, because I thought that'd be fun), though, GLLara uses Apple's ImageIO framework, which can load basically any format and give me the pixels. If you can see it with Preview, GLLara can load it, because it's the same code underneath. That is much simpler than implementing loaders for PNG, BMP, JPEG, TGA and whatever else someone tried to use for some arcane reason. It's very neat... except for one thing: It always premultiplies the pixel values, and it is impossible to tell it to stop. (I really should file a radar for that)

Thankfully, Apple also provides a different framework which provides functions to unpremultiply (their term) such images, and that's what GLLara does. It works well, generally speaking, but it's not ideal, because this premultiplication uses information. Both the image files, and the internal format that GLLara uses for all things, have eight bits per channel, which means the values for e.g. red can range from 0 to 255, where 0 means no red and 255 means all red. Suppose we premultiply this with an alpha value of 50%, meaning we divide everything by two. Then the value 64 becomes 32. But the value 65 also becomes 32, since we can't have fractional numbers here and we're always rounding down. If we unpremultiply it, 32 becomes 64, whether it was that before or not. We have no way of telling the difference. We loose color information.

This is more of a problem the lower the alpha value goes. If alpha is at 25%, then 64, 65, 66 and 67 all get turned to 16, and will later get turned back to 64. And then there is of course the worst case: If alpha is at 0%, then all values for red will get turned to 0, and stay there. That's usually not a problem; most people won't turn the alpha value to 0% and still expect something useful to happen.

Except some people, apparently, do. I encountered some models that have TGA textures where the alpha value is at 0% for seemingly no reason. That wouldn't be a problem, because in that particular case, due to the shaders selected, the alpha value is simply ignored. But since we do that premultiply-unpremultiply dance, the resulting texture simply has all zeroes (meaning black) almost everywhere. The model shows up, but is almost all black.

I knew this could happen in theory, I just never expected it to be a problem in practice. The solution is as easy as it is clunky: I don't use ImageIO for TGA files anymore. At least for uncompressed TGA files with an alpha channel, anyway; I'm happy with letting ImageIO handle the less usual cases.

This problem could, in theory, also appear with other formats, most notably PNG, which is also used for a lot of models. It could also happen that someone uses the weirder TGA formats for some reason. For now I've decided to ignore that, but if you find other models with that issue, please file a bug report. You'll know you have this issue if the texture files don't show up properly in Preview or Quick Look either.

Finally, I've upgraded the minimum supported OS to 10.13, since I don't have a machine with anything older, and even those are historic already.