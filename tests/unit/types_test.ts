// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

/**
 * Unit tests for FireFlag core type definitions
 *
 * Tests the feature flag type system to ensure:
 * - Flag IDs are non-empty strings
 * - Flag values support boolean, string, number types
 * - Flag configurations have required fields
 * - Flag database structure is valid
 * - Environment values are properly defined
 */

import { assertEquals, assertExists, assertThrows } from "std/assert";

// Core type definitions (matching ReScript Types.res)
type SafetyLevel = "safe" | "experimental" | "dangerous";
type FlagValueType = "boolean" | "string" | "integer" | "float";
type FlagCategory =
  | "privacy"
  | "performance"
  | "experimental"
  | "developer"
  | "ui"
  | "network";
type BrowserPermission =
  | "browserSettings"
  | "privacy"
  | "tabs"
  | "notifications"
  | "downloads";
type Environment = "production" | "staging" | "development" | "test";

interface FlagEffects {
  positive: string[];
  negative: string[];
  interesting: string[];
}

interface CategoryMeta {
  name: string;
  description: string;
}

interface Flag {
  key: string;
  type: FlagValueType;
  category: FlagCategory;
  safetyLevel: SafetyLevel;
  defaultValue: unknown;
  description: string;
  effects: FlagEffects;
  permissions: BrowserPermission[];
  geckoMinVersion?: string;
  geckoMaxVersion?: string;
  documentation?: string;
  bugNumber?: number;
}

interface FlagDatabase {
  version: string;
  lastUpdated: string;
  categories: Record<string, CategoryMeta>;
  flags: Flag[];
}

interface FlagState {
  key: string;
  currentValue: unknown;
  defaultValue: unknown;
  isModified: boolean;
  lastModified?: number;
  modifiedBy?: "user" | "extension" | "system";
}

interface FlagChange {
  key: string;
  beforeValue: unknown;
  afterValue: unknown;
  timestamp: number;
  source: string;
  effects?: FlagEffects;
}

// ─────────────────────────────────────────────────────────────────
// Test Helpers
// ─────────────────────────────────────────────────────────────────

function validateFlagKey(key: string): boolean {
  return typeof key === "string" && key.length > 0;
}

function validateFlagValue(value: unknown, type: FlagValueType): boolean {
  switch (type) {
    case "boolean":
      return typeof value === "boolean";
    case "string":
      return typeof value === "string";
    case "integer":
      return typeof value === "number" && Number.isInteger(value);
    case "float":
      return typeof value === "number";
    default:
      return false;
  }
}

function validateFlag(flag: Flag): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  if (!validateFlagKey(flag.key)) errors.push("Flag key must be non-empty string");
  if (!flag.description || flag.description.length === 0)
    errors.push("Flag must have a description");
  if (!["boolean", "string", "integer", "float"].includes(flag.type))
    errors.push(`Invalid flag type: ${flag.type}`);
  if (!["safe", "experimental", "dangerous"].includes(flag.safetyLevel))
    errors.push(`Invalid safety level: ${flag.safetyLevel}`);
  if (
    ![
      "privacy",
      "performance",
      "experimental",
      "developer",
      "ui",
      "network",
    ].includes(flag.category)
  )
    errors.push(`Invalid category: ${flag.category}`);
  if (!validateFlagValue(flag.defaultValue, flag.type))
    errors.push(`Default value does not match type ${flag.type}`);

  return { valid: errors.length === 0, errors };
}

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Flag Keys
// ─────────────────────────────────────────────────────────────────

Deno.test("Flag keys: non-empty string requirement", () => {
  assertEquals(validateFlagKey("privacy.tracking"), true);
  assertEquals(validateFlagKey("perf.optimization"), true);
  assertEquals(validateFlagKey("x"), true);

  assertEquals(validateFlagKey(""), false);
  assertEquals(validateFlagKey(null as never), false);
  assertEquals(validateFlagKey(undefined as never), false);
  assertEquals(validateFlagKey(123 as never), false);
});

Deno.test("Flag keys: dot notation allowed", () => {
  assertEquals(validateFlagKey("privacy.tracking"), true);
  assertEquals(validateFlagKey("perf.cache.enabled"), true);
  assertEquals(validateFlagKey("feature_flag_1"), true);
});

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Flag Values
// ─────────────────────────────────────────────────────────────────

Deno.test("Flag values: boolean type", () => {
  assertEquals(validateFlagValue(true, "boolean"), true);
  assertEquals(validateFlagValue(false, "boolean"), true);

  assertEquals(validateFlagValue("true", "boolean"), false);
  assertEquals(validateFlagValue(1, "boolean"), false);
  assertEquals(validateFlagValue(null, "boolean"), false);
});

Deno.test("Flag values: string type", () => {
  assertEquals(validateFlagValue("enabled", "string"), true);
  assertEquals(validateFlagValue("", "string"), true);
  assertEquals(validateFlagValue("very long description text", "string"), true);

  assertEquals(validateFlagValue(123, "string"), false);
  assertEquals(validateFlagValue(true, "string"), false);
});

Deno.test("Flag values: integer type", () => {
  assertEquals(validateFlagValue(0, "integer"), true);
  assertEquals(validateFlagValue(42, "integer"), true);
  assertEquals(validateFlagValue(-100, "integer"), true);

  assertEquals(validateFlagValue(3.14, "integer"), false);
  assertEquals(validateFlagValue("42", "integer"), false);
});

Deno.test("Flag values: float type", () => {
  assertEquals(validateFlagValue(3.14, "float"), true);
  assertEquals(validateFlagValue(0.0, "float"), true);
  assertEquals(validateFlagValue(42, "float"), true); // integers are floats
  assertEquals(validateFlagValue(-100.5, "float"), true);

  assertEquals(validateFlagValue("3.14", "float"), false);
  assertEquals(validateFlagValue(true, "float"), false);
});

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Flag Configuration
// ─────────────────────────────────────────────────────────────────

Deno.test("Flag config: required fields validation", () => {
  const validFlag: Flag = {
    key: "test.flag",
    type: "boolean",
    category: "experimental",
    safetyLevel: "safe",
    defaultValue: false,
    description: "Test flag",
    effects: { positive: [], negative: [], interesting: [] },
    permissions: [],
  };

  const result = validateFlag(validFlag);
  assertEquals(result.valid, true);
  assertEquals(result.errors.length, 0);
});

Deno.test("Flag config: all required fields must be present", () => {
  // Missing key
  const noKey = {
    type: "boolean",
    category: "experimental",
    safetyLevel: "safe",
    defaultValue: false,
    description: "Test",
    effects: { positive: [], negative: [], interesting: [] },
    permissions: [],
  } as unknown as Flag;
  assertEquals(validateFlag(noKey).valid, false);

  // Missing description
  const noDesc = {
    key: "test",
    type: "boolean",
    category: "experimental",
    safetyLevel: "safe",
    defaultValue: false,
    effects: { positive: [], negative: [], interesting: [] },
    permissions: [],
  } as unknown as Flag;
  assertEquals(validateFlag(noDesc).valid, false);
});

Deno.test("Flag config: default value type mismatch detection", () => {
  const mismatch: Flag = {
    key: "test.flag",
    type: "boolean", // expects boolean
    category: "experimental",
    safetyLevel: "safe",
    defaultValue: "true", // but got string
    description: "Test flag",
    effects: { positive: [], negative: [], interesting: [] },
    permissions: [],
  };

  const result = validateFlag(mismatch);
  assertEquals(result.valid, false);
  assertEquals(
    result.errors.some((e) => e.includes("Default value does not match")),
    true
  );
});

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Safety Levels
// ─────────────────────────────────────────────────────────────────

Deno.test("Safety levels: all variants recognized", () => {
  const levels: SafetyLevel[] = ["safe", "experimental", "dangerous"];

  for (const level of levels) {
    const flag: Flag = {
      key: "test",
      type: "boolean",
      category: "experimental",
      safetyLevel: level,
      defaultValue: false,
      description: "Test",
      effects: { positive: [], negative: [], interesting: [] },
      permissions: [],
    };
    assertEquals(validateFlag(flag).valid, true);
  }
});

Deno.test("Safety levels: invalid level detection", () => {
  const flag = {
    key: "test",
    type: "boolean",
    category: "experimental",
    safetyLevel: "unknown" as never,
    defaultValue: false,
    description: "Test",
    effects: { positive: [], negative: [], interesting: [] },
    permissions: [],
  };

  const result = validateFlag(flag as Flag);
  assertEquals(result.valid, false);
});

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Categories
// ─────────────────────────────────────────────────────────────────

Deno.test("Categories: all variants recognized", () => {
  const categories: FlagCategory[] = [
    "privacy",
    "performance",
    "experimental",
    "developer",
    "ui",
    "network",
  ];

  for (const category of categories) {
    const flag: Flag = {
      key: "test",
      type: "boolean",
      category,
      safetyLevel: "safe",
      defaultValue: false,
      description: "Test",
      effects: { positive: [], negative: [], interesting: [] },
      permissions: [],
    };
    assertEquals(validateFlag(flag).valid, true);
  }
});

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Flag State
// ─────────────────────────────────────────────────────────────────

Deno.test("Flag state: creation with defaults", () => {
  const state: FlagState = {
    key: "privacy.tracking",
    currentValue: false,
    defaultValue: false,
    isModified: false,
  };

  assertEquals(state.key, "privacy.tracking");
  assertEquals(state.currentValue, false);
  assertEquals(state.isModified, false);
});

Deno.test("Flag state: tracks modifications", () => {
  const state: FlagState = {
    key: "test.flag",
    currentValue: true,
    defaultValue: false,
    isModified: true,
    lastModified: Date.now(),
    modifiedBy: "user",
  };

  assertEquals(state.isModified, true);
  assertExists(state.lastModified);
  assertEquals(state.modifiedBy, "user");
});

Deno.test("Flag state: valid modification sources", () => {
  const sources: Array<FlagState["modifiedBy"]> = ["user", "extension", "system"];

  for (const source of sources) {
    const state: FlagState = {
      key: "test",
      currentValue: true,
      defaultValue: false,
      isModified: true,
      modifiedBy: source,
    };
    assertEquals(state.modifiedBy, source);
  }
});

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Flag Changes
// ─────────────────────────────────────────────────────────────────

Deno.test("Flag change: complete change record", () => {
  const change: FlagChange = {
    key: "privacy.tracking",
    beforeValue: false,
    afterValue: true,
    timestamp: Date.now(),
    source: "user",
    effects: {
      positive: ["less tracking"],
      negative: ["slower page load"],
      interesting: ["ads may be more relevant"],
    },
  };

  assertEquals(change.key, "privacy.tracking");
  assertEquals(change.beforeValue, false);
  assertEquals(change.afterValue, true);
  assertExists(change.timestamp);
  assertEquals(change.source, "user");
  assertExists(change.effects);
});

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Flag Database
// ─────────────────────────────────────────────────────────────────

Deno.test("Flag database: empty database structure", () => {
  const db: FlagDatabase = {
    version: "0.1.0",
    lastUpdated: new Date().toISOString(),
    categories: {},
    flags: [],
  };

  assertEquals(db.version, "0.1.0");
  assertEquals(db.flags.length, 0);
  assertEquals(Object.keys(db.categories).length, 0);
});

Deno.test("Flag database: with categories and flags", () => {
  const db: FlagDatabase = {
    version: "1.0.0",
    lastUpdated: new Date().toISOString(),
    categories: {
      privacy: {
        name: "Privacy Features",
        description: "User privacy controls",
      },
      performance: {
        name: "Performance",
        description: "Performance optimizations",
      },
    },
    flags: [
      {
        key: "privacy.tracking",
        type: "boolean",
        category: "privacy",
        safetyLevel: "safe",
        defaultValue: false,
        description: "Disable tracking",
        effects: { positive: [], negative: [], interesting: [] },
        permissions: ["privacy"],
      },
    ],
  };

  assertEquals(db.version, "1.0.0");
  assertEquals(db.flags.length, 1);
  assertEquals(Object.keys(db.categories).length, 2);
  assertEquals(db.flags[0].key, "privacy.tracking");
});

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Environment Variants
// ─────────────────────────────────────────────────────────────────

Deno.test("Environments: all variants valid", () => {
  const environments: Environment[] = [
    "production",
    "staging",
    "development",
    "test",
  ];

  for (const env of environments) {
    assertEquals(
      ["production", "staging", "development", "test"].includes(env),
      true
    );
  }
});

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Permissions
// ─────────────────────────────────────────────────────────────────

Deno.test("Permissions: all browser permissions valid", () => {
  const perms: BrowserPermission[] = [
    "browserSettings",
    "privacy",
    "tabs",
    "notifications",
    "downloads",
  ];

  for (const perm of perms) {
    assertEquals(
      [
        "browserSettings",
        "privacy",
        "tabs",
        "notifications",
        "downloads",
      ].includes(perm),
      true
    );
  }
});

Deno.test("Permissions: flag can have multiple permissions", () => {
  const flag: Flag = {
    key: "test.flag",
    type: "boolean",
    category: "experimental",
    safetyLevel: "experimental",
    defaultValue: false,
    description: "Test flag",
    effects: { positive: [], negative: [], interesting: [] },
    permissions: ["browserSettings", "privacy", "notifications"],
  };

  assertEquals(flag.permissions.length, 3);
  assertEquals(flag.permissions[0], "browserSettings");
});

// ─────────────────────────────────────────────────────────────────
// Unit Tests: Type Composition
// ─────────────────────────────────────────────────────────────────

Deno.test("Type composition: flag effects structure", () => {
  const effects: FlagEffects = {
    positive: ["faster loading", "less memory"],
    negative: ["fewer features"],
    interesting: ["affects ad targeting"],
  };

  assertEquals(effects.positive.length, 2);
  assertEquals(effects.negative.length, 1);
  assertEquals(effects.interesting.length, 1);
});

Deno.test("Type composition: category metadata", () => {
  const meta: CategoryMeta = {
    name: "Privacy Controls",
    description: "Flags affecting user privacy",
  };

  assertEquals(typeof meta.name, "string");
  assertEquals(typeof meta.description, "string");
  assertEquals(meta.name.length > 0, true);
});
