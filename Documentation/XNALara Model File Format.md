XNA Lara Model File Format
==========================

This describes the binary file format used by XNALara. A few notes:

*	All data is little-endian
*	In the following, `float` means a 32-bit IEEE 754 single precision value. `uint8_t`, `uint16_t` and so on refer to the formats in stdtype.h.
*	A string is specified as length, then value. The length is encoded with a simple multi-byte scheme. Only the bottom seven bits of a byte are considered. If the top bit is set, the next byte is length too, specifying the next (higher) 7 bits. I don't know about the encoding. Right now I'm assuming UTF8, but ASCII (or Windows Latin 1, or whatever the user has as default) are possible choices, too. Strings are never 0-terminated.

Without further ado, the file format:

	uint32_t numBones
	Bone bones[numBones]
	uint32_t numMeshes
	Mesh meshes[numMeshes]

Beware, though: If the first uint32 has the magic value 323232, it is not the bone count, but instead the header of a file with the Generic Item 2 format. You have to ask `XNAaral` (sorry, I don't know of a homepage for him) for details about this format, I'm afraid I don't know any.

The format for a bone is:

	string name
	uint16_t parentIndex
	float defaultPositionX
	float defaultPositionY
	float defaultPositionZ

The default position is relative to the model, not to the parent.

The format for a mesh is:

	string name
	uint32_t numUVLayers
	uint32_t numTextures
	Texture textures[numTextures]
	uint32_t numVertices
	Vertex vertices[numVertices]
	uint32_t numElements
	uint32_t elements[numElements]

Special notes: numTextures often is not the same as numUVLayers. The format of a vertex depends on the number of UV layers and whether the model has bones:

	float vertex[3];
	float normal[3];
	uint8_t color[4];
	float texCoord[2][numUVLayers]
	float tangent[4][numUVLayers]
	uint16_t boneIndex[4] // Only if the model has bones
	float boneIndex[4] // Only if the model has bones

A texture is less interesting, it is just

	string filename
	uint32_t uvLayer
	
Note that several textures can use the same uv layer.
