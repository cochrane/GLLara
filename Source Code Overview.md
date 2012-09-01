Source Code Overview
====================

Hello, and welcome to the source code to GLLara! I'll try to keep this document as up-to-date as possible, to give others a quick start into hacking at this project.

GLLara currently requires Mac OS X 10.8, and uses all the newest features: Literals, subscripting, ARC, fast enumeration, bindings and so on. On the framework side, it uses OpenGL 3.2 Core Profile. It shouldn't be too hard to do support 10.7. I don't want to, right now, but I'd readily accept pull requests that make it 10.7 compatible. Porting to anything earlier, on the other hand, will be a world of hurt and make the code ugly. Porting to PowerPC (i.e. 10.5) is right out.

A note: The code is **not** a copy or straight port of XNALara. In many cases, I reorganized things to make more sense for me. So best to get into this with a fresh mind.

Main classes
------------

There are several layers to the code. At the bottom, there is the `GLLModel` with its associated `GLLMesh` and `GLLBone`. A `GLLModel` corresponds to one file, and never ever changes. A scene will have one Model, no matter how often it is shown. A layer up is the `GLLItem`, which is one item and its associated position, pose, scale and so on. A scene can have multiple Items with the same model. The pose is stored in the BoneTransformation.

To draw, there is the `GLLModelDrawer` with the associated `GLLMeshDrawer`. You have one per OpenGL Context (this context must be Core Profile). By themselves they are not that interesting; the `GLLItemDrawer`. Sharing between OpenGL contexts is currently not supported; the main issue is that there are Vertex Array Objects, and in their infinite wisdom, the ARB decided against sharing these things, even though it is fairly obvious how to do so. But shader uniforms are shared, even though there are very good reasons for not doing that. Thanks a lot…

The drawers are brought together by the GLLItemDrawer, which applies the transformations from the Item and applies them to the Model and Mesh Drawer. You have one per context per Item.

Containers
----------

The GLLItems are all part of a GLLScene. Likewise, on the top level, the GLLItemDrawers and so on belong to a GLLSceneDrawer. A scene might have several scene drawers, although since I don't support multiple contexts, nor multiple cameras, I don't think that's actually a useful idea right now.

Other resources
---------------

The GLLSceneDrawer manages drawable resources; both the Model and Mesh drawers, and the textures. It also manages the GLSL programs. At least right now, there is no way to specify custom ones (thank goodness…). The ones I'm using are basically taken directly from XNALara, just with a few important differences.

Utilities, loading, saving
--------------------------

The main utilities are the TRInDataStream and TROutDataStream. Both are originally from another project I'm working on, hence the different prefix (and the very old creation dates in the headers). Specifically, they were meant to parse TR1-4 files, so they support things not used in GLLara. Ignore them if they make you feel uneasy.

All objects know how to load and write themselves from any supported format (currently, only the binary formats are supported), so there is no need for additional helper classes.

User Interface
--------------

None so far. Why are you asking?
