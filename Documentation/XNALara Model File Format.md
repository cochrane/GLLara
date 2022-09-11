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

Beware, though: If the first uint32 has the magic value 323232, it is not the bone count, but instead the header of a file with the Generic Item 2 format. This is described more later.

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

## Ascii Format

The ASCII format is functionally the same. Strings are terminated by newlines instead of leading sizes. Numbers are just written as ASCII and separated by whitespace. The main difference is that tangents are not included in the file, and must be calculated manually.

## Generic Item 2

XPS is a closed-source fork of XNALara that also supports its own file format, called generic mesh 2. There is no full documentation for it as far as I know, but I was able to reverse-engineer most of it. Here's the format:

    uint32_t magicNumber; // 323232; that is how you tell it is a generic mesh v2 file
    uint16_t majorVersion; 
    uint16_t minorVersion; // Irrelevant
    string toolAuthor; // always XNAaraL
    uint32_t countOfUnknownInts;
    string unknownString1;
    string unknownString2;
    string unknownString3; // These strings contain file paths and computer names of whoever created the file. They are not needed for anything.
    uint32_t unknownInts[countOfUnknownInts]; // Unclear what this is.
    
    uint32_t numBones
    Bone bones[numBones]
    uint32_t numMeshes
    Mesh meshes[numMeshes]
    
    // There is some additional trailing data that doesn't seem to be relevant.
    
The format for bones is identical, but the vertex data has some additional wrinkles:

*   If the major version is at least 2, the file does not contain tangents. These must be calculated manually. The vertex format becomes:
    
        float vertex[3];
        float normal[3];
        uint8_t color[4];
        float texCoord[2][numUVLayers]
        uint16_t boneIndex[4] // Only if the model has bones
        float boneIndex[4] // Only if the model has bones

*   If the major version is at least 3, the number of bones per vertex is variable and given by an uint16\_t before the bones. This is usually 4, but can be higher (I have not seen lower values in the models I've tested). As a result the vertex format no longer has a uniform stride. It is now:
    
        float vertex[3];
        float normal[3];
        uint8_t color[4];
        float texCoord[2][numUVLayers]
        uint16_t boneCountForVertex // Only if the model has bones
        uint16_t boneIndex[boneCountForVertex] // Only if the model has bones
        float boneIndex[boneCountForVertex] // Only if the model has bones
