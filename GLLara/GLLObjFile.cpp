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

#include <QuartzCore/QuartzCore.h>

bool followsString(std::istream &stream, const char *string) {
    const char *p = string;
    while (*p) {
        if (stream.get() != *p)
            return false;
        p++;
    }
    return true;
}

void skipToEndOfLine(std::istream &stream) {
    int character;
    do {
        character = stream.get();
    } while (character >= 0 && character != '\n' && character != '\r');
}

void parseVector(std::istream &stream, std::vector<float> &values, unsigned number) throw() {
    for (unsigned i = 0; i < number && stream.good(); i++) {
        float c;
        stream >> c;
        values.push_back(c);
    }
    skipToEndOfLine(stream);
}

void parseVector(std::istream &stream, std::vector<unsigned char> &values, unsigned number) throw() {
    for (unsigned i = 0; i < number && stream.good(); i++) {
        int character = stream.get();
        while (character == ' ' && character >= 0)
            character = stream.get();
        
        unsigned char value = 0;
        while (character >= '0' && character <= '9') {
            value = value * 10 + (character - '0');
            character = stream.get();
        }
        values.push_back(value);
    }
}

std::string stringToEndOfLine(std::istream &stream) throw() {
    int character = stream.get();
    while (character == ' ')
        character = stream.get();
    
    std::string string;
    while (character != '\n' && character != '\r' && character > 0) {
        string.push_back(character);
        character = stream.get();
    }
    return string;
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

size_t GLLObjFile::IndexSet::hash() const {
    size_t hash = vertex;
    hash = 31 * hash + normal;
    hash = 31 * hash + texCoord;
    hash = 31 * hash + color;
    return hash;
}


bool GLLObjFile::IndexSet::operator==(const GLLObjFile::IndexSet &other) const
{
    return vertex == other.vertex && normal == other.normal && texCoord == other.texCoord && color == other.color;
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
    auto iter(vertexDataIndexForSet.find(indexSet));
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
    CFTimeInterval startTime = CACurrentMediaTime();
    
    std::string filename = GLLStringFromFileURL(location);
    
    std::ifstream stream(filename.c_str());
    if (!stream) throw std::runtime_error("Could not open OBJ file.");
    
    materialLibraryURLs = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    std::string activeMaterial("");
    unsigned activeMaterialStart = 0;
    bool hasFirstMaterial = false;
    while(stream.good())
    {
        int character = stream.get();
        while (character == ' ' && character >= 0) {
            character = stream.get();
        }
        if (character < 0)
            break;
        
        switch (character) {
            case 'f':
                parseFace(stream);
                break;
            case 'v':
                character = stream.get();
                switch (character) {
                    case 'n': // Normals
                        parseVector(stream, normals, 3);
                        break;
                    case 't': // Tex coords
                        parseVector(stream, texCoords, 2);
                        break;
                    case 'c': // Colors
                        parseVector(stream, colors, 4);
                        break;
                    case ' ': // Vertex
                        parseVector(stream, vertices, 3);
                        break;
                    default:
                        skipToEndOfLine(stream);
                        break;
                }
                break;
            case 'm':
                if (followsString(stream, "tllib")) {
                    std::string mtllib = stringToEndOfLine(stream);
                    
                    try
                    {
                        CFURLRef mtllibLocation = GLLCreateURLFromString(mtllib, location);
                        CFArrayAppendValue(materialLibraryURLs, mtllibLocation);
                        CFRelease(mtllibLocation);
                    }
                    catch (std::exception &e)
                    {
                        std::cerr << "Ignoring mtllib: " << e.what() << std::endl;
                    }
                } else {
                    skipToEndOfLine(stream);
                }
                break;
            case 'u':
                if (followsString(stream, "semtl")) {
                    if (hasFirstMaterial)
                    {
                        // End previous material run
                        materialRanges.push_back(MaterialRange(activeMaterialStart, (unsigned) originalIndices.size(), activeMaterial));
                    }
                    else
                        hasFirstMaterial = true;
                    
                    activeMaterial = stringToEndOfLine(stream);
                    activeMaterialStart = (unsigned) originalIndices.size();
                } else {
                    skipToEndOfLine(stream);
                }
                break;
            case '\r': // Empty line
            case '\n': // Empty line
            case '#': // Comment
            default:
                skipToEndOfLine(stream);
                break;
        }
    }
    
    // Wrap up final material group
    materialRanges.push_back(MaterialRange(activeMaterialStart, (unsigned) originalIndices.size(), activeMaterial));
    
    fillIndices();
    CFTimeInterval endTime = CACurrentMediaTime();
    
    std::cout << "parsed obj in " << (endTime - startTime) << std::endl;
}

GLLObjFile::~GLLObjFile()
{
    CFRelease(materialLibraryURLs);
}
