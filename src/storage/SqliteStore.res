// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2024 Jonathan D.A. Jewell <hyperpolymath>

/**
 * SQLite Storage Adapter
 *
 * Persists flags to a SQLite database.
 * Suitable for production single-node deployments.
 * Uses WAL mode for concurrent reads and atomic writes.
 */

open Types

// SQLite database handle (Deno SQLite)
type database

// SQLite bindings for Deno
@module("https://deno.land/x/sqlite@v3.8/mod.ts")
external openDatabase: string => database = "DB"

@send external close: database => unit = "close"
@send external execute: (database, string) => unit = "execute"
@send external query: (database, string, array<string>) => array<array<string>> = "query"
@send external queryEntries: (database, string, array<string>) => array<Js.Dict.t<string>> = "queryEntries"

// Store state
type t = {
  db: database,
  nodeId: string,
  mutable version: versionVector,
}

// Initialize database schema
let initSchema = (db: database): unit => {
  execute(db, `
    CREATE TABLE IF NOT EXISTS flags (
      key TEXT PRIMARY KEY,
      data TEXT NOT NULL,
      version INTEGER NOT NULL,
      timestamp REAL NOT NULL,
      checksum TEXT NOT NULL,
      created_at REAL NOT NULL,
      updated_at REAL NOT NULL
    )
  `)

  execute(db, `
    CREATE TABLE IF NOT EXISTS metadata (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  `)

  execute(db, `
    CREATE INDEX IF NOT EXISTS idx_flags_updated ON flags(updated_at)
  `)

  // Enable WAL mode for better concurrency
  execute(db, "PRAGMA journal_mode=WAL")
  execute(db, "PRAGMA synchronous=NORMAL")
}

// Serialize flagWithMeta to JSON string
let serializeFlag = (flag: flagWithMeta): string => {
  Js.Json.stringifyAny(flag)->Option.getOr("{}")
}

// Deserialize flagWithMeta from JSON string
let deserializeFlag = (json: string): option<flagWithMeta> => {
  try {
    Some(Obj.magic(Js.Json.parseExn(json)))
  } catch {
  | _ => None
  }
}

// Create a new SQLite store
let make = async (~dbPath: string, ~nodeId: string): t => {
  let db = openDatabase(dbPath)
  initSchema(db)

  // Load version from metadata
  let versionStr = try {
    let rows = queryEntries(db, "SELECT value FROM metadata WHERE key = ?", ["version"])
    rows[0]->Option.flatMap(row => Js.Dict.get(row, "value"))
  } catch {
  | _ => None
  }

  let version = versionStr
    ->Option.flatMap(VersionVector.fromString)
    ->Option.getOr({
      version: 0,
      timestamp: Date.now(),
      nodeId,
      checksum: "0",
    })

  {db, nodeId, version}
}

// Close the store
let close = async (store: t): unit => {
  close(store.db)
}

// Save version to metadata
let saveVersion = (store: t): unit => {
  let versionStr = VersionVector.toString(store.version)
  execute(store.db, "INSERT OR REPLACE INTO metadata (key, value) VALUES ('version', ?)")
  let _ = query(store.db, "INSERT OR REPLACE INTO metadata (key, value) VALUES ('version', ?)", [versionStr])
}

// Get a flag by key
let get = async (store: t, key: string): option<flagWithMeta> => {
  try {
    let rows = queryEntries(store.db, "SELECT data FROM flags WHERE key = ?", [key])
    rows[0]
      ->Option.flatMap(row => Js.Dict.get(row, "data"))
      ->Option.flatMap(deserializeFlag)
  } catch {
  | _ => None
  }
}

// Set a flag
let set = async (store: t, key: string, flag: flagWithMeta): unit => {
  let data = serializeFlag(flag)
  let now = Date.now()
  let version = flag.meta.version.version
  let timestamp = flag.meta.version.timestamp
  let checksum = flag.meta.version.checksum

  let _ = query(
    store.db,
    `INSERT OR REPLACE INTO flags (key, data, version, timestamp, checksum, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, COALESCE((SELECT created_at FROM flags WHERE key = ?), ?), ?)`,
    [
      key,
      data,
      Int.toString(version),
      Float.toString(timestamp),
      checksum,
      key,
      Float.toString(now),
      Float.toString(now),
    ],
  )

  store.version = VersionVector.increment(store.version, ~value=key)
  saveVersion(store)
}

// Delete a flag
let delete = async (store: t, key: string): bool => {
  let exists = await has(store, key)
  if exists {
    let _ = query(store.db, "DELETE FROM flags WHERE key = ?", [key])
    store.version = VersionVector.increment(store.version, ~value=`delete:${key}`)
    saveVersion(store)
    true
  } else {
    false
  }
}

// Check if flag exists
and has = async (store: t, key: string): bool => {
  try {
    let rows = query(store.db, "SELECT 1 FROM flags WHERE key = ?", [key])
    Array.length(rows) > 0
  } catch {
  | _ => false
  }
}

// List all flags
let list = async (store: t): array<flagWithMeta> => {
  try {
    let rows = queryEntries(store.db, "SELECT data FROM flags ORDER BY updated_at DESC", [])
    rows->Array.filterMap(row => {
      Js.Dict.get(row, "data")->Option.flatMap(deserializeFlag)
    })
  } catch {
  | _ => []
  }
}

// Get all keys
let keys = async (store: t): array<string> => {
  try {
    let rows = queryEntries(store.db, "SELECT key FROM flags ORDER BY key", [])
    rows->Array.filterMap(row => Js.Dict.get(row, "key"))
  } catch {
  | _ => []
  }
}

// Count flags
let count = async (store: t): int => {
  try {
    let rows = queryEntries(store.db, "SELECT COUNT(*) as count FROM flags", [])
    rows[0]
      ->Option.flatMap(row => Js.Dict.get(row, "count"))
      ->Option.flatMap(Int.fromString)
      ->Option.getOr(0)
  } catch {
  | _ => 0
  }
}

// Clear all flags
let clear = async (store: t): unit => {
  execute(store.db, "DELETE FROM flags")
  store.version = VersionVector.increment(store.version, ~value="clear")
  saveVersion(store)
}

// Get current version
let getVersion = async (store: t): versionVector => {
  store.version
}

// Set version
let setVersion = async (store: t, version: versionVector): unit => {
  store.version = version
  saveVersion(store)
}

// Compact (vacuum database)
let compact = async (store: t): unit => {
  execute(store.db, "VACUUM")
}

// Flush (checkpoint WAL)
let flush = async (store: t): unit => {
  execute(store.db, "PRAGMA wal_checkpoint(TRUNCATE)")
}

// Get flags updated after a timestamp
let getUpdatedAfter = async (store: t, timestamp: float): array<flagWithMeta> => {
  try {
    let rows = queryEntries(
      store.db,
      "SELECT data FROM flags WHERE updated_at > ? ORDER BY updated_at ASC",
      [Float.toString(timestamp)],
    )
    rows->Array.filterMap(row => {
      Js.Dict.get(row, "data")->Option.flatMap(deserializeFlag)
    })
  } catch {
  | _ => []
  }
}

// Merge remote flags
let merge = async (store: t, remoteFlags: array<flagWithMeta>): int => {
  let merged = ref(0)

  for i in 0 to Array.length(remoteFlags) - 1 {
    switch remoteFlags[i] {
    | None => ()
    | Some(remoteFlag) =>
      let key = remoteFlag.flag.key
      let localFlag = await get(store, key)

      let shouldUpdate = switch localFlag {
      | None => true
      | Some(local) => VersionVector.isNewer(remoteFlag.meta.version, local.meta.version)
      }

      if shouldUpdate {
        await set(store, key, remoteFlag)
        merged := merged.contents + 1
      }
    }
  }

  merged.contents
}

// Get statistics
type storeStats = {
  flagCount: int,
  dbSizeBytes: int,
  walSizeBytes: int,
  lastUpdated: option<float>,
}

let getStats = async (store: t): storeStats => {
  let flagCount = await count(store)

  let lastUpdated = try {
    let rows = queryEntries(store.db, "SELECT MAX(updated_at) as last FROM flags", [])
    rows[0]
      ->Option.flatMap(row => Js.Dict.get(row, "last"))
      ->Option.flatMap(Float.fromString)
  } catch {
  | _ => None
  }

  {
    flagCount,
    dbSizeBytes: 0, // Would need file stat
    walSizeBytes: 0,
    lastUpdated,
  }
}
