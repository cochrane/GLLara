//
//  GLLMtlFile.h
//  GLLara
//
//  Created by Torsten Kammer on 16.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#ifndef __GLLara__GLLMtlFile__
#define __GLLara__GLLMtlFile__

#include <CoreFoundation/CoreFoundation.h>
#include <map>
#include <string>

/*!
 * @abstract Stores a list of named materials.
 * @discussion This parses an XNALara specific variant of MTL files belonging to
 * OBJ files, and stores their information.
 */
class GLLMtlFile
{
public:
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
		
		Material() : ambient{1, 1, 1, 1}, diffuse{1, 1, 1, 1}, specular{0, 0, 0, 0}, shininess(0.1), diffuseTexture(0), specularTexture(0), normalTexture(0) {}
		~Material();
		
		const float *getAmbient() const { return ambient; }
		const float *getDiffuse() const { return diffuse; }
		const float *getSpecular() const { return specular; }
		float getShininess() const { return shininess; }
		CFURLRef getDiffuseFilename() const { return diffuseTexture; }
		CFURLRef getSpecularFilename() const { return specularTexture; }
		CFURLRef getNormalFilename() const { return normalTexture; }
	};
private:
	// Handling of materials
	std::map<std::string, Material *> materials;
	
public:
	GLLMtlFile(CFURLRef location);
	
	bool hasMaterial(const std::string &name) const { return materials.find(name) != materials.end(); }
	const Material *getMaterial(const std::string &name) const { return materials.at(name); }
};

#endif /* defined(__GLLara__GLLMtlFile__) */
