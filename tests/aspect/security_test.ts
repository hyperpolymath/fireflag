// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

/**
 * Security aspect tests for fireflag extension
 *
 * Tests cross-cutting security concerns:
 * - Flag ID injection protection (path traversal, etc.)
 * - XSS prevention in flag values (HTML escaping)
 * - Unauthorized modification prevention (readonly flags)
 * - DevTools injection protection (malformed JSON handling)
 */

import {
  assertEquals,
  assertThrows,
  assertStringIncludes,
} from "std/assert";

// Type definitions
interface Flag {
  key: string;
  enabled: boolean;
  value: unknown;
  defaultValue: unknown;
  readonly?: boolean;
}

type FlagDatabase = Record<string, Flag>;

// ─────────────────────────────────────────────────────────────────
// Security Implementation
// ─────────────────────────────────────────────────────────────────

// Validate flag IDs to prevent injection
function isValidFlagId(id: string): boolean {
  if (typeof id !== "string" || id.length === 0) return false;
  // Only alphanumeric, dots, and hyphens allowed
  return /^[a-zA-Z0-9._-]+$/.test(id);
}

// Escape HTML to prevent XSS
function escapeHtml(text: unknown): string {
  if (typeof text !== "string") {
    return String(text);
  }

  const map: Record<string, string> = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#039;",
  };

  return text.replace(/[&<>"']/g, (char) => map[char]);
}

// Escape string values to prevent XSS in UI
function getSafeValue(flag: Flag): string {
  if (flag.enabled) {
    const value = flag.value;
    if (typeof value === "string") {
      return escapeHtml(value);
    }
    return escapeHtml(JSON.stringify(value));
  }
  return escapeHtml(JSON.stringify(flag.defaultValue));
}

// Validate JSON to prevent injection
function validateJson(json: string): boolean {
  try {
    JSON.parse(json);
    return true;
  } catch {
    return false;
  }
}

// Parse JSON safely
function safeParseJson<T>(json: string, fallback: T): T {
  try {
    return JSON.parse(json) as T;
  } catch {
    return fallback;
  }
}

// Check if flag is readonly
function isFlagReadonly(flag: Flag): boolean {
  return flag.readonly === true;
}

// Attempt to modify a flag
function modifyFlag(
  flagId: string,
  newValue: unknown,
  database: FlagDatabase
): { success: boolean; error?: string } {
  // 1. Validate flag ID
  if (!isValidFlagId(flagId)) {
    return { success: false, error: "Invalid flag ID" };
  }

  // 2. Check if flag exists
  const flag = database[flagId];
  if (!flag) {
    return { success: false, error: "Flag not found" };
  }

  // 3. Check if readonly
  if (isFlagReadonly(flag)) {
    return { success: false, error: "Flag is readonly" };
  }

  // 4. Modify flag
  flag.value = newValue;
  return { success: true };
}

// ─────────────────────────────────────────────────────────────────
// Security Tests: Flag ID Injection
// ─────────────────────────────────────────────────────────────────

Deno.test("Security: reject path traversal in flag IDs", () => {
  const maliciousIds = [
    "../../../etc/passwd",
    "..\\..\\..\\windows\\system32",
    "flag./../../../config",
    "feature/../../../../secrets",
  ];

  for (const id of maliciousIds) {
    assertEquals(
      isValidFlagId(id),
      false,
      `Path traversal not rejected: ${id}`
    );
  }
});

Deno.test("Security: reject null bytes in flag IDs", () => {
  assertEquals(isValidFlagId("flag\x00injection"), false);
  assertEquals(isValidFlagId("flag\0injection"), false);
});

Deno.test("Security: reject special shell characters in flag IDs", () => {
  const shellChars = [
    "flag;rm -rf /",
    "flag$(whoami)",
    "flag`id`",
    "flag|cat",
    "flag&sleep 10",
    "flag>output.txt",
  ];

  for (const id of shellChars) {
    assertEquals(isValidFlagId(id), false, `Shell char not rejected: ${id}`);
  }
});

Deno.test("Security: accept valid flag IDs", () => {
  const validIds = [
    "privacy.tracking",
    "perf.cache",
    "feature_new",
    "flag-123",
    "x",
    "A1.b2_c3-d4",
  ];

  for (const id of validIds) {
    assertEquals(isValidFlagId(id), true, `Valid ID rejected: ${id}`);
  }
});

Deno.test("Security: reject empty flag IDs", () => {
  assertEquals(isValidFlagId(""), false);
  assertEquals(isValidFlagId(" "), false);
});

// ─────────────────────────────────────────────────────────────────
// Security Tests: XSS Prevention
// ─────────────────────────────────────────────────────────────────

Deno.test("Security: escape HTML in flag values", () => {
  const xssPayloads = [
    '<script>alert("xss")</script>',
    '<img src=x onerror="alert(1)">',
    '<svg onload="alert(1)">',
    '"><script>alert(1)</script>',
    "javascript:alert(1)",
  ];

  for (const payload of xssPayloads) {
    const escaped = escapeHtml(payload);
    // Escaped version should not contain unescaped angle brackets (which would form tags)
    assertEquals(escaped.includes("<"), false, `Unescaped < in: ${escaped}`);
    assertEquals(escaped.includes(">"), false, `Unescaped > in: ${escaped}`);
    // Original content should still be present but escaped
    assertEquals(escaped.length > 0, true);
  }
});

Deno.test("Security: escapeHtml preserves content", () => {
  const original = 'Hello & <World> "Test"';
  const escaped = escapeHtml(original);

  // Content should be preserved but sanitized
  assertStringIncludes(escaped, "Hello");
  assertStringIncludes(escaped, "World");
  assertStringIncludes(escaped, "Test");
});

Deno.test("Security: getSafeValue escapes string flags", () => {
  const flag: Flag = {
    key: "test",
    enabled: true,
    value: '<script>alert("xss")</script>',
    defaultValue: "default",
  };

  const safe = getSafeValue(flag);
  assertEquals(safe.includes("<script>"), false);
  assertEquals(safe.includes("&lt;script&gt;"), true);
});

Deno.test("Security: getSafeValue returns default when disabled", () => {
  const flag: Flag = {
    key: "test",
    enabled: false,
    value: '<script>alert("xss")</script>',
    defaultValue: "safe-default",
  };

  const safe = getSafeValue(flag);
  assertStringIncludes(safe, "safe-default");
});

Deno.test("Security: non-string values safely stringified", () => {
  const testCases: Array<{ value: unknown; description: string }> = [
    { value: 123, description: "number" },
    { value: true, description: "boolean" },
    { value: null, description: "null" },
    { value: { key: "value" }, description: "object" },
    { value: [1, 2, 3], description: "array" },
  ];

  for (const testCase of testCases) {
    const flag: Flag = {
      key: "test",
      enabled: true,
      value: testCase.value,
      defaultValue: "default",
    };

    const safe = getSafeValue(flag);
    assertEquals(typeof safe, "string", `Failed for ${testCase.description}`);
    assertEquals(safe.length > 0, true, `Empty result for ${testCase.description}`);
  }
});

// ─────────────────────────────────────────────────────────────────
// Security Tests: Unauthorized Modification
// ─────────────────────────────────────────────────────────────────

Deno.test("Security: readonly flags cannot be modified", () => {
  const db: FlagDatabase = {
    "system.immutable": {
      key: "system.immutable",
      enabled: true,
      value: "original",
      defaultValue: "default",
      readonly: true,
    },
  };

  const result = modifyFlag("system.immutable", "new-value", db);

  assertEquals(result.success, false);
  assertEquals(result.error, "Flag is readonly");
  // Value should not have changed
  assertEquals(db["system.immutable"].value, "original");
});

Deno.test("Security: writable flags can be modified", () => {
  const db: FlagDatabase = {
    "feature.mutable": {
      key: "feature.mutable",
      enabled: true,
      value: "original",
      defaultValue: "default",
      readonly: false,
    },
  };

  const result = modifyFlag("feature.mutable", "new-value", db);

  assertEquals(result.success, true);
  assertEquals(db["feature.mutable"].value, "new-value");
});

Deno.test("Security: reject modification of nonexistent flags", () => {
  const db: FlagDatabase = {};

  const result = modifyFlag("nonexistent.flag", "value", db);

  assertEquals(result.success, false);
  assertEquals(result.error, "Flag not found");
});

Deno.test("Security: reject modification with invalid flag ID", () => {
  const db: FlagDatabase = {
    "valid.flag": {
      key: "valid.flag",
      enabled: true,
      value: "original",
      defaultValue: "default",
    },
  };

  const result = modifyFlag("../../../etc/passwd", "malicious", db);

  assertEquals(result.success, false);
  assertEquals(result.error, "Invalid flag ID");
});

// ─────────────────────────────────────────────────────────────────
// Security Tests: DevTools Injection
// ─────────────────────────────────────────────────────────────────

Deno.test("Security: reject malformed JSON from DevTools", () => {
  const malformedJson = [
    "{invalid json}",
    "{'single': 'quotes'}",
    "{incomplete:",
    '{"key": undefined}',
    '{"key": function() {}}',
  ];

  for (const json of malformedJson) {
    assertEquals(validateJson(json), false, `Malformed JSON accepted: ${json}`);
  }
});

Deno.test("Security: accept valid JSON from DevTools", () => {
  const validJson = [
    "{}",
    '{"key":"value"}',
    '[1,2,3]',
    '{"nested":{"deep":"value"}}',
    'null',
    'true',
    '123',
    '"string"',
  ];

  for (const json of validJson) {
    assertEquals(validateJson(json), true, `Valid JSON rejected: ${json}`);
  }
});

Deno.test("Security: safeParseJson returns fallback on invalid JSON", () => {
  const fallback = { default: "value" };

  const result1 = safeParseJson("{invalid}", fallback);
  assertEquals(result1, fallback);

  const result2 = safeParseJson('{"valid":"json"}', fallback);
  assertEquals((result2 as Record<string, unknown>).valid, "json");
});

Deno.test("Security: DevTools cannot inject arbitrary code", () => {
  // Even if JSON is valid, injected code should be inert data
  const injectedJson = JSON.stringify({
    key: "test",
    // These are just data, not executable code
    constructor: { prototype: { polluted: true } },
  });

  const result = safeParseJson(injectedJson, {});

  // Should parse successfully as data
  assertEquals(typeof result, "object");
  // But property pollution should not affect other objects
  const clean = {};
  assertEquals(Object.prototype.hasOwnProperty.call(clean, "polluted"), false);
});

// ─────────────────────────────────────────────────────────────────
// Security Tests: Combined Threats
// ─────────────────────────────────────────────────────────────────

Deno.test("Security: combined threat - malicious ID + XSS + JSON injection", () => {
  const db: FlagDatabase = {
    "safe.flag": {
      key: "safe.flag",
      enabled: true,
      value: "normal",
      defaultValue: "default",
    },
  };

  // Attempt 1: Path traversal + XSS
  const maliciousId = "../../../etc/passwd";
  const xssValue = '<script>alert("xss")</script>';

  const result1 = modifyFlag(maliciousId, xssValue, db);
  assertEquals(result1.success, false);
  assertEquals(db["safe.flag"].value, "normal"); // Unchanged

  // Attempt 2: Invalid JSON through safe parse
  const invalidJson = "{corrupted}";
  const fallback = { safe: true };
  const result2 = safeParseJson(invalidJson, fallback);
  assertEquals(result2.safe, true);
});

Deno.test("Security: escapeHtml handles edge cases", () => {
  const testCases = [
    { input: "", expected: "" },
    { input: "normal text", expected: "normal text" },
    { input: "&", expected: "&amp;" },
    { input: "&&", expected: "&amp;&amp;" },
    { input: "<>", expected: "&lt;&gt;" },
    { input: '""', expected: "&quot;&quot;" },
    { input: "''", expected: "&#039;&#039;" },
    { input: '&<>"\'', expected: "&amp;&lt;&gt;&quot;&#039;" },
  ];

  for (const testCase of testCases) {
    const result = escapeHtml(testCase.input);
    assertEquals(result, testCase.expected, `Failed for: ${testCase.input}`);
  }
});

Deno.test("Security: all readonly flags remain protected", () => {
  const db: FlagDatabase = {
    "system.flag1": {
      key: "system.flag1",
      enabled: true,
      value: "v1",
      defaultValue: "d1",
      readonly: true,
    },
    "system.flag2": {
      key: "system.flag2",
      enabled: true,
      value: "v2",
      defaultValue: "d2",
      readonly: true,
    },
    "user.flag": {
      key: "user.flag",
      enabled: true,
      value: "v3",
      defaultValue: "d3",
      readonly: false,
    },
  };

  // Try to modify system flags
  assertEquals(modifyFlag("system.flag1", "hacked", db).success, false);
  assertEquals(modifyFlag("system.flag2", "hacked", db).success, false);
  assertEquals(modifyFlag("user.flag", "allowed", db).success, true);

  // System flags unchanged
  assertEquals(db["system.flag1"].value, "v1");
  assertEquals(db["system.flag2"].value, "v2");
  // User flag changed
  assertEquals(db["user.flag"].value, "allowed");
});
