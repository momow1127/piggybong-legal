import SwiftUI

// MARK: - PiggyBong Animation System
// 🚨 SINGLE SOURCE OF TRUTH - Do not create animation definitions elsewhere
// All components and views must import and use these animation tokens ONLY

struct PiggyAnimations {
    
    // MARK: - Base Animation Timing
    /// Fast animation duration - 0.2 seconds (Micro interactions, toggles)
    static let fast = Animation.easeInOut(duration: 0.2)
    
    /// Standard animation duration - 0.3 seconds (Standard UI transitions)
    static let standard = Animation.easeInOut(duration: 0.3)
    
    /// Slow animation duration - 0.5 seconds (Major state changes)
    static let slow = Animation.easeInOut(duration: 0.5)
    
    // MARK: - Easing Curves
    /// Smooth ease in-out for most UI elements
    static let easeInOut = Animation.easeInOut
    
    /// Spring animation for natural movement
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.7)
    
    /// Bouncy spring for playful interactions
    static let springBouncy = Animation.spring(response: 0.3, dampingFraction: 0.6)
    
    // MARK: - Component-Specific Animations
    /// Button press animation
    static let buttonPress = Animation.easeInOut(duration: 0.1)
    
    /// Sheet presentation animation
    static let sheetPresentation = Animation.easeInOut(duration: 0.4)
    
    /// Modal transition animation
    static let modalTransition = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    /// Card hover animation
    static let cardHover = Animation.easeInOut(duration: 0.2)
    
    /// Loading animation
    static let loading = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
    
    /// Fade animation
    static let fade = Animation.easeInOut(duration: 0.25)
}

// MARK: - Form-Specific Animations
enum PiggyFormAnimations {
    
    /// Form field focus animation
    static let fieldFocus = Animation.easeInOut(duration: 0.2)
    
    /// Form validation error animation
    static let validationError = Animation.easeInOut(duration: 0.3)
    
    /// Form step transition animation
    static let stepTransition = Animation.easeInOut(duration: 0.4)
    
    /// Form progress animation
    static let progress = Animation.easeInOut(duration: 0.5)
    
    /// Form submission animation
    static let submission = Animation.spring(response: 0.6, dampingFraction: 0.8)
    
    /// Currency input animation
    static let currencyInput = Animation.easeInOut(duration: 0.15)
    
    /// Stepper button animation
    static let stepperButton = Animation.easeInOut(duration: 0.1)
}

// MARK: - Priority System Animations
enum PiggyPriorityAnimations {
    
    /// Priority drag animation
    static let drag = Animation.easeInOut(duration: 0.2)
    
    /// Priority reorder animation
    static let reorder = Animation.spring(response: 0.4, dampingFraction: 0.7)
    
    /// Priority allocation animation
    static let allocation = Animation.easeInOut(duration: 0.3)
    
    /// Priority rank change animation
    static let rankChange = Animation.spring(response: 0.5, dampingFraction: 0.8)
}

// MARK: - Settings Animations
enum PiggySettingsAnimations {
    
    /// Toggle switch animation
    static let toggle = Animation.easeInOut(duration: 0.2)
    
    /// Settings row selection animation
    static let rowSelection = Animation.easeInOut(duration: 0.15)
    
    /// Settings section expansion
    static let sectionExpansion = Animation.easeInOut(duration: 0.3)
}

// MARK: - Animation View Extensions
extension View {
    
    /// Apply standard transition animation
    func standardAnimation() -> some View {
        self.animation(PiggyAnimations.standard, value: UUID())
    }
    
    /// Apply spring animation
    func springAnimation() -> some View {
        self.animation(PiggyAnimations.spring, value: UUID())
    }
    
    /// Apply fade transition
    func fadeTransition() -> some View {
        self.transition(.opacity.animation(PiggyAnimations.fade))
    }
    
    /// Apply slide transition
    func slideTransition() -> some View {
        self.transition(.slide.animation(PiggyAnimations.standard))
    }
}

// MARK: - Animation Usage Guidelines
/*
 🎬 ANIMATION USAGE GUIDELINES:

 ✅ DO:
 - Use PiggyAnimations.standard for most UI transitions
 - Use PiggyAnimations.spring for natural movement
 - Use component-specific animations (PiggyFormAnimations.fieldFocus)
 - Keep animations consistent across similar interactions

 ❌ DON'T:
 - Create Animation.easeInOut inline in views
 - Mix different animation durations for similar actions
 - Use overly long animations (>0.5s) for micro-interactions
 - Create custom spring values without design approval

 ⏱️ TIMING HIERARCHY:
 - Micro: buttonPress (0.1s) -> fast (0.2s)
 - Standard: standard (0.3s) -> slow (0.5s)
 - Major: sheetPresentation (0.4s) -> modalTransition (spring)

 🎯 SEMANTIC USAGE:
 - Form interactions: Use PiggyFormAnimations
 - Priority system: Use PiggyPriorityAnimations
 - Settings screens: Use PiggySettingsAnimations
 - General UI: Use PiggyAnimations base tokens
*/