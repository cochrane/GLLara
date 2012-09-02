Mapping of the render parameters to the actual inputs
=====================================================

Oh the hardcoding… In XNALara, important render information is provided in an array, and the shader has to figure out for itself what to do with it. Except it doesn't; the mapping to the DirectX-equivalent of a uniform is, once more, handled in code, in three places for each shader. That's a tiny bit annoying.

Parameter 0
-	Bump specular amount for shader DiffuseLightmapBump3, DiffuseLightmapBumpSpecular, DiffuseLightmapBump3Specular, DiffuseLightmapBump, DiffuseBump, StaticTRLNextGen, 
-	Reflection amount for shader Metallic, MetallicBump3

Parameter 1
-	Bump 1 UV scale for shader DiffuseLightmapBump3, DiffuseLightmapBump3Specular
-	Bump specular amount for shader MetallicBump3

Parameter 2
-	Bump 2 UV scale for shader MetallicBump3 (yes, both at the same time), DiffuseLightmapBump3, DiffuseLightmapBump3Specular
-	Bump 1 UV scale for shader MetallicBump3