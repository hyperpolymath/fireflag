// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2024 Jonathan D.A. Jewell <hyperpolymath>

/**
 * File-Based Storage Adapter
 *
 * Persists flags to JSON files on disk.
 * Suitable for development, testing, and single-node deployments.
 * Uses atomic writes to prevent corruption.
 */

open Types

// Deno file system bindings
@module("node:fs/promises")
external readFile: (string, {"encoding": string}) => promise<string> = "readFile"

@module("node:fs/promises")
external writeFile: (string, string, {"encoding": string}) => promise<unit> = "writeFile"

@module("node:fs/promises")
external mkdir: (string, {"recursive": bool}) => promise<unit> = "mkdir"

@module("node:fs/promises")
external unlink: string => promise<unit> = "unlink"

@module("node:fs/promises")
external access: string => promise<unit> = "access"

@module("node:fs/promises")
external rename: (string, string) => promise<unit> = "rename"

@module("node:path")
external dirname: string => string = "dirname"

@module("node:path")
external join: (string, string) => string = "join"

// File store state
type fileData = {
  flags: Js.Dict.t<flagWithMeta>,
  version: versionVector,
  updatedAt: float,
}

type t = {
  filePath: string,
  mutable data: fileData,
  mutable dirty: bool,
  nodeId: string,
  autoFlush: bool,
  flushInterval: float,
  mutable flushTimer: option<Js.Global.intervalId>,
}

// Serialize flag data to JSON
let serialize = (data: fileData): string => {
  Js.Json.stringifyAny(data)->Option.getOr("{}")
}

// Deserialize flag data from JSON
let deserialize = (json: string): option<fileData> => {
  try {
    let parsed = Js.Json.parseExn(json)
    // Manual deserialization for type safety
    switch Js.Json.classify(parsed) {
    | Js.Json.JSONObject(obj) =>
      let flags = Js.Dict.get(obj, "flags")
        ->Option.flatMap(f => Js.Json.decodeObject(f))
        ->Option.getOr(Js.Dict.empty())

      // Convert raw flags to typed flags
      let typedFlags = Js.Dict.empty()
      Js.Dict.keys(flags)->Array.forEach(key => {
        switch Js.Dict.get(flags, key) {
        | Some(flagJson) =>
          // For reference impl, we trust the JSON structure
          Js.Dict.set(typedFlags, key, Obj.magic(flagJson))
        | None => ()
        }
      })

      let version = Js.Dict.get(obj, "version")
        ->Option.flatMap(v => Js.Json.decodeObject(v))
        ->Option.map(v => {
          version: Js.Dict.get(v, "version")
            ->Option.flatMap(Js.Json.decodeNumber)
            ->Option.mapOr(0, Float.toInt),
          timestamp: Js.Dict.get(v, "timestamp")
            ->Option.flatMap(Js.Json.decodeNumber)
            ->Option.getOr(0.0),
          nodeId: Js.Dict.get(v, "nodeId")
            ->Option.flatMap(Js.Json.decodeString)
            ->Option.getOr("unknown"),
          checksum: Js.Dict.get(v, "checksum")
            ->Option.flatMap(Js.Json.decodeString)
            ->Option.getOr("0"),
        })
        ->Option.getOr({
          version: 0,
          timestamp: Date.now(),
          nodeId: "unknown",
          checksum: "0",
        })

      let updatedAt = Js.Dict.get(obj, "updatedAt")
        ->Option.flatMap(Js.Json.decodeNumber)
        ->Option.getOr(Date.now())

      Some({
        flags: typedFlags,
        version,
        updatedAt,
      })
    | _ => None
    }
  } catch {
  | _ => None
  }
}

// Check if file exists
let fileExists = async (path: string): bool => {
  try {
    await access(path)
    true
  } catch {
  | _ => false
  }
}

// Read data from file
let readData = async (filePath: string, nodeId: string): fileData => {
  let exists = await fileExists(filePath)
  if exists {
    try {
      let content = await readFile(filePath, {"encoding": "utf-8"})
      deserialize(content)->Option.getOr({
        flags: Js.Dict.empty(),
        version: {
          version: 0,
          timestamp: Date.now(),
          nodeId,
          checksum: "0",
        },
        updatedAt: Date.now(),
      })
    } catch {
    | _ => {
        flags: Js.Dict.empty(),
        version: {
          version: 0,
          timestamp: Date.now(),
          nodeId,
          checksum: "0",
        },
        updatedAt: Date.now(),
      }
    }
  } else {
    {
      flags: Js.Dict.empty(),
      version: {
        version: 0,
        timestamp: Date.now(),
        nodeId,
        checksum: "0",
      },
      updatedAt: Date.now(),
    }
  }
}

// Write data to file atomically
let writeData = async (filePath: string, data: fileData): unit => {
  let dir = dirname(filePath)
  await mkdir(dir, {"recursive": true})

  // Write to temp file first, then rename (atomic)
  let tempPath = `${filePath}.tmp`
  let json = serialize(data)
  await writeFile(tempPath, json, {"encoding": "utf-8"})
  await rename(tempPath, filePath)
}

// Create a new file store
let make = async (
  ~filePath: string,
  ~nodeId: string,
  ~autoFlush: bool=true,
  ~flushInterval: float=5000.0,
): t => {
  let data = await readData(filePath, nodeId)

  let store = {
    filePath,
    data,
    dirty: false,
    nodeId,
    autoFlush,
    flushInterval,
    flushTimer: None,
  }

  // Set up auto-flush timer
  if autoFlush {
    let timerId = Js.Global.setInterval(() => {
      if store.dirty {
        let _ = flush(store)
      }
    }, Int.fromFloat(flushInterval))
    store.flushTimer = Some(timerId)
  }

  store
}

// Flush changes to disk
and flush = async (store: t): unit => {
  if store.dirty {
    await writeData(store.filePath, store.data)
    store.dirty = false
  }
}

// Close the store
let close = async (store: t): unit => {
  // Stop auto-flush timer
  switch store.flushTimer {
  | Some(timerId) => Js.Global.clearInterval(timerId)
  | None => ()
  }
  store.flushTimer = None

  // Final flush
  await flush(store)
}

// Get a flag by key
let get = async (store: t, key: string): option<flagWithMeta> => {
  Js.Dict.get(store.data.flags, key)
}

// Get synchronously (for hot path)
let getSync = (store: t, key: string): option<flagWithMeta> => {
  Js.Dict.get(store.data.flags, key)
}

// Set a flag
let set = async (store: t, key: string, flag: flagWithMeta): unit => {
  let newFlags = Js.Dict.fromArray(Js.Dict.entries(store.data.flags))
  Js.Dict.set(newFlags, key, flag)

  store.data = {
    ...store.data,
    flags: newFlags,
    version: VersionVector.increment(store.data.version, ~value=key),
    updatedAt: Date.now(),
  }
  store.dirty = true

  // Immediate flush if auto-flush disabled
  if !store.autoFlush {
    await flush(store)
  }
}

// Delete a flag
let delete = async (store: t, key: string): bool => {
  switch Js.Dict.get(store.data.flags, key) {
  | None => false
  | Some(_) =>
    let entries = Js.Dict.entries(store.data.flags)->Array.filter(((k, _)) => k != key)
    store.data = {
      ...store.data,
      flags: Js.Dict.fromArray(entries),
      version: VersionVector.increment(store.data.version, ~value=`delete:${key}`),
      updatedAt: Date.now(),
    }
    store.dirty = true
    true
  }
}

// Check if flag exists
let has = async (store: t, key: string): bool => {
  Js.Dict.get(store.data.flags, key)->Option.isSome
}

// List all flags
let list = async (store: t): array<flagWithMeta> => {
  Js.Dict.values(store.data.flags)
}

// Get all keys
let keys = async (store: t): array<string> => {
  Js.Dict.keys(store.data.flags)
}

// Count flags
let count = async (store: t): int => {
  Array.length(Js.Dict.keys(store.data.flags))
}

// Clear all flags
let clear = async (store: t): unit => {
  store.data = {
    flags: Js.Dict.empty(),
    version: VersionVector.increment(store.data.version, ~value="clear"),
    updatedAt: Date.now(),
  }
  store.dirty = true
}

// Get current version
let getVersion = async (store: t): versionVector => {
  store.data.version
}

// Set version (for sync)
let setVersion = async (store: t, version: versionVector): unit => {
  store.data = {...store.data, version, updatedAt: Date.now()}
  store.dirty = true
}

// Compact (reload from disk to reclaim memory)
let compact = async (store: t): unit => {
  await flush(store)
  store.data = await readData(store.filePath, store.nodeId)
}

// Merge remote flags
let merge = async (store: t, remoteFlags: array<flagWithMeta>): int => {
  let merged = ref(0)

  remoteFlags->Array.forEach(remoteFlag => {
    let key = remoteFlag.flag.key
    switch Js.Dict.get(store.data.flags, key) {
    | None =>
      let newFlags = Js.Dict.fromArray(Js.Dict.entries(store.data.flags))
      Js.Dict.set(newFlags, key, remoteFlag)
      store.data = {...store.data, flags: newFlags}
      merged := merged.contents + 1
    | Some(localFlag) =>
      if VersionVector.isNewer(remoteFlag.meta.version, localFlag.meta.version) {
        let newFlags = Js.Dict.fromArray(Js.Dict.entries(store.data.flags))
        Js.Dict.set(newFlags, key, remoteFlag)
        store.data = {...store.data, flags: newFlags}
        merged := merged.contents + 1
      }
    }
  })

  if merged.contents > 0 {
    store.data = {
      ...store.data,
      version: VersionVector.increment(store.data.version, ~value="merge"),
      updatedAt: Date.now(),
    }
    store.dirty = true
  }

  merged.contents
}

// Export all data
let exportData = (store: t): string => {
  serialize(store.data)
}

// Import data
let importData = async (store: t, json: string): bool => {
  switch deserialize(json) {
  | None => false
  | Some(data) =>
    store.data = data
    store.dirty = true
    await flush(store)
    true
  }
}
