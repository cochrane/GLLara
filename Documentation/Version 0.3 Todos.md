#  Version 0.3 todo
To be clear: Not all of them will make it to 0.3

## Missing things from new features

- Add assign tex coord to textures in mesh view; consider redoing textures as normal table view
    - Maybe also redo render parameters as normal table view? Dream would be a combined view including features, numeric values, color values and textures (with coordinates), similar in overall design to how Metal shows resources

## Completely new

- Add „show in finder“ context menu item to models
- Add „show in finder“ context menu item to textures; show filename somewhere
- Include feedback link that brings you to Github, with a form you can fill out
- Consider three-point light setup as default
    - Add floor
    - Change camera position
- Make the optional parts (handgun in hand and holster, Thor stuff) officially optional

### 3D UI

- Show rotation target
    - game controller rotate around target
- Can we do something nicer when drawing skeletons?
- Add mode that shows where which light is coming from (draw a line or something)

## Bugs

- Check more random models
- Check tangents on Wonder Woman those look off
- Check all shaders whether they really have the right set of features
- Make private list of interesting test files and what they test. 
- Do something about NSKeyedUnarchiveFromData
- Initial Visible state seems wrong sometimes (e.g. Ruby, Weiss from RWBY)
- Window size gets doubled on restore, probably using wrong size on loading (actual pixels vs drawn size)

## Finish game controller support

- Hint on first launch for 3D mouse, gamepad
- Switch to "rotate around target" mode. Make that mode also selectable in UI, and show HUD indicator when switching from controller

# Not required for 0.3

## Completely new

- Add „show in finder“ context menu item to models
- Add „show in finder“ context menu item to textures; show filename somewhere
- Include feedback link that brings you to Github, with a form you can fill out
- Consider three-point light setup as default
    - Add floor
    - Change camera position
- Make the optional parts (handgun in hand and holster, Thor stuff) officially optional

### Graphics features

- Shadow maps
- Cube maps for reflections
- Skybox mode
- sRGB?
- If really bored: Consider dual depth peeling
- Use dual depth peeling blend formula to get rid of all but 1 (or two?) extra color buffers (first attempt didn’t work, maybe retry later)
- Maybe finally implement this thor glow shit, it’s genuinely annoying to me.
- Cartoon shader - quantify output colors

### 3D UI

- Show rotation target
    - game controller rotate around target
- Can we do something nicer when drawing skeletons?
- Add mode that shows where which light is coming from (draw a line or something)
- Show tangent matrix shader via compute pass? Necessitates moving skinning into compute pass.

## Stuff to think about if it becomes a performance issue

- Custom affineInverse for matrix if necessary (probably not)
- Improve file loading performance
    - Investigate whether multithreaded loading of resources, pipelines might be useful
    - Load textures privately, copying to them with a blit pass. Also add generating mipmaps here.
    - Load vertex arrays privately, copying to them with a blit/copy pass.
    - Special loading mode, entered when loading, view does not update as much, runs in background. Details to be figured out.
    - Check if we can improve loading times

## Finish game controller support

- Game controller bonus feature: Use some key (menu?) to open context menu that allows accessing more features and settings. Features should include: Reset (bone and recursive), undo, redo, …

## Camera

- Can we store the camera as a quaternion instead? (how to translate that back to euler angles for the UI?)
- At least limit max camera up angle
- Quaternion-based editing for bones perhaps? (at least for game controllers)

## Refactoring

- Do all settings in SwiftUI, entire window.
- Use NSHostingController instead of NSHostingView as soon as GLLPreferencesWindowController is all Swift
- Get rid of old unittests
- Add new ones where it makes sense
