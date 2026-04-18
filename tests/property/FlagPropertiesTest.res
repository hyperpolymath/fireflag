// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//
// Property-based tests for flag evaluation.
//
// Tests invariants that must ALWAYS hold:
//   - Evaluation is deterministic (same input → same output)
//   - Disabled flags NEVER return non-default values
//   - Flag IDs are always strings (never null/undefined)
//   - Serialization round-trips correctly
//
// Transpiled from tests/property/flag_properties_test.ts (2026-04-18).

open Bindings

// ─────────────────────────────────────────────────────────────────
// Heterogeneous value type (see FlagEvaluationTest for rationale).
// ─────────────────────────────────────────────────────────────────

type unknown

external toU: 'a => unknown = "%identity"
external fromU: unknown => 'a = "%identity"

let undefinedV: unknown = %raw(`undefined`)
let nullV: unknown = %raw(`null`)

// ─────────────────────────────────────────────────────────────────
// Type definitions
// ─────────────────────────────────────────────────────────────────

type flag = {
  key: string,
  enabled: bool,
  value: unknown,
  defaultValue: unknown,
}

type flagDatabase = Dict.t<flag>

// ─────────────────────────────────────────────────────────────────
// Evaluation + serialization helpers
// ─────────────────────────────────────────────────────────────────

let evaluateFlag = (flagId, database: flagDatabase): unknown => {
  switch Dict.get(database, flagId) {
  | None => undefinedV
  | Some(flag) when !flag.enabled => flag.defaultValue
  | Some(flag) => flag.value
  }
}

@scope("JSON") @val external stringify: 'a => string = "stringify"
@scope("JSON") @val external parse: string => 'a = "parse"

let serializeDatabase = (db: flagDatabase): string => stringify(db)
let deserializeDatabase = (json: string): flagDatabase => parse(json)

// Runtime deep-equality matching the TS helper — same object-walk,
// identical treatment of primitives, arrays, and plain objects.
let rec deepEqual = (a: 'a, b: 'b): bool => {
  // Same JS value (===) — fast path.
  if %raw(`function(x,y){return x===y}`)(a, b) {
    true
  } else if Js.typeof(a) !== Js.typeof(b) {
    false
  } else if (
    Js.typeof(a) !== "object" ||
      %raw(`function(x){return x===null}`)(a) ||
      %raw(`function(x){return x===null}`)(b)
  ) {
    false
  } else {
    // Recursive structural compare over Object.keys.
    let aKeys: array<string> = %raw(`Object.keys`)(a)
    let bKeys: array<string> = %raw(`Object.keys`)(b)
    if Array.length(aKeys) !== Array.length(bKeys) {
      false
    } else {
      aKeys->Array.every(k => {
        let av: 'c = %raw(`function(o,k){return o[k]}`)(a, k)
        let bv: 'c = %raw(`function(o,k){return o[k]}`)(b, k)
        deepEqual(av, bv)
      })
    }
  }
}

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
// Property Tests: Determinism
// ─────────────────────────────────────────────────────────────────

test("Property: flag evaluation is deterministic", () => {
  let db = singleton(
    "feature.test",
    mkFlag(~key="feature.test", ~enabled=true, ~value=toU(42), ~defaultValue=toU(0)),
  )
  let results = []
  for _ in 0 to 99 {
    results->Array.push(evaluateFlag("feature.test", db))
  }
  let firstResult = results[0]->Option.getUnsafe
  results->Array.forEach(result => assertStrictEquals(result, firstResult))
})

test("Property: evaluation of disabled flag is deterministic", () => {
  let db = singleton(
    "feature.disabled",
    mkFlag(
      ~key="feature.disabled",
      ~enabled=false,
      ~value=toU("should-not-return"),
      ~defaultValue=toU("should-return"),
    ),
  )
  for _ in 0 to 99 {
    let result = evaluateFlag("feature.disabled", db)
    assertStrictEquals(result, toU("should-return"))
  }
})

test("Property: evaluation of missing flag is deterministic", () => {
  let db = Dict.make()
  for _ in 0 to 99 {
    let result = evaluateFlag("nonexistent.flag", db)
    assertStrictEquals(result, undefinedV)
  }
})

// ─────────────────────────────────────────────────────────────────
// Property Tests: Disabled Flag Invariant
// ─────────────────────────────────────────────────────────────────

test("Property: disabled flag NEVER returns non-default value (invariant)", () => {
  let cases = [
    (toU(true), toU(false)),
    (toU(42), toU(0)),
    (toU("enabled"), toU("disabled")),
    (toU({"nested": "object"}), toU({"nested": "default"})),
    (toU([1, 2, 3]), toU([])),
  ]
  cases->Array.forEach(((v, d)) => {
    let db = singleton(
      "feature.disabled",
      mkFlag(~key="feature.disabled", ~enabled=false, ~value=v, ~defaultValue=d),
    )
    let result = evaluateFlag("feature.disabled", db)
    assertEquals(deepEqual(result, d), true)
  })
})

test("Property: enabled flag always returns value when available", () => {
  let cases = [
    toU(true),
    toU(false),
    toU(0),
    toU(42),
    toU(-100),
    toU("string"),
    toU(""),
    toU({"key": "value"}),
    toU([1, 2, 3]),
  ]
  cases->Array.forEach(value => {
    let db = singleton(
      "feature.enabled",
      mkFlag(~key="feature.enabled", ~enabled=true, ~value, ~defaultValue=toU("default")),
    )
    let result = evaluateFlag("feature.enabled", db)
    assertEquals(deepEqual(result, value), true)
  })
})

// ─────────────────────────────────────────────────────────────────
// Property Tests: Flag ID Invariants
// ─────────────────────────────────────────────────────────────────

test("Property: flag ID is always a string in database", () => {
  let db = Dict.make()
  Dict.set(
    db,
    "feature.one",
    mkFlag(~key="feature.one", ~enabled=true, ~value=toU(1), ~defaultValue=toU(0)),
  )
  Dict.set(
    db,
    "feature.two",
    mkFlag(~key="feature.two", ~enabled=false, ~value=toU(2), ~defaultValue=toU(0)),
  )
  Dict.set(
    db,
    "feature.three",
    mkFlag(~key="feature.three", ~enabled=true, ~value=toU(3), ~defaultValue=toU(0)),
  )

  Dict.keysToArray(db)->Array.forEach(id => {
    let flag = Dict.get(db, id)->Option.getUnsafe
    assertEquals(Js.typeof(id), "string")
    assertEquals(Js.typeof(flag.key), "string")
    assertExists(id)
    assertExists(flag.key)
  })
})

test("Property: flag key never contains null/undefined", () => {
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
    mkFlag(~key="perf.cache", ~enabled=false, ~value=toU(true), ~defaultValue=toU(false)),
  )

  Dict.valuesToArray(db)->Array.forEach(flag => {
    // The ReScript type system already guarantees `key` is a string, but
    // we mirror the TS null/undefined guard to keep the assertion visible.
    let notNull = %raw(`function(x){return x!==null && x!==undefined}`)(flag.key)
    assertEquals(notNull, true)
    assertEquals(String.length(flag.key) > 0, true)
  })
})

// ─────────────────────────────────────────────────────────────────
// Property Tests: Serialization Round-Trip
// ─────────────────────────────────────────────────────────────────

test("Property: database serialization round-trips correctly", () => {
  let original = Dict.make()
  Dict.set(
    original,
    "feature.one",
    mkFlag(~key="feature.one", ~enabled=true, ~value=toU(42), ~defaultValue=toU(0)),
  )
  Dict.set(
    original,
    "feature.two",
    mkFlag(
      ~key="feature.two",
      ~enabled=false,
      ~value=toU("never-returned"),
      ~defaultValue=toU("default"),
    ),
  )
  Dict.set(
    original,
    "feature.three",
    mkFlag(
      ~key="feature.three",
      ~enabled=true,
      ~value=toU(false),
      ~defaultValue=toU(true),
    ),
  )

  let json = serializeDatabase(original)
  assertEquals(Js.typeof(json), "string")

  let restored = deserializeDatabase(json)
  Dict.keysToArray(original)->Array.forEach(id => {
    let o = Dict.get(original, id)->Option.getUnsafe
    let r = Dict.get(restored, id)->Option.getUnsafe
    assertExists(r)
    assertEquals(r.key, o.key)
    assertEquals(r.enabled, o.enabled)
    assertEquals(deepEqual(r.value, o.value), true)
    assertEquals(deepEqual(r.defaultValue, o.defaultValue), true)
  })
})

test("Property: evaluation identical before/after serialization", () => {
  let original = singleton(
    "feature.test",
    mkFlag(
      ~key="feature.test",
      ~enabled=true,
      ~value=toU("original-value"),
      ~defaultValue=toU("default"),
    ),
  )
  let beforeResult = evaluateFlag("feature.test", original)
  let json = serializeDatabase(original)
  let restored = deserializeDatabase(json)
  let afterResult = evaluateFlag("feature.test", restored)
  assertStrictEquals(afterResult, beforeResult)
})

test("Property: complex nested values round-trip correctly", () => {
  let complexValue = toU({
    "nested": {
      "deep": {
        "array": [1, 2, 3],
        "string": "value",
        "bool": true,
      },
    },
  })

  let original = singleton(
    "feature.complex",
    mkFlag(
      ~key="feature.complex",
      ~enabled=true,
      ~value=complexValue,
      ~defaultValue=toU({"default": "value"}),
    ),
  )

  let json = serializeDatabase(original)
  let restored = deserializeDatabase(json)

  let originalResult = evaluateFlag("feature.complex", original)
  let restoredResult = evaluateFlag("feature.complex", restored)

  assertEquals(deepEqual(originalResult, restoredResult), true)
})

// ─────────────────────────────────────────────────────────────────
// Property Tests: Large-Scale Invariants
// ─────────────────────────────────────────────────────────────────

test("Property: 1000 flags maintain determinism", () => {
  let db = Dict.make()
  for i in 0 to 999 {
    Dict.set(
      db,
      "flag." ++ Int.toString(i),
      mkFlag(
        ~key="flag." ++ Int.toString(i),
        ~enabled=mod(i, 3) == 0,
        ~value=toU(i),
        ~defaultValue=toU(0),
      ),
    )
  }

  let firstPass = Dict.make()
  let secondPass = Dict.make()
  for i in 0 to 999 {
    Dict.set(firstPass, Int.toString(i), evaluateFlag("flag." ++ Int.toString(i), db))
    Dict.set(secondPass, Int.toString(i), evaluateFlag("flag." ++ Int.toString(i), db))
  }
  for i in 0 to 999 {
    assertStrictEquals(
      Dict.get(firstPass, Int.toString(i)),
      Dict.get(secondPass, Int.toString(i)),
    )
  }
})

test("Property: disabled flag invariant holds for 1000 flags", () => {
  let db = Dict.make()
  for i in 0 to 999 {
    Dict.set(
      db,
      "flag." ++ Int.toString(i),
      mkFlag(
        ~key="flag." ++ Int.toString(i),
        ~enabled=false,
        ~value=toU("value-" ++ Int.toString(i)),
        ~defaultValue=toU("default-" ++ Int.toString(i)),
      ),
    )
  }
  for i in 0 to 999 {
    let result = evaluateFlag("flag." ++ Int.toString(i), db)
    assertStrictEquals(result, toU("default-" ++ Int.toString(i)))
  }
})

test("Property: large database serialization round-trip", () => {
  let db = Dict.make()
  for i in 0 to 499 {
    Dict.set(
      db,
      "flag." ++ Int.toString(i),
      mkFlag(
        ~key="flag." ++ Int.toString(i),
        ~enabled=mod(i, 2) == 0,
        ~value=toU({"index": i, "enabled": mod(i, 2) == 0}),
        ~defaultValue=toU({"index": i, "enabled": false}),
      ),
    )
  }
  let json = serializeDatabase(db)
  let restored = deserializeDatabase(json)
  let matches = ref(0)
  for i in 0 to 499 {
    let orig = evaluateFlag("flag." ++ Int.toString(i), db)
    let rest = evaluateFlag("flag." ++ Int.toString(i), restored)
    if deepEqual(orig, rest) {
      matches := matches.contents + 1
    }
  }
  assertEquals(matches.contents, 500)
})

// ─────────────────────────────────────────────────────────────────
// Property Tests: Edge Cases
// ─────────────────────────────────────────────────────────────────

test("Property: empty string flag ID returns undefined", () => {
  let db = Dict.make()
  let result = evaluateFlag("", db)
  assertStrictEquals(result, undefinedV)
})

test("Property: flag with null value (when enabled) returns null", () => {
  let db = singleton(
    "feature.null-value",
    mkFlag(
      ~key="feature.null-value",
      ~enabled=true,
      ~value=nullV,
      ~defaultValue=toU("default"),
    ),
  )
  let result = evaluateFlag("feature.null-value", db)
  assertStrictEquals(result, nullV)
})

test("Property: flag with undefined default is accessible", () => {
  let db = singleton(
    "feature.undefined-default",
    mkFlag(
      ~key="feature.undefined-default",
      ~enabled=false,
      ~value=toU("value"),
      ~defaultValue=undefinedV,
    ),
  )
  let result = evaluateFlag("feature.undefined-default", db)
  assertStrictEquals(result, undefinedV)
})

test("Property: boolean false values are preserved (not converted to falsy)", () => {
  let db = singleton(
    "feature.bool-false",
    mkFlag(
      ~key="feature.bool-false",
      ~enabled=true,
      ~value=toU(false),
      ~defaultValue=toU(true),
    ),
  )
  let result = evaluateFlag("feature.bool-false", db)
  assertStrictEquals(result, toU(false))
  assertEquals(Js.typeof(result), "boolean")
})

test("Property: zero values are preserved (not converted to falsy)", () => {
  let db = singleton(
    "feature.zero",
    mkFlag(~key="feature.zero", ~enabled=true, ~value=toU(0), ~defaultValue=toU(100)),
  )
  let result = evaluateFlag("feature.zero", db)
  assertStrictEquals(result, toU(0))
})
