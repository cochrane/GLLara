//
//  GLLObjFile.h
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#pragma once

#include <CoreFoundation/CoreFoundation.h>

#include <map>
#include <string>
#include <vector>

/*!
 * @abstract A fairly normal OBJ loader, extended for XNALara compatibilitiy.
 * @discussion There is nothing too odd about this loader, except perhaps that it it is in C++. The reason for that is that I had both an old C++ OBJ loader and an Objective-C OBJ loader, and the C++ one was the newer and nicer code. I'm not going to write any part of this again unless I absolutely have to.
 *
 * This has been updated to support colors, and because XNALara will never ever run on anything but Mac OS X, I'm using CFURLs instead of path strings (not NSURL's, I don't want to deal with C++ and ARC. I'm sure that'll blow up).
 */
class GLLObjFile
{
public:
	struct VertexData
	{
		float vert[3];
		float norm[3];
		unsigned char color[4];
		float tex[2];
	};
	struct Material
	{
		float ambient[4];
		float diffuse[4];
		float specular[4];
		float shininess;
		CFURLRef diffuseTexture;
		CFURLRef specularTexture;
		CFURLRef normalTexture;
		std::string name;
		
		Material() : ambient{1, 1, 1, 1}, diffuse{1, 1, 1, 1}, specular{0, 0, 0, 0}, shininess(0), diffuseTexture(0), specularTexture(0), normalTexture(0) {}
		~Material();
		
		const float *getAmbient() const { return ambient; }
		const float *getDiffuse() const { return diffuse; }
		const float *getSpecular() const { return specular; }
		float getShininess() const { return shininess; }
		CFURLRef getDiffuseFilename() const { return diffuseTexture; }
		CFURLRef getSpecularFilename() const { return specularTexture; }
		CFURLRef getNormalFilename() const { return normalTexture; }
	};
	struct MaterialRange
	{
		unsigned start;
		unsigned end;
		Material *material;
		MaterialRange(unsigned s, unsigned e, Material *m) : start(s), end(e), material(m) {}
	};
private:
	// Vertex data as saved in the OBJ-file.
	std::vector<float> vertices;
	std::vector<float> normals;
	std::vector<float> texCoords;
	std::vector<unsigned char> colors;
	
	// Indices as saved in the OBJ-file.
	struct IndexSet
	{
		int vertex;
		int normal;
		int texCoord;
		int color; // Color is an XNA-Lara extension
		
		bool operator<(const GLLObjFile::IndexSet &other) const;
		bool operator>(const GLLObjFile::IndexSet &other) const
			{ return other < *this; }
	};
	std::vector<IndexSet> originalIndices;
	
	// Mapping from a/b/c to single indices
	std::map<IndexSet, unsigned> vertexDataIndexForSet;
	
	// Vertex buffer, used by OpenGL
	std::vector<VertexData> vertexData;
	
	// Index buffers, used by OpenGL
	std::vector<unsigned> indices;
			
	// Support for material handling.
	std::map<std::string, Material *> materials;
	std::vector<MaterialRange> materialRanges;
	
	// Parsing
	void parseUCharVector(const char *line, std::vector<unsigned char> &values, unsigned number) throw();
	void parseFloatVector(const char *line, std::vector<float> &values, unsigned number) throw();
	void parseFace(std::istream &string);
	void parseMaterialLibrary(CFURLRef location);
				
	void fillIndices();
	
	// Find the single index needed for OpenGL for a given a/b/c set.
	unsigned unifiedIndex(const IndexSet &indexSet);
	
public:
	GLLObjFile(CFURLRef location);
	
	const std::vector<MaterialRange> &getMaterialRanges() const { return materialRanges; }
	const std::vector<VertexData> &getVertexData() const { return vertexData; }
	const std::vector<unsigned> &getIndices() const { return indices; }
};
