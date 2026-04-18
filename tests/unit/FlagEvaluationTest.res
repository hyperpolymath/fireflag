// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//
// Unit tests for flag evaluation logic.
//
// Tests the core feature flag evaluation contract:
//   - Enabled flag returns its value
//   - Disabled flag returns default/fallback
//   - Missing flag returns undefined (not crash)
//   - Environment filtering (flag availability per environment)
//   - Override values take precedence over defaults
//
// Transpiled from tests/unit/flag_evaluation_test.ts (2026-04-18).

open Bindings

// ─────────────────────────────────────────────────────────────────
// Heterogeneous value type — TS used `unknown`.  We model it with
// an abstract type + identity coercions, which costs nothing at
// runtime (the compiler emits the value unchanged) while letting
// the ReScript typechecker stay out of the way for tests that
// intermix booleans, strings, and numbers in one database.
// ─────────────────────────────────────────────────────────────────

type unknown

external toU: 'a => unknown = "%identity"
external fromU: unknown => 'a = "%identity"

let undefinedV: unknown = %raw(`undefined`)

// ─────────────────────────────────────────────────────────────────
// Type definitions (mirror the TS interfaces).
// ─────────────────────────────────────────────────────────────────

type environment =
  | @as("production") Production
  | @as("staging") Staging
  | @as("development") Development
  | @as("test") TestEnv

type flag = {
  key: string,
  enabled: bool,
  value: unknown,
  defaultValue: unknown,
  environment: option<environment>,
  requiredEnvironments: option<array<environment>>,
  overrides: option<Dict.t<unknown>>,
}

type flagContext = {
  currentEnvironment: environment,
  userId: option<string>,
  userAttributes: option<Dict.t<unknown>>,
}

type flagDatabase = Dict.t<flag>

// ─────────────────────────────────────────────────────────────────
// Evaluation Engine
// ─────────────────────────────────────────────────────────────────

let evaluateFlag = (flagId: string, database: flagDatabase, context: flagContext): unknown => {
  switch Dict.get(database, flagId) {
  | None => undefinedV // Missing flag returns undefined
  | Some(flag) =>
    // Check environment filter
    let envOK = switch flag.requiredEnvironments {
    | Some(envs) when Array.length(envs) > 0 => envs->Array.includes(context.currentEnvironment)
    | _ => true
    }
    if !envOK {
      flag.defaultValue
    } else if !flag.enabled {
      flag.defaultValue
    } else {
      // Check for user-specific overrides
      switch (flag.overrides, context.userId) {
      | (Some(overrides), Some(uid)) =>
        switch Dict.get(overrides, uid) {
        | Some(v) => v
        | None => flag.value
        }
      | _ => flag.value
      }
    }
  }
}

let getAllFlags = (database: flagDatabase, context: flagContext): Dict.t<unknown> => {
  let result = Dict.make()
  Dict.keysToArray(database)->Array.forEach(key => {
    Dict.set(result, key, evaluateFlag(key, database, context))
  })
  result
}

let getFlagsByCategory = (
  database: flagDatabase,
  category: string,
  context: flagContext,
): Dict.t<unknown> => {
  let result = Dict.make()
  let prefix = category ++ "."
  Dict.keysToArray(database)->Array.forEach(key => {
    if key->String.startsWith(prefix) {
      Dict.set(result, key, evaluateFlag(key, database, context))
    }
  })
  result
}

// Convenience: build a flag with the "nullable" fields defaulted to None.
let mkFlag = (~key, ~enabled, ~value, ~defaultValue, ~reqEnvs=?, ~overrides=?, ()): flag => {
  key,
  enabled,
  value,
  defaultValue,
  environment: None,
  requiredEnvironments: reqEnvs,
  overrides,
}

let mkContext = (~env, ~userId=?, ()): flagContext => {
  currentEnvironment: env,
  userId,
  userAttributes: None,
}

let singleton = (key, flag) => {
  let d = Dict.make()
  Dict.set(d, key, flag)
  d
}

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Enabled Flag Returns Value
// ─────────────────────────────────────────────────────────────────

test("Flag evaluation: enabled boolean flag returns its value", () => {
  let db = singleton(
    "privacy.tracking",
    mkFlag(
      ~key="privacy.tracking",
      ~enabled=true,
      ~value=toU(true),
      ~defaultValue=toU(false),
      (),
    ),
  )
  let context = mkContext(~env=Production, ())
  let result = evaluateFlag("privacy.tracking", db, context)
  assertStrictEquals(result, toU(true))
})

test("Flag evaluation: enabled string flag returns its value", () => {
  let db = singleton(
    "feature.mode",
    mkFlag(
      ~key="feature.mode",
      ~enabled=true,
      ~value=toU("fast"),
      ~defaultValue=toU("standard"),
      (),
    ),
  )
  let result = evaluateFlag("feature.mode", db, mkContext(~env=Production, ()))
  assertStrictEquals(result, toU("fast"))
})

test("Flag evaluation: enabled numeric flag returns its value", () => {
  let db = singleton(
    "perf.timeout",
    mkFlag(
      ~key="perf.timeout",
      ~enabled=true,
      ~value=toU(5000),
      ~defaultValue=toU(3000),
      (),
    ),
  )
  let result = evaluateFlag("perf.timeout", db, mkContext(~env=Production, ()))
  assertStrictEquals(result, toU(5000))
})

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Disabled Flag Returns Default
// ─────────────────────────────────────────────────────────────────

test("Flag evaluation: disabled flag returns default value", () => {
  let db = singleton(
    "feature.new",
    mkFlag(
      ~key="feature.new",
      ~enabled=false,
      ~value=toU(true),
      ~defaultValue=toU(false),
      (),
    ),
  )
  let result = evaluateFlag("feature.new", db, mkContext(~env=Production, ()))
  assertStrictEquals(result, toU(false))
})

test("Flag evaluation: disabled flag ignores its value", () => {
  let db = singleton(
    "feature.experimental",
    mkFlag(
      ~key="feature.experimental",
      ~enabled=false,
      ~value=toU("enabled-value"),
      ~defaultValue=toU("disabled-value"),
      (),
    ),
  )
  let result = evaluateFlag("feature.experimental", db, mkContext(~env=Production, ()))
  assertStrictEquals(result, toU("disabled-value"))
})

test("Flag evaluation: disabled numeric flag returns default", () => {
  let db = singleton(
    "perf.workers",
    mkFlag(~key="perf.workers", ~enabled=false, ~value=toU(4), ~defaultValue=toU(1), ()),
  )
  let result = evaluateFlag("perf.workers", db, mkContext(~env=Production, ()))
  assertStrictEquals(result, toU(1))
})

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Missing Flag Handling
// ─────────────────────────────────────────────────────────────────

test("Flag evaluation: missing flag returns undefined (no crash)", () => {
  let db = Dict.make()
  let result = evaluateFlag("nonexistent.flag", db, mkContext(~env=Production, ()))
  assertStrictEquals(result, undefinedV)
})

test("Flag evaluation: missing flag does not throw", () => {
  let db = Dict.make()
  let context = mkContext(~env=Production, ())
  try {
    let result = evaluateFlag("nonexistent.flag", db, context)
    assertEquals(result, undefinedV)
  } catch {
  | _ => Js.Exn.raiseError("Flag evaluation should not throw for missing flag")
  }
})

test("Flag evaluation: graceful handling of undefined in database", () => {
  let db = Dict.make()
  let context = mkContext(~env=Production, ())
  for i in 0 to 99 {
    let result = evaluateFlag("flag." ++ Int.toString(i), db, context)
    assertStrictEquals(result, undefinedV)
  }
})

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Environment Filtering
// ─────────────────────────────────────────────────────────────────

test("Flag evaluation: environment filter - prod only flag not in dev", () => {
  let db = singleton(
    "feature.prod-only",
    mkFlag(
      ~key="feature.prod-only",
      ~enabled=true,
      ~value=toU(true),
      ~defaultValue=toU(false),
      ~reqEnvs=[Production],
      (),
    ),
  )
  let prodResult = evaluateFlag("feature.prod-only", db, mkContext(~env=Production, ()))
  assertStrictEquals(prodResult, toU(true))
  let devResult = evaluateFlag("feature.prod-only", db, mkContext(~env=Development, ()))
  assertStrictEquals(devResult, toU(false))
})

test("Flag evaluation: environment filter allows multiple environments", () => {
  let db = singleton(
    "feature.staging-prod",
    mkFlag(
      ~key="feature.staging-prod",
      ~enabled=true,
      ~value=toU(true),
      ~defaultValue=toU(false),
      ~reqEnvs=[Production, Staging],
      (),
    ),
  )
  let cases = [(Production, true), (Staging, true), (Development, false), (TestEnv, false)]
  cases->Array.forEach(((env, expected)) => {
    let result = evaluateFlag("feature.staging-prod", db, mkContext(~env, ()))
    assertStrictEquals(result, toU(expected))
  })
})

test("Flag evaluation: no environment restriction means all environments", () => {
  let db = singleton(
    "feature.all-envs",
    mkFlag(
      ~key="feature.all-envs",
      ~enabled=true,
      ~value=toU("available"),
      ~defaultValue=toU("default"),
      (),
    ),
  )
  let envs = [Production, Staging, Development, TestEnv]
  envs->Array.forEach(env => {
    let result = evaluateFlag("feature.all-envs", db, mkContext(~env, ()))
    assertStrictEquals(result, toU("available"))
  })
})

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Override Precedence
// ─────────────────────────────────────────────────────────────────

test("Flag evaluation: override takes precedence over value", () => {
  let overrides = Dict.make()
  Dict.set(overrides, "user-123", toU("user-specific-value"))
  let db = singleton(
    "feature.customized",
    mkFlag(
      ~key="feature.customized",
      ~enabled=true,
      ~value=toU("default-value"),
      ~defaultValue=toU("fallback"),
      ~overrides=overrides,
      (),
    ),
  )

  // Without user context
  let noUser = evaluateFlag("feature.customized", db, mkContext(~env=Production, ()))
  assertStrictEquals(noUser, toU("default-value"))

  // With user in overrides
  let user123 = evaluateFlag(
    "feature.customized",
    db,
    mkContext(~env=Production, ~userId="user-123", ()),
  )
  assertStrictEquals(user123, toU("user-specific-value"))

  // With different user (no override)
  let user456 = evaluateFlag(
    "feature.customized",
    db,
    mkContext(~env=Production, ~userId="user-456", ()),
  )
  assertStrictEquals(user456, toU("default-value"))
})

test("Flag evaluation: multiple overrides for different users", () => {
  let overrides = Dict.make()
  Dict.set(overrides, "user-a", toU(true))
  Dict.set(overrides, "user-b", toU(true))
  Dict.set(overrides, "user-c", toU(false))
  let db = singleton(
    "feature.user-specific",
    mkFlag(
      ~key="feature.user-specific",
      ~enabled=true,
      ~value=toU(false),
      ~defaultValue=toU(false),
      ~overrides=overrides,
      (),
    ),
  )

  let users = [("user-a", true), ("user-b", true), ("user-c", false), ("user-d", false)]
  users->Array.forEach(((id, expected)) => {
    let result = evaluateFlag(
      "feature.user-specific",
      db,
      mkContext(~env=Production, ~userId=id, ()),
    )
    assertStrictEquals(result, toU(expected))
  })
})

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Multi-Flag Operations
// ─────────────────────────────────────────────────────────────────

test("Flag evaluation: get all flags in database", () => {
  let db = Dict.make()
  Dict.set(
    db,
    "feature.one",
    mkFlag(~key="feature.one", ~enabled=true, ~value=toU(1), ~defaultValue=toU(0), ()),
  )
  Dict.set(
    db,
    "feature.two",
    mkFlag(~key="feature.two", ~enabled=false, ~value=toU(2), ~defaultValue=toU(20), ()),
  )
  Dict.set(
    db,
    "feature.three",
    mkFlag(~key="feature.three", ~enabled=true, ~value=toU(3), ~defaultValue=toU(30), ()),
  )

  let all = getAllFlags(db, mkContext(~env=Production, ()))
  assertEquals(Array.length(Dict.keysToArray(all)), 3)
  assertStrictEquals(Dict.get(all, "feature.one"), Some(toU(1)))
  assertStrictEquals(Dict.get(all, "feature.two"), Some(toU(20)))
  assertStrictEquals(Dict.get(all, "feature.three"), Some(toU(3)))
})

test("Flag evaluation: get flags by category", () => {
  let db = Dict.make()
  Dict.set(
    db,
    "privacy.tracking",
    mkFlag(
      ~key="privacy.tracking",
      ~enabled=true,
      ~value=toU(false),
      ~defaultValue=toU(true),
      (),
    ),
  )
  Dict.set(
    db,
    "privacy.cookies",
    mkFlag(
      ~key="privacy.cookies",
      ~enabled=false,
      ~value=toU(true),
      ~defaultValue=toU(false),
      (),
    ),
  )
  Dict.set(
    db,
    "perf.caching",
    mkFlag(
      ~key="perf.caching",
      ~enabled=true,
      ~value=toU(true),
      ~defaultValue=toU(false),
      (),
    ),
  )

  let privacyFlags = getFlagsByCategory(db, "privacy", mkContext(~env=Production, ()))
  assertEquals(Array.length(Dict.keysToArray(privacyFlags)), 2)
  assertStrictEquals(Dict.get(privacyFlags, "privacy.tracking"), Some(toU(false)))
  assertStrictEquals(Dict.get(privacyFlags, "privacy.cookies"), Some(toU(false)))
})

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Complex Scenarios
// ─────────────────────────────────────────────────────────────────

test("Flag evaluation: override + environment filter interaction", () => {
  let overrides = Dict.make()
  Dict.set(overrides, "user-vip", toU("vip-value"))
  let db = singleton(
    "feature.complex",
    mkFlag(
      ~key="feature.complex",
      ~enabled=true,
      ~value=toU("prod-value"),
      ~defaultValue=toU("default"),
      ~reqEnvs=[Production],
      ~overrides=overrides,
      (),
    ),
  )

  let vipProd = evaluateFlag(
    "feature.complex",
    db,
    mkContext(~env=Production, ~userId="user-vip", ()),
  )
  assertEquals(vipProd, toU("vip-value"))

  let regProd = evaluateFlag(
    "feature.complex",
    db,
    mkContext(~env=Production, ~userId="user-regular", ()),
  )
  assertEquals(regProd, toU("prod-value"))

  // VIP user in development (not in allowed environments)
  let vipDev = evaluateFlag(
    "feature.complex",
    db,
    mkContext(~env=Development, ~userId="user-vip", ()),
  )
  assertEquals(vipDev, toU("default"))
})

test("Flag evaluation: disabled flag ignores overrides", () => {
  let overrides = Dict.make()
  Dict.set(overrides, "user-123", toU("override-value"))
  let db = singleton(
    "feature.disabled-override",
    mkFlag(
      ~key="feature.disabled-override",
      ~enabled=false,
      ~value=toU("enabled-value"),
      ~defaultValue=toU("default-value"),
      ~overrides=overrides,
      (),
    ),
  )

  let result = evaluateFlag(
    "feature.disabled-override",
    db,
    mkContext(~env=Production, ~userId="user-123", ()),
  )
  assertStrictEquals(result, toU("default-value"))
})

test("Flag evaluation: batch evaluation of 100 flags", () => {
  let db = Dict.make()
  for i in 0 to 99 {
    Dict.set(
      db,
      "flag." ++ Int.toString(i),
      mkFlag(
        ~key="flag." ++ Int.toString(i),
        ~enabled=mod(i, 2) == 0,
        ~value=toU(i),
        ~defaultValue=toU(0),
        (),
      ),
    )
  }
  let all = getAllFlags(db, mkContext(~env=Production, ()))
  assertEquals(Array.length(Dict.keysToArray(all)), 100)
  for i in 0 to 99 {
    let expected = mod(i, 2) == 0 ? i : 0
    assertStrictEquals(
      Dict.get(all, "flag." ++ Int.toString(i)),
      Some(toU(expected)),
    )
  }
})
