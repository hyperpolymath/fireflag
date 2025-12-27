// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2024 Jonathan D.A. Jewell <hyperpolymath>

/**
 * In-Memory Flag Store
 *
 * Reference implementation of the flag store interface using
 * an in-memory Map. Suitable for development and testing.
 */

open Types

// Internal store state
type t = {
  mutable flags: Js.Dict.t<flagWithMeta>,
  mutable version: versionVector,
  nodeId: string,
}

// Create a new memory store
let make = (~nodeId: string): t => {
  flags: Js.Dict.empty(),
  version: {
    version: 0,
    timestamp: Date.now(),
    nodeId,
    checksum: "0",
  },
  nodeId,
}

// Get a flag by key
let get = (store: t, key: string): option<flagWithMeta> => {
  Js.Dict.get(store.flags, key)
}

// Get a flag by key (Promise version for interface compatibility)
let getAsync = (store: t, key: string): promise<option<flagWithMeta>> => {
  Promise.resolve(get(store, key))
}

// Set a flag
let set = (store: t, key: string, flag: flagWithMeta): unit => {
  let newFlags = Js.Dict.fromArray(Js.Dict.entries(store.flags))
  Js.Dict.set(newFlags, key, flag)
  store.flags = newFlags
  store.version = VersionVector.increment(store.version, ~value=key)
}

// Set a flag (Promise version)
let setAsync = (store: t, key: string, flag: flagWithMeta): promise<unit> => {
  set(store, key, flag)
  Promise.resolve()
}

// Delete a flag
let delete = (store: t, key: string): bool => {
  switch Js.Dict.get(store.flags, key) {
  | None => false
  | Some(_) =>
    let entries = Js.Dict.entries(store.flags)->Array.filter(((k, _)) => k != key)
    store.flags = Js.Dict.fromArray(entries)
    store.version = VersionVector.increment(store.version, ~value=`delete:${key}`)
    true
  }
}

// Delete a flag (Promise version)
let deleteAsync = (store: t, key: string): promise<bool> => {
  Promise.resolve(delete(store, key))
}

// List all flags
let list = (store: t): array<flagWithMeta> => {
  Js.Dict.values(store.flags)
}

// List all flags (Promise version)
let listAsync = (store: t): promise<array<flagWithMeta>> => {
  Promise.resolve(list(store))
}

// Get current version
let getVersion = (store: t): versionVector => {
  store.version
}

// Get current version (Promise version)
let getVersionAsync = (store: t): promise<versionVector> => {
  Promise.resolve(store.version)
}

// Get all keys
let keys = (store: t): array<string> => {
  Js.Dict.keys(store.flags)
}

// Check if a flag exists
let has = (store: t, key: string): bool => {
  Js.Dict.get(store.flags, key)->Option.isSome
}

// Get count of flags
let count = (store: t): int => {
  Array.length(Js.Dict.keys(store.flags))
}

// Clear all flags
let clear = (store: t): unit => {
  store.flags = Js.Dict.empty()
  store.version = VersionVector.increment(store.version, ~value="clear")
}

// Compact (no-op for memory store)
let compact = (_store: t): unit => {
  ()
}

// Compact (Promise version)
let compactAsync = (store: t): promise<unit> => {
  compact(store)
  Promise.resolve()
}

// Create a snapshot of current state
let snapshot = (store: t): (array<(string, flagWithMeta)>, versionVector) => {
  (Js.Dict.entries(store.flags), store.version)
}

// Restore from snapshot
let restore = (store: t, flags: array<(string, flagWithMeta)>, version: versionVector): unit => {
  store.flags = Js.Dict.fromArray(flags)
  store.version = version
}

// Merge remote flags with local (for sync)
let merge = (store: t, remoteFlags: array<flagWithMeta>): int => {
  let merged = ref(0)

  remoteFlags->Array.forEach(remoteFlag => {
    let key = remoteFlag.flag.key
    switch Js.Dict.get(store.flags, key) {
    | None =>
      set(store, key, remoteFlag)
      merged := merged.contents + 1
    | Some(localFlag) =>
      if VersionVector.isNewer(remoteFlag.meta.version, localFlag.meta.version) {
        set(store, key, remoteFlag)
        merged := merged.contents + 1
      }
    }
  })

  merged.contents
}
