//
//  HUDBoneNames.swift
//  GLLara
//
//  Created by Torsten Kammer on 31.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation
import GameController

class HUDBoneNames {
    
    private enum AnimationDirection {
        case parent
        case sibling
        case firstChild
    }
    
    private struct AnimationStep {
        let direction: AnimationDirection
        let bone: GLLItemBone
    }
    
    /// The one we're transitioning away from
    private var previous: GLLItemBone? = nil
    /// The one we're transitioning to, and the ones after that if any
    private var steps: [AnimationStep] = []
    
    var drawerLeft = HUDButtonDrawer(systemImage: "dpad.left.filled")
    var drawerUp = HUDButtonDrawer(systemImage: "dpad.up.filled")
    var drawerDown = HUDButtonDrawer(systemImage: "dpad.down.filled")
    var drawerRight = HUDButtonDrawer(systemImage: "dpad.right.filled")
    
    private struct BoneAndDrawer {
        let drawer: HUDTextDrawer
        let bone: GLLItemBone
        
        init(bone: GLLItemBone) {
            self.bone = bone
            drawer = HUDTextDrawer.drawer(string: bone.bone.name)
        }
    }
    
    /**
     Finds the siblings for the given bone and returns the appropriate drawers. Returns them and the index the center bone has in the list.
     The second bone can be passed, in which case it will be included and its index returned as well. The second index is undefined if the other bone is not given or not included
     */
    private func findSiblings(center bone: GLLItemBone, other: GLLItemBone? = nil) -> ([BoneAndDrawer], Int, Int?) {
        guard let parent = bone.parent, let siblings = parent.children, let index = siblings.firstIndex(of: bone) else {
            return ([ BoneAndDrawer(bone: bone) ], 0, 0)
        }
        
        var secondIndex = index
        if let other = other, let otherIndex = siblings.firstIndex(of: other) {
            secondIndex = otherIndex
        }
        let drawers = siblings.map { BoneAndDrawer(bone: $0) }
        return (drawers, index, secondIndex)
    }
    
    private func lineage(center bone: GLLItemBone) -> ([BoneAndDrawer], [BoneAndDrawer]) {
        var parent = bone.parent
        var ancestors: [BoneAndDrawer] = []
        while let current = parent, ancestors.count < 2 {
            ancestors.append(BoneAndDrawer(bone: current))
            parent = current.parent
        }
        
        var descendants: [BoneAndDrawer] = []
        var child = bone.children?.first
        while let current = child, descendants.count < 2 {
            descendants.append(BoneAndDrawer(bone: current))
            child = current.children?.first
        }
        return (ancestors, descendants)
    }
    
    private struct AnimationKeyFrame {
        var time: Double
        var currentIsCentered: Float
        var otherAxisVisible: Float = 1.0
        var fade: Float = 1.0
        var canStartNext: Bool = false
    }
    
    private let keyframes = [
        AnimationKeyFrame(time: 0.0, currentIsCentered: 0.0, otherAxisVisible: 0.0),
        AnimationKeyFrame(time: 0.2, currentIsCentered: 0.7, otherAxisVisible: 0.0),
        AnimationKeyFrame(time: 0.3, currentIsCentered: 1.0, canStartNext: true),
        AnimationKeyFrame(time: 2.0, currentIsCentered: 1.0, canStartNext: true),
        AnimationKeyFrame(time: 2.5, currentIsCentered: 1.0, fade: 0.0, canStartNext: true)
    ]
    
    private var maxTime: Double {
        return keyframes.last!.time
    }
    
    /// How far along we are in the transition from lastMode to currentMode.
    var transition: Double = 2.5
    
    private func mix<T: FloatingPoint>(_ a: T, _ b: T, alpha: T) -> T {
        return a * alpha + b * (1 - alpha)
    }
    
    private func frame(at time: Double) -> AnimationKeyFrame {
        for i in 1 ..< keyframes.count {
            if keyframes[i].time > time {
                let next = keyframes[i]
                let previous = keyframes[i - 1]
                
                let localTime = (time - previous.time) / (next.time - previous.time)
                return AnimationKeyFrame(time: mix(next.time, previous.time, alpha: localTime),
                                         currentIsCentered: mix(next.currentIsCentered, previous.currentIsCentered, alpha: Float(localTime)),
                                         otherAxisVisible: mix(next.otherAxisVisible, previous.otherAxisVisible, alpha: Float(localTime)),
                                         fade: mix(next.fade, previous.fade, alpha: Float(localTime)),
                                         canStartNext: previous.canStartNext)
            }
        }
        return keyframes.last!
    }
    
    func update(delta: TimeInterval) {
        transition = min(maxTime, transition + delta)
        let frame = frame(at: transition)
        
        // For next frame: See if we can start a new thing
        if frame.canStartNext && steps.count > 1 {
            previous = steps[0].bone
            steps.removeFirst()
            transition = 0.0
        }
    }
    
    var runningAnimation: Bool {
        return transition < maxTime || steps.count > 1
    }
    
    let spacing: Float = 20.0
    let verticalStride = Float(HUDTextDrawer.capsuleHeight) + 20.0
    
    func draw(size: SIMD2<Float>, into encoder: MTLRenderCommandEncoder) {
        guard let previous = previous, let transitioningTo = steps.first else {
            return
        }
        
        let frame = frame(at: transition)
        
        let boneForAncestors: GLLItemBone
        if transitioningTo.direction == .sibling && frame.currentIsCentered < 0.5 {
            boneForAncestors = previous
        } else {
            boneForAncestors = transitioningTo.bone
        }
        
        let (siblings, indexCurrent, indexPrevious) = findSiblings(center: transitioningTo.bone, other: previous)
        let maxSiblingWidth = siblings.reduce(0.0) { max($0, $1.drawer.size.x) }
        let (parents, children) = lineage(center: boneForAncestors)
        
        // Always draw entire thing in a big box, shifting up, down, left, right depending on animation direction
        let shift: SIMD2<Float>
        switch transitioningTo.direction {
        case .parent:
            shift = SIMD2<Float>(x: 0.0, y: +verticalStride * (1 - frame.currentIsCentered))
        case .firstChild:
            shift = SIMD2<Float>(x: 0.0, y: -verticalStride * (1 - frame.currentIsCentered))
        case .sibling:
            let offset = indexCurrent - (indexPrevious ?? indexCurrent)
            shift = SIMD2<Float>(x: (maxSiblingWidth + spacing) * Float(offset) * (1 - frame.currentIsCentered), y: 0.0)
        }
        let baseSiblingShift = Float(-indexCurrent) * (maxSiblingWidth + spacing)
        let boxSize = SIMD2<Float>(x: maxSiblingWidth * 3 + spacing * 4,
                                   y: Float(HUDTextDrawer.capsuleHeight) * 3 + spacing * 4)
        let center = size/2
        let indicatorLeftSafeArea = SIMD2<Float>(x: drawerLeft.size.x + 2*spacing, y: 0)
        let indicatorRightSafeArea = SIMD2<Float>(x: drawerRight.size.x + 2*spacing, y: 0) + size
        let box = HUDTextDrawer.Rectangle(lowerLeft: max(indicatorLeftSafeArea, center - boxSize/2), upperRight: min(center + boxSize/2, indicatorRightSafeArea))
        
        
        var parentOffset = SIMD2<Float>(x: 0.0, y: verticalStride)
        let parentShift: SIMD2<Float>
        let (previousAncestors, previousDescendants) = lineage(center: previous)
        var prevParentWidth = parents.first?.drawer.size.x
        var prevChildWidth = children.first?.drawer.size.x
        if let width = previousDescendants.first?.drawer.size.x {
            prevChildWidth = width
        }
        var prevBox = box
        if transitioningTo.direction == .sibling {
            parentShift = SIMD2<Float>(repeating: 0)
        } else {
            parentShift = shift
            
            // Calculate prevBox - the box for the previous thing, used for attaching the direction indicators
            let (previousSiblings, _, _) = findSiblings(center: previous)
            let maxPrevSiblingsWidth = previousSiblings.reduce(0.0) { max($0, $1.drawer.size.x) }
            let prevBoxSize = SIMD2<Float>(x: maxPrevSiblingsWidth * 3 + spacing * 4,
                                       y: Float(HUDTextDrawer.capsuleHeight) * 3 + spacing * 4)
            prevBox = HUDTextDrawer.Rectangle(lowerLeft: max(indicatorLeftSafeArea, center - prevBoxSize/2), upperRight: min(center + prevBoxSize/2, indicatorRightSafeArea))
            
            if let width = previousAncestors.first?.drawer.size.x {
                prevParentWidth = width
            }
        }
        
        
        for parent in parents {
            parent.drawer.draw(position: center + parentOffset + parentShift,
                        reference: .center,
                        active: active(bone: parent.bone, frame: frame),
                        fadeOutEnd: box,
                        fadeOutLength: 20.0,
                        into: encoder)
            parentOffset.y += verticalStride
        }
        let childVisible = transitioningTo.direction == .sibling ? frame.otherAxisVisible : 1.0
        var childOffset = SIMD2<Float>(x: 0.0, y: -verticalStride)
        for child in children {
            child.drawer.draw(position: center + childOffset + shift,
                              reference: .center,
                              active: childVisible * active(bone: child.bone, frame: frame),
                              fadeOutEnd: box,
                              fadeOutLength: 20.0,
                              into: encoder)
            childOffset.y -= verticalStride
        }
        
        let siblingVisible = transitioningTo.direction == .sibling ? 1.0 : frame.otherAxisVisible
        var siblingOffset = baseSiblingShift
        for sibling in siblings {
            var visible = active(bone: sibling.bone, frame: frame)
            if sibling.bone != transitioningTo.bone && sibling.bone != previous.bone {
                visible *= siblingVisible
            }
            sibling.drawer.draw(position: center + shift + SIMD2<Float>(x: siblingOffset, y: 0.0),
                                reference: .center,
                                active: visible,
                                fadeOutEnd: box,
                                fadeOutLength: 20.0,
                                into: encoder)
            siblingOffset += maxSiblingWidth + spacing
        }
        
        // Left/right DPad indicators
        if indexCurrent > 0 {
            let positionLeft = box.lowerLeft.x * frame.currentIsCentered + prevBox.lowerLeft.x * (1 - frame.currentIsCentered)
            let highlighted = GCController.current?.extendedGamepad?.dpad.left.isPressed ?? false
            drawerLeft.draw(position: SIMD2<Float>(x: positionLeft, y: center.y),
                            reference: .centerRight,
                            highlighted: highlighted,
                            active: frame.fade,
                            into: encoder)
        }
        if indexCurrent < (siblings.count - 1) {
            let positionRight = box.upperRight.x * frame.currentIsCentered + prevBox.upperRight.x * (1 - frame.currentIsCentered)
            let highlighted = GCController.current?.extendedGamepad?.dpad.right.isPressed ?? false
            drawerRight.draw(position: SIMD2<Float>(x: positionRight, y: center.y),
                             reference: .centerLeft,
                             highlighted: highlighted,
                             active: frame.fade,
                             into: encoder)
        }
        
        // Top/down DPad indicators
        if !parents.isEmpty {
            var size = parents.first!.drawer.size.x
            if let previous = prevParentWidth {
                size = size * frame.currentIsCentered + previous * (1 - frame.currentIsCentered)
            }
            let highlighted = GCController.current?.extendedGamepad?.dpad.up.isPressed ?? false
            drawerUp.draw(position: SIMD2<Float>(x: center.x - size/2 - spacing, y: center.y + verticalStride),
                          reference: .centerRight,
                          highlighted: highlighted,
                          active: frame.fade * 0.75,
                          into: encoder)
        }
        
        if !children.isEmpty {
            var size = children.first!.drawer.size.x
            if let previous = prevChildWidth {
                size = size * frame.currentIsCentered + previous * (1 - frame.currentIsCentered)
            }
            let highlighted = GCController.current?.extendedGamepad?.dpad.down.isPressed ?? false
            drawerDown.draw(position: SIMD2<Float>(x: center.x - size/2 - spacing, y: center.y - verticalStride),
                            reference: .centerRight,
                            highlighted: highlighted,
                            active: frame.fade * childVisible * 0.75,
                            into: encoder)
        }
        
        // Bonus special case for the up/down DPad indicators whose positions shift if we're going up/down
        
        
    }
    
    private func active(bone: GLLItemBone, frame: AnimationKeyFrame) -> Float {
        guard let previous = previous, let transitioningTo = steps.first else {
            return 0.0
        }
        
        let fullyActive: Float = 1.0
        let fullyInactive: Float = 0.75
        
        if bone == previous {
            return frame.fade * (frame.currentIsCentered * fullyInactive + (1 - frame.currentIsCentered) * fullyActive)
        } else if bone == transitioningTo.bone {
            return frame.fade * (frame.currentIsCentered * fullyActive + (1 - frame.currentIsCentered) * fullyInactive)
        } else {
            return frame.fade * fullyInactive
        }
    }
    
    func setExplicit(bone: GLLItemBone) {
        previous = bone
        steps = [ AnimationStep(direction: .sibling, bone: bone) ]
        transition = 0.0
    }
    
    func setNext(bone: GLLItemBone) {
        if previous != nil, let lastStep = steps.last?.bone {
            if bone.parent == lastStep {
                steps.append(AnimationStep(direction: .firstChild, bone: bone))
            } else if lastStep.parent == bone {
                steps.append(AnimationStep(direction: .parent, bone: bone))
            } else {
                steps.append(AnimationStep(direction: .sibling, bone: bone))
            }
        } else {
            setExplicit(bone: bone)
        }
    }
}
