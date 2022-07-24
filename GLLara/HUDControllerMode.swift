//
//  HUDControllerMOde.swift
//  GLLara
//
//  Created by Torsten Kammer on 23.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

class HUDControllerMode {
    /// The controller mode that was last shown, and from which we're transitioning away (if transition != 1.0)
    var lastMode: GLLView.ControllerRightStickMode = .moveCamera
    /// The controller mode that is currently active and that we're transitioning towards (or showing entirely, if transition == 1.0)
    var currentMode: GLLView.ControllerRightStickMode = .moveCamera
    /// The mode we need to transition after the current animation is done. Used so we don't get animation issues if the user switches modes rapidly and gets to a new one before the current animation is done.
    var nextMode: GLLView.ControllerRightStickMode? = nil
    
    /// How far along we are in the transition from lastMode to currentMode. If 1.0 then we're showing currentMode entirely.
    var transition: Double = 0.0
    
    private struct AnimationKeyFrame {
        var time: Double
        var buttonVisible: Double
        var frameSizeFromCurrent: Double
        var currentIsCentered: Double
        var fade: Double = 0.0
        var canStartNext: Bool = false
    }
    
    private let keyframes = [
        AnimationKeyFrame(time: 0.0, buttonVisible: 1.0, frameSizeFromCurrent: 0.0, currentIsCentered: 0.0),
        AnimationKeyFrame(time: 0.05, buttonVisible: 0.0, frameSizeFromCurrent: 0.0, currentIsCentered: 0.0),
        AnimationKeyFrame(time: 0.25, buttonVisible: 0.0, frameSizeFromCurrent: 1.0, currentIsCentered: 1.0),
        AnimationKeyFrame(time: 0.3, buttonVisible: 1.0, frameSizeFromCurrent: 1.0, currentIsCentered: 1.0, canStartNext: true),
        AnimationKeyFrame(time: 2.0, buttonVisible: 1.0, frameSizeFromCurrent: 1.0, currentIsCentered: 1.0, canStartNext: true),
        AnimationKeyFrame(time: 2.5, buttonVisible: 1.0, frameSizeFromCurrent: 1.0, currentIsCentered: 1.0, fade: 0.0, canStartNext: true)
    ]
    
    private func mix(_ a: Double, _ b: Double, alpha: Double) -> Double {
        return a * alpha + b * (1 - alpha)
    }
    
    private func frame(at time: Double) -> AnimationKeyFrame {
        for i in 1 ..< keyframes.count {
            if keyframes[i].time > time {
                let next = keyframes[i]
                let previous = keyframes[i - 1]
                
                let localTime = (time - previous.time) / (next.time - previous.time)
                return AnimationKeyFrame(time: mix(next.time, previous.time, alpha: localTime),
                                         buttonVisible: mix(next.buttonVisible, previous.buttonVisible, alpha: localTime),
                                         frameSizeFromCurrent: mix(next.frameSizeFromCurrent, previous.frameSizeFromCurrent, alpha: localTime),
                                         currentIsCentered: mix(next.currentIsCentered, previous.currentIsCentered, alpha: localTime),
                                         fade: mix(next.fade, previous.fade, alpha: localTime),
                                         canStartNext: previous.canStartNext)
            }
        }
        return keyframes.last!
    }
    
    func displayedSize(for frame: CGSize) {
        
    }
    
    let drawerLeftButton = HUDTextDrawer.drawer(systemImage: "lb.rectangle.roundedbottom.fill")
    let drawerRightButton = HUDTextDrawer.drawer(systemImage: "rb.rectangle.roundedbottom.fill")
    
    let drawerCameraMove = HUDTextDrawer.drawer(string: NSLocalizedString("Move Camera", comment: "controller mode HUD"))
    let drawerBoneRotate = HUDTextDrawer.drawer(string: NSLocalizedString("Rotate Bones", comment: "controller mode HUD"))
    let drawerBoneMove = HUDTextDrawer.drawer(string: NSLocalizedString("Move Bones", comment: "controller mode HUD"))
    
    let spacing = 10.0
    let margins = 10.0
    
    private func index(of mode: GLLView.ControllerRightStickMode) -> Int {
        switch mode {
        case .moveCamera: return 0
        case .rotateBones: return 1
        case .moveBones: return 2
        }
    }
    private func drawer(for index: Int) -> HUDTextDrawer? {
        switch index {
        case 0: return drawerCameraMove
        case 1: return drawerBoneRotate
        case 2: return drawerBoneMove
        default: return nil
        }
    }
    
    func draw(timeDelta: TimeInterval, in size: CGSize, into encoder: MTLRenderCommandEncoder) {
        transition = min(1.0, transition + timeDelta)
        let frame = frame(at: transition)
        
        // For next frame: See if we can start a new thing
        if frame.canStartNext, let activeNextMode = nextMode {
            transition = 0.0
            lastMode = currentMode
            currentMode = activeNextMode
            nextMode = nil
        }
        
        // Sizing calculations
        let innerSize = size.width - 2*margins
        let modeDrawerWidth = [ drawerCameraMove, drawerBoneMove, drawerBoneRotate ].reduce(into: 0.0) { max($0, $1.size.width) }
        
        let maxDrawerHeight = [ drawerCameraMove.size.height, drawerBoneMove.size.height, drawerBoneRotate.size.height, drawerLeftButton.size.height, drawerRightButton.size.height ].reduce(0.0) { max($0, $1) }
        
        let centerLine = size.height - margins - maxDrawerHeight/2
        
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
        let previousIndex = index(of: currentMode)
        let indices = [ (currentIndex + 3 - 2) % 3, (currentIndex + 3 - 1) % 3,
                        currentIndex,
                        (currentIndex + 1) % 3, (currentIndex + 2 % 3) ]
        let shiftingRight = currentIndex == (previousIndex + 1) % 3
        let absoluteShiftAmount = (modeDrawerWidth + spacing) * frame.currentIsCentered
        let shiftAmount = shiftingRight ? absoluteShiftAmount : -absoluteShiftAmount
        for i in -2 ... +2 {
            let baseOffset = Double(i) * (modeDrawerWidth + spacing)
            let drawPosition = baseOffset + shiftAmount + size.width/2
            
            // TODO draw center one (i == 0) different
            drawer(for: indices[i + 2])?.draw(position: CGPoint(x: drawPosition, y: centerLine), active: frame.fade, into: encoder)
        }
        
        
        // Draw the button prompts at the left and right of the indicator, assuming there's space for them
        if innerSize >= (modeDrawerWidth + 2*spacing + drawerLeftButton.size.width + drawerRightButton.size.width) {
            drawerLeftButton.draw(position: CGPoint(x: margins, y: centerLine), reference: .centerLeft, active: frame.buttonVisible, into: encoder)
            
            drawerRightButton.draw(position: CGPoint(x: size.width - margins, y: centerLine), reference: .centerRight, active: frame.buttonVisible, into: encoder)
        }
    }
}
