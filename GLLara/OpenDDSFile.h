#pragma once
/*
 *  OpenDDSFile.h
 *  DDSQuickLook
 *
 *  Created by Torsten Kammer on 15.02.08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <CoreFoundation/CoreFoundation.h>

typedef struct __DDSFile DDSFile;

enum DDSDataFormat
{
	DDS_UNKNOWN,
	DDS_DXT1,
	DDS_DXT3,
	DDS_DXT5,
	DDS_ARGB_1555,
	DDS_ARGB_4,
	DDS_RGB_565,
	DDS_RGB_8,
	DDS_ARGB_8
};

DDSFile *DDSOpenFile(CFURLRef file);
DDSFile *DDSOpenData(CFDataRef data);
void DDSDestroy(DDSFile *file);

CFIndex DDSGetWidth(const DDSFile *file);
CFIndex DDSGetHeight(const DDSFile *file);
Boolean DDSHasMipmaps(const DDSFile *file);
CFIndex DDSGetNumMipmaps(const DDSFile *file);
Boolean DDSIsCompressed(const DDSFile *file);
enum DDSDataFormat DDSGetDataFormat(const DDSFile *file);
CFDataRef DDSCreateDataForMipmapLevel(const DDSFile *file, CFIndex level);