// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2024 Jonathan D.A. Jewell <hyperpolymath>

/**
 * Cache and TTL Management
 *
 * Implements multi-tier caching with TTL, stale-while-revalidate,
 * and adaptive expiry policies for fire-and-forget semantics.
 */

open Types

// Cache entry
type cacheEntry<'a> = {
  value: 'a,
  cachedAt: float,
  expiresAt: float,
  staleAt: float,
  accessCount: int,
  lastAccessedAt: float,
  expiryPolicy: expiryPolicy,
}

// Cache statistics
type cacheStats = {
  hits: int,
  misses: int,
  staleHits: int,
  evictions: int,
  size: int,
}

// Cache state
type t<'a> = {
  mutable entries: Js.Dict.t<cacheEntry<'a>>,
  mutable stats: cacheStats,
  config: ttlConfig,
  maxSize: int,
}

// Create a new cache
let make = (~config: ttlConfig=defaultTtlConfig, ~maxSize: int=1000): t<'a> => {
  entries: Js.Dict.empty(),
  stats: {
    hits: 0,
    misses: 0,
    staleHits: 0,
    evictions: 0,
    size: 0,
  },
  config,
  maxSize,
}

// Calculate expiry time based on policy
let calculateExpiry = (
  ~policy: expiryPolicy,
  ~config: ttlConfig,
  ~lastChangedAt: option<float>=?,
): (float, float) => {
  let now = Date.now()

  switch policy {
  | Absolute => (now +. config.defaultTtl, now +. config.defaultTtl +. config.staleTtl)

  | Sliding => (now +. config.defaultTtl, now +. config.defaultTtl +. config.staleTtl)

  | Adaptive =>
    // Adaptive TTL: more stable flags get longer TTLs
    let stabilityFactor = switch lastChangedAt {
    | None => 1.0
    | Some(changed) =>
      let timeSinceChange = now -. changed
      Js.Math.min_float(timeSinceChange /. config.defaultTtl, 10.0)
    }
    let adaptiveTtl = config.defaultTtl *. (1.0 +. stabilityFactor)
    let clampedTtl = Js.Math.max_float(
      config.minTtl,
      Js.Math.min_float(adaptiveTtl, config.maxTtl),
    )
    (now +. clampedTtl, now +. clampedTtl +. config.staleTtl)
  }
}

// Get cache state for an entry
let getState = (entry: cacheEntry<'a>): cacheState => {
  let now = Date.now()
  if now < entry.expiresAt {
    Fresh
  } else if now < entry.staleAt {
    Stale
  } else {
    CacheExpired
  }
}

// Evict least recently used entries if over capacity
let evictIfNeeded = (cache: t<'a>): unit => {
  let keys = Js.Dict.keys(cache.entries)
  if Array.length(keys) >= cache.maxSize {
    // Sort by last accessed time and remove oldest 10%
    let sortedEntries =
      keys
      ->Array.filterMap(key => {
        Js.Dict.get(cache.entries, key)->Option.map(entry => (key, entry))
      })
      ->Array.toSorted(((_, a), (_, b)) => a.lastAccessedAt -. b.lastAccessedAt)

    let toEvict = cache.maxSize / 10
    sortedEntries->Array.slice(~start=0, ~end=toEvict)->Array.forEach(((key, _)) => {
      let newEntries = Js.Dict.fromArray(
        Js.Dict.entries(cache.entries)->Array.filter(((k, _)) => k != key),
      )
      cache.entries = newEntries
      cache.stats = {...cache.stats, evictions: cache.stats.evictions + 1}
    })
  }
}

// Put a value in the cache
let put = (
  cache: t<'a>,
  key: string,
  value: 'a,
  ~policy: expiryPolicy=Absolute,
  ~lastChangedAt: option<float>=?,
): unit => {
  evictIfNeeded(cache)

  let (expiresAt, staleAt) = calculateExpiry(~policy, ~config=cache.config, ~lastChangedAt?)
  let now = Date.now()

  let entry: cacheEntry<'a> = {
    value,
    cachedAt: now,
    expiresAt,
    staleAt,
    accessCount: 0,
    lastAccessedAt: now,
    expiryPolicy: policy,
  }

  let newEntries = Js.Dict.fromArray(Js.Dict.entries(cache.entries))
  Js.Dict.set(newEntries, key, entry)
  cache.entries = newEntries
  cache.stats = {...cache.stats, size: Array.length(Js.Dict.keys(cache.entries))}
}

// Get a value from the cache
let get = (cache: t<'a>, key: string): option<('a, cacheState)> => {
  switch Js.Dict.get(cache.entries, key) {
  | None =>
    cache.stats = {...cache.stats, misses: cache.stats.misses + 1}
    None
  | Some(entry) =>
    let state = getState(entry)
    let now = Date.now()

    // Update access stats
    let updatedEntry = {
      ...entry,
      accessCount: entry.accessCount + 1,
      lastAccessedAt: now,
      // For sliding expiry, extend the TTL
      expiresAt: switch entry.expiryPolicy {
      | Sliding => now +. cache.config.defaultTtl
      | _ => entry.expiresAt
      },
      staleAt: switch entry.expiryPolicy {
      | Sliding => now +. cache.config.defaultTtl +. cache.config.staleTtl
      | _ => entry.staleAt
      },
    }

    let newEntries = Js.Dict.fromArray(Js.Dict.entries(cache.entries))
    Js.Dict.set(newEntries, key, updatedEntry)
    cache.entries = newEntries

    switch state {
    | Fresh =>
      cache.stats = {...cache.stats, hits: cache.stats.hits + 1}
      Some((entry.value, Fresh))
    | Stale =>
      cache.stats = {...cache.stats, staleHits: cache.stats.staleHits + 1}
      Some((entry.value, Stale))
    | CacheExpired => None
    }
  }
}

// Get only fresh values
let getFresh = (cache: t<'a>, key: string): option<'a> => {
  switch get(cache, key) {
  | Some((value, Fresh)) => Some(value)
  | _ => None
  }
}

// Get including stale values
let getWithStale = (cache: t<'a>, key: string): option<('a, bool)> => {
  switch get(cache, key) {
  | Some((value, Fresh)) => Some((value, false))
  | Some((value, Stale)) => Some((value, true))
  | _ => None
  }
}

// Remove a value from the cache
let remove = (cache: t<'a>, key: string): bool => {
  switch Js.Dict.get(cache.entries, key) {
  | None => false
  | Some(_) =>
    let entries = Js.Dict.entries(cache.entries)->Array.filter(((k, _)) => k != key)
    cache.entries = Js.Dict.fromArray(entries)
    cache.stats = {...cache.stats, size: Array.length(entries)}
    true
  }
}

// Check if a key exists (not expired)
let has = (cache: t<'a>, key: string): bool => {
  switch get(cache, key) {
  | Some(_) => true
  | None => false
  }
}

// Clear all entries
let clear = (cache: t<'a>): unit => {
  cache.entries = Js.Dict.empty()
  cache.stats = {...cache.stats, size: 0}
}

// Purge expired entries
let purgeExpired = (cache: t<'a>): int => {
  let now = Date.now()
  let originalCount = Array.length(Js.Dict.keys(cache.entries))

  let freshEntries =
    Js.Dict.entries(cache.entries)->Array.filter(((_, entry)) => now < entry.staleAt)

  cache.entries = Js.Dict.fromArray(freshEntries)
  cache.stats = {...cache.stats, size: Array.length(freshEntries)}

  originalCount - Array.length(freshEntries)
}

// Get cache statistics
let getStats = (cache: t<'a>): cacheStats => {
  cache.stats
}

// Get hit rate
let hitRate = (cache: t<'a>): float => {
  let total = cache.stats.hits + cache.stats.misses
  if total == 0 {
    0.0
  } else {
    Float.fromInt(cache.stats.hits) /. Float.fromInt(total)
  }
}

// Reset statistics
let resetStats = (cache: t<'a>): unit => {
  cache.stats = {
    hits: 0,
    misses: 0,
    staleHits: 0,
    evictions: 0,
    size: Array.length(Js.Dict.keys(cache.entries)),
  }
}

// Get all keys
let keys = (cache: t<'a>): array<string> => {
  Js.Dict.keys(cache.entries)
}

// Get current size
let size = (cache: t<'a>): int => {
  Array.length(Js.Dict.keys(cache.entries))
}
