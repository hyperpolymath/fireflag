// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2024 Jonathan D.A. Jewell <hyperpolymath>

/**
 * Audit Logging System
 *
 * Immutable, append-only audit log for all flag operations.
 * Uses UUID v7 for time-sortable record IDs.
 */

open Types

// Audit event types
type auditEventType =
  | @as("created") Created
  | @as("updated") Updated
  | @as("deleted") Deleted
  | @as("evaluated") Evaluated
  | @as("expired") Expired
  | @as("synced") Synced
  | @as("conflict_resolved") ConflictResolved

// Actor types
type actorType =
  | @as("user") User
  | @as("system") System
  | @as("api") Api

// Audit actor
type auditActor = {
  actorType: actorType,
  actorId: string,
  ipAddress: option<string>,
}

// Audit context
type auditContext = {
  nodeId: string,
  environment: string,
  userAgent: option<string>,
  correlationId: option<string>,
}

// Audit record
type auditRecord = {
  id: string,
  timestamp: float,
  eventType: auditEventType,
  flagKey: string,
  previousValue: option<string>,
  newValue: option<string>,
  actor: auditActor,
  context: auditContext,
  checksum: string,
}

// Audit query
type auditQuery = {
  flagKey: option<string>,
  eventTypes: option<array<auditEventType>>,
  actorId: option<string>,
  startTime: option<float>,
  endTime: option<float>,
  limit: int,
  cursor: option<string>,
}

// Audit log configuration
type auditConfig = {
  enabled: bool,
  retentionDays: int,
  evaluationLogging: bool,
  maxRecords: int,
}

// Default audit configuration
let defaultConfig: auditConfig = {
  enabled: true,
  retentionDays: 90,
  evaluationLogging: false,
  maxRecords: 100000,
}

// Audit log state
type t = {
  mutable records: array<auditRecord>,
  config: auditConfig,
  nodeId: string,
}

// Generate a simple UUID v7-like ID (time-sortable)
// Production should use proper UUID v7 implementation
let generateId = (): string => {
  let timestamp = Date.now()->Float.toInt
  let random = Js.Math.random() *. 1000000.0->Float.toInt
  let timestampHex = Int.toString(timestamp, ~radix=16)->String.padStart(12, "0")
  let randomHex = Int.toString(random, ~radix=16)->String.padStart(12, "0")
  `${timestampHex}-${randomHex}`
}

// Generate checksum for audit record
let generateChecksum = (record: {..}): string => {
  // Simple hash for reference implementation
  let str = Js.Json.stringifyAny(record)->Option.getOr("")
  let hash = ref(0)
  for i in 0 to String.length(str) - 1 {
    let char = String.charCodeAt(str, i)->Float.toInt
    hash := Int.land(Int.lsl(hash.contents, 5) - hash.contents + char, 0x7FFFFFFF)
  }
  Int.toString(hash.contents, ~radix=16)->String.padStart(8, "0")
}

// Create a new audit log
let make = (~config: auditConfig=defaultConfig, ~nodeId: string): t => {
  records: [],
  config,
  nodeId,
}

// System actor
let systemActor = (): auditActor => {
  actorType: System,
  actorId: "system",
  ipAddress: None,
}

// Create default context
let defaultContext = (nodeId: string): auditContext => {
  nodeId,
  environment: "development",
  userAgent: None,
  correlationId: None,
}

// Append a record (internal)
let append = (log: t, record: auditRecord): unit => {
  // Check if logging is enabled
  if log.config.enabled {
    // Enforce max records limit
    if Array.length(log.records) >= log.config.maxRecords {
      // Remove oldest 10% to make room
      let keepCount = log.config.maxRecords * 9 / 10
      log.records = Array.sliceToEnd(log.records, ~start=Array.length(log.records) - keepCount)
    }

    log.records = Array.concat(log.records, [record])
  }
}

// Log flag created
let logCreated = (
  log: t,
  ~flagKey: string,
  ~newValue: string,
  ~actor: auditActor=systemActor(),
  ~context: option<auditContext>=?,
): unit => {
  let ctx = context->Option.getOr(defaultContext(log.nodeId))
  let record = {
    id: generateId(),
    timestamp: Date.now(),
    eventType: Created,
    flagKey,
    previousValue: None,
    newValue: Some(newValue),
    actor,
    context: ctx,
    checksum: "",
  }
  let checksum = generateChecksum(record)
  append(log, {...record, checksum})
}

// Log flag updated
let logUpdated = (
  log: t,
  ~flagKey: string,
  ~previousValue: string,
  ~newValue: string,
  ~actor: auditActor=systemActor(),
  ~context: option<auditContext>=?,
): unit => {
  let ctx = context->Option.getOr(defaultContext(log.nodeId))
  let record = {
    id: generateId(),
    timestamp: Date.now(),
    eventType: Updated,
    flagKey,
    previousValue: Some(previousValue),
    newValue: Some(newValue),
    actor,
    context: ctx,
    checksum: "",
  }
  let checksum = generateChecksum(record)
  append(log, {...record, checksum})
}

// Log flag deleted
let logDeleted = (
  log: t,
  ~flagKey: string,
  ~previousValue: string,
  ~actor: auditActor=systemActor(),
  ~context: option<auditContext>=?,
): unit => {
  let ctx = context->Option.getOr(defaultContext(log.nodeId))
  let record = {
    id: generateId(),
    timestamp: Date.now(),
    eventType: Deleted,
    flagKey,
    previousValue: Some(previousValue),
    newValue: None,
    actor,
    context: ctx,
    checksum: "",
  }
  let checksum = generateChecksum(record)
  append(log, {...record, checksum})
}

// Log flag evaluated (if enabled)
let logEvaluated = (
  log: t,
  ~flagKey: string,
  ~result: string,
  ~context: option<auditContext>=?,
): unit => {
  if log.config.evaluationLogging {
    let ctx = context->Option.getOr(defaultContext(log.nodeId))
    let record = {
      id: generateId(),
      timestamp: Date.now(),
      eventType: Evaluated,
      flagKey,
      previousValue: None,
      newValue: Some(result),
      actor: systemActor(),
      context: ctx,
      checksum: "",
    }
    let checksum = generateChecksum(record)
    append(log, {...record, checksum})
  }
}

// Log flag expired
let logExpired = (log: t, ~flagKey: string, ~context: option<auditContext>=?): unit => {
  let ctx = context->Option.getOr(defaultContext(log.nodeId))
  let record = {
    id: generateId(),
    timestamp: Date.now(),
    eventType: Expired,
    flagKey,
    previousValue: None,
    newValue: None,
    actor: systemActor(),
    context: ctx,
    checksum: "",
  }
  let checksum = generateChecksum(record)
  append(log, {...record, checksum})
}

// Log sync event
let logSynced = (
  log: t,
  ~flagKey: string,
  ~newValue: string,
  ~context: option<auditContext>=?,
): unit => {
  let ctx = context->Option.getOr(defaultContext(log.nodeId))
  let record = {
    id: generateId(),
    timestamp: Date.now(),
    eventType: Synced,
    flagKey,
    previousValue: None,
    newValue: Some(newValue),
    actor: systemActor(),
    context: ctx,
    checksum: "",
  }
  let checksum = generateChecksum(record)
  append(log, {...record, checksum})
}

// Log conflict resolution
let logConflictResolved = (
  log: t,
  ~flagKey: string,
  ~previousValue: string,
  ~newValue: string,
  ~context: option<auditContext>=?,
): unit => {
  let ctx = context->Option.getOr(defaultContext(log.nodeId))
  let record = {
    id: generateId(),
    timestamp: Date.now(),
    eventType: ConflictResolved,
    flagKey,
    previousValue: Some(previousValue),
    newValue: Some(newValue),
    actor: systemActor(),
    context: ctx,
    checksum: "",
  }
  let checksum = generateChecksum(record)
  append(log, {...record, checksum})
}

// Query audit records
let query = (log: t, q: auditQuery): array<auditRecord> => {
  let filtered =
    log.records
    ->Array.filter(r => {
      // Filter by flag key
      let keyMatch = switch q.flagKey {
      | None => true
      | Some(key) => r.flagKey == key
      }

      // Filter by event types
      let typeMatch = switch q.eventTypes {
      | None => true
      | Some(types) => types->Array.some(t => t == r.eventType)
      }

      // Filter by actor ID
      let actorMatch = switch q.actorId {
      | None => true
      | Some(id) => r.actor.actorId == id
      }

      // Filter by time range
      let startMatch = switch q.startTime {
      | None => true
      | Some(start) => r.timestamp >= start
      }

      let endMatch = switch q.endTime {
      | None => true
      | Some(end_) => r.timestamp <= end_
      }

      keyMatch && typeMatch && actorMatch && startMatch && endMatch
    })
    ->Array.toSorted((a, b) => b.timestamp -. a.timestamp) // Sort by timestamp descending

  // Apply cursor and limit
  let startIndex = switch q.cursor {
  | None => 0
  | Some(cursor) =>
    filtered->Array.findIndex(r => r.id == cursor)->Option.mapOr(0, i => i + 1)
  }

  filtered->Array.slice(~start=startIndex, ~end=startIndex + q.limit)
}

// Get recent records
let recent = (log: t, ~limit: int=100): array<auditRecord> => {
  query(
    log,
    {
      flagKey: None,
      eventTypes: None,
      actorId: None,
      startTime: None,
      endTime: None,
      limit,
      cursor: None,
    },
  )
}

// Get records for a specific flag
let forFlag = (log: t, ~flagKey: string, ~limit: int=100): array<auditRecord> => {
  query(
    log,
    {
      flagKey: Some(flagKey),
      eventTypes: None,
      actorId: None,
      startTime: None,
      endTime: None,
      limit,
      cursor: None,
    },
  )
}

// Count total records
let count = (log: t): int => {
  Array.length(log.records)
}

// Purge old records based on retention policy
let purge = (log: t): int => {
  let cutoff = Date.now() -. Float.fromInt(log.config.retentionDays * 24 * 60 * 60 * 1000)
  let originalCount = Array.length(log.records)
  log.records = log.records->Array.filter(r => r.timestamp >= cutoff)
  originalCount - Array.length(log.records)
}

// Export records (for backup)
let export = (log: t): array<auditRecord> => {
  log.records
}

// Import records (from backup)
let import = (log: t, records: array<auditRecord>): unit => {
  log.records = Array.concat(log.records, records)
}
