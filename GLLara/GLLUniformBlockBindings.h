//
//  GLLUniformBlockBindings.h
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#ifndef GLLara_GLLUniformBlockBindings_h
#define GLLara_GLLUniformBlockBindings_h

/*!
 * @abstract The names for the uniform blocks.
 * @discussion All shaders use the same uniform block bindings. Together with the fact that almost all of them use std140 layout, this means that the buffers can be set once and then forgot about until they need changing.
 */
enum GLLUniformBlockBindings
{
	GLLUniformBlockBindingTransforms,
	GLLUniformBlockBindingLights,
	GLLUniformBlockBindingRenderParameters,
	GLLUniformBlockBindingAlphaTest,
	GLLUniformBlockBindingBoneMatrices
};

#endif
