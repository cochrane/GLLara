//
//  GLLView.swift
//  GLLara
//
//  Created by Torsten Kammer on 09.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Cocoa
import MetalKit
import GameController
import Combine

@objc class GLLView: MTKView {
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device ?? GLLResourceManager.shared.metalDevice)
        
        clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0)
        enableSetNeedsDisplay = false
        isPaused = false
        autoResizeDrawable = true
        sampleCount = 1
        
        notificationObservers.append(NotificationCenter.default.addObserver(forName: NSNotification.Name(GLLTexture.changeNotification), object: nil, queue: OperationQueue.main) { [weak self] notification in
            self?.unpause()
        })
        notificationObservers.append(NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: OperationQueue.main) { [weak self] notification in
            self?.showSelection = UserDefaults.standard.bool(forKey: GLLPrefShowSkeleton)
        })
        notificationObservers.append(NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidBecomeCurrent, object: nil, queue: OperationQueue.main) { [weak self] notification in
            self?.unpause()
        })
        
        showSelection = UserDefaults.standard.bool(forKey: GLLPrefShowSkeleton)
        
        registerForDraggedTypes( [ NSPasteboard.PasteboardType.fileURL ] )
        
        // Trigger loading of manager
        _ = GLLGameControllerManager.shared
    }
    
    @objc func unpause() {
        if isPaused {
            lastPositionUpdate = Date.timeIntervalSinceReferenceDate
        }
        somethingChangedLastFrame = true
        isPaused = false
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
         // The MetalKit implementation of this delegates to init(frame:device:) so we should never get here.
    }
    
    @objc func set(camera: GLLCamera, sceneDrawer: GLLSceneDrawer) {
        self.camera = camera
        sceneDrawerUpdateRegistration?.cancel()
        self.sceneDrawer = sceneDrawer
        sceneDrawerUpdateRegistration = sceneDrawer.$needsUpdate.sink { [weak self] value in
            if value {
                self?.unpause()
            }
        }
        self.viewDrawer = GLLViewDrawer(sceneDrawer: sceneDrawer, camera: camera, view: self)
    }
    
    var camera: GLLCamera? = nil
    @objc weak var document: GLLDocument? = nil
    var sceneDrawer: GLLSceneDrawer? = nil
    var sceneDrawerUpdateRegistration: AnyCancellable? = nil
    @objc var viewDrawer: GLLViewDrawer? = nil
    var showSelection: Bool = false
    var keysDown = CharacterSet()
    private var currentModifierFlags: NSEvent.ModifierFlags = []
    var notificationObservers: [NSObjectProtocol] = []
    
    @objc func unload() {
        viewDrawer = nil
        camera = nil
    }
    
    private static let wasdCharacters = CharacterSet(charactersIn: "wasd")
    private static let xyzCharacters = CharacterSet(charactersIn: "xyz")
    private static let arrowCharacters = CharacterSet(charactersIn: UnicodeScalar(NSUpArrowFunctionKey)! ... UnicodeScalar(NSRightArrowFunctionKey)!)
    private static let interestingCharacters = wasdCharacters.union(xyzCharacters).union(arrowCharacters)
    private static let unitsPerSecond = 0.2
    
    private var inGesture = false
    private var dragDestination = GLLItemDragDestination()
    private var inEventLoop = false
    
    // MARK: - Events
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func rotate(with event: NSEvent) {
        guard let camera = camera, !camera.cameraLocked else {
            return
        }
        
        let angle = event.rotation * Float.pi / 180.0
        camera.longitude -= angle
        unpause()
    }
    
    override func magnify(with event: NSEvent) {
        guard let camera = camera, !camera.cameraLocked else {
            return
        }
        
        camera.distance *= Float(1 + event.magnification)
        unpause()
    }
    
    override func beginGesture(with event: NSEvent) {
        guard let camera = camera, !camera.cameraLocked else {
            return
        }
        
        inGesture = true
        camera.managedObjectContext?.undoManager?.beginUndoGrouping()
        camera.managedObjectContext?.undoManager?.setActionIsDiscardable(true)
    }
    
    override func endGesture(with event: NSEvent) {
        inGesture = false
        
        guard let camera = camera, !camera.cameraLocked else {
            return
        }
        camera.managedObjectContext?.undoManager?.setActionName(NSLocalizedString("Camera changed", comment: "Undo: data of camera has changed"))
        camera.managedObjectContext?.undoManager?.endUndoGrouping()
        unpause()
    }
    
    override func scrollWheel(with event: NSEvent) {
        guard let camera = camera, !camera.cameraLocked else {
            return
        }
        
        camera.currentPositionX += Float(event.deltaX / bounds.size.width)
        camera.currentPositionY += Float(event.deltaY / bounds.size.height)
        unpause()
    }
    
    override func mouseDragged(with event: NSEvent) {
        if !GLLView.xyzCharacters.intersection(keysDown).isEmpty {
            let amountX = event.deltaX / bounds.size.width
            let amountY = event.deltaY / bounds.size.height
            
            let angle = amountX + amountY
            
            let rotation = SIMD3<Float>(x: keysDown.contains("x") ? Float(angle) : 0.0,
                                        y: keysDown.contains("y") ? Float(angle) : 0.0,
                                        z: keysDown.contains("z") ? Float(angle) : 0.0)
            rotateBones(eulerAngles: rotation)
        } else if event.modifierFlags.contains(.option) {
            // Move the object in the x/z plane
            let factor = event.modifierFlags.contains(.shift) ? 0.01 : 0.001
            let deltaScreen = SIMD4<Float32>(Float32(event.deltaX * factor), 0.0, Float32(event.deltaY * factor), 0.0)
            let deltaWorld = self.camera!.viewMatrix.inverse * deltaScreen
            
            for item in document?.selection.selectedItems ?? [] {
                item.positionX += deltaWorld.x;
                item.positionZ += deltaWorld.z;
            }
        } else if event.modifierFlags.contains(.shift) && GLLView.wasdCharacters.intersection(keysDown).isEmpty {
            // This is a move event
            guard let camera = camera, !camera.cameraLocked else {
                return
            }
            
            let deltaX = Float(event.deltaX / self.bounds.size.width)
            let deltaY = Float(event.deltaY / self.bounds.size.height)
            camera.moveLocalX(-deltaX, y: deltaY, z: 0)
        } else if event.modifierFlags.contains(.control) {
            self.rightMouseDragged(with: event)
        } else {
            // This is a rotate event
            guard let camera = camera, !camera.cameraLocked else {
                return
            }
            camera.longitude -= Float(event.deltaX * Double.pi / self.bounds.size.width);
            camera.latitude -= Float(event.deltaY * Double.pi / self.bounds.size.height);
        }
        
        unpause()
    }
    
    override func rightMouseDragged(with event: NSEvent) {
        let deltaX = Float(event.deltaX / self.bounds.size.width)
        let deltaY = Float(event.deltaY / self.bounds.size.height)
        
        turnAroundCamera(deltaX: deltaX, deltaY: deltaY)
    }
    
    override func keyDown(with event: NSEvent) {
        keysDown.formUnion(CharacterSet(charactersIn: event.charactersIgnoringModifiers?.lowercased() ?? ""))
        currentModifierFlags = event.modifierFlags
        unpause()
    }
    
    override func mouseDown(with event: NSEvent) {
        if self.showSelection, let document = self.document, var selectedBones = document.selection.selectedBones {
            // Try to find the bone that corresponds to this event.
            if let bone = closestBone(atScreenPoint: convert(event.locationInWindow, from: nil), from: document.allBones) {
               
                if event.modifierFlags.isSuperset(of: [.shift, .command]) {
                    // Add to/remove from the selection
                    if let index = selectedBones.firstIndex(of: bone) {
                        selectedBones.remove(at: index)
                        document.selection.selectedBones = selectedBones
                    } else {
                        selectedBones.append(bone)
                        document.selection.selectedBones = selectedBones
                    }
                } else {
                    // Set as only selection
                    document.selection.selectedBones = [bone]
                }
            }
            unpause()
        }
    }
    
    override func keyUp(with event: NSEvent) {
        keysDown.subtract(CharacterSet(charactersIn: event.charactersIgnoringModifiers?.lowercased() ?? ""))
        currentModifierFlags = event.modifierFlags
        unpause()
    }
    
    override func flagsChanged(with event: NSEvent) {
        currentModifierFlags = event.modifierFlags
        unpause()
    }
    
    private var buttonWasDown = Set<GCControllerButtonInput>()
    /**
     Determine whether the given button was actually pressed first in this frame. Just looking for the "pressed" state may give wrong answers, especially since MFI gamepads have button that can report pressure levels, and so can call gamepadChanged multiple times for one press.
     */
    private func buttonPressed(element: GCControllerElement) -> Bool {
        guard let button = element as? GCControllerButtonInput else {
            return false
        }
        if button.isPressed {
            return !buttonWasDown.contains(button)
        } else {
            return false
        }
    }
    
    private func boneOfDocument(first: Bool) -> GLLItemBone? {
        guard let document = document, let managedObjectContext = document.managedObjectContext else {
            return nil
        }
        
        let fetchRequest = NSFetchRequest<GLLItem>()
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "GLLItem", in: managedObjectContext)
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "displayName", ascending: first) ]
        fetchRequest.fetchLimit = 1
        
        let result = (try? managedObjectContext.fetch(fetchRequest)) ?? []
        return firstBone(item: result.first)
    }

    private func parentBone() -> GLLItemBone? {
        guard let document = document else {
            return nil
        }

        // If item is selected: Select its root bone
        if let firstSelected = document.selection.selectedObjects.firstObject as? GLLItem {
            return firstSelected.bones.firstObject as? GLLItemBone
        }
        
        // If nothing selected: Root bone of first model
        if document.selection.selectedBones.isEmpty {
            return boneOfDocument(first: true)
        }
        
        // If multiple selection: Parent of first item that doesn't have an ancestor in the selection
        let selectedBones = document.selection.selectedBones!
        var filteredBones = selectedBones
        filteredBones.removeAll { bone in
            bone.isChild(ofAny: selectedBones)
        }
        let skipUnused = UserDefaults.standard.bool(forKey: GLLPrefHideUnusedBones)
        return filteredBones.first?.parent(skippingUnused: skipUnused)
    }
    
    private func isValid(bone: GLLItemBone?) -> Bool {
        guard let bone = bone else {
            return false
        }
        return !UserDefaults.standard.bool(forKey: GLLPrefHideUnusedBones) || !bone.bone.name.hasPrefix("unused")
    }
    
    private func firstBone(item: GLLItem?) -> GLLItemBone? {
        return item?.bones.first(where: { isValid(bone: $0 as? GLLItemBone) }) as? GLLItemBone
    }
    
    private func lastBone(item: GLLItem?) -> GLLItemBone? {
        return item?.bones.reverseObjectEnumerator().first(where: { isValid(bone: $0 as? GLLItemBone) }) as? GLLItemBone
    }
    
    private func childBone() -> GLLItemBone? {
        guard let document = document else {
            return nil
        }
        
        // If item is selected: Select its root bone
        if let firstSelected = document.selection.selectedObjects.firstObject as? GLLItem {
            return firstBone(item: firstSelected)
        }
        
        // If nothing selected: Root bone of first model
        if document.selection.selectedBones.isEmpty {
            return boneOfDocument(first: false)
        }
        
        // If multiple selected: First child of last item that doesn't have a child in the selection
        let selectedBones = document.selection.selectedBones!
        var filteredBones = selectedBones
        var ancestorsOfSelected = Set<GLLItemBone>()
        for selected in selectedBones {
            var parent = selected.parent
            while parent != nil {
                ancestorsOfSelected.remove(parent!)
                parent = parent?.parent
            }
        }
        filteredBones.removeAll { bone in
            ancestorsOfSelected.contains(bone)
        }
        let skipUnused = UserDefaults.standard.bool(forKey: GLLPrefHideUnusedBones)
        return filteredBones.last?.firstChild(skippingUnused: skipUnused)
    }
    
    private func nextSiblingBone() -> GLLItemBone? {
        guard let document = document, let managedObjectContext = document.managedObjectContext else {
            return nil
        }
        
        // If item is selected: Select its root bone
        if let firstSelected = document.selection.selectedObjects.firstObject as? GLLItem {
            return firstBone(item: firstSelected)
        }
        
        // If nothing selected: Root bone of first model
        if document.selection.selectedBones.isEmpty {
            return boneOfDocument(first: true)
        }
        let skipUnused = UserDefaults.standard.bool(forKey: GLLPrefHideUnusedBones)
        // Select next sibling bone of last selected bone.
        let selection = document.selection.selectedBones
        if let lastSelectedBone = selection?.last {
            if let siblings = lastSelectedBone.siblings(skippingUnused: skipUnused) {
                if let index = siblings.firstIndex(of: lastSelectedBone) {
                    let nextIndex = (index + 1) % siblings.count
                    return siblings[nextIndex]
                }
            } else {
                // If root bone: Either next root bone or next model
                let item = lastSelectedBone.item!
                let rootBones = item.rootBones
                if let index = rootBones.firstIndex(of: lastSelectedBone) {
                    let nextIndex = (index + 1) % rootBones.count
                    return rootBones[nextIndex]
                } else {
                    // Root of next item
                    let fetchRequest = NSFetchRequest<GLLItem>()
                    fetchRequest.entity = NSEntityDescription.entity(forEntityName: "GLLItem", in: managedObjectContext)
                    fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "displayName", ascending: true) ]
                    
                    if let result = try? managedObjectContext.fetch(fetchRequest), let index = result.firstIndex(of: item) {
                        if index < result.count - 1 {
                            return firstBone(item: result[index + 1])
                        } else {
                            return lastBone(item: result[0])
                        }
                    }
                }
            }
        }
        return nil
    }
    
    private func previousSiblingBone() -> GLLItemBone? {
        guard let document = document, let managedObjectContext = document.managedObjectContext else {
            return nil
        }
        
        // If item is selected: Select its root bone
        if let firstSelected = document.selection.selectedObjects.firstObject as? GLLItem {
            return firstBone(item: firstSelected)
        }
        
        // If nothing selected: Root bone of last model
        if document.selection.selectedBones.isEmpty {
            return boneOfDocument(first: false)
        }
        let skipUnused = UserDefaults.standard.bool(forKey: GLLPrefHideUnusedBones)
        // Select next sibling bone of last selected bone.
        let selection = document.selection.selectedBones
        if let firstSelectedBone = selection?.first {
            if let siblings = firstSelectedBone.siblings(skippingUnused: skipUnused) {
                if let index = siblings.firstIndex(of: firstSelectedBone) {
                    let nextIndex = (index + siblings.count - 1) % siblings.count
                    return siblings[nextIndex]
                }
            } else {
                // If root bone: Either next root bone or next model
                let item = firstSelectedBone.item!
                let rootBones = item.rootBones
                if let index = rootBones.firstIndex(of: firstSelectedBone) {
                    let nextIndex = (index + rootBones.count - 1) % rootBones.count
                    return item.rootBones[nextIndex]
                } else {
                    // Root of previous item
                    let fetchRequest = NSFetchRequest<GLLItem>()
                    fetchRequest.entity = NSEntityDescription.entity(forEntityName: "GLLItem", in: managedObjectContext)
                    fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "displayName", ascending: true) ]
                    
                    if let result = try? managedObjectContext.fetch(fetchRequest), let index = result.firstIndex(of: item) {
                        if index > 0 {
                            return lastBone(item: result[index - 1])
                        } else {
                            return firstBone(item: result[0])
                        }
                    }
                }
            }
        }
        return nil
    }
    
    private func selectGamepadMode(delta: Int) {
        let current = controllerRightStickMode
        let orderedModes = ControllerRightStickMode.allCases
        if let index = orderedModes.firstIndex(of: current) {
            var nextIndex = index + delta
            if nextIndex < 0 {
                nextIndex = orderedModes.count - 1
            }
            let next = orderedModes[nextIndex % orderedModes.count]
            UserDefaults.standard.set(next.rawValue, forKey: GLLPrefControllerRightStickMode)
        }
    }
    
    private func selectNextGamepadCameraMode() {
        let current = controllerLeftStickMode
        let orderedModes = CameraMovementMode.allCases
        if let index = orderedModes.firstIndex(of: current) {
            let nextIndex = (index + 1) % orderedModes.count
            let next = orderedModes[nextIndex % orderedModes.count]
            UserDefaults.standard.set(next.rawValue, forKey: GLLPrefControllerLeftStickMode)
        }
    }
    
    func gamepadChanged(gamepad: GCExtendedGamepad, element: GCControllerElement) {
        // Left shoulder: Go to previous controller mode
        if element == gamepad.leftShoulder && buttonPressed(element: element) {
            selectGamepadMode(delta: -1)
        }
        
        // Right trigger: Go to next controller mode
        if element == gamepad.rightShoulder && buttonPressed(element: element) {
            selectGamepadMode(delta: +1)
        }
        
        if let leftStickButton = gamepad.leftThumbstickButton, element == leftStickButton, buttonPressed(element: element) {
            selectNextGamepadCameraMode()
        }
        
        // DPad: Go to different bone
        if element == gamepad.dpad {
            let newSelection: GLLItemBone?
            if buttonPressed(element: gamepad.dpad.up) {
                newSelection = parentBone()
            } else if buttonPressed(element: gamepad.dpad.down) {
                newSelection = childBone()
            } else if buttonPressed(element: gamepad.dpad.left) {
                newSelection = previousSiblingBone()
            } else if buttonPressed(element: gamepad.dpad.right) {
                newSelection = nextSiblingBone()
            } else {
                newSelection = nil
            }
            if let document = document, let bone = newSelection {
                document.selection.selectedBones = [ bone ]
                viewDrawer?.selectViaController(bone: bone)
            }
        }
        
        // Cleanup: Update "was pressed" state
        if let button = element as? GCDeviceButtonInput {
            if button.isPressed {
                buttonWasDown.insert(button)
            } else {
                buttonWasDown.remove(button)
            }
        }
        
        // Draw a frame
        self.contiuousInputActive = true
        unpause()
    }
    
    private var somethingChangedLastFrame = true
    
    override func draw() {
        updatePositions()
        
        super.draw()
        
        if !contiuousInputActive && !somethingChangedLastFrame && !(viewDrawer?.runningAnimation ?? false) {
            isPaused = true
        }
        somethingChangedLastFrame = false
    }
    
    // MARK: - Drag and drop
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let document = document else {
            return []
        }
        dragDestination.document = document
        
        return dragDestination.itemDraggingEntered(sender)
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let document = document else {
            return false
        }
        dragDestination.document = document
        
        do {
            try dragDestination.performItemDragOperation(sender)
            return true
        } catch {
            presentError(error)
            return false
        }
    }
    
    // MARK: - Activity status
    @objc static weak var lastActiveView: GLLView? = nil
    
    func windowBecameKey() {
        GLLView.lastActiveView = self
    }
    
    func windowResignedKey() {
    }
    
    // MARK: - Private methods
    
    private var lastPositionUpdate: TimeInterval?
    
    private func adjustForDeadzone(vector: SIMD3<Float>, deadzone: Double) -> (SIMD3<Float>, SIMDMask<SIMD3<Float>.MaskStorage>) {
        let deadzoneVector = SIMD3<Float>(repeating: Float(deadzone))
        let insideDeadzone = simd_abs(vector) .<= deadzoneVector
        
        let adjustedRangeMin = __tg_copysign(deadzoneVector, vector);
        let adjusted = (vector - adjustedRangeMin) / (SIMD3<Float>(repeating: 1.0) - deadzoneVector)
        return (adjusted.replacing(with: 0.0, where: insideDeadzone), insideDeadzone)
    }
    
    // Whether any continuous input is going on, including keyboard or controllers
    private var contiuousInputActive: Bool = false {
        didSet {
            if contiuousInputActive {
                unpause()
            }
        }
    }
    
    private func updatePositions() {
        let now = Date.timeIntervalSinceReferenceDate
        var diff = now - (lastPositionUpdate ?? now)
        lastPositionUpdate = now
        
        viewDrawer?.updateHudAnimation(delta: diff)
    
        if currentModifierFlags.contains(.shift) {
            diff *= 10
        }
        
        // Get the current state for the space mouse
        let rawSpaceMouseRotation = GLLConnexionManager.shared().averageRotation()
        let rawSpaceMousePosition = GLLConnexionManager.shared().averagePosition()
        
        let (adjustedRotation, rotationInsideDeadzone) = adjustForDeadzone(vector: rawSpaceMouseRotation, deadzone: spaceMouseDeadZoneRotation)
        let (adjustedPosition, positionInsideDeadzone) = adjustForDeadzone(vector: rawSpaceMousePosition, deadzone: spaceMouseDeadZoneTranslation)
        
        // Check whether we should still be moving
        if GLLView.interestingCharacters.intersection(keysDown).isEmpty && currentModifierFlags.isDisjoint(with: [.shift, .option]) && all(rotationInsideDeadzone) && all(positionInsideDeadzone) && !currentControllerActive {
            contiuousInputActive = false
            return
        }
        contiuousInputActive = true
        
        // Perform actions
        // - Move
        if let camera = camera, !camera.cameraLocked {
            let deltaX = directionFactor(positive: ["d"], negative: ["a"])
            let deltaZ = directionFactor(positive: ["s"], negative: ["w"])
            if deltaX != nil || deltaZ != nil {
                let diffX = (deltaX ?? 0) * Float(diff * GLLView.unitsPerSecond)
                let diffZ = (deltaZ ?? 0) * Float(diff * GLLView.unitsPerSecond)
                camera.moveLocalX(diffX, y: 0, z: diffZ)
            }
        }
        
        // Move bones with arrow keys
        if !GLLView.xyzCharacters.intersection(keysDown).isEmpty {
            if let delta = directionFactor(positive: [UnicodeScalar(NSLeftArrowFunctionKey)!, UnicodeScalar(NSUpArrowFunctionKey)!], negative: [UnicodeScalar(NSRightArrowFunctionKey)!, UnicodeScalar(NSDownArrowFunctionKey)!]) {
                let speed = delta * Float(diff * 0.1 * GLLView.unitsPerSecond)
                for bone in document?.selection.selectedBones ?? [] {
                    if keysDown.contains("x") {
                        bone.positionX += speed
                    }
                    if keysDown.contains("y") {
                        bone.positionY += speed
                    }
                    if keysDown.contains("z") {
                        bone.positionZ += speed
                    }
                }
            }
        } else if currentModifierFlags.contains(.option) {
            // Move the object up or down with arrow keys
            if let deltaY = directionFactor(positive: [UnicodeScalar(NSUpArrowFunctionKey)!], negative: [UnicodeScalar(NSDownArrowFunctionKey)!]) {
            
                for item in document?.selection.selectedItems ?? [] {
                    item.positionY += deltaY * 0.1 * Float(diff * GLLView.unitsPerSecond)
                }
            }
        } else if !GLLView.arrowCharacters.intersection(keysDown).isEmpty {
            if let camera = camera {
                let deltaX = directionFactor(positive: [UnicodeScalar(NSRightArrowFunctionKey)!], negative: [UnicodeScalar(NSLeftArrowFunctionKey)!])
                let deltaZ = directionFactor(positive: [UnicodeScalar(NSDownArrowFunctionKey)!], negative: [UnicodeScalar(NSUpArrowFunctionKey)!])
                
                if deltaX != nil || deltaZ != nil {
                    let diffX = (deltaX ?? 0) * 0.1 * Float(diff * GLLView.unitsPerSecond)
                    let diffZ = (deltaZ ?? 0) * 0.1 * Float(diff * GLLView.unitsPerSecond)
                    let screenDelta = SIMD4<Float32>(x: diffX,
                                                     y: 0,
                                                     z: diffZ,
                                                     w: 0)
                    let worldDelta = camera.viewMatrix.inverse * screenDelta
                    
                    for item in document?.selection.selectedItems ?? [] {
                        item.positionX += worldDelta.x
                        item.positionZ += worldDelta.z
                    }
                }
            }
        }
        // Controller input
        if GLLView.lastActiveView == self, let camera = camera, !camera.cameraLocked {
            if !all(rotationInsideDeadzone) || !all(positionInsideDeadzone) {
                // Update based on space mouse inputs
                // Need to swap the coordinates because the space mouse uses a different coordinate system from us
                let positionSpeed = Float(spaceMouseTranslationSpeed * diff)
                camera.moveLocalX(adjustedPosition.x * positionSpeed, y: -adjustedPosition.z * positionSpeed, z: adjustedPosition.y * positionSpeed)
                
                let rotationSpeed = Float(spaceMouseRotationSpeed * diff)
                if spaceMouseMode == .rotateAroundTarget {
                    camera.longitude -= adjustedRotation.z * rotationSpeed;
                    camera.latitude += adjustedRotation.x * rotationSpeed;
                } else {
                    turnAroundCamera(deltaX: adjustedRotation.z * rotationSpeed, deltaY: -adjustedRotation.x * rotationSpeed)
                }
            }
            
            // Game controller input
            if let controller = GCController.current, let extendedGamepad = controller.extendedGamepad {
                // Rotate camera based on left thumbstick
                let rotationX = extendedGamepad.leftThumbstick.xAxis.value
                let rotationY = extendedGamepad.leftThumbstick.yAxis.value
                
                if rotationX != 0.0 || rotationY != 0.0 {
                    let rotationSpeed = Float(controllerRotationSpeedCamera * diff)
                    let xSign: Float = UserDefaults.standard.bool(forKey: GLLPrefControllerInvertXAxis) ? -1.0 : 1.0
                    let ySign: Float = UserDefaults.standard.bool(forKey: GLLPrefControllerInvertYAxis) ? -1.0 : 1.0
                    if controllerLeftStickMode == .rotateAroundTarget {
                        camera.longitude -= rotationX * rotationSpeed * xSign;
                        camera.latitude += rotationY * rotationSpeed * ySign;
                    } else {
                        turnAroundCamera(deltaX: rotationX * rotationSpeed * xSign, deltaY: -rotationY * rotationSpeed * ySign)
                    }
                }
                
                let otherStickX = extendedGamepad.rightThumbstick.xAxis.value
                let otherStickY = -extendedGamepad.rightThumbstick.yAxis.value
                let otherStickZ = extendedGamepad.leftTrigger.value * -1 + extendedGamepad.rightTrigger.value
                if otherStickX != 0.0 || otherStickZ != 0.0 || otherStickY != 0.0 {
                    if controllerRightStickMode == .moveCamera {
                        let positionSpeed = Float(controllerMoveCameraSpeed * diff)
                        camera.moveLocalX(otherStickX * positionSpeed, y: otherStickZ * positionSpeed, z: otherStickY * positionSpeed)
                    } else if let bones = document?.selection.selectedBones, !bones.isEmpty {
                        if controllerRightStickMode == .moveBones {
                            let movementSpeed = Float(controllerMoveCameraSpeed * controllerMoveBoneSpeed * diff)
                            for bone in bones {
                                // Move bone
                                // Note y/z swap that's on purpose
                                bone.positionX += otherStickX * movementSpeed
                                bone.positionY += otherStickZ * movementSpeed
                                bone.positionZ += otherStickY * movementSpeed
                            }
                        } else {
                            let rotationSpeed = Float(controllerRotationSpeedCamera * controllerRotationSpeedBone * diff)
                            // Note x/y swapped that's on purpose
                            rotateBones(eulerAngles: SIMD3<Float>(x: otherStickY, y: otherStickX, z: otherStickZ) * rotationSpeed)
                        }
                    }
                }
            }
        }
    }
    
    private func rotateBones(eulerAngles: SIMD3<Float>) {
        guard let bones = document?.selection.selectedBones, !bones.isEmpty, eulerAngles != SIMD3<Float>(repeating: 0) else {
            return
        }
        
        for bone in bones {
            // Rotate bone
            let current = bone.rotation
            let multiply = GLLItemBone.rotationMatrix(angles: eulerAngles)
            let modified = current * multiply
            
            let angles = GLLItemBone.eulerAngles(rotationMatrix: modified)
            bone.rotationX = angles.x
            bone.rotationY = angles.y
            bone.rotationZ = angles.z
        }
    }
    
    private var currentControllerActive: Bool {
        guard let gamepad = GCController.current?.extendedGamepad else {
            return false
        }
        return gamepad.leftTrigger.value != 0 || gamepad.rightTrigger.value != 0 || gamepad.leftThumbstick.xAxis.value != 0 || gamepad.leftThumbstick.yAxis.value != 0 || gamepad.rightThumbstick.xAxis.value != 0 || gamepad.rightThumbstick.yAxis.value != 0
    }
        
    /**
     Returns 1 if any "positive" keys are pressed and none of the "negative" ones, -1 if any of the "negative" keys are pressed and none of the positive ones, and 0 if keys from neither or both sets are pressed
     */
    private func directionFactor(positive: [UnicodeScalar], negative: [UnicodeScalar]) -> Float? {
        let anyInPositive = !CharacterSet(positive).isDisjoint(with: keysDown)
        let anyInNegative = !CharacterSet(negative).isDisjoint(with: keysDown)
        if anyInPositive && !anyInNegative {
            return 1.0
        } else if anyInNegative && !anyInPositive {
            return -1.0
        } else {
            return nil
        }
    }
    
    private func closestBone(atScreenPoint point: NSPoint, from bones: [GLLItemBone]) -> GLLItemBone? {
        guard let camera = camera else {
            return nil
        }
        
        let viewProjection = camera.viewProjectionMatrix
        let size = simd_float2(Float(bounds.width), Float(bounds.height))
        
        var closestDistance = Float.infinity
        var closestBone: GLLItemBone? = nil
        
        for bone in bones {
            let worldPosition = bone.globalPosition
            var screenPosition = viewProjection * worldPosition
            screenPosition /= screenPosition.w
            let screen2D = simd_float2(x: screenPosition.x, y: screenPosition.y)
            
            let screenXY = (screen2D * 0.5 + 0.5) * size
            
            let distanceToRay = simd_length(screenXY)
            if distanceToRay > 10 {
                continue
            }
            
            if screenPosition.z < closestDistance {
                closestDistance = screenPosition.z
                closestBone = bone
            }
        }
        
        return closestBone
    }
    
    private func turnAroundCamera(deltaX: Float, deltaY: Float) {
        guard let camera = camera, !camera.cameraLocked else {
            return
        }
        
        // TODO None of these maths work
        // Turn camera around it's current position. To do this:
        // 1. Find current position
        let position = camera.cameraWorldPosition
        // 2. Calculate new position of target
        let cameraRelativeLatitude = camera.latitude - deltaY
        let cameraRelativeLongitude = camera.longitude - deltaX
        
        let viewDirection = simd_mat_euler(vec_float4(cameraRelativeLatitude, cameraRelativeLongitude, 0, 0), vec_float4(0, 0, 0, 1)) * vec_float4(0, 0, 1, 0)
        
        let newTargetPosition = position - viewDirection * camera.distance
        
        camera.positionX = newTargetPosition.x;
        camera.positionY = newTargetPosition.y;
        camera.positionZ = newTargetPosition.z;
        
        // 3. Calculate new rotation of camera
        camera.longitude -= deltaX;
        camera.latitude -= deltaY;
        
        unpause()
    }
    
    // TODO Read from prefs
    var spaceMouseDeadZoneTranslation: Double {
        UserDefaults.standard.double(forKey: GLLPrefSpaceMouseDeadzoneTranslation)
    }
    var spaceMouseDeadZoneRotation: Double {
        UserDefaults.standard.double(forKey: GLLPrefSpaceMouseDeadzoneRotation)
    }
    var spaceMouseRotationSpeed: Double {
        UserDefaults.standard.double(forKey: GLLPrefSpaceMouseSpeedRotation)
    }
    var spaceMouseTranslationSpeed: Double {
        UserDefaults.standard.double(forKey: GLLPrefSpaceMouseSpeedTranslation)
    }
    
    enum CameraMovementMode: String, CaseIterable {
        case rotateAroundTarget
        case rotateAroundCamera
    }
    var spaceMouseMode: CameraMovementMode {
        return CameraMovementMode(rawValue: UserDefaults.standard.string(forKey: GLLPrefSpaceMouseMode) ?? CameraMovementMode.rotateAroundCamera.rawValue) ?? .rotateAroundCamera
    }
    
    var controllerLeftStickMode: CameraMovementMode {
        return CameraMovementMode(rawValue: UserDefaults.standard.string(forKey: GLLPrefControllerLeftStickMode) ?? CameraMovementMode.rotateAroundCamera.rawValue) ?? .rotateAroundCamera
    }
    
    var controllerRotationSpeedCamera: Double {
        return UserDefaults.standard.double(forKey: GLLPrefControllerCameraRotationSpeed)
    }
    
    var controllerMoveCameraSpeed: Double {
        return UserDefaults.standard.double(forKey: GLLPrefControllerCameraMovementSpeed)
    }
    
    var controllerRotationSpeedBone: Double {
        return UserDefaults.standard.double(forKey: GLLPrefControllerBoneRotationSpeed)
    }
    
    var controllerMoveBoneSpeed: Double {
        return UserDefaults.standard.double(forKey: GLLPrefControllerBoneMovementSpeed)
    }
    
    enum ControllerRightStickMode: String, CaseIterable {
        case moveCamera
        case rotateBones
        case moveBones
    }
    var controllerRightStickMode: ControllerRightStickMode {
        return ControllerRightStickMode(rawValue: UserDefaults.standard.string(forKey: GLLPrefControllerRightStickMode) ?? ControllerRightStickMode.moveCamera.rawValue) ?? .moveCamera
    }
}
