//
//  GLLMtlFile.cpp
//  GLLara
//
//  Created by Torsten Kammer on 16.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#include "GLLMtlFile.h"

#include <fstream>
#include <stdexcept>
#include <sstream>

#include "GLLStringURLConversion.h"

GLLMtlFile::GLLMtlFile(CFURLRef location)
{
	std::string filename = GLLStringFromFileURL(location);
	
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
			currentMaterial->diffuseTexture = GLLURLFromString(line.substr(token.size() + 1), location);
		else if (token == "map_Ks")
			currentMaterial->specularTexture = GLLURLFromString(line.substr(token.size() + 1), location);
		else if (token == "map_Kn" || token == "bump" || token == "map_bump")
			currentMaterial->normalTexture = GLLURLFromString(line.substr(token.size() + 1), location);
	}
	
	// Wrap up final material
	currentMaterial->ambient[3] = currentMaterial->diffuse[3] = currentMaterial->specular[3] = 1.0f;
	materials[materialName] = currentMaterial;
}

GLLMtlFile::Material::~Material()
{
	CFRelease(diffuseTexture);
	CFRelease(specularTexture);
	CFRelease(normalTexture);
}
