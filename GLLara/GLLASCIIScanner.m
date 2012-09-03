//
//  GLLASCIIScanner.m
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLASCIIScanner.h"

@interface GLLASCIIScanner ()
{
	NSScanner *scanner;
}

- (NSInteger)_readInteger;
- (void)_skipComments;

@end

@implementation GLLASCIIScanner

- (id)initWithString:(NSString *)string;
{
	if (!(self = [super init])) return nil;
	
	scanner = [NSScanner scannerWithString:string];
	
	// Use american english at all times, because that is the number format used.
	scanner.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en-US"];
	
	return self;
}

- (uint32_t)readUint32;
{
	return (uint32_t) [self _readInteger];
}
- (uint16_t)readUint16;
{
	return (uint16_t) [self _readInteger];
}
- (uint8_t)readUint8;
{
	return (uint8_t) [self _readInteger];
}
- (Float32)readFloat32;
{
	[self _skipComments];
	if (scanner.isAtEnd)
		[NSException raise:NSInvalidArgumentException format:@"Premature end of file!"];
	
	float result;
	if (![scanner scanFloat:&result])
		[NSException raise:NSInvalidArgumentException format:@"Expected float at position %lu, but didn't get it.", scanner.scanLocation];
	
	return result;
}

- (NSString *)readPascalString;
{
	[self _skipComments];
	if (scanner.isAtEnd) [NSException raise:NSInvalidArgumentException format:@"Premature end of file!"];
	
	[scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
	
	NSString *result;
	if (![scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&result])
		[NSException raise:NSInvalidArgumentException format:@"Expected string at position %lu, but didn't get it.", scanner.scanLocation];
	
	return result;
}


- (NSInteger)_readInteger;
{
	[self _skipComments];
	if (scanner.isAtEnd)
		[NSException raise:NSInvalidArgumentException format:@"Premature end of file!"];
	
	NSInteger result;
	if (![scanner scanInteger:&result])
		[NSException raise:NSInvalidArgumentException format:@"Expected integer at position %lu, but didn't get it.", scanner.scanLocation];
	
	return result;
}

- (void)_skipComments;
{
	while ([scanner scanString:@"#" intoString:NULL])
		[scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
}

@end
