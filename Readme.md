GLLara
======

[XNALara][xnalara] is an open-source tool to pose 3D models and render high-quality images. Sadly, it's Windows only. GLLara does the same as XNALara and tries to be as compatible as possible, but runs only on Mac OS X.

This thing is still a work in progress. Right now, you can't actually do anything useful with it, and almost all models will fail to load, guaranteed. That is why there is no download yet. However, if you feel like hacking, you can clone or fork the source. Most of the basic infrastructure is there, I'm just lacking an UI for posing, most of the shaders and some matrix code for the bone transformations that I am absolutely not looking forward to.

[xnalara]: http://www.tombraiderforums.com/showthread.php?t=147100

Note for developers
-------------------

This project uses submodules. So after cloning, you have to do

	git submodule init
	git submodule update

to get all the code needed to build the program.

Some license stuff
------------------

The entire project is under the GPL, version 2 or later (at your choice). If you want to contribute code to this project, you have to make it available under the same conditions.

As an exception, the things in the shared_simd directory are public domain, because they're trivial. Do with them what you want.

To the best of my knowledge, this project does not include any data from any software, other than where listed. It does not allow you to extract data from any video game. It is possible to view any data you can export to this format, including things you don't have the copyright to, but that's your problem, not mine.

This software does not directly share code with XNALara, but it does share a lot of ideas, structures and implementation details. So consider this a derivative work of that.

The binary `.mesh`-format for standard items was implemented based on the open source format from XNALara. The ASCII format and the `Generic_Item`-extensions were learned based only on publicly available information, including documentation for modders and reading files that use these formats in hex editors. As a result, this project is not a derivative work of any code used to implement reading of either of these formats.
