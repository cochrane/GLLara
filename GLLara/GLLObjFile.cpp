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

std::string stringFromFileURL(CFURLRef fileURL)
{
	// Not using CFURLGetFileSystemRepresentation here, because there is no function to find the maximum needed buffer size for CFURL.
	CFURLRef absolute = CFURLCopyAbsoluteURL(fileURL);
	CFStringRef fsPath = CFURLCopyFileSystemPath(absolute, kCFURLPOSIXPathStyle);
	if (!fsPath)
		throw std::runtime_error("Could not convert file path to URL");
	CFRelease(absolute);
	CFIndex length = CFStringGetMaximumSizeOfFileSystemRepresentation(fsPath);
	char *buffer = new char[length];
	CFStringGetFileSystemRepresentation(fsPath, buffer, length);
	CFRelease(fsPath);
	
	std::string result(buffer);
	delete [] buffer;
	return result;
}

CFURLRef urlFromString(const std::string &string, CFURLRef relativeTo)
{
	std::string path = string;
	
	// Is this possibly a windows path?
	if (string.size() > 2 && string[1] == ':' && string[2] == '\\')
	{
		// It is! Take only the last component
		size_t lastBackslash = string.find_last_of('\\');
		path = string.substr(lastBackslash+1);
	}
	path.erase(path.find_last_not_of(" \n\r\t")+1);
	return CFURLCreateWithBytes(kCFAllocatorDefault, (UInt8 *)path.c_str(), path.size(), kCFStringEncodingUTF8, relativeTo);
}

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

GLLObjFile::Material::~Material()
{
	CFRelease(diffuseTexture);
	CFRelease(specularTexture);
	CFRelease(normalTexture);
}

void GLLObjFile::normalizeTexCoords(float *texCoords)
{
//	texCoords[0] = std::fmod(texCoords[0], 1);
//	if (texCoords[0] < 0.0f) texCoords[0] += 1.0f;
//	texCoords[1] = std::fmod(texCoords[1], 1);
//	if (texCoords[1] < 0.0f) texCoords[1] += 1.0f;
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
	IndexSet set[3];
	
	for (unsigned i = 0; i < 3; i++)
	{
		std::string indices;
		stream >> indices;
		
		int scanned = sscanf(indices.c_str(), "%d/%d/%d/%d", &set[i].vertex, &set[i].texCoord, &set[i].normal, &set[i].color);
		
		if (scanned < 3) throw std::invalid_argument("Only OBJ files with vertices, normals and texture coordinates are supported.");
		
		if (set[i].vertex > 0) set[i].vertex -= 1;
		else set[i].vertex += vertices.size() / 3;
		
		if (set[i].normal > 0) set[i].normal -= 1;
		else set[i].normal += normals.size() / 3;
		
		if (set[i].texCoord > 0) set[i].texCoord -= 1;
		else set[i].texCoord += texCoords.size() / 2;
		
		if (scanned > 3) // Color is optional.
		{
			if (set[i].color > 0) set[i].color -= 1;
			else set[i].color += colors.size() / 4;
		}
		else set[i].color = INT_MAX;
		
		originalIndices.push_back(set[i]);
	}
}

void GLLObjFile::parseMaterialLibrary(CFURLRef location)
{
	std::string filename = stringFromFileURL(location);
	
	std::ifstream stream(filename.c_str());
	if (!stream) throw std::runtime_error("Could not open MTLLib file.");
	
	bool hasFirstMaterial = false;
	std::string materialName;
	Material *currentMaterial = new Material();
	
	while(stream.good())
	{
		std::string line;
		std::getline(stream, line);
		
		std::istringstream linestream(line);
		std::string token;
		linestream >> token;
		
		if (token == "newmtl")
		{
			if (!hasFirstMaterial)
			{
				// This is the first material. Just save the name.
				linestream >> materialName;
				hasFirstMaterial = true;
				currentMaterial->name = materialName;
			}
			else
			{
				// Old material ends here. Store it here; map copies it, so it can be overwritten now.
				currentMaterial->ambient[3] = currentMaterial->diffuse[3] = currentMaterial->specular[3] = 1.0f;
				materials[materialName] = currentMaterial;
				
				// Reset material
				currentMaterial = new Material();
				
				// Save new name
				linestream >> materialName;
				currentMaterial->name = materialName;
			}
		}
		else if (token == "Ka")
		{
			int scanned = sscanf(line.c_str(), "Ka %f %f %f", &currentMaterial->ambient[0], &currentMaterial->ambient[1], &currentMaterial->ambient[2]);
			if (scanned == 1)
				currentMaterial->ambient[1] = currentMaterial->ambient[2] = currentMaterial->ambient[0];
		}
		else if (token == "Kd")
		{
			int scanned = sscanf(line.c_str(), "Kd %f %f %f", &currentMaterial->diffuse[0], &currentMaterial->diffuse[1], &currentMaterial->diffuse[2]);
			if (scanned == 1)
				currentMaterial->diffuse[1] = currentMaterial->diffuse[2] = currentMaterial->diffuse[0];
		}
		else if (token == "Ks")
		{
			int scanned = sscanf(line.c_str(), "Ks %f %f %f", &currentMaterial->specular[0], &currentMaterial->specular[1], &currentMaterial->specular[2]);
			if (scanned == 1)
				currentMaterial->specular[1] = currentMaterial->specular[2] = currentMaterial->specular[0];
		}
		else if (token == "Ns")
			sscanf(line.c_str(), "Ns %f", &currentMaterial->shininess);
		else if (token == "map_Kd")
			currentMaterial->diffuseTexture = urlFromString(line.substr(token.size() + 1), location);
		else if (token == "map_Ks")
			currentMaterial->specularTexture = urlFromString(line.substr(token.size() + 1), location);
		else if (token == "map_Kn" || token == "bump" || token == "map_bump")
			currentMaterial->normalTexture = urlFromString(line.substr(token.size() + 1), location);
	}
	
	// Wrap up final material
	currentMaterial->ambient[3] = currentMaterial->diffuse[3] = currentMaterial->specular[3] = 1.0f;
	materials[materialName] = currentMaterial;
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
	std::string filename = stringFromFileURL(location);
	
	std::ifstream stream(filename.c_str());
	if (!stream) throw std::runtime_error("Could not open OBJ file.");
	
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
		{
			parseFloatVector(line.c_str(), texCoords, 2);
			normalizeTexCoords(&texCoords[texCoords.size() - 2]);
		}
		else if (token == "vc")
			parseUCharVector(line.c_str(), colors, 4);
		else if (token == "f")
			parseFace(linestream);
		else if (token == "mtllib")
		{
			try
			{
				CFURLRef mtllibLocation = urlFromString(line.substr(token.size() + 1), location);
				parseMaterialLibrary(mtllibLocation);
				CFRelease(mtllibLocation);
			}
			catch (std::exception &e)
			{
				std::cerr << "Ignoring mtllib: " << e.what() << std::endl;
			}
		}
		else if (token == "usemtl")
		{
			if (materials.size() == 0)
			{
				// Try to find an mtllib of the same name as the obj in the same directory as the obj
				CFStringRef lastPathComponent = CFURLCopyLastPathComponent(location);
				CFMutableStringRef mtlLibName = CFStringCreateMutableCopy(kCFAllocatorDefault, CFStringGetLength(lastPathComponent), lastPathComponent);
				CFStringReplace(mtlLibName, CFRangeMake(CFStringGetLength(mtlLibName) - 3, 3), CFSTR("mtl"));
				
				CFURLRef mtlLibURL = CFURLCreateWithString(kCFAllocatorDefault, mtlLibName, location);
				
				CFRelease(lastPathComponent);
				CFRelease(mtlLibName);
				
				try {
					parseMaterialLibrary(mtlLibURL);
				} catch (std::exception &e) {
					CFRelease(mtlLibURL);
					throw e;
				}
				CFRelease(mtlLibURL);
			}
				
			if (hasFirstMaterial)
			{
				// End previous material run
				materialRanges.push_back(MaterialRange(activeMaterialStart, (unsigned) originalIndices.size(), materials[activeMaterial]));
			}
			else
				hasFirstMaterial = true;
			
			linestream >> activeMaterial;
			activeMaterialStart = (unsigned) originalIndices.size();
		}
	}
	
	// Wrap up final material group
	materialRanges.push_back(MaterialRange(activeMaterialStart, (unsigned) originalIndices.size(), materials[activeMaterial]));
	
	fillIndices();
}
