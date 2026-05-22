// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//
// End-to-End lifecycle tests for the browser extension.
//
// Tests complete user workflows:
//   - Initialize extension → load flag database → evaluate flag
//   - Update flag database → re-evaluate → verify changes reflected
//   - DevTools open → inspect flags → list all → count matches
//   - Flag changed → extension notified → state updated
//
// Transpiled from tests/e2e/extension_lifecycle_test.ts (2026-04-18).
//
// The TypeScript version used a `class FireflagExtension` with mutable
// state; ReScript doesn't have classes, so the port models the same
// surface with a mutable record and top-level functions that take the
// record as their first argument.  The test semantics are identical —
// the TS `await ext.initialize()` pattern compiles to a no-op wait on
// a resolved promise, which we mirror with `Promise.resolve()`.

open Bindings

type unknown
external toU: 'a => unknown = "%identity"
let undefinedV: unknown = %raw(`undefined`)

@scope("JSON") @val external stringify: 'a => string = "stringify"
@scope("Date") @val external dateNow: unit => float = "now"

// ─────────────────────────────────────────────────────────────────
// Mutable state records
// ─────────────────────────────────────────────────────────────────

type flag = {
  key: string,
  enabled: bool,
  mutable value: unknown,
  defaultValue: unknown,
}

type flagDatabase = Dict.t<flag>

type changeEntry = {
  key: string,
  timestamp: float,
}

type extensionState = {
  mutable initialized: bool,
  mutable databaseLoaded: bool,
  mutable database: flagDatabase,
  flagChanges: array<changeEntry>,
}

type devToolsPanel = {
  mutable visible: bool,
  mutable flags: array<flag>,
  mutable selectedFlag: option<string>,
}

type fireflagExtension = {
  mutable state: extensionState,
  mutable devToolsPanel: devToolsPanel,
}

// ─────────────────────────────────────────────────────────────────
// Mock Extension Implementation
// ─────────────────────────────────────────────────────────────────

let create = (): fireflagExtension => {
  state: {
    initialized: false,
    databaseLoaded: false,
    database: Dict.make(),
    flagChanges: [],
  },
  devToolsPanel: {
    visible: false,
    flags: [],
    selectedFlag: None,
  },
}

// Shallow-clone a flagDatabase — the TS version used `{ ...db }` spread
// to avoid aliasing the caller's mutable database.
let cloneDb = (db: flagDatabase): flagDatabase => {
  let out = Dict.make()
  Dict.keysToArray(db)->Array.forEach(k => {
    switch Dict.get(db, k) {
    | Some(f) => Dict.set(out, k, f)
    | None => ()
    }
  })
  out
}

let initialize = async (ext: fireflagExtension): unit => {
  ext.state.initialized = true
}

let loadDatabase = async (ext: fireflagExtension, db: flagDatabase): unit => {
  ext.state.database = cloneDb(db)
  ext.state.databaseLoaded = true
}

let evaluateFlag = (ext: fireflagExtension, flagId: string): unknown => {
  switch Dict.get(ext.state.database, flagId) {
  | None => undefinedV
  | Some(flag) when !flag.enabled => flag.defaultValue
  | Some(flag) => flag.value
  }
}

let updateDatabase = async (ext: fireflagExtension, newDb: flagDatabase): unit => {
  let oldDb = ext.state.database

  // Track changes — compare JSON-stringified forms for content equality.
  Dict.keysToArray(newDb)->Array.forEach(key => {
    let newFlag = Dict.get(newDb, key)->Option.getUnsafe
    let changed = switch Dict.get(oldDb, key) {
    | None => true
    | Some(old) => stringify(old) !== stringify(newFlag)
    }
    if changed {
      ext.state.flagChanges->Array.push({key, timestamp: dateNow()})
    }
  })

  ext.state.database = cloneDb(newDb)
}

let getAllFlags = (ext: fireflagExtension): array<flag> => {
  Dict.valuesToArray(ext.state.database)
}

let getFlagsByCategory = (ext: fireflagExtension, category: string): array<flag> => {
  let prefix = category ++ "."
  getAllFlags(ext)->Array.filter(f => f.key->String.startsWith(prefix))
}

let openDevToolsPanel = async (ext: fireflagExtension): unit => {
  ext.devToolsPanel.visible = true
  ext.devToolsPanel.flags = getAllFlags(ext)
}

let inspectFlag = (ext: fireflagExtension, flagId: string): unit => {
  ext.devToolsPanel.selectedFlag = Some(flagId)
}

let countFlags = (ext: fireflagExtension, predicate: flag => bool): int => {
  getAllFlags(ext)->Array.filter(predicate)->Array.length
}

let notifyFlagChanged = (ext: fireflagExtension, flagId: string, newValue: unknown): unit => {
  switch Dict.get(ext.state.database, flagId) {
  | None => ()
  | Some(flag) =>
    flag.value = newValue
    ext.state.flagChanges->Array.push({key: flagId, timestamp: dateNow()})
  }
}

let getChangeHistory = (ext: fireflagExtension): array<changeEntry> => ext.state.flagChanges

let reset = (ext: fireflagExtension): unit => {
  ext.state = {
    initialized: false,
    databaseLoaded: false,
    database: Dict.make(),
    flagChanges: [],
  }
  ext.devToolsPanel = {
    visible: false,
    flags: [],
    selectedFlag: None,
  }
}

// Small helpers for building fixture databases.
let mkFlag = (~key, ~enabled, ~value, ~defaultValue): flag => {
  key,
  enabled,
  value,
  defaultValue,
}

let singleton = (key, flag) => {
  let d = Dict.make()
  Dict.set(d, key, flag)
  d
}

// ─────────────────────────────────────────────────────────────────
// E2E Tests: Extension Initialization
// ─────────────────────────────────────────────────────────────────

testAsync("E2E: initialize extension", async () => {
  let ext = create()
  assertEquals(ext.state.initialized, false)
  await initialize(ext)
  assertEquals(ext.state.initialized, true)
  reset(ext)
})

testAsync("E2E: load flag database after initialization", async () => {
  let ext = create()
  let db = singleton(
    "privacy.tracking",
    mkFlag(
      ~key="privacy.tracking",
      ~enabled=true,
      ~value=toU(false),
      ~defaultValue=toU(true),
    ),
  )
  await initialize(ext)
  assertEquals(ext.state.databaseLoaded, false)
  await loadDatabase(ext, db)
  assertEquals(ext.state.databaseLoaded, true)
  assertEquals(Array.length(Dict.keysToArray(ext.state.database)), 1)
  reset(ext)
})

// ─────────────────────────────────────────────────────────────────
// E2E Tests: Flag Evaluation
// ─────────────────────────────────────────────────────────────────

testAsync("E2E: initialize → load database → evaluate flag", async () => {
  let ext = create()
  let db = singleton(
    "feature.new",
    mkFlag(~key="feature.new", ~enabled=true, ~value=toU(true), ~defaultValue=toU(false)),
  )
  await initialize(ext)
  assertExists(ext.state.initialized)
  await loadDatabase(ext, db)
  assertExists(Dict.get(ext.state.database, "feature.new"))
  let result = evaluateFlag(ext, "feature.new")
  assertStrictEquals(result, toU(true))
  reset(ext)
})

testAsync("E2E: evaluate multiple flags", async () => {
  let ext = create()
  let db = Dict.make()
  Dict.set(
    db,
    "feature.one",
    mkFlag(
      ~key="feature.one",
      ~enabled=true,
      ~value=toU("first"),
      ~defaultValue=toU("default"),
    ),
  )
  Dict.set(
    db,
    "feature.two",
    mkFlag(
      ~key="feature.two",
      ~enabled=false,
      ~value=toU("second"),
      ~defaultValue=toU("default"),
    ),
  )
  Dict.set(
    db,
    "feature.three",
    mkFlag(
      ~key="feature.three",
      ~enabled=true,
      ~value=toU(42),
      ~defaultValue=toU(0),
    ),
  )

  await initialize(ext)
  await loadDatabase(ext, db)

  assertEquals(evaluateFlag(ext, "feature.one"), toU("first"))
  assertEquals(evaluateFlag(ext, "feature.two"), toU("default"))
  assertEquals(evaluateFlag(ext, "feature.three"), toU(42))
  assertEquals(evaluateFlag(ext, "nonexistent"), undefinedV)

  reset(ext)
})

// ─────────────────────────────────────────────────────────────────
// E2E Tests: Database Updates
// ─────────────────────────────────────────────────────────────────

testAsync("E2E: update database → re-evaluate → see new values", async () => {
  let ext = create()
  let db1 = singleton(
    "feature.beta",
    mkFlag(
      ~key="feature.beta",
      ~enabled=true,
      ~value=toU(false),
      ~defaultValue=toU(false),
    ),
  )
  await initialize(ext)
  await loadDatabase(ext, db1)
  assertStrictEquals(evaluateFlag(ext, "feature.beta"), toU(false))

  let db2 = singleton(
    "feature.beta",
    mkFlag(
      ~key="feature.beta",
      ~enabled=true,
      ~value=toU(true),
      ~defaultValue=toU(false),
    ),
  )
  await updateDatabase(ext, db2)
  assertStrictEquals(evaluateFlag(ext, "feature.beta"), toU(true))

  reset(ext)
})

testAsync("E2E: database update tracks changes", async () => {
  let ext = create()
  let db1 = Dict.make()
  Dict.set(
    db1,
    "feature.a",
    mkFlag(~key="feature.a", ~enabled=true, ~value=toU(1), ~defaultValue=toU(0)),
  )
  Dict.set(
    db1,
    "feature.b",
    mkFlag(~key="feature.b", ~enabled=true, ~value=toU(2), ~defaultValue=toU(0)),
  )

  await initialize(ext)
  await loadDatabase(ext, db1)

  let db2 = Dict.make()
  Dict.set(
    db2,
    "feature.a",
    mkFlag(~key="feature.a", ~enabled=true, ~value=toU(100), ~defaultValue=toU(0)),
  )
  Dict.set(
    db2,
    "feature.b",
    mkFlag(~key="feature.b", ~enabled=true, ~value=toU(2), ~defaultValue=toU(0)),
  )
  Dict.set(
    db2,
    "feature.c",
    mkFlag(~key="feature.c", ~enabled=true, ~value=toU(3), ~defaultValue=toU(0)),
  )

  await updateDatabase(ext, db2)
  let history = getChangeHistory(ext)
  assertEquals(Array.length(history) >= 2, true)
  assertEquals(history->Array.some(h => h.key == "feature.a"), true)
  assertEquals(history->Array.some(h => h.key == "feature.c"), true)

  reset(ext)
})

// ─────────────────────────────────────────────────────────────────
// E2E Tests: DevTools Panel
// ─────────────────────────────────────────────────────────────────

testAsync("E2E: open DevTools panel", async () => {
  let ext = create()
  let db = singleton(
    "feature.test",
    mkFlag(~key="feature.test", ~enabled=true, ~value=toU(true), ~defaultValue=toU(false)),
  )
  await initialize(ext)
  await loadDatabase(ext, db)
  assertEquals(ext.devToolsPanel.visible, false)
  await openDevToolsPanel(ext)
  assertEquals(ext.devToolsPanel.visible, true)
  assertEquals(Array.length(ext.devToolsPanel.flags), 1)
  reset(ext)
})

testAsync("E2E: DevTools inspect flag", async () => {
  let ext = create()
  let db = Dict.make()
  Dict.set(
    db,
    "privacy.tracking",
    mkFlag(
      ~key="privacy.tracking",
      ~enabled=true,
      ~value=toU(false),
      ~defaultValue=toU(true),
    ),
  )
  Dict.set(
    db,
    "perf.cache",
    mkFlag(
      ~key="perf.cache",
      ~enabled=false,
      ~value=toU(true),
      ~defaultValue=toU(false),
    ),
  )
  await initialize(ext)
  await loadDatabase(ext, db)
  await openDevToolsPanel(ext)
  inspectFlag(ext, "privacy.tracking")
  assertEquals(ext.devToolsPanel.selectedFlag, Some("privacy.tracking"))
  reset(ext)
})

testAsync("E2E: DevTools list all flags", async () => {
  let ext = create()
  let db = Dict.make()
  Dict.set(
    db,
    "privacy.tracking",
    mkFlag(
      ~key="privacy.tracking",
      ~enabled=true,
      ~value=toU(false),
      ~defaultValue=toU(true),
    ),
  )
  Dict.set(
    db,
    "privacy.cookies",
    mkFlag(
      ~key="privacy.cookies",
      ~enabled=true,
      ~value=toU(false),
      ~defaultValue=toU(true),
    ),
  )
  Dict.set(
    db,
    "perf.cache",
    mkFlag(
      ~key="perf.cache",
      ~enabled=false,
      ~value=toU(true),
      ~defaultValue=toU(false),
    ),
  )
  await initialize(ext)
  await loadDatabase(ext, db)
  await openDevToolsPanel(ext)
  assertEquals(Array.length(ext.devToolsPanel.flags), 3)
  reset(ext)
})

testAsync("E2E: DevTools count matches", async () => {
  let ext = create()
  let db = Dict.make()
  Dict.set(
    db,
    "privacy.tracking",
    mkFlag(
      ~key="privacy.tracking",
      ~enabled=true,
      ~value=toU(false),
      ~defaultValue=toU(true),
    ),
  )
  Dict.set(
    db,
    "privacy.cookies",
    mkFlag(
      ~key="privacy.cookies",
      ~enabled=true,
      ~value=toU(false),
      ~defaultValue=toU(true),
    ),
  )
  Dict.set(
    db,
    "perf.cache",
    mkFlag(
      ~key="perf.cache",
      ~enabled=false,
      ~value=toU(true),
      ~defaultValue=toU(false),
    ),
  )
  Dict.set(
    db,
    "perf.network",
    mkFlag(
      ~key="perf.network",
      ~enabled=true,
      ~value=toU(true),
      ~defaultValue=toU(false),
    ),
  )
  await initialize(ext)
  await loadDatabase(ext, db)

  let enabledCount = countFlags(ext, f => f.enabled)
  assertEquals(enabledCount, 3)
  let privacyFlags = getFlagsByCategory(ext, "privacy")
  assertEquals(Array.length(privacyFlags), 2)
  let perfFlags = getFlagsByCategory(ext, "perf")
  assertEquals(Array.length(perfFlags), 2)

  reset(ext)
})

// ─────────────────────────────────────────────────────────────────
// E2E Tests: Flag Change Notifications
// ─────────────────────────────────────────────────────────────────

testAsync("E2E: flag changed → extension notified → state updated", async () => {
  let ext = create()
  let db = singleton(
    "feature.experimental",
    mkFlag(
      ~key="feature.experimental",
      ~enabled=true,
      ~value=toU(false),
      ~defaultValue=toU(false),
    ),
  )
  await initialize(ext)
  await loadDatabase(ext, db)
  assertEquals(evaluateFlag(ext, "feature.experimental"), toU(false))

  notifyFlagChanged(ext, "feature.experimental", toU(true))
  assertEquals(evaluateFlag(ext, "feature.experimental"), toU(true))

  let history = getChangeHistory(ext)
  assertEquals(history->Array.some(h => h.key == "feature.experimental"), true)
  reset(ext)
})

testAsync("E2E: multiple flag changes tracked", async () => {
  let ext = create()
  let db = Dict.make()
  Dict.set(
    db,
    "flag.a",
    mkFlag(~key="flag.a", ~enabled=true, ~value=toU(1), ~defaultValue=toU(0)),
  )
  Dict.set(
    db,
    "flag.b",
    mkFlag(~key="flag.b", ~enabled=true, ~value=toU(2), ~defaultValue=toU(0)),
  )
  Dict.set(
    db,
    "flag.c",
    mkFlag(~key="flag.c", ~enabled=true, ~value=toU(3), ~defaultValue=toU(0)),
  )
  await initialize(ext)
  await loadDatabase(ext, db)

  notifyFlagChanged(ext, "flag.a", toU(10))
  notifyFlagChanged(ext, "flag.b", toU(20))
  notifyFlagChanged(ext, "flag.c", toU(30))

  assertEquals(evaluateFlag(ext, "flag.a"), toU(10))
  assertEquals(evaluateFlag(ext, "flag.b"), toU(20))
  assertEquals(evaluateFlag(ext, "flag.c"), toU(30))

  let history = getChangeHistory(ext)
  assertEquals(Array.length(history), 3)
  reset(ext)
})

// ─────────────────────────────────────────────────────────────────
// E2E Tests: Complex Workflows
// ─────────────────────────────────────────────────────────────────

testAsync("E2E: complete workflow: init → load → devtools → update → verify", async () => {
  let ext = create()

  // 1. Initialize
  await initialize(ext)
  assertExists(ext.state.initialized)

  // 2. Load initial database
  let db1 = Dict.make()
  Dict.set(
    db1,
    "feature.alpha",
    mkFlag(
      ~key="feature.alpha",
      ~enabled=true,
      ~value=toU("v1"),
      ~defaultValue=toU("default"),
    ),
  )
  Dict.set(
    db1,
    "feature.beta",
    mkFlag(
      ~key="feature.beta",
      ~enabled=false,
      ~value=toU("v2"),
      ~defaultValue=toU("disabled"),
    ),
  )
  await loadDatabase(ext, db1)
  assertEquals(Array.length(Dict.keysToArray(ext.state.database)), 2)

  // 3. Evaluate flags
  assertEquals(evaluateFlag(ext, "feature.alpha"), toU("v1"))
  assertEquals(evaluateFlag(ext, "feature.beta"), toU("disabled"))

  // 4. Open DevTools and inspect
  await openDevToolsPanel(ext)
  assertEquals(ext.devToolsPanel.visible, true)
  assertEquals(Array.length(ext.devToolsPanel.flags), 2)
  inspectFlag(ext, "feature.alpha")
  assertEquals(ext.devToolsPanel.selectedFlag, Some("feature.alpha"))

  // 5. Update database
  let db2 = Dict.make()
  Dict.set(
    db2,
    "feature.alpha",
    mkFlag(
      ~key="feature.alpha",
      ~enabled=true,
      ~value=toU("v1-updated"),
      ~defaultValue=toU("default"),
    ),
  )
  Dict.set(
    db2,
    "feature.beta",
    mkFlag(
      ~key="feature.beta",
      ~enabled=true,
      ~value=toU("v2-updated"),
      ~defaultValue=toU("disabled"),
    ),
  )
  Dict.set(
    db2,
    "feature.gamma",
    mkFlag(
      ~key="feature.gamma",
      ~enabled=true,
      ~value=toU("v3"),
      ~defaultValue=toU("default"),
    ),
  )
  await updateDatabase(ext, db2)

  // 6. Verify changes reflected
  assertEquals(evaluateFlag(ext, "feature.alpha"), toU("v1-updated"))
  assertEquals(evaluateFlag(ext, "feature.beta"), toU("v2-updated"))
  assertEquals(evaluateFlag(ext, "feature.gamma"), toU("v3"))

  // 7. Verify DevTools updated
  let updatedFlags = getAllFlags(ext)
  assertEquals(Array.length(updatedFlags), 3)

  reset(ext)
})
