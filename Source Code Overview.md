Source Code Overview
====================

Hello, and welcome to the source code to GLLara! I'll try to keep this document as up-to-date as possible, to give others a quick start into hacking at this project.

GLLara currently requires Mac OS X 10.8, and uses all the newest features: Literals, subscripting, ARC, fast enumeration, bindings and so on. On the framework side, it uses OpenGL 3.2 Core Profile. It shouldn't be too hard to do support 10.7. I don't want to, right now, but I'd readily accept pull requests that make it 10.7 compatible. Porting to anything earlier, on the other hand, will be a world of hurt and make the code ugly. Porting to PowerPC (i.e. 10.5) is right out.

A note: The code is **not** a copy or straight port of XNALara. In many cases, I reorganized things to make more sense for me. So best to get into this with a fresh mind.

Conventions
-----------

All class names start with `GLL` (for GL Lara, duh). The `CFBundleIdentifier` is mine; if you make a  different version, please change it to one that does not start with `de.ferroequinologist` (or ask me first). There is always one class per file, and the files are named after the class they contain, to reduce searching.

Main classes
------------

There are several layers to the code. At the bottom, there is the `GLLModel` with its associated `GLLMesh` and `GLLBone`. A `GLLModel` corresponds to one file, and is immutable. A model gets loaded exactly once, no matter how many scenes include it or how often it is shown in a given scene. A layer up is the `GLLItem`, which is one item and its associated position, pose, scale and so on. A scene can have multiple Items with the same model. The pose is stored in the `GLLBoneTransformation`s, which are owned by the Item. Right now, there is no support for importing OBJs, but that will come in time.

To draw, there is the `GLLModelDrawer` with the associated `GLLMeshDrawer`. You have one per OpenGL Context (this context must be Core Profile). The Model Drawer is basically just a container for the Mesh Drawers, though. To actually draw a full item, you need the `GLLItemDrawer`, which draws the meshes of the model based on the transformations from the Item. All data like model drawers, shaders and textures are managed by a resource manager. Right now, only these resources are shared, not the item drawers (this could be done, too, but it would require another layer and not help with anything). As a result, you need one `GLLItemDrawer` per context per item.

Rendering Parameters
--------------------

In XNALara, basically anything is hardcoded. What shader to use, what parameters, all these things are written in class files that are selected by file name. To be a bit more flexible, here the `GLLModelParams` class encapsulates all this and reads it from Plist files. Model params include what shaders exist (together with what mesh group they belong to), what meshes form which mesh group, parameters for the shaders, and information how to split up meshes, because apparently, that's needed, too.

This is a hierarchical system; each file can specify a "base" file from which it inherits. An actual item will thus most likely inherit all the data from `xnaLaraDefault` and possibly others, too.

The generic item format is considered as a special case here; it always inherits from `xnaLaraDefault`, and the parameters are retrieved from the model by parsing the mesh names.

Containers
----------

The data for a scene is handled by CoreData, in a managed object context. Specifically, saved in there are the Items, their Bone Transformations and Mesh Settings, the Lights and everything else that needs saving.

For drawing, there is an explicit container: The `GLLSceneDrawer` (which has exactly one `GLLView`). A scene can have several GLLSceneDrawers, although there is currently no code in place for sharing resources between them, so resource usage might grow too large to be useful very quickly.

Other resources
---------------

The drawable resources like GLSL programs, textures, model and mesh drawers (but not, at the moment, item drawers or light buffers) belong to a `GLLResourceManager`, which stores the resources for all objects in all open windows. It uses OpenGL context sharing for this. Note: It assumes that Vertex Array Objects can be shared between contexts, which they normally can't, but on Mac OS X, it works. I think the `GL_APPLE_container_object_shareable` OpenGL extension is responsible for that, but it isn't documented anywhere.

Utilities, loading, saving
--------------------------

The main utilities are the `TRInDataStream` and `TROutDataStream`. Both are originally from another project I'm working on, hence the different prefix. Specifically, they were meant to parse TR1-4 files, so they support things not used in GLLara. Ignore them if they make you feel uneasy. The `GLLASCIIScanner` (in the future, there will likely be an ASCII writer, too) is used for the .mesh.ascii format, which is identical to the .mesh format, except with all the numbers written out and no tangents. 

For things like matrix manipulations, the things in `shared_simd` provide fairly adequate solutions. I've used them in various projects over a lot of years, so they are all known to work, but not always the prettiest solution.

All objects know how to load and write themselves from any supported format (currently, only the binary formats are supported), so there is no need for additional helper classes.

User Interface
--------------

The UI is closely linked with its controller layer. The root is the `GLLDocument`, which doesn't actually do much other than create its windows. Everything else is handled by Core Data, through `NSPersistentDocument`.

Every document has one `GLLDocumentWindowController`. This provides the main window, with a source list on the left and varying views (loaded via view controllers) on the right. The view controller is loaded based on what is selected in the source list. It's represented object is the selected object. Right now, there are view controllers for lights, bones and meshes, but there will be more.

The source list does not use an NSTreeController, but is written by hand, and a bit hackish at times. All items that can be displayed there implement the `GLLSourceListItem` protocol.

A document can have any number of render views, including none. Right now, it starts with one as default and there is no way to create new ones, which causes a bit of trouble if you close that one. In the future, I plan to implement arbitrary numbers of render views, with their own cameras, stored in Core Data.
