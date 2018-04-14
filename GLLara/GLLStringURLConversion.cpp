//
//  GLLStringURLConversion.cpp
//  GLLara
//
//  Created by Torsten Kammer on 16.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#include "GLLStringURLConversion.h"

#include <stdexcept>

std::string GLLStringFromFileURL(CFURLRef fileURL)
{
    // Not using CFURLGetFileSystemRepresentation here, because there is no function to find the maximum needed buffer size for CFURL.
    CFURLRef absolute = CFURLCopyAbsoluteURL(fileURL);
    CFStringRef fsPath = CFURLCopyFileSystemPath(absolute, kCFURLPOSIXPathStyle);
    if (!fsPath)
    {
        CFRelease(absolute);
        throw std::runtime_error("Could not convert file path to URL");
    }
    CFRelease(absolute);
    CFIndex length = CFStringGetMaximumSizeOfFileSystemRepresentation(fsPath);
    char *buffer = new char[length];
    CFStringGetFileSystemRepresentation(fsPath, buffer, length);
    CFRelease(fsPath);
    
    std::string result(buffer);
    delete [] buffer;
    return result;
}

CFURLRef GLLCreateURLFromString(const std::string &string, CFURLRef relativeTo)
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
    
    CFStringRef cfString = CFStringCreateWithBytes(kCFAllocatorDefault, (UInt8*) path.c_str(), path.size(), kCFStringEncodingUTF8, false);
    
    CFURLRef result = CFURLCreateWithFileSystemPathRelativeToBase(kCFAllocatorDefault, cfString, kCFURLWindowsPathStyle, false, relativeTo);
    CFRelease(cfString);
    return result;
}
