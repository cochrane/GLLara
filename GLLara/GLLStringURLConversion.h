//
//  GLLStringURLConversion.h
//  GLLara
//
//  Created by Torsten Kammer on 16.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#ifndef __GLLara__GLLStringURLConversion__
#define __GLLara__GLLStringURLConversion__

#include <CoreFoundation/CoreFoundation.h>
#include <string>

/*!
 * @header GLLStringURLConversion.h
 * @abstract Converting between CFURLs and std::string containing local paths.
 * @discussion These functions are not particularly interesting, but needed
 * both by the MTL and OBJ files.
 */
std::string GLLStringFromFileURL(CFURLRef fileURL);
CFURLRef GLLCreateURLFromString(const std::string &string, CFURLRef relativeTo);

#endif /* defined(__GLLara__GLLStringURLConversion__) */
