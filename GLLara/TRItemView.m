//
//  TRItemView.m
//  GLLara
//
//  Created by Torsten Kammer on 18.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "TRItemView.h"

#import <AppKit/NSOpenGL.h>
#import <OpenGL/gl3.h>

#import "simd_project.h"
#import "simd_matrix.h"
#import "TR1Level.h"
#import "TR1Mesh.h"
#import "TR1MeshPointer.h"
#import "TR1Moveable.h"
#import "TR1Room.h"
#import "TR1StaticMesh.h"
#import "TRRenderElement.h"
#import "TRRenderLevelResources.h"
#import "TRRenderMesh.h"
#import "TRRenderTexture.h"

static const char *colorVertexShaderSource = "#version 150\n\
in vec3 position;\
in vec3 color;\
in vec2 texCoord;\
\
out vec2 outTexCoord;\
out vec3 outColor;\
\
uniform mat4 modelViewProjection;\
\
void main()\
{\
	gl_Position = modelViewProjection * vec4(position, 1.0);\
	outColor = color;\
	outTexCoord = texCoord;\
}";

static const char *colorFragmentShaderSource = "#version 150\n\
in vec2 outTexCoord;\
in vec3 outColor;\
\
out vec4 screenColor;\
\
uniform sampler2D levelTexture;\
\
void main()\
{\
	vec4 textureColor = texture(levelTexture, outTexCoord);\
	if (textureColor.a < 0.5) discard;\
	screenColor = textureColor * vec4(outColor, 1.0);\
}";

static const char *lightVertexShaderSource = "#version 150\n\
in vec3 position;\
in vec3 normal;\
in vec2 texCoord;\
\
out vec2 outTexCoord;\
out vec3 outNormal;\
\
uniform mat4 modelViewProjection;\
uniform mat4 modelView;\
\
void main()\
{\
	gl_Position = modelViewProjection * vec4(position, 1.0);\
	outNormal = vec3(modelView * vec4(normal, 0.0));\
	outTexCoord = texCoord;\
}";

static const char *lightFragmentShaderSource = "#version 150\n\
in vec2 outTexCoord;\
in vec3 outNormal;\
\
out vec4 screenColor;\
\
uniform sampler2D levelTexture;\
\
const vec3 lightDirection = vec3(-1, 1, -1);\
\
void main()\
{\
	vec4 textureColor = texture(levelTexture, outTexCoord);\
	if (textureColor.a < 0.5) discard;\
	float brightness = 0.5 + max(0, dot(lightDirection, normalize(outNormal)));\
	screenColor = textureColor * vec4(brightness);\
}";

enum TRItemView_VertexArray
{
	TRItemView_Position,
	TRItemView_Normal,
	TRItemView_Color,
	TRItemView_TexCoord
};

enum TRItemView_RenderMode
{
	TRItemView_OpaqueColor,
	TRItemView_OpaqueLight,
	TRItemView_AlphaColor,
	TRItemView_AlphaLight
};

@interface TRItemView ()
{
	GLuint colorProgram;
	GLuint lightProgram;
	GLint colorMVPLocation;
	GLint lightMVPLocation;
	GLint lightMVLocation;
	
	GLuint colorVAO;
	GLuint lightVAO;
	
	GLuint elementBuffer;
	GLuint vertexBuffer;
	
	GLsizei partsCount;
	GLsizei *elementsPerPart[4];
	const GLvoid* *elementsVBOOffset[4];
	GLint *indexOffsets[4];
	
	float cameraLatitude;
	float cameraLongitude;
	float cameraZoom;
	
	mat_float16 projectionMatrix;
	mat_float16 viewMatrix;
	mat_float16 viewProjectionMatrix;
	
	vec_float4 center;
	
	TRRenderLevelResources *resources;
}

- (NSData *)_vertexData:(NSData *)original movedByX:(float)x y:(float)y z:(float)z;
- (void)_loadLevel:(TR1Level *)level;
- (void)_updateViewMatrix;
- (void)_calculateCenterFromVertexData:(NSData *)data;
- (GLuint)_compileShader:(const char *)source type:(GLenum)type;

@end

@implementation TRItemView

- (id)initWithFrame:(NSRect)frame
{
	NSOpenGLPixelFormatAttribute attribs[] = {
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
		NSOpenGLPFAMultisample, 1,
		NSOpenGLPFASampleBuffers, 1,
		NSOpenGLPFASamples, 8,
		0
	};
	
	NSOpenGLPixelFormat *format = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
	
	if (!(self = [super initWithFrame:frame pixelFormat:format])) return nil;
	
	viewMatrix = simd_mat_identity();
	
	[self setWantsBestResolutionOpenGLSurface:YES];
	
	return self;
}

- (void)prepareOpenGL
{
	// Set up basic properties
	glEnable(GL_DEPTH_TEST);
	glClearColor(1, 1, 1, 1);
	glBlendFunc(GL_ONE, GL_ONE);
	
	// Create programs
	
	// -- Color
	colorProgram = glCreateProgram();
	GLuint colorVertexShader = [self _compileShader:colorVertexShaderSource type:GL_VERTEX_SHADER];
	GLuint colorFragmentShader = [self _compileShader:colorFragmentShaderSource type:GL_FRAGMENT_SHADER];
	glAttachShader(colorProgram, colorVertexShader);
	glAttachShader(colorProgram, colorFragmentShader);
	
	glBindAttribLocation(colorProgram, TRItemView_Position, "position");
	glBindAttribLocation(colorProgram, TRItemView_Color, "color");
	glBindAttribLocation(colorProgram, TRItemView_TexCoord, "texCoord");
	glLinkProgram(colorProgram);
	glUseProgram(colorProgram);
	glUniform1i(glGetUniformLocation(colorProgram, "levelTexture"), 0);
	colorMVPLocation = glGetUniformLocation(colorProgram, "modelViewProjection");
	
	// -- Light
	lightProgram = glCreateProgram();
	GLuint lightVertexShader = [self _compileShader:lightVertexShaderSource type:GL_VERTEX_SHADER];
	GLuint lightFragmentShader = [self _compileShader:lightFragmentShaderSource type:GL_FRAGMENT_SHADER];
	glAttachShader(lightProgram, lightVertexShader);
	glAttachShader(lightProgram, lightFragmentShader);
	
	glBindAttribLocation(lightProgram, TRItemView_Position, "position");
	glBindAttribLocation(lightProgram, TRItemView_Normal, "normal");
	glBindAttribLocation(lightProgram, TRItemView_TexCoord, "texCoord");
	glLinkProgram(lightProgram);
	glUseProgram(lightProgram);
	glUniform1i(glGetUniformLocation(lightProgram, "levelTexture"), 0);
	lightMVPLocation = glGetUniformLocation(lightProgram, "modelViewProjection");
	lightMVLocation = glGetUniformLocation(lightProgram, "modelView");
	
	// Create VAOs
	glGenBuffers(1, &elementBuffer);
	glGenBuffers(1, &vertexBuffer);
	
	glGenVertexArrays(1, &lightVAO);
	glGenVertexArrays(1, &colorVAO);
	
	glBindVertexArray(lightVAO);
	glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer);
	
	glEnableVertexAttribArray(TRItemView_Position);
	glEnableVertexAttribArray(TRItemView_Normal);
	glEnableVertexAttribArray(TRItemView_TexCoord);
	glVertexAttribPointer(TRItemView_Position, 3, GL_FLOAT, GL_FALSE, sizeof(TRRenderElement), (const GLvoid *) offsetof(TRRenderElement, position));
	glVertexAttribPointer(TRItemView_Normal, 3, GL_FLOAT, GL_FALSE, sizeof(TRRenderElement), (const GLvoid *) offsetof(TRRenderElement, normalOrColor));
	glVertexAttribPointer(TRItemView_TexCoord, 2, GL_FLOAT, GL_FALSE, sizeof(TRRenderElement), (const GLvoid *) offsetof(TRRenderElement, texCoord));
	
	glBindVertexArray(colorVAO);
	glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer);
	
	glEnableVertexAttribArray(TRItemView_Position);
	glEnableVertexAttribArray(TRItemView_Color);
	glEnableVertexAttribArray(TRItemView_TexCoord);
	glVertexAttribPointer(TRItemView_Position, 3, GL_FLOAT, GL_FALSE, sizeof(TRRenderElement), (const GLvoid *) offsetof(TRRenderElement, position));
	glVertexAttribPointer(TRItemView_Color, 3, GL_FLOAT, GL_FALSE, sizeof(TRRenderElement), (const GLvoid *) offsetof(TRRenderElement, normalOrColor));
	glVertexAttribPointer(TRItemView_TexCoord, 2, GL_FLOAT, GL_FALSE, sizeof(TRRenderElement), (const GLvoid *) offsetof(TRRenderElement, texCoord));
	
	// Create texture. Again, there's just the one
	GLuint texture;
	glGenTextures(1, &texture);
	glBindTexture(GL_TEXTURE_2D, texture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	
	glEnable(GL_MULTISAMPLE);
	
	cameraZoom = 2.0;
}

- (void)reshape
{
	NSRect actualPixels = [self convertRectToBacking:[self bounds]];
	glViewport(0, 0, actualPixels.size.width, actualPixels.size.height);
	
	projectionMatrix = simd_frustumMatrix(65.0f, actualPixels.size.width/actualPixels.size.height, 0.1, 200.0f);
	
	viewProjectionMatrix = simd_mat_mul(projectionMatrix, viewMatrix);
	
	[[self openGLContext] makeCurrentContext];
	glUseProgram(lightProgram);
	glUniformMatrix4fv(lightMVPLocation, 1, GL_FALSE, (const float *) &viewProjectionMatrix);
	glUseProgram(colorProgram);
	glUniformMatrix4fv(colorMVPLocation, 1, GL_FALSE, (const float *) &viewProjectionMatrix);
}

- (void)drawRect:(NSRect)dirtyRect
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glUseProgram(colorProgram);
	glBindVertexArray(colorVAO);
	glMultiDrawElementsBaseVertex(GL_TRIANGLES, elementsPerPart[TRItemView_OpaqueColor], GL_UNSIGNED_SHORT, elementsVBOOffset[TRItemView_OpaqueColor], partsCount, indexOffsets[TRItemView_OpaqueColor]);
	
	glUseProgram(lightProgram);
	glBindVertexArray(lightVAO);
	glMultiDrawElementsBaseVertex(GL_TRIANGLES, elementsPerPart[TRItemView_OpaqueLight], GL_UNSIGNED_SHORT, elementsVBOOffset[TRItemView_OpaqueLight], partsCount, indexOffsets[TRItemView_OpaqueLight]);
	
	glEnable(GL_BLEND);
	
	glMultiDrawElementsBaseVertex(GL_TRIANGLES, elementsPerPart[TRItemView_AlphaLight], GL_UNSIGNED_SHORT, elementsVBOOffset[TRItemView_AlphaLight], partsCount, indexOffsets[TRItemView_AlphaLight]);
	
	glUseProgram(colorProgram);
	glBindVertexArray(colorVAO);
	glMultiDrawElementsBaseVertex(GL_TRIANGLES, elementsPerPart[TRItemView_AlphaColor], GL_UNSIGNED_SHORT, elementsVBOOffset[TRItemView_AlphaColor], partsCount, indexOffsets[TRItemView_AlphaColor]);
	
	glDisable(GL_BLEND);
	
	[[self openGLContext] flushBuffer];
}

- (void)showMoveable:(TR1Moveable *)moveable;
{
	NSLog(@"not supported");
}
- (void)showRoom:(TR1Room *)room;
{
	NSLog(@"not supported");
}
- (void)showStaticMesh:(TR1StaticMesh *)staticMesh;
{
	if (staticMesh.level != resources.level)
		[self _loadLevel:staticMesh.level];
	
	TR1Mesh *mesh = staticMesh.mesh.mesh;
	TRRenderMesh *renderMesh = [[TRRenderMesh alloc] initWithMesh:mesh resources:resources];
	
	NSUInteger opaqueCount, alphaCount, vertexCount;
	NSData *vertexData = [renderMesh createVertexDataVectorCount:&vertexCount];
	NSData *elementData = [renderMesh createElementsNormalCount:&opaqueCount alphaCount:&alphaCount];
	
	for (int i = 0; i < 4; i++)
	{
		elementsPerPart[i] = realloc(elementsPerPart[i], sizeof(GLsizei));
		elementsPerPart[i][0] = 0;
		elementsVBOOffset[i] = realloc(elementsVBOOffset[i], sizeof(GLvoid *));
		elementsVBOOffset[i][0] = 0;
		indexOffsets[i] = realloc(indexOffsets[i], sizeof(GLint));
		indexOffsets[i][0] = 0;
	}

	if (mesh.usesInternalLighting)
	{
		elementsPerPart[TRItemView_OpaqueColor][0] = (GLsizei) opaqueCount;
		elementsPerPart[TRItemView_AlphaColor][0] = (GLsizei) alphaCount;
		elementsVBOOffset[TRItemView_AlphaColor][0] = (GLvoid *) (opaqueCount * sizeof(GLuint));
	}
	else
	{
		elementsPerPart[TRItemView_OpaqueLight][0] = (GLsizei) opaqueCount;
		elementsPerPart[TRItemView_AlphaLight][0] = (GLsizei) alphaCount;
		elementsVBOOffset[TRItemView_AlphaLight][0] = (GLvoid *) (opaqueCount * sizeof(GLuint));
	}
	
	partsCount = 1;
	
	[self _calculateCenterFromVertexData:vertexData];
	
	[self.openGLContext makeCurrentContext];
	glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
	glBufferData(GL_ARRAY_BUFFER, (GLsizei) vertexData.length, vertexData.bytes, GL_STATIC_DRAW);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, (GLsizei) elementData.length, elementData.bytes, GL_STATIC_DRAW);
	
	self.needsDisplay = YES;
}
- (void)showAllRoomsOfLevel:(TR1Level *)level withMoveables:(BOOL)includeThem;
{
	NSLog(@"not supported");
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	cameraLatitude += M_PI * theEvent.deltaY / self.bounds.size.height;
	cameraLongitude += M_PI * theEvent.deltaX / self.bounds.size.width;
	[self _updateViewMatrix];
}

#pragma mark - Private methods

- (NSData *)_vertexData:(NSData *)original movedByX:(float)x y:(float)y z:(float)z;
{
	NSMutableData *result = [original mutableCopy];
	NSUInteger count = result.length / sizeof(TRRenderElement);
	TRRenderElement *vertex = (TRRenderElement *) result.mutableBytes;
	
	for (NSUInteger i = 0; i < count; i++)
	{
		vertex[i].position[0] += x;
		vertex[i].position[1] += y;
		vertex[i].position[2] += z;
	}
	
	return [result copy];
}

- (void)_loadLevel:(TR1Level *)level;
{
	resources = [[TRRenderLevelResources alloc] initWithLevel:level];
	
	// Load texture
	TRRenderTexture *tex = resources.renderTexture;
	NSData *data = tex.create32BitData;
	[self.openGLContext makeCurrentContext];
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei) tex.width, (GLsizei) tex.height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, data.bytes);
}

- (void)_updateViewMatrix
{
	vec_float4 viewDirection = simd_mat_vecmul(simd_mat_euler(simd_make(cameraLatitude, cameraLongitude, 0.0f, 0.0f), simd_e_w), -simd_e_z);
	
	vec_float4 position = center - viewDirection * simd_splatf(cameraZoom);
	
	viewMatrix = simd_mat_lookat(viewDirection, position);
	viewMatrix = simd_mat_mul(simd_mat_rotate(M_PI, simd_e_z), viewMatrix);
	
	viewProjectionMatrix = simd_mat_mul(projectionMatrix, viewMatrix);
	
	[self.openGLContext makeCurrentContext];
	glUseProgram(lightProgram);
	glUniformMatrix4fv(lightMVPLocation, 1, GL_FALSE, (const float *) &viewProjectionMatrix);
	glUniformMatrix4fv(lightMVLocation, 1, GL_FALSE, (const float *) &viewMatrix);
	glUseProgram(colorProgram);
	glUniformMatrix4fv(colorMVPLocation, 1, GL_FALSE, (const float *) &viewProjectionMatrix);
	
	self.needsDisplay = YES;
}

- (void)_calculateCenterFromVertexData:(NSData *)data;
{
	const TRRenderElement *element = (const TRRenderElement *) data.bytes;
	NSUInteger count = data.length / sizeof(TRRenderElement);
	float x, y, z;
	for (NSUInteger i = 0; i < count; i += 1)
	{
		x += element[i].position[0] / (float) count;
		y += element[i].position[1] / (float) count;
		z += element[i].position[2] / (float) count;
	}
	
	center = simd_make(x, y, z, 1);
	[self _updateViewMatrix];
}
- (GLuint)_compileShader:(const char *)source type:(GLenum)type;
{
	GLuint shader = glCreateShader(type);
	
	glShaderSource(shader, 1, (const GLchar *[]) { source }, (const GLint[]) { (GLint) strlen(source)});
	glCompileShader(shader);
	
	GLint compileStatus;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &compileStatus);
	if (compileStatus != GL_TRUE)
	{
		GLsizei length;
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
		GLchar log[length+1];
		glGetShaderInfoLog(shader, length+1, NULL, log);
		log[length] = '\0';
		
		NSLog(@"compile error in shader %s: %s", source, log);
		
		glDeleteShader(shader);
		return 0;
	}
	return shader;
}

@end
