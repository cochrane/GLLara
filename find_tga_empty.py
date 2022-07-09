import argparse
import glob
import os.path

def readUint8Le(file):
    bytes = f.read(1)
    return bytes[0]

def readUint16Le(file):
    bytes = f.read(2)
    return bytes[0] | (bytes[1] << 8)

# Parse the arguments
parser = argparse.ArgumentParser(description="Finds TGA files that have a zero alpha channel with color information")
parser.add_argument("paths", nargs="+")
args = parser.parse_args()

# Find the paths
allpaths = []
for path in args.paths:
    allpaths += glob.glob(path, recursive=True)

# Find the TGA files
for path in allpaths:
    base, extension = os.path.splitext(path)
    if extension.lower() != ".tga":
        continue

    with open(path, mode="rb") as f:
        pictureIdLength = readUint8Le(f)
        paletteType = readUint8Le(f)
        pictureType = readUint8Le(f)
        paletteStart = readUint16Le(f)
        paletteLength = readUint16Le(f)
        bitsPerPaletteEntry = readUint8Le(f)
        originX = readUint16Le(f)
        originY = readUint16Le(f)
        width = readUint16Le(f)
        height = readUint16Le(f)
        bitsPerPixel = readUint8Le(f)
        pictureAttribute = readUint8Le(f)
        
        if paletteType != 0 or paletteStart != 0 or paletteLength != 0 or bitsPerPaletteEntry != 0:
            # Ignore if has palette
            continue
        if pictureType != 2:
            # Ignore if not raw
            continue
        if originX != 0 or originY != 0:
            # Must have normal origin
            continue
        if bitsPerPixel != 32:
            # Must be 32 bit BGRA
            continue
        if pictureAttribute & 0x0F != 8:
            # Forgot what this is but it's probably important
            continue
        
        dataLength = 4 * width * height
        matchingPixels = 0
        for i in range(0, dataLength, 4):
            values = f.read(4)
            if values[0] != 0 and values[1] != 0 and values[2] != 0 and values[3] == 0:
                # Has color but zero alpha
                matchingPixels += 1
    
    if matchingPixels > 0:
        print("TGA file", path, "has", matchingPixels, "pixels with color but no alpha")
