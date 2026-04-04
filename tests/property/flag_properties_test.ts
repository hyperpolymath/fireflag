// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

/**
 * Property-based tests for flag evaluation
 *
 * Tests invariants that must ALWAYS hold:
 * - Evaluation is deterministic (same input → same output)
 * - Disabled flags NEVER return non-default values
 * - Flag IDs are always strings (never null/undefined)
 * - Serialization round-trips correctly
 */

import { assertEquals, assertStrictEquals, assertExists } from "std/assert";

// Type definitions
interface Flag {
  key: string;
  enabled: boolean;
  value: unknown;
  defaultValue: unknown;
}

type FlagDatabase = Record<string, Flag>;

// ─────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────

function evaluateFlag(
  flagId: string,
  database: FlagDatabase
): unknown {
  const flag = database[flagId];
  if (!flag) return undefined;
  if (!flag.enabled) return flag.defaultValue;
  return flag.value;
}

function serializeDatabase(db: FlagDatabase): string {
  return JSON.stringify(db);
}

function deserializeDatabase(json: string): FlagDatabase {
  return JSON.parse(json);
}

function deepEqual(a: unknown, b: unknown): boolean {
  if (a === b) return true;
  if (typeof a !== typeof b) return false;
  if (typeof a !== "object" || a === null || b === null) return false;

  const aObj = a as Record<string, unknown>;
  const bObj = b as Record<string, unknown>;
  const aKeys = Object.keys(aObj);
  const bKeys = Object.keys(bObj);

  if (aKeys.length !== bKeys.length) return false;

  for (const key of aKeys) {
    if (!deepEqual(aObj[key], bObj[key])) return false;
  }

  return true;
}

// ─────────────────────────────────────────────────────────────────
// Property Tests: Determinism
// ─────────────────────────────────────────────────────────────────

Deno.test("Property: flag evaluation is deterministic", () => {
  const db: FlagDatabase = {
    "feature.test": {
      key: "feature.test",
      enabled: true,
      value: 42,
      defaultValue: 0,
    },
  };

  // Evaluate same flag 100 times
  const results = [];
  for (let i = 0; i < 100; i++) {
    results.push(evaluateFlag("feature.test", db));
  }

  // All results must be identical
  const firstResult = results[0];
  for (const result of results) {
    assertStrictEquals(result, firstResult);
  }
});

Deno.test("Property: evaluation of disabled flag is deterministic", () => {
  const db: FlagDatabase = {
    "feature.disabled": {
      key: "feature.disabled",
      enabled: false,
      value: "should-not-return",
      defaultValue: "should-return",
    },
  };

  const results = [];
  for (let i = 0; i < 100; i++) {
    results.push(evaluateFlag("feature.disabled", db));
  }

  for (const result of results) {
    assertStrictEquals(result, "should-return");
  }
});

Deno.test("Property: evaluation of missing flag is deterministic", () => {
  const db: FlagDatabase = {};

  const results = [];
  for (let i = 0; i < 100; i++) {
    results.push(evaluateFlag("nonexistent.flag", db));
  }

  for (const result of results) {
    assertStrictEquals(result, undefined);
  }
});

// ─────────────────────────────────────────────────────────────────
// Property Tests: Disabled Flag Invariant
// ─────────────────────────────────────────────────────────────────

Deno.test("Property: disabled flag NEVER returns non-default value (invariant)", () => {
  const testCases = [
    { value: true, default: false },
    { value: 42, default: 0 },
    { value: "enabled", default: "disabled" },
    { value: { nested: "object" }, default: { nested: "default" } },
    { value: [1, 2, 3], default: [] },
  ];

  for (const testCase of testCases) {
    const db: FlagDatabase = {
      "feature.disabled": {
        key: "feature.disabled",
        enabled: false,
        value: testCase.value,
        defaultValue: testCase.default,
      },
    };

    const result = evaluateFlag("feature.disabled", db);

    // Must return default, never the value
    assertEquals(
      deepEqual(result, testCase.default),
      true,
      `Disabled flag returned non-default value`
    );
  }
});

Deno.test("Property: enabled flag always returns value when available", () => {
  const testCases = [
    true,
    false,
    0,
    42,
    -100,
    "string",
    "",
    { key: "value" },
    [1, 2, 3],
  ];

  for (const value of testCases) {
    const db: FlagDatabase = {
      "feature.enabled": {
        key: "feature.enabled",
        enabled: true,
        value: value,
        defaultValue: "default",
      },
    };

    const result = evaluateFlag("feature.enabled", db);
    assertEquals(deepEqual(result, value), true);
  }
});

// ─────────────────────────────────────────────────────────────────
// Property Tests: Flag ID Invariants
// ─────────────────────────────────────────────────────────────────

Deno.test("Property: flag ID is always a string in database", () => {
  const db: FlagDatabase = {
    "feature.one": {
      key: "feature.one",
      enabled: true,
      value: 1,
      defaultValue: 0,
    },
    "feature.two": {
      key: "feature.two",
      enabled: false,
      value: 2,
      defaultValue: 0,
    },
    "feature.three": {
      key: "feature.three",
      enabled: true,
      value: 3,
      defaultValue: 0,
    },
  };

  for (const [id, flag] of Object.entries(db)) {
    assertEquals(typeof id, "string");
    assertEquals(typeof flag.key, "string");
    assertExists(id);
    assertExists(flag.key);
  }
});

Deno.test("Property: flag key never contains null/undefined", () => {
  const db: FlagDatabase = {
    "privacy.tracking": {
      key: "privacy.tracking",
      enabled: true,
      value: false,
      defaultValue: true,
    },
    "perf.cache": {
      key: "perf.cache",
      enabled: false,
      value: true,
      defaultValue: false,
    },
  };

  for (const flag of Object.values(db)) {
    assertEquals(flag.key !== null && flag.key !== undefined, true);
    assertEquals(flag.key.length > 0, true);
  }
});

// ─────────────────────────────────────────────────────────────────
// Property Tests: Serialization Round-Trip
// ─────────────────────────────────────────────────────────────────

Deno.test("Property: database serialization round-trips correctly", () => {
  const original: FlagDatabase = {
    "feature.one": {
      key: "feature.one",
      enabled: true,
      value: 42,
      defaultValue: 0,
    },
    "feature.two": {
      key: "feature.two",
      enabled: false,
      value: "never-returned",
      defaultValue: "default",
    },
    "feature.three": {
      key: "feature.three",
      enabled: true,
      value: false,
      defaultValue: true,
    },
  };

  // Serialize
  const json = serializeDatabase(original);
  assertEquals(typeof json, "string");

  // Deserialize
  const restored = deserializeDatabase(json);

  // Verify all flags match
  for (const [id, originalFlag] of Object.entries(original)) {
    const restoredFlag = restored[id];
    assertExists(restoredFlag);
    assertEquals(restoredFlag.key, originalFlag.key);
    assertEquals(restoredFlag.enabled, originalFlag.enabled);
    assertEquals(deepEqual(restoredFlag.value, originalFlag.value), true);
    assertEquals(
      deepEqual(restoredFlag.defaultValue, originalFlag.defaultValue),
      true
    );
  }
});

Deno.test("Property: evaluation identical before/after serialization", () => {
  const original: FlagDatabase = {
    "feature.test": {
      key: "feature.test",
      enabled: true,
      value: "original-value",
      defaultValue: "default",
    },
  };

  // Evaluate before serialization
  const beforeResult = evaluateFlag("feature.test", original);

  // Serialize and deserialize
  const json = serializeDatabase(original);
  const restored = deserializeDatabase(json);

  // Evaluate after serialization
  const afterResult = evaluateFlag("feature.test", restored);

  // Results must be identical
  assertStrictEquals(afterResult, beforeResult);
});

Deno.test("Property: complex nested values round-trip correctly", () => {
  const complexValue = {
    nested: {
      deep: {
        array: [1, 2, 3],
        string: "value",
        bool: true,
      },
    },
  };

  const original: FlagDatabase = {
    "feature.complex": {
      key: "feature.complex",
      enabled: true,
      value: complexValue,
      defaultValue: { default: "value" },
    },
  };

  const json = serializeDatabase(original);
  const restored = deserializeDatabase(json);

  const originalResult = evaluateFlag("feature.complex", original);
  const restoredResult = evaluateFlag("feature.complex", restored);

  assertEquals(
    deepEqual(originalResult, restoredResult),
    true,
    "Complex nested values do not round-trip correctly"
  );
});

// ─────────────────────────────────────────────────────────────────
// Property Tests: Large-Scale Invariants
// ─────────────────────────────────────────────────────────────────

Deno.test("Property: 1000 flags maintain determinism", () => {
  const db: FlagDatabase = {};

  // Create 1000 flags
  for (let i = 0; i < 1000; i++) {
    db[`flag.${i}`] = {
      key: `flag.${i}`,
      enabled: i % 3 === 0, // 1/3 enabled
      value: i,
      defaultValue: 0,
    };
  }

  // Evaluate all flags twice
  const firstPass: Record<number, unknown> = {};
  const secondPass: Record<number, unknown> = {};

  for (let i = 0; i < 1000; i++) {
    firstPass[i] = evaluateFlag(`flag.${i}`, db);
    secondPass[i] = evaluateFlag(`flag.${i}`, db);
  }

  // Results must be identical
  for (let i = 0; i < 1000; i++) {
    assertStrictEquals(firstPass[i], secondPass[i]);
  }
});

Deno.test("Property: disabled flag invariant holds for 1000 flags", () => {
  const db: FlagDatabase = {};

  for (let i = 0; i < 1000; i++) {
    db[`flag.${i}`] = {
      key: `flag.${i}`,
      enabled: false,
      value: `value-${i}`,
      defaultValue: `default-${i}`,
    };
  }

  // Verify all disabled flags return their default
  for (let i = 0; i < 1000; i++) {
    const result = evaluateFlag(`flag.${i}`, db);
    assertStrictEquals(result, `default-${i}`);
  }
});

Deno.test("Property: large database serialization round-trip", () => {
  const db: FlagDatabase = {};

  // Create 500 flags
  for (let i = 0; i < 500; i++) {
    db[`flag.${i}`] = {
      key: `flag.${i}`,
      enabled: i % 2 === 0,
      value: { index: i, enabled: i % 2 === 0 },
      defaultValue: { index: i, enabled: false },
    };
  }

  // Serialize
  const json = serializeDatabase(db);

  // Deserialize
  const restored = deserializeDatabase(json);

  // Verify all flags
  let matches = 0;
  for (let i = 0; i < 500; i++) {
    const orig = evaluateFlag(`flag.${i}`, db);
    const rest = evaluateFlag(`flag.${i}`, restored);

    if (deepEqual(orig, rest)) {
      matches++;
    }
  }

  assertEquals(matches, 500, "Not all flags matched after round-trip");
});

// ─────────────────────────────────────────────────────────────────
// Property Tests: Edge Cases
// ─────────────────────────────────────────────────────────────────

Deno.test("Property: empty string flag ID returns undefined", () => {
  const db: FlagDatabase = {};

  const result = evaluateFlag("", db);
  assertStrictEquals(result, undefined);
});

Deno.test("Property: flag with null value (when enabled) returns null", () => {
  const db: FlagDatabase = {
    "feature.null-value": {
      key: "feature.null-value",
      enabled: true,
      value: null,
      defaultValue: "default",
    },
  };

  const result = evaluateFlag("feature.null-value", db);
  assertStrictEquals(result, null);
});

Deno.test("Property: flag with undefined default is accessible", () => {
  const db: FlagDatabase = {
    "feature.undefined-default": {
      key: "feature.undefined-default",
      enabled: false,
      value: "value",
      defaultValue: undefined,
    },
  };

  const result = evaluateFlag("feature.undefined-default", db);
  assertStrictEquals(result, undefined);
});

Deno.test("Property: boolean false values are preserved (not converted to falsy)", () => {
  const db: FlagDatabase = {
    "feature.bool-false": {
      key: "feature.bool-false",
      enabled: true,
      value: false,
      defaultValue: true,
    },
  };

  const result = evaluateFlag("feature.bool-false", db);
  assertStrictEquals(result, false);
  assertEquals(typeof result, "boolean");
});

Deno.test("Property: zero values are preserved (not converted to falsy)", () => {
  const db: FlagDatabase = {
    "feature.zero": {
      key: "feature.zero",
      enabled: true,
      value: 0,
      defaultValue: 100,
    },
  };

  const result = evaluateFlag("feature.zero", db);
  assertStrictEquals(result, 0);
});
