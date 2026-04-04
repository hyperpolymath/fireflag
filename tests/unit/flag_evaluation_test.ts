// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

/**
 * Unit tests for flag evaluation logic
 *
 * Tests the core feature flag evaluation contract:
 * - Enabled flag returns its value
 * - Disabled flag returns default/fallback
 * - Missing flag returns undefined (not crash)
 * - Environment filtering (flag availability per environment)
 * - Override values take precedence over defaults
 */

import { assertEquals, assertStrictEquals } from "std/assert";

// Type definitions
interface Flag {
  key: string;
  enabled: boolean;
  value: unknown;
  defaultValue: unknown;
  environment?: "production" | "staging" | "development" | "test";
  requiredEnvironments?: Array<"production" | "staging" | "development" | "test">;
  overrides?: Record<string, unknown>;
}

interface FlagContext {
  currentEnvironment: "production" | "staging" | "development" | "test";
  userId?: string;
  userAttributes?: Record<string, unknown>;
}

type FlagDatabase = Record<string, Flag>;

// ─────────────────────────────────────────────────────────────────
// Evaluation Engine
// ─────────────────────────────────────────────────────────────────

function evaluateFlag(
  flagId: string,
  database: FlagDatabase,
  context: FlagContext
): unknown {
  const flag = database[flagId];

  // Missing flag returns undefined
  if (!flag) {
    return undefined;
  }

  // Check environment filter
  if (flag.requiredEnvironments && flag.requiredEnvironments.length > 0) {
    if (!flag.requiredEnvironments.includes(context.currentEnvironment)) {
      return flag.defaultValue;
    }
  }

  // Check if flag is enabled
  if (!flag.enabled) {
    return flag.defaultValue;
  }

  // Check for user-specific overrides
  if (flag.overrides && context.userId && context.userId in flag.overrides) {
    return flag.overrides[context.userId];
  }

  // Return flag value
  return flag.value;
}

function getAllFlags(
  database: FlagDatabase,
  context: FlagContext
): Record<string, unknown> {
  const result: Record<string, unknown> = {};

  for (const [key, flag] of Object.entries(database)) {
    result[key] = evaluateFlag(key, database, context);
  }

  return result;
}

function getFlagsByCategory(
  database: FlagDatabase,
  category: string,
  context: FlagContext
): Record<string, unknown> {
  const result: Record<string, unknown> = {};

  for (const [key, flag] of Object.entries(database)) {
    if (key.startsWith(`${category}.`)) {
      result[key] = evaluateFlag(key, database, context);
    }
  }

  return result;
}

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Enabled Flag Returns Value
// ─────────────────────────────────────────────────────────────────

Deno.test("Flag evaluation: enabled boolean flag returns its value", () => {
  const db: FlagDatabase = {
    "privacy.tracking": {
      key: "privacy.tracking",
      enabled: true,
      value: true,
      defaultValue: false,
    },
  };

  const context: FlagContext = { currentEnvironment: "production" };
  const result = evaluateFlag("privacy.tracking", db, context);

  assertStrictEquals(result, true);
});

Deno.test("Flag evaluation: enabled string flag returns its value", () => {
  const db: FlagDatabase = {
    "feature.mode": {
      key: "feature.mode",
      enabled: true,
      value: "fast",
      defaultValue: "standard",
    },
  };

  const context: FlagContext = { currentEnvironment: "production" };
  const result = evaluateFlag("feature.mode", db, context);

  assertStrictEquals(result, "fast");
});

Deno.test("Flag evaluation: enabled numeric flag returns its value", () => {
  const db: FlagDatabase = {
    "perf.timeout": {
      key: "perf.timeout",
      enabled: true,
      value: 5000,
      defaultValue: 3000,
    },
  };

  const context: FlagContext = { currentEnvironment: "production" };
  const result = evaluateFlag("perf.timeout", db, context);

  assertStrictEquals(result, 5000);
});

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Disabled Flag Returns Default
// ─────────────────────────────────────────────────────────────────

Deno.test("Flag evaluation: disabled flag returns default value", () => {
  const db: FlagDatabase = {
    "feature.new": {
      key: "feature.new",
      enabled: false,
      value: true,
      defaultValue: false,
    },
  };

  const context: FlagContext = { currentEnvironment: "production" };
  const result = evaluateFlag("feature.new", db, context);

  assertStrictEquals(result, false);
});

Deno.test("Flag evaluation: disabled flag ignores its value", () => {
  const db: FlagDatabase = {
    "feature.experimental": {
      key: "feature.experimental",
      enabled: false,
      value: "enabled-value",
      defaultValue: "disabled-value",
    },
  };

  const context: FlagContext = { currentEnvironment: "production" };
  const result = evaluateFlag("feature.experimental", db, context);

  assertStrictEquals(result, "disabled-value");
});

Deno.test("Flag evaluation: disabled numeric flag returns default", () => {
  const db: FlagDatabase = {
    "perf.workers": {
      key: "perf.workers",
      enabled: false,
      value: 4,
      defaultValue: 1,
    },
  };

  const context: FlagContext = { currentEnvironment: "production" };
  const result = evaluateFlag("perf.workers", db, context);

  assertStrictEquals(result, 1);
});

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Missing Flag Handling
// ─────────────────────────────────────────────────────────────────

Deno.test("Flag evaluation: missing flag returns undefined (no crash)", () => {
  const db: FlagDatabase = {};
  const context: FlagContext = { currentEnvironment: "production" };

  const result = evaluateFlag("nonexistent.flag", db, context);

  assertStrictEquals(result, undefined);
});

Deno.test("Flag evaluation: missing flag does not throw", () => {
  const db: FlagDatabase = {};
  const context: FlagContext = { currentEnvironment: "production" };

  try {
    const result = evaluateFlag("nonexistent.flag", db, context);
    assertEquals(result, undefined);
  } catch {
    throw new Error("Flag evaluation should not throw for missing flag");
  }
});

Deno.test("Flag evaluation: graceful handling of undefined in database", () => {
  const db: FlagDatabase = {};
  const context: FlagContext = { currentEnvironment: "production" };

  for (let i = 0; i < 100; i++) {
    const result = evaluateFlag(`flag.${i}`, db, context);
    assertStrictEquals(result, undefined);
  }
});

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Environment Filtering
// ─────────────────────────────────────────────────────────────────

Deno.test("Flag evaluation: environment filter - prod only flag not in dev", () => {
  const db: FlagDatabase = {
    "feature.prod-only": {
      key: "feature.prod-only",
      enabled: true,
      value: true,
      defaultValue: false,
      requiredEnvironments: ["production"],
    },
  };

  const devContext: FlagContext = { currentEnvironment: "development" };
  const prodContext: FlagContext = { currentEnvironment: "production" };

  // In production, should get the enabled value
  const prodResult = evaluateFlag("feature.prod-only", db, prodContext);
  assertStrictEquals(prodResult, true);

  // In development, should get the default value
  const devResult = evaluateFlag("feature.prod-only", db, devContext);
  assertStrictEquals(devResult, false);
});

Deno.test("Flag evaluation: environment filter allows multiple environments", () => {
  const db: FlagDatabase = {
    "feature.staging-prod": {
      key: "feature.staging-prod",
      enabled: true,
      value: true,
      defaultValue: false,
      requiredEnvironments: ["production", "staging"],
    },
  };

  const contexts = [
    { env: "production" as const, expected: true },
    { env: "staging" as const, expected: true },
    { env: "development" as const, expected: false },
    { env: "test" as const, expected: false },
  ];

  for (const { env, expected } of contexts) {
    const context: FlagContext = { currentEnvironment: env };
    const result = evaluateFlag("feature.staging-prod", db, context);
    assertStrictEquals(
      result,
      expected,
      `Failed for environment: ${env}`
    );
  }
});

Deno.test("Flag evaluation: no environment restriction means all environments", () => {
  const db: FlagDatabase = {
    "feature.all-envs": {
      key: "feature.all-envs",
      enabled: true,
      value: "available",
      defaultValue: "default",
      // No requiredEnvironments
    },
  };

  const environments: Array<"production" | "staging" | "development" | "test"> =
    ["production", "staging", "development", "test"];

  for (const env of environments) {
    const context: FlagContext = { currentEnvironment: env };
    const result = evaluateFlag("feature.all-envs", db, context);
    assertStrictEquals(result, "available", `Failed for environment: ${env}`);
  }
});

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Override Precedence
// ─────────────────────────────────────────────────────────────────

Deno.test("Flag evaluation: override takes precedence over value", () => {
  const db: FlagDatabase = {
    "feature.customized": {
      key: "feature.customized",
      enabled: true,
      value: "default-value",
      defaultValue: "fallback",
      overrides: {
        "user-123": "user-specific-value",
      },
    },
  };

  // Without user context
  const noUserContext: FlagContext = { currentEnvironment: "production" };
  const noUserResult = evaluateFlag("feature.customized", db, noUserContext);
  assertStrictEquals(noUserResult, "default-value");

  // With user in overrides
  const userContext: FlagContext = {
    currentEnvironment: "production",
    userId: "user-123",
  };
  const userResult = evaluateFlag("feature.customized", db, userContext);
  assertStrictEquals(userResult, "user-specific-value");

  // With different user (no override)
  const otherUserContext: FlagContext = {
    currentEnvironment: "production",
    userId: "user-456",
  };
  const otherResult = evaluateFlag("feature.customized", db, otherUserContext);
  assertStrictEquals(otherResult, "default-value");
});

Deno.test("Flag evaluation: multiple overrides for different users", () => {
  const db: FlagDatabase = {
    "feature.user-specific": {
      key: "feature.user-specific",
      enabled: true,
      value: false,
      defaultValue: false,
      overrides: {
        "user-a": true,
        "user-b": true,
        "user-c": false,
      },
    },
  };

  const users = [
    { id: "user-a", expected: true },
    { id: "user-b", expected: true },
    { id: "user-c", expected: false },
    { id: "user-d", expected: false },
  ];

  for (const { id, expected } of users) {
    const context: FlagContext = {
      currentEnvironment: "production",
      userId: id,
    };
    const result = evaluateFlag("feature.user-specific", db, context);
    assertStrictEquals(
      result,
      expected,
      `Failed for user: ${id}`
    );
  }
});

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Multi-Flag Operations
// ─────────────────────────────────────────────────────────────────

Deno.test("Flag evaluation: get all flags in database", () => {
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
      defaultValue: 20,
    },
    "feature.three": {
      key: "feature.three",
      enabled: true,
      value: 3,
      defaultValue: 30,
    },
  };

  const context: FlagContext = { currentEnvironment: "production" };
  const all = getAllFlags(db, context);

  assertEquals(Object.keys(all).length, 3);
  assertStrictEquals(all["feature.one"], 1);
  assertStrictEquals(all["feature.two"], 20);
  assertStrictEquals(all["feature.three"], 3);
});

Deno.test("Flag evaluation: get flags by category", () => {
  const db: FlagDatabase = {
    "privacy.tracking": {
      key: "privacy.tracking",
      enabled: true,
      value: false,
      defaultValue: true,
    },
    "privacy.cookies": {
      key: "privacy.cookies",
      enabled: false,
      value: true,
      defaultValue: false,
    },
    "perf.caching": {
      key: "perf.caching",
      enabled: true,
      value: true,
      defaultValue: false,
    },
  };

  const context: FlagContext = { currentEnvironment: "production" };
  const privacyFlags = getFlagsByCategory(db, "privacy", context);

  assertEquals(Object.keys(privacyFlags).length, 2);
  assertStrictEquals(privacyFlags["privacy.tracking"], false);
  assertStrictEquals(privacyFlags["privacy.cookies"], false);
});

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Complex Scenarios
// ─────────────────────────────────────────────────────────────────

Deno.test("Flag evaluation: override + environment filter interaction", () => {
  const db: FlagDatabase = {
    "feature.complex": {
      key: "feature.complex",
      enabled: true,
      value: "prod-value",
      defaultValue: "default",
      requiredEnvironments: ["production"],
      overrides: {
        "user-vip": "vip-value",
      },
    },
  };

  // VIP user in production
  const vipProdContext: FlagContext = {
    currentEnvironment: "production",
    userId: "user-vip",
  };
  assertEquals(
    evaluateFlag("feature.complex", db, vipProdContext),
    "vip-value"
  );

  // Regular user in production
  const userProdContext: FlagContext = {
    currentEnvironment: "production",
    userId: "user-regular",
  };
  assertEquals(
    evaluateFlag("feature.complex", db, userProdContext),
    "prod-value"
  );

  // VIP user in development (not in allowed environments)
  const vipDevContext: FlagContext = {
    currentEnvironment: "development",
    userId: "user-vip",
  };
  assertEquals(
    evaluateFlag("feature.complex", db, vipDevContext),
    "default"
  );
});

Deno.test("Flag evaluation: disabled flag ignores overrides", () => {
  const db: FlagDatabase = {
    "feature.disabled-override": {
      key: "feature.disabled-override",
      enabled: false,
      value: "enabled-value",
      defaultValue: "default-value",
      overrides: {
        "user-123": "override-value",
      },
    },
  };

  const context: FlagContext = {
    currentEnvironment: "production",
    userId: "user-123",
  };

  // Even with override, disabled flag returns default
  const result = evaluateFlag("feature.disabled-override", db, context);
  assertStrictEquals(result, "default-value");
});

Deno.test("Flag evaluation: batch evaluation of 100 flags", () => {
  const db: FlagDatabase = {};
  for (let i = 0; i < 100; i++) {
    db[`flag.${i}`] = {
      key: `flag.${i}`,
      enabled: i % 2 === 0,
      value: i,
      defaultValue: 0,
    };
  }

  const context: FlagContext = { currentEnvironment: "production" };
  const all = getAllFlags(db, context);

  assertEquals(Object.keys(all).length, 100);

  // Verify pattern
  for (let i = 0; i < 100; i++) {
    const expected = i % 2 === 0 ? i : 0;
    assertStrictEquals(
      all[`flag.${i}`],
      expected,
      `Failed for flag.${i}`
    );
  }
});
