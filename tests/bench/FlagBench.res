// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//
// Benchmarks for flag evaluation performance.
//
// Measures:
//   - Flag lookup in small database (10 flags)
//   - Flag lookup in large database (10,000 flags)
//   - Database serialization (100 flags)
//   - Database deserialization (100 flags)
//   - Flag evaluation with environment filtering
//
// Transpiled from tests/bench/flag_bench.ts (2026-04-18).

open Bindings

type unknown
external toU: 'a => unknown = "%identity"
let undefinedV: unknown = %raw(`undefined`)

type flag = {
  key: string,
  enabled: bool,
  value: unknown,
  defaultValue: unknown,
}

type flagDatabase = Dict.t<flag>

@scope("JSON") @val external stringify: 'a => string = "stringify"
@scope("JSON") @val external parse: string => 'a = "parse"

let evaluateFlag = (flagId, database: flagDatabase): unknown => {
  switch Dict.get(database, flagId) {
  | None => undefinedV
  | Some(flag) when !flag.enabled => flag.defaultValue
  | Some(flag) => flag.value
  }
}

let serializeDatabase = (db: flagDatabase): string => stringify(db)
let deserializeDatabase = (json: string): flagDatabase => parse(json)

let createSmallDatabase = (): flagDatabase => {
  let db = Dict.make()
  for i in 0 to 9 {
    Dict.set(
      db,
      "flag." ++ Int.toString(i),
      {
        key: "flag." ++ Int.toString(i),
        enabled: mod(i, 2) == 0,
        value: toU(i),
        defaultValue: toU(0),
      },
    )
  }
  db
}

let createMediumDatabase = (): flagDatabase => {
  let db = Dict.make()
  for i in 0 to 99 {
    Dict.set(
      db,
      "flag." ++ Int.toString(i),
      {
        key: "flag." ++ Int.toString(i),
        enabled: mod(i, 3) == 0,
        value: toU(i * 10),
        defaultValue: toU(0),
      },
    )
  }
  db
}

let createLargeDatabase = (): flagDatabase => {
  let db = Dict.make()
  for i in 0 to 9999 {
    Dict.set(
      db,
      "flag." ++ Int.toString(i),
      {
        key: "flag." ++ Int.toString(i),
        enabled: mod(i, 5) == 0,
        value: toU(i * 100),
        defaultValue: toU(0),
      },
    )
  }
  db
}

// ─────────────────────────────────────────────────────────────────
// Benchmarks: Small Database
// ─────────────────────────────────────────────────────────────────

bench("Bench: Flag lookup in 10-flag database (enabled)", () => {
  let db = createSmallDatabase()
  let _ = evaluateFlag("flag.0", db)
  let _ = evaluateFlag("flag.2", db)
  let _ = evaluateFlag("flag.4", db)
})

bench("Bench: Flag lookup in 10-flag database (disabled)", () => {
  let db = createSmallDatabase()
  let _ = evaluateFlag("flag.1", db)
  let _ = evaluateFlag("flag.3", db)
  let _ = evaluateFlag("flag.5", db)
})

bench("Bench: Flag lookup in 10-flag database (missing)", () => {
  let db = createSmallDatabase()
  let _ = evaluateFlag("nonexistent.0", db)
  let _ = evaluateFlag("nonexistent.1", db)
  let _ = evaluateFlag("nonexistent.2", db)
})

bench("Bench: Batch lookup 10 flags from 10-flag database", () => {
  let db = createSmallDatabase()
  for i in 0 to 9 {
    let _ = evaluateFlag("flag." ++ Int.toString(i), db)
  }
})

// ─────────────────────────────────────────────────────────────────
// Benchmarks: Medium Database
// ─────────────────────────────────────────────────────────────────

bench("Bench: Flag lookup in 100-flag database (early)", () => {
  let db = createMediumDatabase()
  let _ = evaluateFlag("flag.5", db)
})

bench("Bench: Flag lookup in 100-flag database (middle)", () => {
  let db = createMediumDatabase()
  let _ = evaluateFlag("flag.50", db)
})

bench("Bench: Flag lookup in 100-flag database (late)", () => {
  let db = createMediumDatabase()
  let _ = evaluateFlag("flag.95", db)
})

bench("Bench: Batch lookup 10 random flags from 100-flag database", () => {
  let db = createMediumDatabase()
  let indices = [5, 15, 25, 35, 45, 55, 65, 75, 85, 95]
  indices->Array.forEach(i => {
    let _ = evaluateFlag("flag." ++ Int.toString(i), db)
  })
})

bench("Bench: Batch lookup all flags from 100-flag database", () => {
  let db = createMediumDatabase()
  for i in 0 to 99 {
    let _ = evaluateFlag("flag." ++ Int.toString(i), db)
  }
})

// ─────────────────────────────────────────────────────────────────
// Benchmarks: Large Database
// ─────────────────────────────────────────────────────────────────

bench("Bench: Flag lookup in 10k-flag database (early)", () => {
  let db = createLargeDatabase()
  let _ = evaluateFlag("flag.100", db)
})

bench("Bench: Flag lookup in 10k-flag database (middle)", () => {
  let db = createLargeDatabase()
  let _ = evaluateFlag("flag.5000", db)
})

bench("Bench: Flag lookup in 10k-flag database (late)", () => {
  let db = createLargeDatabase()
  let _ = evaluateFlag("flag.9900", db)
})

bench("Bench: Batch lookup 100 flags from 10k-flag database", () => {
  let db = createLargeDatabase()
  let step = 100
  let i = ref(0)
  while i.contents < 10000 {
    let _ = evaluateFlag("flag." ++ Int.toString(i.contents), db)
    i := i.contents + step
  }
})

// ─────────────────────────────────────────────────────────────────
// Benchmarks: Serialization
// ─────────────────────────────────────────────────────────────────

bench("Bench: Serialize 100-flag database to JSON", () => {
  let db = createMediumDatabase()
  let _ = serializeDatabase(db)
})

bench("Bench: Deserialize 100-flag database from JSON", () => {
  let db = createMediumDatabase()
  let json = serializeDatabase(db)
  let _ = deserializeDatabase(json)
})

bench("Bench: Serialize + Deserialize 100-flag database", () => {
  let db = createMediumDatabase()
  let json = serializeDatabase(db)
  let _ = deserializeDatabase(json)
})

bench("Bench: Serialize 10k-flag database to JSON", () => {
  let db = createLargeDatabase()
  let _ = serializeDatabase(db)
})

bench("Bench: Deserialize 10k-flag database from JSON", () => {
  let db = createLargeDatabase()
  let json = serializeDatabase(db)
  let _ = deserializeDatabase(json)
})

// ─────────────────────────────────────────────────────────────────
// Benchmarks: Complex Operations
// ─────────────────────────────────────────────────────────────────

bench("Bench: Evaluate all flags in 100-flag database", () => {
  let db = createMediumDatabase()
  Dict.keysToArray(db)->Array.forEach(key => {
    let _ = evaluateFlag(key, db)
  })
})

bench("Bench: Evaluate all flags in 10k-flag database", () => {
  let db = createLargeDatabase()
  // Sample every 10th flag to keep bench time reasonable.
  let i = ref(0)
  while i.contents < 10000 {
    let _ = evaluateFlag("flag." ++ Int.toString(i.contents), db)
    i := i.contents + 10
  }
})

bench("Bench: Find enabled flags in 100-flag database", () => {
  let db = createMediumDatabase()
  let count = ref(0)
  Dict.valuesToArray(db)->Array.forEach(flag => {
    if flag.enabled {
      count := count.contents + 1
    }
  })
})

bench("Bench: Filter by category (100 flags)", () => {
  let db = Dict.make()
  for i in 0 to 99 {
    let category = mod(i, 5) == 0 ? "privacy" : "perf"
    let key = category ++ ".flag" ++ Int.toString(i)
    Dict.set(
      db,
      key,
      {key, enabled: true, value: toU(i), defaultValue: toU(0)},
    )
  }

  let count = ref(0)
  Dict.keysToArray(db)->Array.forEach(key => {
    if key->String.startsWith("privacy.") {
      count := count.contents + 1
    }
  })
})

// ─────────────────────────────────────────────────────────────────
// Benchmarks: Memory & Creation
// ─────────────────────────────────────────────────────────────────

bench("Bench: Create 10-flag database", () => {
  let _ = createSmallDatabase()
})

bench("Bench: Create 100-flag database", () => {
  let _ = createMediumDatabase()
})

bench("Bench: Create 10k-flag database", () => {
  let _ = createLargeDatabase()
})

// ─────────────────────────────────────────────────────────────────
// Benchmarks: Stress Tests
// ─────────────────────────────────────────────────────────────────

bench("Bench: 1000 lookups in 10-flag database", () => {
  let db = createSmallDatabase()
  for i in 0 to 999 {
    let _ = evaluateFlag("flag." ++ Int.toString(mod(i, 10)), db)
  }
})

bench("Bench: 100 lookups in 10k-flag database", () => {
  let db = createLargeDatabase()
  for i in 0 to 99 {
    let flagNum = mod(i * 100, 10000)
    let _ = evaluateFlag("flag." ++ Int.toString(flagNum), db)
  }
})

bench("Bench: Sequential access pattern (100-flag db)", () => {
  let db = createMediumDatabase()
  for i in 0 to 99 {
    let _ = evaluateFlag("flag." ++ Int.toString(i), db)
  }
})

bench("Bench: Random access pattern (100-flag db)", () => {
  let db = createMediumDatabase()
  let seed = 42
  let rng = ref(seed)
  for _ in 0 to 99 {
    rng := land(rng.contents * 1103515245 + 12345, 0x7fffffff)
    let idx = mod(rng.contents, 100)
    let _ = evaluateFlag("flag." ++ Int.toString(idx), db)
  }
})
