// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2024 Jonathan D.A. Jewell <hyperpolymath>

/**
 * Storage Adapter Interface
 *
 * Defines the contract for flag storage backends.
 * Implementations must provide async CRUD operations
 * with version vector support for conflict resolution.
 */

open Types

// Storage adapter interface (module type)
module type StorageAdapter = {
  // Adapter type
  type t

  // Lifecycle
  let make: (~config: Js.Dict.t<string>) => promise<t>
  let close: t => promise<unit>

  // CRUD operations
  let get: (t, string) => promise<option<flagWithMeta>>
  let set: (t, string, flagWithMeta) => promise<unit>
  let delete: (t, string) => promise<bool>
  let has: (t, string) => promise<bool>

  // Bulk operations
  let list: t => promise<array<flagWithMeta>>
  let keys: t => promise<array<string>>
  let count: t => promise<int>
  let clear: t => promise<unit>

  // Version tracking
  let getVersion: t => promise<versionVector>
  let setVersion: (t, versionVector) => promise<unit>

  // Maintenance
  let compact: t => promise<unit>
  let flush: t => promise<unit>
}

// Storage adapter configuration
type storageConfig = {
  adapterType: string,
  options: Js.Dict.t<string>,
}

// Storage error types
type storageError =
  | @as("connection_failed") ConnectionFailed
  | @as("read_error") ReadError
  | @as("write_error") WriteError
  | @as("not_found") NotFoundError
  | @as("corruption") CorruptionError
  | @as("permission_denied") PermissionDenied

// Storage result type
type storageResult<'a> = result<'a, storageError>

// Storage events for reactive updates
type storageEvent =
  | @as("flag_changed") FlagChanged(string, flagWithMeta)
  | @as("flag_deleted") FlagDeleted(string)
  | @as("storage_cleared") StorageCleared
  | @as("sync_completed") SyncCompleted(int)

// Storage listener type
type storageListener = storageEvent => unit

// Observable storage wrapper
type observableStorage<'t> = {
  storage: 't,
  mutable listeners: array<storageListener>,
}

// Add listener
let addListener = (obs: observableStorage<'t>, listener: storageListener): unit => {
  obs.listeners = Array.concat(obs.listeners, [listener])
}

// Remove listener
let removeListener = (obs: observableStorage<'t>, listener: storageListener): unit => {
  obs.listeners = obs.listeners->Array.filter(l => l !== listener)
}

// Notify listeners
let notify = (obs: observableStorage<'t>, event: storageEvent): unit => {
  obs.listeners->Array.forEach(listener => listener(event))
}

// Create observable wrapper
let makeObservable = (storage: 't): observableStorage<'t> => {
  storage,
  listeners: [],
}
