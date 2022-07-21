#  Version 0.3 todo
To be clear: Not all of them will make it to 0.3

## Missing existing features

- Implement render to file
- Fix automatic view updating (can’t do full automatic rendering on laptop). Maybe make target frame rate configurable or dependent on battery state.
    - Make updating of the GLLView pause once nothing is happening (and make it start up again if there is key down, mouse down, or value change on space mouse or game controller)
- Add support for SSAA

## Missing things from new features

- Autogenerate the always present render parameters, in particular materials. Automatically replace specular intensity with specular color.
- Add assign tex coord to textures in mesh view; consider redoing textures as normal table view
- Game controller stuff (see further down)

## Completely new

- Add „show in finder“ context menu item to models
- Add „show in finder“ context menu item to textures; show filename somewhere
- Include feedback link that brings you to Github, with a form you can fill out
- Consider three-point light setup as default
    - Floor
    - Camera Position
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
- Can we do something nicer when drawing skeletons?
- Add mode that shows where which light is coming from (draw a line or something)

## Bugs

- Check more random models
- Check tangents on Wonder Woman those look off
- Check all shaders whether they really have the right set of features
- Make private list of interesting test files and what they test. 
- Do something about NSKeyedUnarchiveFromData
- Initial Visible state seems wrong sometimes (e.g. Ruby, Weiss from RWBY)

## Stuff to think about if it becomes a performance issue

- Custom affineInverse for matrix if necessary (probably not)
- Improve file loading performance
    - Investigate whether multithreaded loading of resources, pipelines might be useful
    - Load textures privately, copying to them with a blit pass. Also add generating mipmaps here.
    - Load vertex arrays privately, copying to them with a blit/copy pass.
    - Special loading mode, entered when loading, view does not update as much, runs in background. Details to be figured out.
    - Check if we can improve loading times

## Finish game controller support

- Use only current game controller
- Show battery state of game controller in settings
- Support for 3D mouse (still needs a hint on first launch if a 3D mouse is found and the setup page has never been shown before)
- Support for gamepads now with Apple APIs instead of HID stuff (needs overview window, current state view, hint on first launch)
- Game controller bonus feature: Use some key (menu?) to open context menu that allows accessing more features and settings. Features should include: Reset (bone and recursive), undo, redo, …
- Actually use those invert X/Y settings we have

## Camera

- Can we store the camera as a quaternion instead? (how to translate that back to euler angles for the UI?)
- At least limit max camera up angle
- Quaternion-based editing for bones perhaps?

## Refactoring

- Do all settings in SwiftUI, entire window.
- Use NSHostingController instead of NSHostingView as soon as GLLPreferencesWindowController is all Swift
- Get rid of old unittests
- Add new ones where it makes sense
