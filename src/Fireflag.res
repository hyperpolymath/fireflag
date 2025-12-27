// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2024 Jonathan D.A. Jewell <hyperpolymath>

/**
 * Fireflag - Fire-and-Forget Feature Flags
 *
 * Main client module implementing fire-and-forget semantics:
 * - Configure once, system handles propagation
 * - Eventual consistency with bounded propagation delay
 * - Self-healing cache with TTL and stale-while-revalidate
 * - Immutable audit logging
 */

open Types

module MemoryStore = MemoryStore
module AuditLog = AuditLog
module Cache = Cache
module Evaluator = Evaluator
module VersionVector = VersionVector

// Client configuration
type clientConfig = {
  nodeId: string,
  environment: string,
  cacheConfig: ttlConfig,
  maxCacheSize: int,
  auditEnabled: bool,
  evaluationLogging: bool,
}

// Default client configuration
let defaultConfig = (): clientConfig => {
  nodeId: `node-${Float.toString(Js.Math.random() *. 1000000.0)}`,
  environment: "development",
  cacheConfig: defaultTtlConfig,
  maxCacheSize: 1000,
  auditEnabled: true,
  evaluationLogging: false,
}

// Client state
type t = {
  store: MemoryStore.t,
  cache: Cache.t<flagWithMeta>,
  auditLog: AuditLog.t,
  config: clientConfig,
  mutable lastSyncAt: option<float>,
}

// Create a new fireflag client
let make = (~config: clientConfig=defaultConfig()): t => {
  store: MemoryStore.make(~nodeId=config.nodeId),
  cache: Cache.make(~config=config.cacheConfig, ~maxSize=config.maxCacheSize),
  auditLog: AuditLog.make(
    ~config={
      enabled: config.auditEnabled,
      retentionDays: 90,
      evaluationLogging: config.evaluationLogging,
      maxRecords: 100000,
    },
    ~nodeId=config.nodeId,
  ),
  config,
  lastSyncAt: None,
}

// Create a new flag
let createFlag = (
  client: t,
  ~key: string,
  ~name: string,
  ~description: string="",
  ~flagType: flagType=Boolean,
  ~value: flagValue,
  ~defaultValue: option<flagValue>=?,
  ~variants: option<array<string>>=?,
  ~percentage: option<float>=?,
  ~rules: option<array<targetingRule>>=?,
  ~hashSeed: option<string>=?,
  ~tags: array<string>=[],
): flagWithMeta => {
  let now = Date.now()
  let default = defaultValue->Option.getOr(value)

  let flag: flag = {
    key,
    name,
    description,
    flagType,
    state: Enabled,
    value,
    defaultValue: default,
    variants,
    percentage,
    rules,
    hashSeed,
    tags,
    environment: client.config.environment,
  }

  let meta: flagMeta = {
    createdAt: now,
    updatedAt: now,
    version: VersionVector.make(~nodeId=client.config.nodeId, ~value=key),
    expiresAt: None,
    expiryPolicy: Adaptive,
    lastEvaluatedAt: None,
    evaluationCount: 0,
  }

  let flagWithMeta = {flag, meta}

  // Store the flag
  MemoryStore.set(client.store, key, flagWithMeta)

  // Update cache
  Cache.put(client.cache, key, flagWithMeta, ~policy=Adaptive)

  // Audit log
  AuditLog.logCreated(client.auditLog, ~flagKey=key, ~newValue=Js.Json.stringifyAny(value)->Option.getOr(""))

  flagWithMeta
}

// Create a boolean flag (convenience)
let createBoolFlag = (
  client: t,
  ~key: string,
  ~name: string,
  ~value: bool,
  ~defaultValue: bool=false,
): flagWithMeta => {
  createFlag(
    client,
    ~key,
    ~name,
    ~flagType=Boolean,
    ~value=Bool(value),
    ~defaultValue=Bool(defaultValue),
  )
}

// Create a variant flag (convenience)
let createVariantFlag = (
  client: t,
  ~key: string,
  ~name: string,
  ~value: string,
  ~variants: array<string>,
  ~defaultValue: option<string>=?,
): flagWithMeta => {
  createFlag(
    client,
    ~key,
    ~name,
    ~flagType=Variant,
    ~value=String(value),
    ~defaultValue=String(defaultValue->Option.getOr(value)),
    ~variants,
  )
}

// Create a rollout flag (convenience)
let createRolloutFlag = (
  client: t,
  ~key: string,
  ~name: string,
  ~percentage: float,
  ~seed: option<string>=?,
): flagWithMeta => {
  let hashSeed = seed->Option.getOr(key)
  createFlag(
    client,
    ~key,
    ~name,
    ~flagType=Rollout,
    ~value=Bool(false),
    ~defaultValue=Bool(false),
    ~percentage,
    ~hashSeed,
  )
}

// Get a flag from cache or store
let getFlag = (client: t, key: string): option<flagWithMeta> => {
  // Try cache first
  switch Cache.getWithStale(client.cache, key) {
  | Some((flag, _isStale)) =>
    // TODO: trigger background refresh if stale
    Some(flag)
  | None =>
    // Cache miss, get from store
    switch MemoryStore.get(client.store, key) {
    | Some(flag) =>
      // Populate cache
      Cache.put(client.cache, key, flag, ~policy=flag.meta.expiryPolicy)
      Some(flag)
    | None => None
    }
  }
}

// Evaluate a flag
let evaluate = (client: t, key: string, ~ctx: evaluationContext=Evaluator.defaultContext()): evaluationResult => {
  switch getFlag(client, key) {
  | None => {
      flagKey: key,
      value: Bool(false),
      reason: "flag_not_found",
      ruleIndex: None,
      cached: false,
      stale: false,
    }
  | Some(flagWithMeta) =>
    let result = Evaluator.evaluate(flagWithMeta, ctx)

    // Log evaluation if enabled
    AuditLog.logEvaluated(
      client.auditLog,
      ~flagKey=key,
      ~result=Js.Json.stringifyAny(result.value)->Option.getOr(""),
    )

    result
  }
}

// Evaluate a boolean flag
let evaluateBool = (client: t, key: string, ~ctx: evaluationContext=Evaluator.defaultContext()): bool => {
  let result = evaluate(client, key, ~ctx)
  switch result.value {
  | Bool(b) => b
  | _ => false
  }
}

// Evaluate a string flag
let evaluateString = (
  client: t,
  key: string,
  ~defaultValue: string="",
  ~ctx: evaluationContext=Evaluator.defaultContext(),
): string => {
  let result = evaluate(client, key, ~ctx)
  switch result.value {
  | String(s) => s
  | Bool(b) => b ? "true" : "false"
  | Int(i) => Int.toString(i)
  | Float(f) => Float.toString(f)
  | Json(j) => Js.Json.stringify(j)
  }
}

// Evaluate rollout for a user
let evaluateRollout = (client: t, key: string, ~userId: string): bool => {
  let ctx = Evaluator.contextWithUser(userId)
  evaluateBool(client, key, ~ctx)
}

// Update a flag value
let updateFlag = (client: t, key: string, ~value: flagValue): option<flagWithMeta> => {
  switch MemoryStore.get(client.store, key) {
  | None => None
  | Some(existing) =>
    let previousValue = Js.Json.stringifyAny(existing.flag.value)->Option.getOr("")

    let updated: flagWithMeta = {
      flag: {...existing.flag, value},
      meta: {
        ...existing.meta,
        updatedAt: Date.now(),
        version: VersionVector.increment(existing.meta.version, ~value=key),
      },
    }

    MemoryStore.set(client.store, key, updated)
    Cache.put(client.cache, key, updated, ~policy=updated.meta.expiryPolicy)

    AuditLog.logUpdated(
      client.auditLog,
      ~flagKey=key,
      ~previousValue,
      ~newValue=Js.Json.stringifyAny(value)->Option.getOr(""),
    )

    Some(updated)
  }
}

// Enable a flag
let enableFlag = (client: t, key: string): bool => {
  switch MemoryStore.get(client.store, key) {
  | None => false
  | Some(existing) =>
    let updated: flagWithMeta = {
      flag: {...existing.flag, state: Enabled},
      meta: {
        ...existing.meta,
        updatedAt: Date.now(),
        version: VersionVector.increment(existing.meta.version, ~value=`enable:${key}`),
      },
    }
    MemoryStore.set(client.store, key, updated)
    Cache.put(client.cache, key, updated, ~policy=updated.meta.expiryPolicy)
    true
  }
}

// Disable a flag
let disableFlag = (client: t, key: string): bool => {
  switch MemoryStore.get(client.store, key) {
  | None => false
  | Some(existing) =>
    let updated: flagWithMeta = {
      flag: {...existing.flag, state: Disabled},
      meta: {
        ...existing.meta,
        updatedAt: Date.now(),
        version: VersionVector.increment(existing.meta.version, ~value=`disable:${key}`),
      },
    }
    MemoryStore.set(client.store, key, updated)
    Cache.put(client.cache, key, updated, ~policy=updated.meta.expiryPolicy)
    true
  }
}

// Delete a flag
let deleteFlag = (client: t, key: string): bool => {
  switch MemoryStore.get(client.store, key) {
  | None => false
  | Some(existing) =>
    let previousValue = Js.Json.stringifyAny(existing.flag.value)->Option.getOr("")
    let deleted = MemoryStore.delete(client.store, key)
    if deleted {
      Cache.remove(client.cache, key)->ignore
      AuditLog.logDeleted(client.auditLog, ~flagKey=key, ~previousValue)
    }
    deleted
  }
}

// List all flags
let listFlags = (client: t): array<flagWithMeta> => {
  MemoryStore.list(client.store)
}

// Get flag keys
let getFlagKeys = (client: t): array<string> => {
  MemoryStore.keys(client.store)
}

// Get flag count
let flagCount = (client: t): int => {
  MemoryStore.count(client.store)
}

// Get cache statistics
let cacheStats = (client: t): Cache.cacheStats => {
  Cache.getStats(client.cache)
}

// Get audit records
let auditRecords = (client: t, ~limit: int=100): array<AuditLog.auditRecord> => {
  AuditLog.recent(client.auditLog, ~limit)
}

// Get audit records for a flag
let flagAuditRecords = (client: t, ~key: string, ~limit: int=100): array<AuditLog.auditRecord> => {
  AuditLog.forFlag(client.auditLog, ~flagKey=key, ~limit)
}

// Get current version
let version = (client: t): versionVector => {
  MemoryStore.getVersion(client.store)
}

// Purge expired cache entries
let purgeCache = (client: t): int => {
  Cache.purgeExpired(client.cache)
}

// Purge old audit records
let purgeAudit = (client: t): int => {
  AuditLog.purge(client.auditLog)
}

// Merge remote flags (for sync)
let mergeRemote = (client: t, remoteFlags: array<flagWithMeta>): int => {
  let merged = MemoryStore.merge(client.store, remoteFlags)

  // Update cache for merged flags
  remoteFlags->Array.forEach(flag => {
    Cache.put(client.cache, flag.flag.key, flag, ~policy=flag.meta.expiryPolicy)
    AuditLog.logSynced(
      client.auditLog,
      ~flagKey=flag.flag.key,
      ~newValue=Js.Json.stringifyAny(flag.flag.value)->Option.getOr(""),
    )
  })

  client.lastSyncAt = Some(Date.now())
  merged
}

// Create snapshot for export
let snapshot = (client: t): (array<flagWithMeta>, versionVector) => {
  let flags = MemoryStore.list(client.store)
  let ver = MemoryStore.getVersion(client.store)
  (flags, ver)
}

// Restore from snapshot
let restore = (client: t, flags: array<flagWithMeta>): unit => {
  flags->Array.forEach(flag => {
    MemoryStore.set(client.store, flag.flag.key, flag)
    Cache.put(client.cache, flag.flag.key, flag, ~policy=flag.meta.expiryPolicy)
  })
}
