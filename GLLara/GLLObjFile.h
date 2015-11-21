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
#include <unordered_map>

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
	struct MaterialRange
	{
		unsigned start;
		unsigned end;
		std::string materialName;
		MaterialRange(unsigned s, unsigned e, const std::string &m) : start(s), end(e), materialName(m) {}
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
        bool operator==(const GLLObjFile::IndexSet &other) const;
        size_t hash() const;
	};
	std::vector<IndexSet> originalIndices;
    
    struct IndexSetHash {
        size_t operator()(const IndexSet &set) const {
            return set.hash();
        }
    };
	
	// Mapping from a/b/c to single indices
    std::unordered_map<IndexSet, unsigned, IndexSetHash> vertexDataIndexForSet;
	
	// Vertex buffer, used by OpenGL
	std::vector<VertexData> vertexData;
	
	// Index buffers, used by OpenGL
	std::vector<unsigned> indices;
			
	// Support for material handling.
	std::vector<MaterialRange> materialRanges;
	CFMutableArrayRef materialLibraryURLs;
	
	// Parsing
	void parseUCharVector(const char *line, std::vector<unsigned char> &values, unsigned number) throw();
	void parseFloatVector(const char *line, std::vector<float> &values, unsigned number) throw();
	void parseFace(std::istream &string);
				
	void fillIndices();
	
	// Find the single index needed for OpenGL for a given a/b/c set.
	unsigned unifiedIndex(const IndexSet &indexSet);
	
public:
	GLLObjFile(CFURLRef location);
	~GLLObjFile();
	
	const std::vector<MaterialRange> &getMaterialRanges() const { return materialRanges; }
	const std::vector<VertexData> &getVertexData() const { return vertexData; }
	const std::vector<unsigned> &getIndices() const { return indices; }
	CFArrayRef getMaterialLibaryURLs() const { return materialLibraryURLs; }
};
