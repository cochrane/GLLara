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
#include <thread>

#include <sys/mman.h>
#include <sys/stat.h>

#include "GLLStringURLConversion.h"
#include "GLLTiming.h"

bool followsString(const char *&current, const char *end, const char *string) {
    const char *p = string;
    while (*p) {
        if (current == end || *current != *p)
            return false;
        p++;
        current++;
    }
    return true;
}

void skipToEndOfLine(const char *&current, const char *end) {
    while (current != end && *current != '\n' && *current != '\r') {
        current++;
    }
}

int parseInt(const char *&current, const char *end) {
    int value = 0;
    int signum = 1;
    while (current != end && *current == '-') {
        signum *= -1;
        current += 1;
    }
    while (current != end && *current >= '0' && *current <= '9') {
        value = value * 10 + (*current - '0');
        current += 1;
    }
    return signum * value;
}

enum float_parse_state_t {
    INITIAL,
    SIGN,
    LEADING_ZERO,
    LEADING_DECIMAL,
    INTEGRAL_PART,
    DECIMAL,
    FRACTIONAL_PART,
    EXPONENT_MARKER,
    EXPONENT_SIGN,
    EXPONENT,
    INVALID
};

void parseVector(const char *&current, const char *end, std::vector<float> &values, unsigned number) throw() {
    for (unsigned i = 0; i < number; i++) {
        // Skip whitespace
        while (current != end && *current == ' ') {
            current += 1;
        }
        const char *rangeEnd = current;
        while (rangeEnd != end && *rangeEnd != ' ' && *rangeEnd != '\n' && *rangeEnd != '\r') {
            rangeEnd += 1;
        }
        
        char characters[256];
        size_t size = rangeEnd - current;
        float value;
        if (size >= sizeof(characters)) {
            value = std::numeric_limits<float>::quiet_NaN();
        } else {
            memcpy(characters, current, size);
            characters[size] = 0;
            value = strtof_l(characters, nullptr, nullptr);
        }
        values.push_back(value);
        current = rangeEnd;
    }
    skipToEndOfLine(current, end);
}

void parseVector(const char *&current, const char *end, std::vector<unsigned char> &values, unsigned number) throw() {
    for (unsigned i = 0; i < number; i++) {
        while (current != end && *current == ' ') {
            current += 1;
        }
        
        unsigned char value = 0;
        while (current != end && *current >= '0' && *current <= '9') {
            value = value * 10 + (*current - '0');
            current += 1;
        }
        values.push_back(value);
    }
}

std::string stringToEndOfLine(const char *&current, const char *end) throw() {
    while (current != end && *current == ' ') {
        current += 1;
    }
    
    const char *start = current;
    while (current != end && *current != '\n' && *current != '\r') {
        current += 1;
    }
    return std::string(start, current);
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
    size_t hash = color;
    hash = 31 * hash + normal;
    hash = 31 * hash + texCoord;
    hash = 31 * hash + vertex;
    return hash;
}

bool GLLObjFile::IndexSet::operator==(const GLLObjFile::IndexSet &other) const
{
    return vertex == other.vertex && normal == other.normal && texCoord == other.texCoord && color == other.color;
}

void GLLObjFile::parseFace(const char *&current, const char *end)
{
    std::vector<IndexSet> sets;
    if (current != end && *current == 'f')
        current += 1;
    
    while (current != end)
    {
        while (current != end && *current == ' ') {
            current += 1;
        }
        
        if (current == end || *current == '\n' || *current == '\r')
            break;
        
        IndexSet set;
        
        // Scan vertex
        set.vertex = parseInt(current, end);
        if (current == end) {
            throw std::invalid_argument("String too short.");
        } else if (*current == '/') {
            // Standard case: Have tex coord, normal
            current += 1;
            
            // Scan tex coord
            set.texCoord = parseInt(current, end);
            if (current == end || *current != '/') {
                throw std::invalid_argument("Expected \"/\" (Only OBJ files with vertices, normals and texture coordinates are supported).");
            }
            current += 1;
            
            // Scan normal
            set.normal = parseInt(current, end);
            
            // Scan color (if present)
            set.color = INT_MAX;
            if (current != end && *current == '/') {
                current += 1;
                set.color = parseInt(current, end);
            }
        } else {
            current += 1;
            // Only vertices
            set.texCoord = INT_MAX;
            set.normal = INT_MAX;
            set.color = INT_MAX;
        }
        
        if (set.vertex > 0) set.vertex -= 1;
        else set.vertex += vertices.size() / 3;
        
        if (set.normal != INT_MAX) {
            if (set.normal > 0) set.normal -= 1;
            else set.normal += normals.size() / 3;
        }
        
        if (set.texCoord != INT_MAX) {
            if (set.texCoord > 0) set.texCoord -= 1;
            else set.texCoord += texCoords.size() / 2;
        }
        
        if (set.color != INT_MAX) // Color is optional.
        {
            if (set.color > 0) set.color -= 1;
            else set.color += colors.size() / 4;
        }
        
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
        if (indexSet.normal >= (int) normals.size() && indexSet.normal != INT_MAX)
            throw std::range_error("Surface normal index out of range.");
        if (indexSet.texCoord >= (int) texCoords.size() && indexSet.texCoord != INT_MAX)
            throw std::range_error("Texture coordinate index out of range.");
        
        memcpy(data.vert, &(vertices[indexSet.vertex*3]), sizeof(float [3]));
        if (indexSet.normal != INT_MAX)
            memcpy(data.norm, &(normals[indexSet.normal*3]), sizeof(float [3]));
        else
            data.norm[0] = data.norm[1] = data.norm[2];
            
        if (indexSet.texCoord != INT_MAX)
            memcpy(data.tex, &(texCoords[indexSet.texCoord*2]), sizeof(float [2]));
        else
            data.tex[0] = data.tex[1] = 0.0f;
        
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
    
    for (const auto &index : originalIndices)
        indices.push_back(unifiedIndex(index));
}

GLLObjFile::GLLObjFile(CFURLRef location)
{
    GLLTimer loadingTimer("OBJ");
    
    std::string filename = GLLStringFromFileURL(location);
    
    int fdes = ::open(filename.c_str(), O_RDONLY);
    if (fdes < 0) {
        throw std::runtime_error("Could not open file");
    }
    
    struct stat statistics;
    if (fstat(fdes, &statistics) < 0) {
        close(fdes);
        throw std::runtime_error("Could not get file size");
    }
    
    const char *buffer = (const char *) mmap(nullptr, statistics.st_size, PROT_READ, MAP_PRIVATE, fdes, 0);
    close(fdes);
    const char *current = buffer;
    const char *end = &buffer[statistics.st_size];
    posix_madvise((void *) buffer, statistics.st_size, POSIX_MADV_SEQUENTIAL);
    
    materialLibraryURLs = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    std::string activeMaterial("");
    unsigned activeMaterialStart = 0;
    bool hasFirstMaterial = false;
    while(current != end)
    {
        while (current != end && (*current == ' ' || *current == '\n' || *current == '\r')) {
            current++;
        }
        if (current == end)
            break;
        
        switch (*current) {
            case 'f':
                parseFace(current, end);
                break;
            case 'v':
                current += 1;
                switch (*current) {
                    case 'n': // Normals
                        current += 1;
                        parseVector(current, end, normals, 3);
                        break;
                    case 't': // Tex coords
                        current += 1;
                        parseVector(current, end, texCoords, 2);
                        break;
                    case 'c': // Colors
                        current += 1;
                        parseVector(current, end, colors, 4);
                        break;
                    case ' ': // Vertex
                        parseVector(current, end, vertices, 3);
                        break;
                    default:
                        skipToEndOfLine(current, end);
                        break;
                }
                break;
            case 'm':
                if (followsString(current, end, "mtllib")) {
                    std::string mtllib = stringToEndOfLine(current, end);
                    
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
                    skipToEndOfLine(current, end);
                }
                break;
            case 'u':
                if (followsString(current, end, "usemtl")) {
                    if (hasFirstMaterial)
                    {
                        // End previous material run
                        materialRanges.push_back(MaterialRange(activeMaterialStart, (unsigned) originalIndices.size(), activeMaterial));
                    }
                    else
                        hasFirstMaterial = true;
                    
                    current += 1;
                    activeMaterial = stringToEndOfLine(current, end);
                    activeMaterialStart = (unsigned) originalIndices.size();
                } else {
                    skipToEndOfLine(current, end);
                }
                break;
            case '#': // Comment
            default:
                skipToEndOfLine(current, end);
                break;
        }
    }
    munmap((void *) buffer, statistics.st_size);
    
    // Wrap up final material group
    materialRanges.push_back(MaterialRange(activeMaterialStart, (unsigned) originalIndices.size(), activeMaterial));
    
    fillIndices();
}

GLLObjFile::~GLLObjFile()
{
    CFRelease(materialLibraryURLs);
}
