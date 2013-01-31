//
//  GLLModel.m
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModel.h"

#import "NSArray+Map.h"
#import "GLLASCIIScanner.h"
#import "GLLModelBone.h"
#import "GLLModelMesh.h"
#import "GLLModelParams.h"
#import "GLLModelObj.h"
#import "TRInDataStream.h"
#import "TROutDataStream.h"

NSString *GLLModelLoadingErrorDomain = @"GLL Model loading error domain";

@interface GLLModel ()

// Adds a single mesh to the object, splitting it up into multiple parts if necessary (as specified by the model parameters). Also takes care to add it to the mesh groups and so on.
- (void)_addMesh:(GLLModelMesh *)mesh toArray:(NSMutableArray *)array;

@end

static NSCache *cachedModels;

@implementation GLLModel

+ (void)initialize
{
	cachedModels = [[NSCache alloc] init];
}

+ (id)cachedModelFromFile:(NSURL *)file error:(NSError *__autoreleasing*)error;
{
	id result = [cachedModels objectForKey:file.absoluteURL];
	if (!result)
	{
		if ([file.path hasSuffix:@".mesh"])
		{
			result = [[self alloc] initBinaryFromFile:file error:error];
			if (!result) return nil;
		}
		else if ([file.path hasSuffix:@".mesh.ascii"])
		{
			result = [[self alloc] initASCIIFromFile:file error:error];
			if (!result) return nil;
		}
		else if ([file.path hasSuffix:@".obj"])
		{
			result = [[GLLModelObj alloc] initWithContentsOfURL:file error:error];
			if (!result) return nil;
		}
		else
		{
			if (error)
			{
				// Find display name for this extension
				CFStringRef fileType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef) file.pathExtension, NULL);
				CFStringRef fileTypeDescription = UTTypeCopyDescription(fileType);
				CFRelease(fileType);
				
				*error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_FileTypeNotSupported userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Files of type %@ are not supported.", @"Tried to load other than .mesh or .mesh.ascii"), (__bridge NSString *)fileTypeDescription]  }];
				CFRelease(fileTypeDescription);
			}
			return nil;
		}
		
		[cachedModels setObject:result forKey:file.absoluteURL];
	}
	return result;
}

- (id)initBinaryFromFile:(NSURL *)file error:(NSError *__autoreleasing*)error;
{	
	NSData *data = [NSData dataWithContentsOfURL:file options:0 error:error];
	if (!data) return nil;
	
	return [self initBinaryFromData:data baseURL:file error:error];
}

- (id)initBinaryFromData:(NSData *)data baseURL:(NSURL *)baseURL error:(NSError *__autoreleasing*)error;
{
	if (!(self = [super init])) return nil;
	
	if (data.length < sizeof(uint32_t [2])) // Minimum length
	{
		if (error)
			*error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_PrematureEndOfFile userInfo:@{
				   NSLocalizedDescriptionKey : NSLocalizedString(@"The file is shorter than the minimum file size.", @"Premature end of file error"),
	   NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"A model has to be at least eight bytes long. This file may be corrupted.", @"Premature end of file error.")}];
		return nil;
	}
	
	_baseURL = baseURL;
	_parameters = [GLLModelParams parametersForModel:self error:error];
	if (!_parameters)
	{
		if (error)
			*error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_ParametersNotFound userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Parameters for file could not be found.", @"Loading error: No parameters for this model.")}];
		return nil;
	}
	
	TRInDataStream *stream = [[TRInDataStream alloc] initWithData:data];
	
	BOOL isGenericItem2 = NO;
	
	NSUInteger header = [stream readUint32];
	if (header == 323232)
	{
		/*
		 * This is my idea of how to support the Generic Item 2 format. Note
		 * that this is all reverse engineered from looking at files. I do not
		 * know whether my variable names are correct, and I do not interpret
		 * it in any way.
		 */
		NSLog(@"Warning: Using experimental, hackish, ugly Generic Item 2 support");
		isGenericItem2 = YES;
		
		// First: Two uint16s. My guess: Major, then minor version.
		// Always 1 and 12.
		uint16_t possiblyMajorVersion = [stream readUint16];
		if (possiblyMajorVersion != 0x0001)
		{
			if (error)
				*error = [NSError errorWithDomain:@"GLLModel" code:10 userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"New-style Generic Item has wrong major version.", @"Generic Item 2: Expected 0x0001 at offset 4"), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"If there is a .mesh.ascii version, try opening that.", @"New-style binary generic item won't work.")}];
			return nil;
		}
		uint16_t possiblyMinorVersion = [stream readUint16];
		if (possiblyMinorVersion != 0x000C)
		{
			if (error)
				*error = [NSError errorWithDomain:@"GLLModel" code:10 userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"New-style Generic Item has wrong minor version.", @"Generic Item 2: Expected 0x000C at offset 6"), NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"If there is a .mesh.ascii version, try opening that.", @"New-style binary generic item won't work.")}];
			return nil;
		}
		
		// A string. In all files that I've seen it is XNAaraL.
		NSString *toolAuthor = [stream readPascalString];
		if (![toolAuthor isEqual:@"XNAaraL"])
			NSLog(@"Unusual string at offset %lu: Expected XNAaraL, got %@", stream.position, toolAuthor);
		
		// A count of… thingies that appear after the next three strings. Skip that count times four bytes and you are ready to read bones.
		NSUInteger countOfUnknownint32s = [stream readUint32];
		
		// Three strings. The third is often just a letter (e.g. X).
		NSString *firstAuxilaryString = [stream readPascalString];
		NSString *secondAuxilaryString = [stream readPascalString];
		NSString *thirdAuxilaryString = [stream readPascalString];
		NSLog(@"Auxilary strings: %@, %@, %@", firstAuxilaryString, secondAuxilaryString, thirdAuxilaryString);
		
		// The thingies from above. All the same value in the models I've seen so far, typically small integers (0 or 3). Not sure what count relates to; is not bone count, mesh count, bone count + mesh count or anything like that.
		[stream skipBytes:4 * countOfUnknownint32s];
		
		// Read number of bones.
		header = [stream readUint32];
	}
	
	NSUInteger numBones = header;	
	NSMutableArray *bones = [[NSMutableArray alloc] initWithCapacity:numBones];
	for (NSUInteger i = 0; i < numBones; i++)
	{
		GLLModelBone *bone = [[GLLModelBone alloc] initFromSequentialData:stream partOfModel:self error:error];
		if (!bone) return nil;
		[bones addObject:bone];
	}
	_bones = [bones copy];
	for (GLLModelBone *bone in _bones)
		if (![bone findParentsAndChildrenError:error])
			return nil;
	
	if (!stream.isValid)
	{
		if (error)
			*error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_PrematureEndOfFile userInfo:@{
				   NSLocalizedDescriptionKey : NSLocalizedString(@"The file is missing some data.", @"Premature end of file error"),
	   NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file contains only bones and no meshes. Maybe it was damaged?", @"Premature end of file error")}];
		return nil;
	}
	
	NSUInteger numMeshes = [stream readUint32];
	NSMutableArray *meshes = [[NSMutableArray alloc] initWithCapacity:numMeshes];
	for (NSUInteger i = 0; i < numMeshes; i++)
	{
		GLLModelMesh *mesh = [[GLLModelMesh alloc] initFromStream:stream partOfModel:self error:error];
		if (!mesh) return nil;
		[self _addMesh:mesh toArray:meshes];
	}
	_meshes = meshes;
	
	if (!stream.isValid)
	{
		if (error)
			*error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_PrematureEndOfFile userInfo:@{
				   NSLocalizedDescriptionKey : NSLocalizedString(@"The file is missing some data.", @"Premature end of file error"),
	   NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The mesh data is incomplete. The file may be damaged.", @"Premature end of file error")
					}];
		return nil;
	}
	
	if (isGenericItem2 && !stream.isAtEnd)
	{
		// A string; always $$XNAaraL$$
		NSString *footerAuthor = [stream readPascalString];
		if (![footerAuthor isEqual:@"$$XNAaraL$$"])
			NSLog(@"Unusual string at offset %lu: Expected $$XNAaraL$$, got %@", stream.position, footerAuthor);

		NSString *copyrightNotice = [stream readPascalString];
		NSLog(@"Copyright notice: %@", copyrightNotice);
		
		NSString *creationToolText = [stream readPascalString];
		NSLog(@"Creation tool text: %@", creationToolText);
		
		if (!stream.isValid)
		{
			if (error)
				*error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_PrematureEndOfFile userInfo:@{
					   NSLocalizedDescriptionKey : NSLocalizedString(@"The file is missing some data.", @"Premature end of file error"),
		   NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The Generic Item 2 footer section is incomplete. The file may be damaged.", @"Premature end of file error") }];
			return nil;
		}
	}
	
	return self;
}

- (id)initASCIIFromFile:(NSURL *)file error:(NSError *__autoreleasing*)error;
{
	NSString *source = [NSString stringWithContentsOfURL:file usedEncoding:NULL error:error];
	if (!source) return nil;
	
	return [self initASCIIFromString:source baseURL:file error:error];
}

- (id)initASCIIFromString:(NSString *)source baseURL:(NSURL *)baseURL error:(NSError *__autoreleasing*)error;
{
	if (!(self = [super init])) return nil;
	
	_baseURL = baseURL;
	_parameters = [GLLModelParams parametersForModel:self error:error];
	if (!_parameters)
	{
		if (error)
			*error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_ParametersNotFound userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Parameters for file could not be found.", @"Loading error: No parameters for this model.")}];
		return nil;
	}
	
	GLLASCIIScanner *scanner = [[GLLASCIIScanner alloc] initWithString:source];
	
	NSUInteger numBones = [scanner readUint32];
	NSMutableArray *bones = [[NSMutableArray alloc] initWithCapacity:numBones];
	for (NSUInteger i = 0; i < numBones; i++)
	{
		GLLModelBone *bone = [[GLLModelBone alloc] initFromSequentialData:scanner partOfModel:self error:error];
		if (!bone) return nil;
		[bones addObject:bone];
	}
	_bones = [bones copy];
	for (GLLModelBone *bone in _bones)
		if (![bone findParentsAndChildrenError:error])
			return nil;
	
	if (!scanner.isValid)
	{
		if (error)
			*error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_PrematureEndOfFile userInfo:@{
				   NSLocalizedDescriptionKey : NSLocalizedString(@"The file is missing some data.", @"Premature end of file error"),
	   NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"The file contains only bones and no meshes. Maybe it was damaged?", @"Premature end of file error") }];
		return nil;
	}
	
	NSUInteger numMeshes = [scanner readUint32];
	NSMutableArray *meshes = [[NSMutableArray alloc] initWithCapacity:numMeshes];
	for (NSUInteger i = 0; i < numMeshes; i++)
	{
		GLLModelMesh *mesh = [[GLLModelMesh alloc] initFromScanner:scanner partOfModel:self error:error];
		if (!mesh) return nil;
		[self _addMesh:mesh toArray:meshes];
	}
	_meshes = meshes;
	
	if (!scanner.isValid)
	{
		if (error)
			*error = [NSError errorWithDomain:GLLModelLoadingErrorDomain code:GLLModelLoadingError_PrematureEndOfFile userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"The file is missing some data.", @"Premature end of file error") }];
		return nil;
	}
	
	return self;
}

#pragma mark - Export

- (NSString *)writeASCII;
{
	NSMutableString *result = [NSMutableString string];
	[result appendFormat:@"%lu\n", self.bones.count];
	[result appendString:[[self.bones valueForKey:@"writeASCII"] componentsJoinedByString:@""]];
	[result appendFormat:@"%lu\n", self.meshes.count];
	[result appendString:[[self.meshes valueForKey:@"writeASCII"] componentsJoinedByString:@""]];
	
	return [result copy];
}
- (NSData *)writeBinary;
{
	TROutDataStream *stream = [[TROutDataStream alloc] init];
	[stream appendUint32:(uint32_t) self.bones.count];
	for (GLLModelBone *bone in self.bones)
		[stream appendData:[bone writeBinary]];
	[stream appendUint32:(uint32_t) self.meshes.count];
	for (GLLModelMesh *mesh in self.meshes)
		[stream appendData:[mesh writeBinary]];
	
	return stream.data;
}

#pragma mark - Accessors

- (BOOL)hasBones
{
	return self.bones.count > 0;
}

- (NSArray *)rootBones
{
	return [self.bones filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"hasParent == NO"]];
}

- (NSArray *)cameraTargetNames
{
	return self.parameters.cameraTargets;
}
- (NSArray *)boneNamesForCameraTarget:(NSString *)target;
{
	return [self.parameters boneNamesForCameraTarget:target];
}

#pragma mark - Private methods

- (void)_addMesh:(GLLModelMesh *)mesh toArray:(NSMutableArray *)array;
{
	if ([self.parameters.meshesToSplit containsObject:mesh.name])
	{
		[array addObjectsFromArray:[[self.parameters meshSplittersForMesh:mesh.name] map:^(GLLMeshSplitter *splitter) {
			return [mesh partialMeshFromSplitter:splitter];
		}]];
	}
	else
	{
		[array addObject:mesh];
	}
}

@end
