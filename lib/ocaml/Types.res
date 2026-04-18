// SPDX-License-Identifier: MPL-2.0
// (PMPL-1.0-or-later preferred; MPL-2.0 required for Firefox extension store)
// Copyright (C) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

/**
 * FireFlag Core Types
 *
 * Type definitions for Firefox/Gecko flag management with safety guarantees.
 */

// Safety classification for flags
type safetyLevel =
  | @as("safe") Safe
  | @as("experimental") Experimental
  | @as("dangerous") Dangerous

// Flag value types
type flagValueType =
  | @as("boolean") Boolean
  | @as("string") String
  | @as("integer") Integer
  | @as("float") Float

// Flag categories
type flagCategory =
  | @as("privacy") Privacy
  | @as("performance") Performance
  | @as("experimental") ExperimentalFeatures
  | @as("developer") Developer
  | @as("ui") UserInterface
  | @as("network") Network

// Browser permissions required for flag modification
type browserPermission =
  | @as("browserSettings") BrowserSettings
  | @as("privacy") PrivacyPermission
  | @as("tabs") Tabs
  | @as("notifications") Notifications
  | @as("downloads") Downloads

// Flag effects classification
type flagEffects = {
  positive: array<string>,
  negative: array<string>,
  interesting: array<string>,
}

// Category metadata
type categoryMeta = {
  name: string,
  description: string,
}

// Complete flag definition
type flag = {
  key: string,
  @as("type") valueType: flagValueType,
  category: flagCategory,
  safetyLevel: safetyLevel,
  defaultValue: Js.Json.t,
  description: string,
  effects: flagEffects,
  permissions: array<browserPermission>,
  geckoMinVersion: option<string>,
  geckoMaxVersion: option<string>,
  documentation: option<string>,
  bugNumber: option<int>,
}

// Flag database structure
type flagDatabase = {
  version: string,
  lastUpdated: string,
  categories: Js.Dict.t<categoryMeta>,
  flags: array<flag>,
}

// Current flag state in browser
type flagState = {
  key: string,
  currentValue: Js.Json.t,
  defaultValue: Js.Json.t,
  isModified: bool,
  lastModified: option<float>,
  modifiedBy: option<string>, // "user" | "extension" | "system"
}

// Flag change tracking
type flagChange = {
  key: string,
  beforeValue: Js.Json.t,
  afterValue: Js.Json.t,
  timestamp: float,
  source: string,
  effects: option<flagEffects>,
}

// Flag filter options
type flagFilter = {
  category: option<flagCategory>,
  safetyLevel: option<safetyLevel>,
  searchQuery: option<string>,
  modifiedOnly: bool,
  requiresPermissions: option<array<browserPermission>>,
}

// Permission request result
type permissionResult =
  | @as("granted") Granted
  | @as("denied") Denied
  | @as("prompt") PromptRequired(array<browserPermission>)

// Export format for developer reports
type exportFormat =
  | @as("json") JSON
  | @as("markdown") Markdown
  | @as("csv") CSV

// Developer report structure
type developerReport = {
  timestamp: float,
  browserVersion: string,
  geckoVersion: string,
  flagChanges: array<flagChange>,
  performanceMetrics: option<Js.Dict.t<float>>,
  notes: option<string>,
}

// UI state for permission feedback
type permissionUIState = {
  requestedPermissions: array<browserPermission>,
  grantedPermissions: array<browserPermission>,
  pendingFlags: array<string>,
  blockedFlags: array<string>,
}

// Browser compatibility check
type browserCompatibility = {
  isGecko: bool,
  geckoVersion: option<string>,
  isFirefox: bool,
  isLibrewolf: bool,
  isWaterfox: bool,
  isPaleMoon: bool,
  supportedFlags: array<string>,
}
