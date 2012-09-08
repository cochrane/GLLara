/*
 *  OpenDDSFile.c
 *  DDSQuickLook
 *
 *  Created by Torsten Kammer on 15.02.08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "OpenDDSFile.h"
#include <ApplicationServices/ApplicationServices.h>

// All information about the DDS file format is taken from
// http://msdn.microsoft.com/archive/default.asp?url=/archive/en-us/directx9_c/directx/graphics/reference/ddsfilereference/ddsfileformat.asp

struct __DDSFile
{
	enum DDSDataFormat format;
	CFIndex width;
	CFIndex height;
	CFIndex numMipmapLevels;
	CFDataRef data;
};

struct DDSPixelFormat
{
	uint32_t size;
	uint32_t flags;
	uint32_t fourCC;
	uint32_t rgbBitCount;
	uint32_t rBitMask;
	uint32_t gBitMask;
	uint32_t bBitMask;
	uint32_t aBitMask;
};

struct DDSCaps
{
	uint32_t caps1;
	uint32_t caps2;
	uint32_t reserved[2];
};

struct DDSFileHeader
{
	uint32_t size;
	uint32_t flags;
	uint32_t height;
	uint32_t width;
	uint32_t pitchOrLinearSize;
	uint32_t depth;
	uint32_t mipMapCount;
	uint32_t reserved1[11];
	struct DDSPixelFormat pixelFormat;
	struct DDSCaps caps;
	uint32_t reserved2;
};

void dds_swap_file_header(struct DDSFileHeader *header)
{
#define SWAP_FIELD(a) a = CFSwapInt32(a)
#ifdef __LITTLE_ENDIAN__
	// Swap the fourCC so we can use it the apple way
	SWAP_FIELD(header->pixelFormat.fourCC);
#else

	SWAP_FIELD(header->size);
	SWAP_FIELD(header->flags);
	SWAP_FIELD(header->height);
	SWAP_FIELD(header->width);
	SWAP_FIELD(header->pitchOrLinearSize);
	SWAP_FIELD(header->depth);
	SWAP_FIELD(header->mipMapCount);
	// Reserved field in DDSFileHeader is not swapped
	
	SWAP_FIELD(header->pixelFormat.size);
	SWAP_FIELD(header->pixelFormat.flags);
	SWAP_FIELD(header->pixelFormat.rgbBitCount);
	SWAP_FIELD(header->pixelFormat.rBitMask);
	SWAP_FIELD(header->pixelFormat.gBitMask);
	SWAP_FIELD(header->pixelFormat.bBitMask);
	SWAP_FIELD(header->pixelFormat.aBitMask);
	
	SWAP_FIELD(header->caps.caps1);
	SWAP_FIELD(header->caps.caps2);
	// Reserved field in DDSCaps is not swapped
	
	// Reserved field in DDSFileHeader is not swapped
#endif /* __LITTLE_ENDIAN__ */
#undef SWAP_FIELD
}

DDSFile *DDSOpenFile(CFURLRef url)
{
	CGDataProviderRef dataProvider = CGDataProviderCreateWithURL(url);
	CFDataRef data = CGDataProviderCopyData(dataProvider);
	CGDataProviderRelease(dataProvider);
	
	if (!data) return NULL;
    DDSFile *result = DDSOpenData(data);
    return result;
}

DDSFile *DDSOpenData(CFDataRef data)
{
#define ASSUME(a) do { if (!(a)) { CFRelease(data); free(file); return NULL; } } while(0)
	CFRetain(data);
	
	// Is there a way to get a CFDataRef from an url without going through Core Graphics,
	// but just as short?
	DDSFile *file = calloc(sizeof(DDSFile), 1);
	
	
	// Check for magic header
	const void *fileData = CFDataGetBytePtr(data);
	ASSUME(memcmp(fileData, "DDS ", 4) == 0);
	
	struct DDSFileHeader header;
	memcpy((void *) &header, fileData + 4, sizeof(header));
	dds_swap_file_header(&header);
	
	// Check whether size fields have correct value
	ASSUME(header.size == 124 && header.pixelFormat.size == 32);
	
	// Find the file's format
	if (header.pixelFormat.flags == 4) // Use the FourCC
	{
		if (header.pixelFormat.fourCC == 'DXT1')
			file->format = DDS_DXT1;
		else if (header.pixelFormat.fourCC == 'DXT3')
			file->format = DDS_DXT3;
		else if (header.pixelFormat.fourCC == 'DXT5')
			file->format = DDS_DXT5;
		else ASSUME(0);
	}
	else if (header.pixelFormat.flags & 64) // Use RGB
	{
		if (header.pixelFormat.flags & 1) // Contains alpha
		{
			if (header.pixelFormat.rgbBitCount == 32)
			{
				// To be supported, it has to be ARGB32 now.
				ASSUME(header.pixelFormat.aBitMask == 0xff000000);
				ASSUME(header.pixelFormat.rBitMask == 0x00ff0000);
				ASSUME(header.pixelFormat.gBitMask == 0x0000ff00);
				ASSUME(header.pixelFormat.bBitMask == 0x000000ff);
				file->format = DDS_ARGB_8;
			}
			else if (header.pixelFormat.rgbBitCount == 16)
			{
				// It can be ARGB4 (what format is that? never heard of it) or ARGB1555.
				if (header.pixelFormat.aBitMask == 0x8000 && header.pixelFormat.rBitMask == 0x7C00 && header.pixelFormat.gBitMask == 0x03E0 && header.pixelFormat.bBitMask == 0x001F)
					file->format = DDS_ARGB_1555;
				else if (header.pixelFormat.aBitMask == 0xF000 && header.pixelFormat.rBitMask == 0x0F00 && header.pixelFormat.gBitMask == 0x00F0 && header.pixelFormat.bBitMask == 0x000F)
					file->format = DDS_ARGB_1555;
				else ASSUME(0);
			}
			else ASSUME(0);
			
		}
		else // No alpha
		{
			if (header.pixelFormat.rgbBitCount == 24)
			{
				// To be supported, it has to be RGB32 now.
				ASSUME(header.pixelFormat.rBitMask == 0x00ff0000);
				ASSUME(header.pixelFormat.gBitMask == 0x0000ff00);
				ASSUME(header.pixelFormat.bBitMask == 0x000000ff);
				file->format = DDS_RGB_8;
			}
			else if (header.pixelFormat.rgbBitCount == 16)
			{
				// To be supported, it has to be RGB565 now.
				ASSUME(header.pixelFormat.rBitMask == 0xF800);
				ASSUME(header.pixelFormat.gBitMask == 0x7E0);
				ASSUME(header.pixelFormat.bBitMask == 0x001F);
				file->format = DDS_RGB_565;
			}
			else ASSUME(0);
		}
	}
	else ASSUME(0);
	
	file->width = header.width;
	file->height = header.height;
	file->numMipmapLevels = header.mipMapCount;
	file->data = data;
	
	return file;
}

CFDataRef DDSCreateDataForMipmapLevel(const DDSFile *file, CFIndex level)
{	
	CFIndex size = 0;
	CFIndex offset = 0;
	CFIndex height = file->height;
	CFIndex width = file->width;
	CFIndex i;
	for (i = 0; i <= level && (width || height); ++i) 
	{ 
		if (width == 0) 
			width = 1; 
		if (height == 0) 
			height = 1;

		offset += size;
				
		switch(file->format)
		{
			case DDS_DXT1:
				size = ((width+3)/4)*((height+3)/4)*8;
			break;
			case DDS_DXT3:
			case DDS_DXT5:
				size = ((width+3)/4)*((height+3)/4)*16;
			break;
			case DDS_ARGB_1555:
			case DDS_ARGB_4:
			case DDS_RGB_565:
				size = (width * height) * 2;
			break;
			case DDS_RGB_8:
				size = (width * height) * 3;
			break;
			case DDS_ARGB_8:
				size = (width * height) * 4;
			break;
			default:
				size = 0;
		}
		width  >>= 1; 
		height >>= 1; 
	}
	UInt8 *newData = malloc(size);
	CFIndex newDataStart = 4 + sizeof(struct DDSFileHeader) + offset;
	
	if (newDataStart + size > CFDataGetLength(file->data))
		return DDSCreateDataForMipmapLevel(file, level-1);
	
	CFDataGetBytes(file->data, CFRangeMake(newDataStart, size), newData);
	
	return CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, newData, size, kCFAllocatorMalloc);
}

CFIndex DDSGetWidth(const DDSFile *file)
{
	return file->width;
}
CFIndex DDSGetHeight(const DDSFile *file)
{
	return file->height;
}
Boolean DDSHasMipmaps(const DDSFile *file)
{
	return (file->numMipmapLevels > 0);
}
CFIndex DDSGetNumMipmaps(const DDSFile *file)
{
	return file->numMipmapLevels;
}
Boolean DDSIsCompressed(const DDSFile *file)
{
	return (file->format == DDS_DXT1 || file->format == DDS_DXT3 || file->format == DDS_DXT5);
}
enum DDSDataFormat DDSGetDataFormat(const DDSFile *file)
{
	return file->format;
}

void DDSDestroy(DDSFile *file)
{
	CFRelease(file->data);
	file->data = nil;
	free(file);
}