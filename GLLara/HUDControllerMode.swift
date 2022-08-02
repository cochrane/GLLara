//
//  HUDControllerMOde.swift
//  GLLara
//
//  Created by Torsten Kammer on 23.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation
import GameController

class HUDControllerMode {
    /// The controller mode that was last shown, and from which we're transitioning away (if transition != 1.0)
    var lastMode: GLLView.ControllerRightStickMode = .moveCamera
    /// The controller mode that is currently active and that we're transitioning towards (or showing entirely, if transition == 1.0)
    var currentMode: GLLView.ControllerRightStickMode = .moveCamera
    /// The mode we need to transition after the current animation is done. Used so we don't get animation issues if the user switches modes rapidly and gets to a new one before the current animation is done.
    var nextMode: GLLView.ControllerRightStickMode? = nil
    
    /// How far along we are in the transition from lastMode to currentMode.
    var transition: Double = 2.5
    
    private struct AnimationKeyFrame {
        var time: Double
        var currentIsCentered: Float
        var fade: Float = 1.0
        var canStartNext: Bool = false
    }
    
    private let keyframes = [
        AnimationKeyFrame(time: 0.0, currentIsCentered: 0.0),
        AnimationKeyFrame(time: 0.3, currentIsCentered: 1.0, canStartNext: true),
        AnimationKeyFrame(time: 2.0, currentIsCentered: 1.0, canStartNext: true),
        AnimationKeyFrame(time: 2.5, currentIsCentered: 1.0, fade: 0.0, canStartNext: true)
    ]
    
    private var maxTime: Double {
        return keyframes.last!.time
    }
    
    private var notificationObservers: [NSObjectProtocol] = []
    init() {
        notificationObservers.append(NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: OperationQueue.main) { [weak self] notification in
            self?.updateState()
        })
        notificationObservers.append(NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidBecomeCurrent, object: nil, queue: OperationQueue.main) { [weak self] notification in
            self?.showIfPresent()
        })
        currentMode = userDefaultMode
        lastMode = userDefaultMode
        
        showIfPresent()
    }
    
    private var userDefaultMode: GLLView.ControllerRightStickMode {
        return GLLView.ControllerRightStickMode(rawValue: UserDefaults.standard.string(forKey: GLLPrefControllerRightStickMode) ?? GLLView.ControllerRightStickMode.moveCamera.rawValue) ?? .moveCamera
    }
    
    private func showIfPresent() {
        if GCController.current != nil && transition == keyframes.last!.time {
            // Have controller and currently not showing the thing
            // Show again, starting from solid
            transition = keyframes.first(where: { $0.currentIsCentered == 1.0 })!.time
        }
    }
    
    private func updateState() {
        let mode = userDefaultMode
        if mode != currentMode {
            nextMode = mode
        }
    }
    
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
                                         fade: mix(next.fade, previous.fade, alpha: Float(localTime)),
                                         canStartNext: previous.canStartNext)
            }
        }
        return keyframes.last!
    }
    
    let drawerLeftButton = HUDButtonDrawer(systemImage: "lb.rectangle.roundedbottom.fill")
    let drawerRightButton = HUDButtonDrawer(systemImage: "rb.rectangle.roundedbottom.fill")
    
    let drawerCameraMove = HUDTextDrawer.drawer(string: NSLocalizedString("Move Camera", comment: "controller mode HUD"))
    let drawerBoneRotate = HUDTextDrawer.drawer(string: NSLocalizedString("Rotate Bones", comment: "controller mode HUD"))
    let drawerBoneMove = HUDTextDrawer.drawer(string: NSLocalizedString("Move Bones", comment: "controller mode HUD"))
    
    let spacing: Float = 20.0
    let margins: Float = 20.0
    
    private func index(of mode: GLLView.ControllerRightStickMode) -> Int {
        return GLLView.ControllerRightStickMode.allCases.firstIndex(of: mode)!
    }
    private func drawer(for index: Int) -> HUDTextDrawer? {
        switch index {
        case 0: return drawerCameraMove
        case 1: return drawerBoneRotate
        case 2: return drawerBoneMove
        default: return nil
        }
    }
    
    func update(delta: TimeInterval) {
        transition = min(maxTime, transition + delta)
        let frame = frame(at: transition)
        
        // For next frame: See if we can start a new thing
        if frame.canStartNext, let activeNextMode = nextMode {
            transition = 0.0
            lastMode = currentMode
            currentMode = activeNextMode
            nextMode = nil
        }
    }
    
    var runningAnimation: Bool {
        return transition < maxTime || nextMode != nil
    }
    
    func draw(size: SIMD2<Float>, into encoder: MTLRenderCommandEncoder) {
        let frame = frame(at: transition)
        
        // Sizing calculations
        let modeDrawerWidth = [ drawerCameraMove, drawerBoneMove, drawerBoneRotate ].reduce(0.0) { max($0, $1.size.x) }
        
        let maxDrawerHeight = [ drawerCameraMove.size.y, drawerBoneMove.size.y, drawerBoneRotate.size.y, drawerLeftButton.size.y, drawerRightButton.size.y ].reduce(0.0) { max($0, $1) }
        
        let centerLine = size.y - margins - maxDrawerHeight/2
        
        let minIndicatorWidth = modeDrawerWidth + margins*2
        let maxIndicatorWidth = modeDrawerWidth*3 + spacing*4
        let buttonsTotalWidth = 2*spacing + 2*margins + drawerLeftButton.size.x + drawerRightButton.size.x
        let inNarrowMode = maxIndicatorWidth > (size.x - buttonsTotalWidth)
        let extraNarrowMode = size.x - buttonsTotalWidth < minIndicatorWidth
        
        // Draw the different indicators. Note that we need n+1 during rotation.
        
        // Logical order: MC, RB, MB, MC, RB, MB, MC, RB, MB…
        // Options:
        // MC -> RB:  MB [MC] RB -> MC [RB] MB  => MB [MC->RB] MB, index 1->2
        // MC -> MB:  MB [MC] RB <- RB [MB] MC  => RB [MB<-MC] RB, index 2->1
        // RB -> MC:  MC [RB] MB <- MB [MC] RB  => MB [MC<-RB] MB, index 2->1
        // RB -> MB:  MC [RB] MB -> RB [MB] MC  => MC [RB->MB] MC, index 1->2
        // MB -> MC:  RB [MB] MC <- MB [MC] RB  => RB [MB->MC] RB, index 1->2
        // MB -> RB:  RB [MB] MC -> MC [RB] MB  => MC [RB<-MB] MC, index 2<-1
        // Array centered on current, using rawValue:
        // (i + n - 1) % n; i; (i + 1) % n
        // If next left of current: add last on the beginning
        // If next right of current: add first on the right
        // Simplify: Do both
        
        let currentIndex = index(of: currentMode)
        let previousIndex = index(of: lastMode)
        let indices = [ (currentIndex + 3 - 2) % 3, (currentIndex + 3 - 1) % 3,
                        currentIndex,
                        (currentIndex + 1) % 3, (currentIndex + 2) % 3 ]
        let shiftingAtAll = currentIndex != previousIndex
        let shiftingRight = currentIndex == (previousIndex + 1) % 3
        let absoluteShiftAmount = (modeDrawerWidth + spacing) * (1.0 - frame.currentIsCentered)
        let shiftAmount = shiftingAtAll ? (shiftingRight ? absoluteShiftAmount : -absoluteShiftAmount) : 0.0
        
        let indicatorAreaWidth = inNarrowMode ? max(size.x - buttonsTotalWidth, minIndicatorWidth) : maxIndicatorWidth
        
        let fadeOutRectangle = extraNarrowMode ? HUDTextDrawer.Rectangle(lowerLeft: SIMD2<Float>(repeating: -1e6), upperRight: SIMD2<Float>(repeating: +1e6)) : HUDTextDrawer.Rectangle(lowerLeft: SIMD2<Float>(x: size.x/2 - indicatorAreaWidth/2, y: -1e6), upperRight: SIMD2<Float>(x: size.x/2 + indicatorAreaWidth/2, y: 1e7))
        
        let fullyActive: Float = 1.0
        let fullyInactive: Float = 0.75
        for i in -2 ... +2 {
            let baseOffset = Float(i) * (modeDrawerWidth + spacing)
            let drawPosition = baseOffset + shiftAmount + size.x/2
            
            let active: Float
            let index = indices[i+2]
            if index == currentIndex {
                active = (frame.currentIsCentered * (fullyActive - fullyInactive)) + fullyInactive
            } else if index == previousIndex {
                active = ((1.0-frame.currentIsCentered) * (fullyActive - fullyInactive)) + fullyInactive
            } else {
                active = fullyInactive
            }
            
            drawer(for: index)?.draw(position: SIMD2<Float>(x: drawPosition, y: centerLine), reference: .center, active: active * frame.fade, fadeOutEnd: fadeOutRectangle, fadeOutLength: spacing*2, into: encoder)
        }
        
        
        // Draw the button prompts at the left and right of the indicator, assuming there's space for them
        if !inNarrowMode || !extraNarrowMode {
            let buttonLeftDown = GCController.current?.extendedGamepad?.leftShoulder.isPressed ?? false
            if inNarrowMode {
                drawerLeftButton.draw(position: SIMD2<Float>(x: margins, y: centerLine), reference: .centerLeft, highlighted: buttonLeftDown, active: frame.fade, into: encoder)
            } else {
                drawerLeftButton.draw(position: SIMD2<Float>(x: size.x/2 - indicatorAreaWidth/2 - spacing, y: centerLine), reference: .centerRight, highlighted: buttonLeftDown, active: frame.fade, into: encoder)
            }
            
            let buttonRightDown = GCController.current?.extendedGamepad?.rightShoulder.isPressed ?? false
            if inNarrowMode {
                drawerRightButton.draw(position: SIMD2<Float>(x: size.x - margins, y: centerLine), reference: .centerRight, highlighted: buttonRightDown, active: frame.fade, into: encoder)
            } else {
                drawerRightButton.draw(position: SIMD2<Float>(x: size.x/2 + indicatorAreaWidth/2 + spacing, y: centerLine), reference: .centerLeft, highlighted: buttonRightDown, active: frame.fade, into: encoder)
            }
        }
    }
}
