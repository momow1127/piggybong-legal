//
//  Typealiases.swift
//  PiggyBong
//
//  Centralized type aliases for resolving duplicate models
//

import Foundation

// MARK: - Artist
// Use `Artist` from FanExperienceModels.swift as canonical
typealias ComebackArtist = Artist

// MARK: - FanActivity
// If SavedFanActivity and FanActivity are meant to be the same
typealias SavedFanActivity = FanActivity

// MARK: - ImpactLevel
// If multiple ImpactLevel enums exist, unify to one
typealias AppImpactLevel = ImpactLevel

// MARK: - Dashboard Data
// Bridge if older code references renamed types
typealias DashboardData = FanDashboardData

// MARK: - Fan Category
// Ensure icon-based category model compiles everywhere
typealias FanCategoryWithIcon = FanCategory