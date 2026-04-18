// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//
// Bindings for the Deno test runtime and the `std/assert` module used by
// the fireflag test suites.  The paths `"std/assert"` and `"std/testing/..."`
// are resolved via the import map in `deno.json`.
//
// Kept terse — each binding is the minimum surface the test suites use.

// ── Deno.test ────────────────────────────────────────────────────────────

@scope("Deno") @val
external test: (string, unit => unit) => unit = "test"

@scope("Deno") @val
external testAsync: (string, unit => promise<unit>) => unit = "test"

// ── Deno.bench ───────────────────────────────────────────────────────────

@scope("Deno") @val
external bench: (string, unit => unit) => unit = "bench"

// ── std/assert ───────────────────────────────────────────────────────────

@module("std/assert")
external assertEquals: ('a, 'a) => unit = "assertEquals"

@module("std/assert")
external assertEqualsMsg: ('a, 'a, string) => unit = "assertEquals"

@module("std/assert")
external assertStrictEquals: ('a, 'a) => unit = "assertStrictEquals"

@module("std/assert")
external assertExists: 'a => unit = "assertExists"

@module("std/assert")
external assertNotEquals: ('a, 'a) => unit = "assertNotEquals"

@module("std/assert")
external assertThrows: (unit => 'a) => unit = "assertThrows"

@module("std/assert")
external assertThrowsMsg: (unit => 'a, string) => unit = "assertThrows"

@module("std/assert")
external assertMatch: (string, Js.Re.t) => unit = "assertMatch"

@module("std/assert")
external assertStringIncludes: (string, string) => unit = "assertStringIncludes"

@module("std/assert")
external assertRejects: (unit => promise<'a>) => promise<unit> = "assertRejects"

@module("std/assert")
external assert_: bool => unit = "assert"

@module("std/assert")
external assertMsg: (bool, string) => unit = "assert"

// ── std/testing/bdd (optional) ───────────────────────────────────────────

@module("std/testing/bdd.ts")
external describe: (string, unit => unit) => unit = "describe"

@module("std/testing/bdd.ts")
external it: (string, unit => unit) => unit = "it"
