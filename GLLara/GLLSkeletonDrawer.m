//
//  GLLSkeletonDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 25.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLSkeletonDrawer.h"

#import <OpenGL/gl3.h>

#import "GLLItem.h"
#import "GLLItemBone.h"
#import "GLLModelBone.h"
#import "GLLProgram.h"
#import "GLLResourceManager.h"
#import "GLLVertexFormat.h"
#import "NSColor+Color32Bit.h"
#import "simd_functions.h"

struct GLLSkeletonDrawer_Vertex {
	float position[3];
	uint8_t color[4];
};

@interface GLLSkeletonDrawer ()
{
	GLuint program;
	
	GLuint vertexArray;
	GLuint vertexBuffer;
	GLuint lineElementBuffer;
	
	GLsizei numPoints;
	
	BOOL vertexBufferNeedsUpdate;
	BOOL elementBufferNeedsUpdate;
}

- (void)_updateElementBuffer;
- (void)_updateVertexBuffer;

@end

@implementation GLLSkeletonDrawer

- (id)initWithResourceManager:(GLLResourceManager *)resourceManager;
{
	if (!(self = [super init])) return nil;
	
	program = resourceManager.skeletonProgram.programID;
	
	glGenVertexArrays(1, &vertexArray);
	glGenBuffers(1, &vertexBuffer);
	glGenBuffers(1, &lineElementBuffer);
	
	glBindVertexArray(vertexArray);
	glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, lineElementBuffer);
	glEnableVertexAttribArray(GLLVertexAttribPosition);
	glEnableVertexAttribArray(GLLVertexAttribColor);
	glVertexAttribPointer(GLLVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(struct GLLSkeletonDrawer_Vertex), (GLvoid *) offsetof(struct GLLSkeletonDrawer_Vertex, position));
	glVertexAttribPointer(GLLVertexAttribColor, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(struct GLLSkeletonDrawer_Vertex), (GLvoid *) offsetof(struct GLLSkeletonDrawer_Vertex, color));

	self.defaultColor = [NSColor yellowColor];
	self.selectedColor = [NSColor redColor];
	self.childOfSelectedColor = [NSColor greenColor];
	
	glBindVertexArray(0);
	
	return self;
}

- (void)dealloc
{
	NSAssert(vertexArray == 0 && vertexBuffer == 0 && lineElementBuffer == 0, @"Have to call unload before deallocing!");
}

- (void)unload;
{
	glDeleteVertexArrays(1, &vertexArray);
	glDeleteBuffers(1, &vertexBuffer);
	glDeleteBuffers(1, &lineElementBuffer);
	vertexArray = 0;
	vertexBuffer = 0;
	lineElementBuffer = 0;
}

- (void)draw;
{
	if (!self.items || [self.items count] == 0) return;
	
	glBindVertexArray(vertexArray);
	
	if (elementBufferNeedsUpdate)
		[self _updateElementBuffer];
	if (vertexBufferNeedsUpdate)
		[self _updateVertexBuffer];
	
	glUseProgram(program);
	
	glDrawArrays(GL_POINTS, 0, numPoints);
	glDrawElements(GL_LINES, numPoints*2, GL_UNSIGNED_SHORT, 0);
}

- (void)setItems:(id)items
{
	_items = items;
	elementBufferNeedsUpdate = YES;
	vertexBufferNeedsUpdate = YES;
}

- (void)setSelectedBones:(id)selectedBones
{
	_selectedBones = selectedBones;
	id objects = [_selectedBones valueForKeyPath:@"@distinctUnionOfObjects.item"];
	if (![objects isEqual:self.items])
		self.items = objects;
	elementBufferNeedsUpdate = YES;
}

- (void)_updateElementBuffer;
{
	numPoints = 0;
	for (GLLItem *item in self.items)
		numPoints += item.bones.count;
	
	uint16_t *indices = malloc(sizeof(uint16_t) * numPoints * 2);
	
	NSUInteger i = 0;
	NSUInteger base = 0;
	for (GLLItem *item in self.items)
	{
		for (GLLItemBone *bone in item.bones)
		{
			indices[i+0] = (uint16_t) (i + base);
			indices[i+1] = bone.bone.parentIndex == UINT16_MAX ? indices[i] : (uint16_t) (bone.bone.parentIndex + base);
			
			i += 2;
		}
		base += item.bones.count;
	}
	
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, lineElementBuffer);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(uint16_t) * numPoints * 2, indices, GL_DYNAMIC_DRAW);
	
	glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(struct GLLSkeletonDrawer_Vertex) * numPoints, NULL, GL_DYNAMIC_DRAW);
	
	elementBufferNeedsUpdate = NO;
}

- (void)_updateVertexBuffer;
{
	glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(struct GLLSkeletonDrawer_Vertex) * numPoints, NULL, GL_DYNAMIC_DRAW);
	struct GLLSkeletonDrawer_Vertex *vertices = glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);

	uint8_t defaultColorValue[4];
	[self.defaultColor get32BitRGBAComponents:defaultColorValue];
	uint8_t selectedColorValue[4];
	[self.selectedColor get32BitRGBAComponents:selectedColorValue];
	uint8_t childOfSelectedColorValue[4];
	[self.childOfSelectedColor get32BitRGBAComponents:childOfSelectedColorValue];
	
	NSUInteger i = 0;
	for (GLLItem *item in self.items)
	{
		for (GLLItemBone *bone in item.bones)
		{
			vec_float4 position;
			[bone.globalPosition getValue:&position];
			
			vertices[i].position[0] = simd_extract(position, 0);
			vertices[i].position[1] = simd_extract(position, 1);
			vertices[i].position[2] = simd_extract(position, 2);
			
			if ([self.selectedBones containsObject:bone]) memcpy(vertices[i].color, selectedColorValue, 4);
			else if ([bone isChildOfAny:self.selectedBones]) memcpy(vertices[i].color, childOfSelectedColorValue, 4);
			else memcpy(vertices[i].color, defaultColorValue, 4);
			
			i += 1;
		}
	}
	
	glUnmapBuffer(GL_ARRAY_BUFFER);
	vertexBufferNeedsUpdate = NO;
}

@end
