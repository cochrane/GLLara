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

std::string GLLStringFromFileURL(CFURLRef fileURL);
CFURLRef GLLURLFromString(const std::string &string, CFURLRef relativeTo);

#endif /* defined(__GLLara__GLLStringURLConversion__) */
