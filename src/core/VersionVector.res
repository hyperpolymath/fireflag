// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2024 Jonathan D.A. Jewell <hyperpolymath>

/**
 * Version Vector Implementation
 *
 * Provides conflict resolution for eventual consistency using
 * version vectors with timestamp and node ID tiebreakers.
 */

open Types

// Generate a simple hash (for demo; production would use SHA-256)
let generateChecksum = (value: string): string => {
  // Simple hash for reference implementation
  // Production should use SubtleCrypto.digest with SHA-256
  let hash = ref(0)
  for i in 0 to String.length(value) - 1 {
    let char = String.charCodeAt(value, i)->Float.toInt
    hash := Int.land(Int.lsl(hash.contents, 5) - hash.contents + char, 0x7FFFFFFF)
  }
  Int.toString(hash.contents, ~radix=16)->String.padStart(8, "0")
}

// Create a new version vector
let make = (~nodeId: string, ~value: string): versionVector => {
  version: 1,
  timestamp: Date.now(),
  nodeId,
  checksum: generateChecksum(value),
}

// Increment version
let increment = (v: versionVector, ~value: string): versionVector => {
  ...v,
  version: v.version + 1,
  timestamp: Date.now(),
  checksum: generateChecksum(value),
}

// Compare two version vectors
// Returns: -1 if a < b, 0 if a == b, 1 if a > b
let compare = (a: versionVector, b: versionVector): int => {
  if a.version != b.version {
    a.version > b.version ? 1 : -1
  } else if a.timestamp != b.timestamp {
    a.timestamp > b.timestamp ? 1 : -1
  } else if a.nodeId != b.nodeId {
    a.nodeId > b.nodeId ? 1 : -1
  } else {
    0
  }
}

// Resolve conflict between two version vectors
// Returns the winning version vector
let resolveConflict = (a: versionVector, b: versionVector): versionVector => {
  compare(a, b) >= 0 ? a : b
}

// Check if version a is newer than version b
let isNewer = (a: versionVector, b: versionVector): bool => {
  compare(a, b) > 0
}

// Check if version a is older than version b
let isOlder = (a: versionVector, b: versionVector): bool => {
  compare(a, b) < 0
}

// Check if two versions are equal
let isEqual = (a: versionVector, b: versionVector): bool => {
  compare(a, b) == 0
}

// Merge two version vectors (for sync)
let merge = (local: versionVector, remote: versionVector): versionVector => {
  let winner = resolveConflict(local, remote)
  {
    ...winner,
    version: max(local.version, remote.version) + 1,
    timestamp: Date.now(),
  }
}

// Serialize to string for transport
let toString = (v: versionVector): string => {
  `${Int.toString(v.version)}:${Float.toString(v.timestamp)}:${v.nodeId}:${v.checksum}`
}

// Parse from string
let fromString = (s: string): option<versionVector> => {
  let parts = String.split(s, ":")
  if Array.length(parts) == 4 {
    switch (
      Int.fromString(parts[0]->Option.getOr("0")),
      Float.fromString(parts[1]->Option.getOr("0")),
    ) {
    | (Some(version), Some(timestamp)) =>
      Some({
        version,
        timestamp,
        nodeId: parts[2]->Option.getOr(""),
        checksum: parts[3]->Option.getOr(""),
      })
    | _ => None
    }
  } else {
    None
  }
}
