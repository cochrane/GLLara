---
title: GLLara optimizations in v0.2.4
author: cochrane
layout: default
---

Been meaning to write more about these. First of all, this is nothing you can see as a user, and I’m not really sure that they helped all that much. This was mostly for fun. Still, maybe they are of interest to other developers. While this is OpenGL specific, some of this may translate to DirectX as well. So here goes:

## Changed buffer update (already in 0.2.3)

I store all rendering data in uniform buffers, so I need to constantly update them and write new values. There are three different ways of doing that. I changed to the way the OpenGL wiki recommended. Me, I don’t see any performance changes; my hope was that someone else might.

## Large vertex arrays

The vertex data for a model  was previously saved on a per-mesh basis. One mesh, one vertex array. Seems simple, but the recommendation is to actually use far fewer of them, both in general and as a precondition to further optimizations. So I did just that.

Now, each model has a set of vertex arrays; one per format (the format consists of enabled attributes and element size, see below). For many models, this will be only one. I’ve yet to see a model that has more than three. The drawing data for each mesh is now not a full vertex array, but simply a reference to the shared one, and the appropriate offsets into it (Specifically offset into elements buffer, count and base vertex).

## Optimized element buffer

The index data in an XNALara format file is always uint32\_t, allowing a mesh to contain up to 2^32 vertices (a bit over four billion). In reality meshes aren’t that large; even more than 65,535 vertices are, as far as I can tell, nonexistent. That means of the four byte, two to three are always zero, and thus a waste of space.

So I’m discarding them. For meshes with less than 256 vertices, the element buffer now uses uint8\_t; for ones above that but with less than 65,535 vertices, it uses uint16\_t. Ones above that remain at uint32\_t, in theory, but I’ve not yet seen a model that requires that.

(In regards to the optimization above: Meshes with the same vertex buffer format, but different element buffer sizes, count as different and get different vertex buffers. I’m not sure that’s the right call, but it doesn’t seem to hurt that much either.)

## Optimized vertex buffer

This one took more work. All data in the vertex section is single-precision float, which is certainly the most precise method of storing this information that makes any sense at all. But that’s excessive. Most of the data doesn’t need that range. So now the vertex formats are dynamically changed:

-   Position stays at three floats (was and is twelve bytes).
-   Normal is changed to GL\_INT\_2\_10\_10\_10\_REV, using normalized integers (was twelve bytes, is now four).
-   Color is and was four bytes
-   Tex coords are now half floats. I was going to go with int16\_t, but that maps to the [-1,+1] range, and some models use higher values (and insist on tiling). I’m not sure the precision of a half float is actually high enough, but so far it seems to work. Oh, and my conversion code contains a few things that could technically be classified as quirks; in particular, anything that would map to a denormal is flushed to zero, and too large values (are correctly) mapped to ±infinity, but so is NaN. The OpenGL specification gives no guarantee that such values would be handled in any way at all, so I figured I didn’t need to care. Anyway: Was eight bytes per layer, is now four. (Most models have one layer, a few rare ones have two)
-   Tangents are kind of like normals, and so they get treated the same way. Of course tangents have a fourth component, but only the sign is relevant, and that is easily stuffed into the remaining two bits of GL\_INT\_2\_10\_10\_10\_REV. So now I’m using that. Note that this requires me to normalize all tangents on loading, because some models don’t have that before. Fun stuff. Was sixteen bytes per layer, is now four - if the model has tangents at all, which some XPS ones don’t.
-   Relative bone weights are an incredibly obvious candidate for converting to uint16\_t, and that’s what I did. Was sixteen bytes (for poseable models), is now eight.

That means at least eight bytes saved per vertex (static model, no tangents), at best 48 (poseable, two sets of tex coords. No idea if that’s actually a thing), and in the typical case (posable model, one texture layer) exactly 32 bytes per vertex, from 76 down to 44. That’s 40% less VRAM here. Not a lot in the grand scheme of things (most VRAM is and will always be taken up by textures), but hey, it doesn’t hurt.

## No glGenerateMipmap

This may be OS X-specific. Letting the driver generate mipmaps through glGenerateMipmap seems to allocate a lot of memory and never let go of it. I haven’t tested before, so this may be 10.10 specific (gonna install 10.11 once I have the time). Anyway, I changed that to calculating the mipmap layers myself, using the vImage framework, which ended up reducing total RAM usage by 100-200 MB depending on scene. I’m as surprised as you are.

I do still use glGenerateMipmap for DDS files, but only if they don’t have all the mipmap layers I need and only for the missing ones now. I could have calculated the mipmap layers manually for DDS files that contain uncompressed data, but I really didn’t care enough for this very rare special case.

## MMapping mesh files

The way GLLara handles models is that it first reads the file (assuming it is binary) and stores it in memory. Then it uploads the file contents to VRAM. I’ve now added a huge conversion step in between, but according to tracing results it doesn’t hurt, and the basics are the same.

The problem is that the file contents are in RAM and stay in RAM. This isn’t really optional; I need them for all the export features. My change now was to read them using memory mapping instead of normal reads. The result is that this data can now simply be discarded when it needs to be paged out, which means it can leave main memory quickly, and will automatically be re-read if I ever need it again for anything. 

The memory usage tracing tools I’m using don’t actually count such named file mappings against my memory usage, and tell me that I am now using about 30-50 MB less memory than before. That doesn’t really describe the reality of the situation of course, but in low-memory situations, this area of RAM can actually be considered more or less free now as long as nobody accesses it.

## Sorting draw calls

You’d think it wouldn’t matter that much, but simply defining a total order on the meshes in an object (based on drawing data) and sorting them by that actually helps cut down the unnecessary state changes. Fascinating stuff.

## Coalescing draw calls

So here’s where it gets good. For some models, especially scenery, there may be thousands of meshes that all use the same texture. They might differ in their render parameters, but usually won’t. Before, I generated one draw call for each. But now that I’ve sorted them, and that they’re using the same vertex array, I can simply identify runs with identical shader and render parameter values, and render them all at once using glMultiDrawElementsBaseVertex. For many models, that provides no benefit, or only a tiny one because both of Lara’s guns now get rendered in one draw call or something. But for those few big scenery ones, I got up to 300 meshes into the same draw call. The end result: A trace of one frame of a complex scene would be 10,000 function calls. Now I got it down to 800.

I’m not sure any of this really helps anything at all, but it sure was fun. I do have a few ideas for where I want to go next, but I don’t want to jinx anything by bringing them up too early. For what it’s worth, the performance problems were never really in the drawing anyway; they are in all the classic Cocoa code that takes place once I change a slider value somewhere. That’s gotta be the next main angle of attack.