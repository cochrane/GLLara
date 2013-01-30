//
//  GLLObjFile.cpp
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#include "GLLObjFile.h"

#include <algorithm>
#include <cmath>
#include <iostream>
#include <fstream>
#include <sstream>
#include <stdexcept>

#include "GLLStringURLConversion.h"

bool GLLObjFile::IndexSet::operator<(const GLLObjFile::IndexSet &other) const
{
	if (vertex < other.vertex) return true;
	else if (vertex > other.vertex) return false;
	
	if (normal < other.normal) return true;
	else if (normal > other.normal) return false;
	
	if (texCoord < other.texCoord) return true;
	else if (texCoord > other.texCoord) return false;
	
	return false;
}

void GLLObjFile::parseUCharVector(const char *line, std::vector<unsigned char> &values, unsigned number) throw()
{
	float vals[4];
	int scanned = sscanf(line, "%*s %f %f %f %f", &vals[0], &vals[1], &vals[2], &vals[3]);
	for (int i = 0; i < std::min(scanned, (int) number); i++)
		values.push_back((unsigned char) std::min(vals[i]*255.0f, 255.0f));
}

void GLLObjFile::parseFloatVector(const char *line, std::vector<float> &values, unsigned number) throw()
{
	float vals[4];
	int scanned = sscanf(line, "%*s %f %f %f %f", &vals[0], &vals[1], &vals[2], &vals[3]);
	for (int i = 0; i < std::min(scanned, (int) number); i++)
		values.push_back(vals[i]);
}

void GLLObjFile::parseFace(std::istream &stream)
{
	std::vector<IndexSet> sets;
	
	while (stream.good())
	{
		std::string indices;
		stream >> indices;
		
		IndexSet set;
		
		int scanned = sscanf(indices.c_str(), "%d/%d/%d/%d", &set.vertex, &set.texCoord, &set.normal, &set.color);
		
		if (scanned == -1) break; // Reached end of this face.
		
		if (scanned < 3) throw std::invalid_argument("Only OBJ files with vertices, normals and texture coordinates are supported.");
		
		if (set.vertex > 0) set.vertex -= 1;
		else set.vertex += vertices.size() / 3;
		
		if (set.normal > 0) set.normal -= 1;
		else set.normal += normals.size() / 3;
		
		if (set.texCoord > 0) set.texCoord -= 1;
		else set.texCoord += texCoords.size() / 2;
		
		if (scanned > 3) // Color is optional.
		{
			if (set.color > 0) set.color -= 1;
			else set.color += colors.size() / 4;
		}
		else set.color = INT_MAX;
		
		sets.push_back(set);
	}
	
	if (sets.size() < 3)
		throw std::invalid_argument("OBJ files have to have at least three vertices per face");
	
	// Treat the face as a triangle fan. And reverse order while we're at it.
	for (unsigned i = 2; i < sets.size(); i++)
	{
		originalIndices.push_back(sets[0]);
		originalIndices.push_back(sets[i]);
		originalIndices.push_back(sets[i-1]);
	}
}

unsigned GLLObjFile::unifiedIndex(const IndexSet &indexSet)
{
	std::map<IndexSet, unsigned>::iterator iter(vertexDataIndexForSet.find(indexSet));
	if (iter == vertexDataIndexForSet.end())
	{
		VertexData data;
		
		if (indexSet.vertex >= (int) vertices.size())
			throw std::range_error("Vertex index out of range.");
		if (indexSet.normal >= (int) normals.size())
			throw std::range_error("Surface normal index out of range.");
		if (indexSet.texCoord >= (int) texCoords.size())
			throw std::range_error("Texture coordinate index out of range.");
		
		memcpy(data.vert, &(vertices[indexSet.vertex*3]), sizeof(float [3]));
		memcpy(data.norm, &(normals[indexSet.normal*3]), sizeof(float [3]));
		memcpy(data.tex, &(texCoords[indexSet.texCoord*2]), sizeof(float [2]));
		if (indexSet.color < (int) colors.size())
			memcpy(data.color, &(colors[indexSet.color*4]), 4);
		else
			data.color[0] = data.color[1] = data.color[2] = data.color[3] = 255;
		
		unsigned dataSoFar = (unsigned) vertexData.size();
		vertexData.push_back(data);
		
		vertexDataIndexForSet[indexSet] = dataSoFar;
		
		return dataSoFar;
	}
	return iter->second;
}

void GLLObjFile::fillIndices()
{
	indices.clear();
	vertexData.clear();
	vertexDataIndexForSet.clear();
	
	for (unsigned i = 0; i < originalIndices.size(); i ++)
		indices.push_back(unifiedIndex(originalIndices[i]));
}

GLLObjFile::GLLObjFile(CFURLRef location)
{
	std::string filename = GLLStringFromFileURL(location);
	
	std::ifstream stream(filename.c_str());
	if (!stream) throw std::runtime_error("Could not open OBJ file.");
	
	materialLibraryURLs = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
	std::string activeMaterial("");
	unsigned activeMaterialStart = 0;
	bool hasFirstMaterial = false;
	while(stream.good())
	{
		std::string line;
		std::getline(stream, line);
		
		std::istringstream linestream(line);
		std::string token;
		linestream >> token;
		
		if (token == "v")
			parseFloatVector(line.c_str(), vertices, 3);
		else if (token == "vn")
			parseFloatVector(line.c_str(), normals, 3);
		else if (token == "vt")
			parseFloatVector(line.c_str(), texCoords, 2);
		else if (token == "vc")
			parseUCharVector(line.c_str(), colors, 4);
		else if (token == "f")
			parseFace(linestream);
		else if (token == "mtllib")
		{
			try
			{
				CFURLRef mtllibLocation = GLLCreateURLFromString(line.substr(token.size() + 1), location);
				CFArrayAppendValue(materialLibraryURLs, mtllibLocation);
				CFRelease(mtllibLocation);
			}
			catch (std::exception &e)
			{
				std::cerr << "Ignoring mtllib: " << e.what() << std::endl;
			}
		}
		else if (token == "usemtl")
		{				
			if (hasFirstMaterial)
			{
				// End previous material run
				materialRanges.push_back(MaterialRange(activeMaterialStart, (unsigned) originalIndices.size(), activeMaterial));
			}
			else
				hasFirstMaterial = true;
			
			linestream >> activeMaterial;
			activeMaterialStart = (unsigned) originalIndices.size();
		}
	}
	
	// Wrap up final material group
	materialRanges.push_back(MaterialRange(activeMaterialStart, (unsigned) originalIndices.size(), activeMaterial));
	
	fillIndices();
}

GLLObjFile::~GLLObjFile()
{
	CFRelease(materialLibraryURLs);
}
