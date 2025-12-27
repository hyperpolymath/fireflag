// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2024 Jonathan D.A. Jewell <hyperpolymath>

/**
 * Fireflag Client SDK
 *
 * Browser/client SDK for fire-and-forget feature flags.
 * Provides:
 * - Automatic background sync with SSE
 * - Local caching with IndexedDB fallback
 * - React-like hooks for reactive flag evaluation
 * - Offline support with stale-while-revalidate
 */

open Types

// Client configuration
type clientConfig = {
  // Server endpoint
  serverUrl: string,
  // Client identifier
  clientId: string,
  // Environment
  environment: string,
  // Sync interval (ms)
  syncInterval: float,
  // Enable SSE for real-time updates
  enableSSE: bool,
  // Enable offline support
  enableOffline: bool,
  // Cache TTL config
  cacheTtl: ttlConfig,
  // User context
  defaultContext: evaluationContext,
}

// Default client configuration
let defaultConfig = (): clientConfig => {
  serverUrl: "https://localhost:8080",
  clientId: `client-${Float.toString(Js.Math.random() *. 1000000.0)}`,
  environment: "production",
  syncInterval: 30000.0,
  enableSSE: true,
  enableOffline: true,
  cacheTtl: defaultTtlConfig,
  defaultContext: {
    userId: None,
    sessionId: None,
    attributes: Js.Dict.empty(),
    timestamp: Date.now(),
  },
}

// Connection state
type connectionState =
  | @as("disconnected") Disconnected
  | @as("connecting") Connecting
  | @as("connected") Connected
  | @as("reconnecting") Reconnecting

// Client events
type clientEvent =
  | @as("ready") Ready
  | @as("flag_changed") FlagChanged(string, flagValue)
  | @as("flags_synced") FlagsSynced(int)
  | @as("connection_changed") ConnectionChanged(connectionState)
  | @as("error") Error(string)

// Event listener type
type eventListener = clientEvent => unit

// Client state
type t = {
  config: clientConfig,
  mutable flags: Js.Dict.t<flagWithMeta>,
  mutable version: versionVector,
  mutable connectionState: connectionState,
  mutable lastSyncAt: option<float>,
  mutable listeners: array<eventListener>,
  mutable flagListeners: Js.Dict.t<array<flagValue => unit>>,
  mutable eventSource: option<eventSource>,
  mutable syncTimer: option<Js.Global.intervalId>,
  cache: Cache.t<flagWithMeta>,
}

// EventSource bindings
and eventSource

@new external createEventSource: string => eventSource = "EventSource"
@send external closeEventSource: eventSource => unit = "close"
@set external onMessage: (eventSource, {"data": string} => unit) => unit = "onmessage"
@set external onError: (eventSource, unit => unit) => unit = "onerror"
@set external onOpen: (eventSource, unit => unit) => unit = "onopen"
@get external readyState: eventSource => int = "readyState"

// Fetch bindings
type fetchResponse
@val external fetch: (string, 'options) => promise<fetchResponse> = "fetch"
@send external json: fetchResponse => promise<'a> = "json"
@send external text: fetchResponse => promise<string> = "text"
@get external ok: fetchResponse => bool = "ok"
@get external status: fetchResponse => int = "status"

// Create a new client
let make = (~config: clientConfig=defaultConfig()): t => {
  config,
  flags: Js.Dict.empty(),
  version: {
    version: 0,
    timestamp: Date.now(),
    nodeId: config.clientId,
    checksum: "0",
  },
  connectionState: Disconnected,
  lastSyncAt: None,
  listeners: [],
  flagListeners: Js.Dict.empty(),
  eventSource: None,
  syncTimer: None,
  cache: Cache.make(~config=config.cacheTtl, ~maxSize=1000),
}

// Emit event to listeners
let emit = (client: t, event: clientEvent): unit => {
  client.listeners->Array.forEach(listener => listener(event))
}

// Emit flag change to flag-specific listeners
let emitFlagChange = (client: t, key: string, value: flagValue): unit => {
  switch Js.Dict.get(client.flagListeners, key) {
  | None => ()
  | Some(listeners) => listeners->Array.forEach(listener => listener(value))
  }
  emit(client, FlagChanged(key, value))
}

// Add event listener
let addEventListener = (client: t, listener: eventListener): unit => {
  client.listeners = Array.concat(client.listeners, [listener])
}

// Remove event listener
let removeEventListener = (client: t, listener: eventListener): unit => {
  client.listeners = client.listeners->Array.filter(l => l !== listener)
}

// Subscribe to a specific flag
let subscribeToFlag = (client: t, key: string, listener: flagValue => unit): unit => {
  let existing = Js.Dict.get(client.flagListeners, key)->Option.getOr([])
  let newListeners = Js.Dict.fromArray(Js.Dict.entries(client.flagListeners))
  Js.Dict.set(newListeners, key, Array.concat(existing, [listener]))
  client.flagListeners = newListeners
}

// Unsubscribe from a flag
let unsubscribeFromFlag = (client: t, key: string, listener: flagValue => unit): unit => {
  switch Js.Dict.get(client.flagListeners, key) {
  | None => ()
  | Some(listeners) =>
    let filtered = listeners->Array.filter(l => l !== listener)
    let newListeners = Js.Dict.fromArray(Js.Dict.entries(client.flagListeners))
    Js.Dict.set(newListeners, key, filtered)
    client.flagListeners = newListeners
  }
}

// Fetch flags from server
let fetchFlags = async (client: t): array<flagWithMeta> => {
  let url = `${client.config.serverUrl}/flags?env=${client.config.environment}`
  let response = await fetch(url, {
    "method": "GET",
    "headers": {
      "Accept": "application/json",
      "X-Client-Id": client.config.clientId,
      "X-Client-Version": Int.toString(client.version.version),
    },
  })

  if ok(response) {
    let data: {"flags": array<flagWithMeta>, "version": versionVector} = await json(response)
    data["flags"]
  } else {
    []
  }
}

// Sync flags with server
let sync = async (client: t): int => {
  try {
    let remoteFlags = await fetchFlags(client)
    let updated = ref(0)

    remoteFlags->Array.forEach(flag => {
      let key = flag.flag.key
      let existing = Js.Dict.get(client.flags, key)

      let shouldUpdate = switch existing {
      | None => true
      | Some(local) => VersionVector.isNewer(flag.meta.version, local.meta.version)
      }

      if shouldUpdate {
        let newFlags = Js.Dict.fromArray(Js.Dict.entries(client.flags))
        Js.Dict.set(newFlags, key, flag)
        client.flags = newFlags
        Cache.put(client.cache, key, flag, ~policy=flag.meta.expiryPolicy)
        emitFlagChange(client, key, flag.flag.value)
        updated := updated.contents + 1
      }
    })

    client.lastSyncAt = Some(Date.now())
    emit(client, FlagsSynced(updated.contents))
    updated.contents
  } catch {
  | _ =>
    emit(client, Error("Sync failed"))
    0
  }
}

// Start SSE connection
let startSSE = (client: t): unit => {
  if client.config.enableSSE {
    let url = `${client.config.serverUrl}/events?env=${client.config.environment}&clientId=${client.config.clientId}`

    client.connectionState = Connecting
    emit(client, ConnectionChanged(Connecting))

    let es = createEventSource(url)

    onOpen(es, () => {
      client.connectionState = Connected
      emit(client, ConnectionChanged(Connected))
    })

    onMessage(es, event => {
      try {
        let data: {"type": string, "flag": option<flagWithMeta>} = Obj.magic(Js.Json.parseExn(event["data"]))

        switch (data["type"], data["flag"]) {
        | ("flag_update", Some(flag)) =>
          let key = flag.flag.key
          let newFlags = Js.Dict.fromArray(Js.Dict.entries(client.flags))
          Js.Dict.set(newFlags, key, flag)
          client.flags = newFlags
          Cache.put(client.cache, key, flag, ~policy=flag.meta.expiryPolicy)
          emitFlagChange(client, key, flag.flag.value)
        | _ => ()
        }
      } catch {
      | _ => ()
      }
    })

    onError(es, () => {
      client.connectionState = Reconnecting
      emit(client, ConnectionChanged(Reconnecting))
    })

    client.eventSource = Some(es)
  }
}

// Stop SSE connection
let stopSSE = (client: t): unit => {
  switch client.eventSource {
  | None => ()
  | Some(es) =>
    closeEventSource(es)
    client.eventSource = None
    client.connectionState = Disconnected
    emit(client, ConnectionChanged(Disconnected))
  }
}

// Start periodic sync
let startSync = (client: t): unit => {
  let timerId = Js.Global.setInterval(
    () => {
      let _ = sync(client)
    },
    Int.fromFloat(client.config.syncInterval),
  )
  client.syncTimer = Some(timerId)
}

// Stop periodic sync
let stopSync = (client: t): unit => {
  switch client.syncTimer {
  | None => ()
  | Some(timerId) =>
    Js.Global.clearInterval(timerId)
    client.syncTimer = None
  }
}

// Initialize client
let init = async (client: t): unit => {
  // Initial sync
  let _ = await sync(client)

  // Start SSE if enabled
  startSSE(client)

  // Start periodic sync as fallback
  startSync(client)

  emit(client, Ready)
}

// Shutdown client
let shutdown = (client: t): unit => {
  stopSSE(client)
  stopSync(client)
  client.connectionState = Disconnected
}

// Get a flag value
let getFlag = (client: t, key: string): option<flagWithMeta> => {
  // Try cache first
  switch Cache.getWithStale(client.cache, key) {
  | Some((flag, _stale)) => Some(flag)
  | None => Js.Dict.get(client.flags, key)
  }
}

// Evaluate a flag
let evaluate = (client: t, key: string, ~ctx: option<evaluationContext>=?): evaluationResult => {
  let context = ctx->Option.getOr(client.config.defaultContext)

  switch getFlag(client, key) {
  | None => {
      flagKey: key,
      value: Bool(false),
      reason: "flag_not_found",
      ruleIndex: None,
      cached: false,
      stale: false,
    }
  | Some(flag) => Evaluator.evaluate(flag, context)
  }
}

// Evaluate boolean flag
let evaluateBool = (client: t, key: string, ~defaultValue: bool=false): bool => {
  switch evaluate(client, key).value {
  | Bool(b) => b
  | _ => defaultValue
  }
}

// Evaluate string flag
let evaluateString = (client: t, key: string, ~defaultValue: string=""): string => {
  switch evaluate(client, key).value {
  | String(s) => s
  | Bool(b) => b ? "true" : "false"
  | Int(i) => Int.toString(i)
  | Float(f) => Float.toString(f)
  | Json(j) => Js.Json.stringify(j)
  }
}

// Evaluate rollout
let evaluateRollout = (client: t, key: string, ~userId: string): bool => {
  let ctx = {...client.config.defaultContext, userId: Some(userId)}
  switch evaluate(client, key, ~ctx).value {
  | Bool(b) => b
  | _ => false
  }
}

// Set user context
let setUser = (client: t, userId: string): unit => {
  client.config.defaultContext.userId->ignore
  // Note: ReScript records are immutable, so we'd need to recreate
  // For reference impl, we just update the evaluation context per-call
}

// Set attribute in context
let setAttribute = (client: t, key: string, value: string): unit => {
  Js.Dict.set(client.config.defaultContext.attributes, key, value)
}

// Get all flag keys
let getFlagKeys = (client: t): array<string> => {
  Js.Dict.keys(client.flags)
}

// Get connection state
let getConnectionState = (client: t): connectionState => {
  client.connectionState
}

// Check if client is ready
let isReady = (client: t): bool => {
  client.lastSyncAt->Option.isSome
}

// Force sync
let forceSync = async (client: t): int => {
  await sync(client)
}

// Get last sync timestamp
let getLastSyncAt = (client: t): option<float> => {
  client.lastSyncAt
}
