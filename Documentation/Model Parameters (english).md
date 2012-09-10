Model parameters Format
=======================

_Es gibt auch eine deutsche Version dieser Dokumentation._

In XNALara, a lot of values are hardcoded into the program, which has made it historically rather difficult to add new models. GLLara instead saves the values in single .modelparams.plist files. Currently, the result is the same, but in the future it will be possible for authors to provide their own .modelparams.plist files, with significantly enhanced possibilities for rendering (such as completely custom shaders).

This document explains the format, and will always be kept up-to-date. If not, file a bug.

Property List
-------------

All these files are Apple Property List files (Plist in short) and can be edited with any Plsit editor. It's also possible to manipulate them with a text editor. The next part is only for those who don't know plists yet.

Plists do pretty much the same thing as JSON (in fact, historically they looked a lot like it, but then Apple switched to the much more "modern" XML, and the JSON guys were left to rediscover simpler formats years later). It can save any kind of structured value.

The big advantage over JSON is that reading it on a Mac is very, very easy. The files are converted directly to the standard array, dictionary, string and number classes.

The basic structure looks like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	</plist>
	
In there are arrays, dictionaries, strings and numbers (and theoretically some others that I don't use).

A number is simple:

	<real>0.4</real>
	<integer>12</integer>

In this app, it should be `<real>` everywhere, but the odd `<integer>` doesn't hurt anyone (as long as it is an integer).

A string is:

	<string>This is a text</string>

You can save numbers in strings (`<string>0.4</string>`), but that is bad style.

An array is a sorted list of objects. An object can be any element, including numbers, strings, dictionaries and other arrays, and they can even be mixed (although for the modelparams format, they aren't):

	<array>
		<real>12</real>
		<string>hallo!</string>
		<dict>…</dict>
		<array>…</array>
		<real>0.8</real>
	</array>

In most cases, I don't care about the order. When I do, it's especially mentioned below.

A dictionariy is a list of keys followed by objects. The keys are saved as `<key>Key name</key>` and are always strings. Like an array, the objects can be any of the other formats.

	<dict>
		<key>defaultRenderParameters</key>
		<dict>
			<key>bumpSpecularAmount</key>
			<real>0.1</real>
		</dict>
	</dict>

The order of pairs in a dictionary is completely irrelevant. A plist file here always contains exactly one dictionary under the `<plist>` root element.

Defining Models
---------------

For every model that does not use the Generic Item format, there has to be one `modellname.modelparams.plist` file. GLLara includes it into the app when compiling (it ends up in the resources directory). It is always a dictionary, with any or all of the following keys: `base`, `defaultMeshGroup`, `meshGroupNames`, `defaultRenderParameters`, `renderParameters`, `cameraTargets`, `shaders`, `renderParameterDescriptions` und `meshSplitters`.

### base

A string. Gives the name of another modelparams file (without extension). The values of this file will be used, too. You don't have to provide this, but in practice, all files will inherit from `xnaLaraDefault` or a file that inherits from it. If two objects have the same parameters, it is permissible that only one gets a full file and the second uses that full file as its base.

Example:

	…
	<key>base</key>
	<string>xnaLaraDefault</string>
	…

or, for models where it makes sense:

	…
	<key>base</key>
	<string>lara</string>
	…

### meshGroupNames

A dictionary. The keys are the names of mesh groups, the values are arrays containing the names of meshes. A mesh group or render group (the terms can be used interchangeably) are rendered together with the same shader (which one is defined below). A mesh can be part of several mesh groups, but only one of them can have a shader, otherwise the result is undefined. What shader belongs to what group is defined in the `shaders` key below.

Note: All standard mesh groups are supported, but there aren't yet shaders for all of them. The number of supported shaders is constantly growing, though.

Example:

	…
	<key>meshGroupNames</key>
	<dict>
		<key>MeshGroup1</key>
		<array>
			<string>mesh1</string>
			<string>mesh2</string>
		</array>
		<key>MeshGroup2</key>
		<array>
			<string>mesh4</string>
		</array>
		<key>MeshGroup8</key>
		<array>
			<string>mesh3</string>
		</array>
	</dict>
	…

### renderParameters

A dictionary. The keys are names of meshes, the values are dictionaries consisting of names of render parameters and their values.

Setting values for render parameters in XNALara happens by position, i.e. you set parameter 0 and hope that somewhere deep down, the code knows that you mean `bumpSpecularAmount`. I think that's ugly, so here the parameters are set by name. The available parameters and their order in XNALara can be found in `Render Parameters.md`.

Example:

	…
	<key>renderParameters</key>
	<dict>
		<key>belts1</key>
		<dict>
			<key>bump1UVScale</key>
			<integer>16</integer>
			<key>bump2UVScale</key>
			<integer>16</integer>
			<key>bumpSpecularAmount</key>
			<real>0.1</real>
		</dict>
		<key>metal</key>
		<dict>
			<key>bumpSpecularAmount</key>
			<real>0.6</real>
		</dict>
	</dict>
	…

### defaultRenderParameters

A dictionary. Every key is the name of a render parameter, every value is a number that is assigned to that one.

A typical pattern in XNALara is, that the first render parameter is set to the same value for all meshes and then overwritten for some. This implements that behavior. The renderParameter values set here will be used for meshes that don't have their own values for these parameters.

Example:

	…
	<key>defaultRenderParameters</key>
	<dict>
		<key>bumpSpecularAmount</key>
		<real>0.1</real>
	</dict>
	…

### cameraTargets

A dictionary. Every key is the name of a camera target, every value is an array of bones that define the camera target.

Example:

	…
	<key>cameraTargets</key>
	<dict>
		<key>body</key>
		<array>
			<string>root body</string>
		</array>
		<key>head</key>
		<array>
			<string>head jaws upper left 2</string>
			<string>head jaws upper left 1</string>
		</array>
	</dict>
	…

### defaultMeshGroup

**Used rarely.** A string. Gives the mesh group for meshes that don't have one explicitly set.

### shaders

**Normal model files don't need this.** A dictionary. The keys are names of shaders; the values are dictionaries that describe the shader.

A shader here is always GLSL version 150. The interfaces the shaders have to conform to are not yet finalized; they'll be document once they are. The format for the dictionary is available, though:

*	`fragment`: String, file name of a fragment shader.
*	`vertex`: String, file name of a vertex shader.
*	`textures`: Array of strings. The names of the uniforms of the texture samplers, in the order in which they textures are referenced in the mesh.
*	`parameters`: The parameters (uniform names) used by this shader. They are used for the generic item format, and are specified in the order in which they are specified there.
*	`solidMeshGroups`: Array of strings. The names of mesh groups that should be drawn with this shader without blending.
*	`alphaMeshGroups`: Array of strings. The names of mesh groups that should be drawn with this shader with blending.

Every mesh group should have at most one shader (no matter whether it is with or without alpha). The result is not defined otherwise. (In reality, one of the shaders will be selected non-deterministically. There is no guarantee that it will be the same for two meshes even in the same model).

Example:

	…
	<key>shaders</key>
	<dict>
		<key>DiffuseLightmapBump3</key>
		<dict>
			<key>alphaMeshGroups</key>
			<array>
				<string>MeshGroup20</string>
			</array>
			<key>solidMeshGroups</key>
			<array>
				<string>MeshGroup1</string>
			</array>
			<key>textures</key>
			<array>
				<string>diffuseTexture</string>
				<string>lightmapTexture</string>
				<string>bumpTexture</string>
				<string>maskTexture</string>
				<string>bump1Texture</string>
				<string>bump2Texture</string>
			</array>
			<key>parameters</key>
			<array>
				<string>bumpSpecularAmount</string>
				<string>bump1UVScale</string>
				<string>bump2UVScale</string>
			</array>
			<key>fragment</key>
			<string>DiffuseLightmapBump3.fs</string>
			<key>vertex</key>
			<string>Bump.vs</string>
		</dict>
		…
	</dict>
	…

### renderParameterDescriptions

**Normal model files don't need this.** A dictionary; the keys are the names of render parameters, while the dictionaries describe them for display in a user interface.

This part has no corresponding feature in XNALara. In GLLara, you can set render parameters per mesh, no matter what was originally specified. The program determines which render parameters are used by the mesh, and then offers a nice UI for them.

A side effect is that each render parameter has to have the same meaning if it has the same name, across all shaders (at least within a model). I'm assuming that anyway, though, otherwise `defaultRenderParameters` wouldn't make any sense at all.

The contents are:

*	`title`: String, the name the user sees.
*	`description`: String, a short description of what this slider does.
*	`max`: Number, the maximum value e.g. for a slider. Users can still specify values outside the allowed range via a text field.
*	`min`: Number, the corresponding minimum value.

Example:

	…
	<key>renderParameterDescriptions</key>
	<dict>
		<key>bumpSpecularGloss</key>
		<dict>
			<key>title</key>
			<string>Bump Specular Gloss</string>
			<key>description</key>
			<string>Sharpness of the highlights. Higher values produce smaller, more focused highlights.</string>
			<key>max</key>
			<real>100</real>
			<key>min</key>
			<real>0</real>
		</dict>
		…
	</dict>
	…

### meshSplitters

**Normal model files don't need this.** A dictionary. The keys are names of models to split; the values are arrays of dictionaries that describe the new parts and where they come from.

This may be the most obscure part. XNALara insists that on all Lara models, exactly one mesh has to be split into three parts. Fine by me, but I'm doing this a bit less specific here. Every mesh can have one or more mesh splitters. A splitter describes a part of the mesh. On reading, meshes that have such splitters will be replaced by the results of all of their splitters.

A splitter is defined by a dictionary with the key name `Name` (new name of the part) and `{max,min}{X,Y,Z}`, numbers definining a box that the part is in. You don't have to specify all of them. By default, it is negative infinity for the min and positive infinity for the max values.

Render parameters have to be applied to the new pieces, not the original. This thing is used only in the `lara` file and all that inherit from it.

Example (most likely the only one that ever will exist):

	…
	<key>meshSplitters</key>
	<dict>
		<key>thorwireframe</key>
		<array>
			<dict>
				<key>maxX</key>
				<string>0</string>
				<key>minY</key>
				<real>1.25</real>
				<key>Name</key>
				<string>thorglowgauntletright</string>
			</dict>
			<dict>
				<key>minX</key>
				<string>0</string>
				<key>minY</key>
				<real>1.25</real>
				<key>Name</key>
				<string>thorglowgauntletleft</string>
			</dict>
			<dict>
				<key>maxY</key>
				<real>1.25</real>
				<key>Name</key>
				<string>thorglowbelt</string>
			</dict>
		</array>
	</dict>
	…
