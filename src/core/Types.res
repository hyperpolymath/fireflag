// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2024 Jonathan D.A. Jewell <hyperpolymath>

/**
 * Fire-and-Forget Flag Core Types
 *
 * Defines the fundamental types for the fireflag feature flag system.
 */

// Version vector for conflict resolution
type versionVector = {
  version: int,
  timestamp: float,
  nodeId: string,
  checksum: string,
}

// Flag value types
type flagValue =
  | @as("bool") Bool(bool)
  | @as("string") String(string)
  | @as("int") Int(int)
  | @as("float") Float(float)
  | @as("json") Json(Js.Json.t)

// Expiry policies
type expiryPolicy =
  | @as("absolute") Absolute
  | @as("sliding") Sliding
  | @as("adaptive") Adaptive

// TTL configuration
type ttlConfig = {
  defaultTtl: float,
  minTtl: float,
  maxTtl: float,
  staleTtl: float,
}

// Targeting rule operators
type ruleOperator =
  | @as("eq") Equals
  | @as("neq") NotEquals
  | @as("contains") Contains
  | @as("startsWith") StartsWith
  | @as("endsWith") EndsWith
  | @as("in") In
  | @as("notIn") NotIn
  | @as("gt") GreaterThan
  | @as("gte") GreaterThanOrEqual
  | @as("lt") LessThan
  | @as("lte") LessThanOrEqual
  | @as("regex") Regex

// Targeting rule
type targetingRule = {
  attribute: string,
  operator: ruleOperator,
  value: string,
  negate: bool,
}

// Flag state
type flagState =
  | @as("enabled") Enabled
  | @as("disabled") Disabled
  | @as("archived") Archived

// Boolean flag
type booleanFlag = {
  key: string,
  value: bool,
  defaultValue: bool,
}

// Variant flag
type variantFlag = {
  key: string,
  value: string,
  variants: array<string>,
  defaultValue: string,
}

// Percentage rollout flag
type rolloutFlag = {
  key: string,
  percentage: float,
  hashSeed: string,
}

// Segment targeting flag
type segmentFlag = {
  key: string,
  rules: array<targetingRule>,
  fallthrough: flagValue,
}

// Unified flag definition
type flagType =
  | @as("boolean") Boolean
  | @as("variant") Variant
  | @as("rollout") Rollout
  | @as("segment") Segment

type flag = {
  key: string,
  name: string,
  description: string,
  flagType: flagType,
  state: flagState,
  value: flagValue,
  defaultValue: flagValue,
  variants: option<array<string>>,
  percentage: option<float>,
  rules: option<array<targetingRule>>,
  hashSeed: option<string>,
  tags: array<string>,
  environment: string,
}

// Flag with metadata
type flagMeta = {
  createdAt: float,
  updatedAt: float,
  version: versionVector,
  expiresAt: option<float>,
  expiryPolicy: expiryPolicy,
  lastEvaluatedAt: option<float>,
  evaluationCount: int,
}

type flagWithMeta = {
  flag: flag,
  meta: flagMeta,
}

// Evaluation context
type evaluationContext = {
  userId: option<string>,
  sessionId: option<string>,
  attributes: Js.Dict.t<string>,
  timestamp: float,
}

// Evaluation result
type evaluationResult = {
  flagKey: string,
  value: flagValue,
  reason: string,
  ruleIndex: option<int>,
  cached: bool,
  stale: bool,
}

// Error types
type flagError =
  | @as("not_found") NotFound
  | @as("invalid_type") InvalidType
  | @as("evaluation_error") EvaluationError
  | @as("storage_error") StorageError
  | @as("network_error") NetworkError
  | @as("expired") Expired
  | @as("conflict") Conflict

// Cache state
type cacheState =
  | @as("fresh") Fresh
  | @as("stale") Stale
  | @as("expired") CacheExpired

// Default TTL configuration
let defaultTtlConfig: ttlConfig = {
  defaultTtl: 300000.0,
  minTtl: 1000.0,
  maxTtl: 86400000.0,
  staleTtl: 60000.0,
}
