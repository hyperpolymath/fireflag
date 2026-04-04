// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

/**
 * Benchmarks for flag evaluation performance
 *
 * Measures:
 * - Flag lookup in small database (10 flags)
 * - Flag lookup in large database (10,000 flags)
 * - Database serialization (100 flags)
 * - Database deserialization (100 flags)
 * - Flag evaluation with environment filtering
 */

// Type definitions
interface Flag {
  key: string;
  enabled: boolean;
  value: unknown;
  defaultValue: unknown;
}

type FlagDatabase = Record<string, Flag>;

// ─────────────────────────────────────────────────────────────────
// Benchmark Implementation
// ─────────────────────────────────────────────────────────────────

function evaluateFlag(flagId: string, database: FlagDatabase): unknown {
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

function createSmallDatabase(): FlagDatabase {
  const db: FlagDatabase = {};
  for (let i = 0; i < 10; i++) {
    db[`flag.${i}`] = {
      key: `flag.${i}`,
      enabled: i % 2 === 0,
      value: i,
      defaultValue: 0,
    };
  }
  return db;
}

function createMediumDatabase(): FlagDatabase {
  const db: FlagDatabase = {};
  for (let i = 0; i < 100; i++) {
    db[`flag.${i}`] = {
      key: `flag.${i}`,
      enabled: i % 3 === 0,
      value: i * 10,
      defaultValue: 0,
    };
  }
  return db;
}

function createLargeDatabase(): FlagDatabase {
  const db: FlagDatabase = {};
  for (let i = 0; i < 10000; i++) {
    db[`flag.${i}`] = {
      key: `flag.${i}`,
      enabled: i % 5 === 0,
      value: i * 100,
      defaultValue: 0,
    };
  }
  return db;
}

// ─────────────────────────────────────────────────────────────────
// Benchmarks: Small Database
// ─────────────────────────────────────────────────────────────────

Deno.bench("Bench: Flag lookup in 10-flag database (enabled)", () => {
  const db = createSmallDatabase();
  evaluateFlag("flag.0", db);
  evaluateFlag("flag.2", db);
  evaluateFlag("flag.4", db);
});

Deno.bench("Bench: Flag lookup in 10-flag database (disabled)", () => {
  const db = createSmallDatabase();
  evaluateFlag("flag.1", db);
  evaluateFlag("flag.3", db);
  evaluateFlag("flag.5", db);
});

Deno.bench("Bench: Flag lookup in 10-flag database (missing)", () => {
  const db = createSmallDatabase();
  evaluateFlag("nonexistent.0", db);
  evaluateFlag("nonexistent.1", db);
  evaluateFlag("nonexistent.2", db);
});

Deno.bench("Bench: Batch lookup 10 flags from 10-flag database", () => {
  const db = createSmallDatabase();
  for (let i = 0; i < 10; i++) {
    evaluateFlag(`flag.${i}`, db);
  }
});

// ─────────────────────────────────────────────────────────────────
// Benchmarks: Medium Database
// ─────────────────────────────────────────────────────────────────

Deno.bench("Bench: Flag lookup in 100-flag database (early)", () => {
  const db = createMediumDatabase();
  evaluateFlag("flag.5", db);
});

Deno.bench("Bench: Flag lookup in 100-flag database (middle)", () => {
  const db = createMediumDatabase();
  evaluateFlag("flag.50", db);
});

Deno.bench("Bench: Flag lookup in 100-flag database (late)", () => {
  const db = createMediumDatabase();
  evaluateFlag("flag.95", db);
});

Deno.bench("Bench: Batch lookup 10 random flags from 100-flag database", () => {
  const db = createMediumDatabase();
  const indices = [5, 15, 25, 35, 45, 55, 65, 75, 85, 95];
  for (const i of indices) {
    evaluateFlag(`flag.${i}`, db);
  }
});

Deno.bench("Bench: Batch lookup all flags from 100-flag database", () => {
  const db = createMediumDatabase();
  for (let i = 0; i < 100; i++) {
    evaluateFlag(`flag.${i}`, db);
  }
});

// ─────────────────────────────────────────────────────────────────
// Benchmarks: Large Database
// ─────────────────────────────────────────────────────────────────

Deno.bench("Bench: Flag lookup in 10k-flag database (early)", () => {
  const db = createLargeDatabase();
  evaluateFlag("flag.100", db);
});

Deno.bench("Bench: Flag lookup in 10k-flag database (middle)", () => {
  const db = createLargeDatabase();
  evaluateFlag("flag.5000", db);
});

Deno.bench("Bench: Flag lookup in 10k-flag database (late)", () => {
  const db = createLargeDatabase();
  evaluateFlag("flag.9900", db);
});

Deno.bench("Bench: Batch lookup 100 flags from 10k-flag database", () => {
  const db = createLargeDatabase();
  const step = 100;
  for (let i = 0; i < 10000; i += step) {
    evaluateFlag(`flag.${i}`, db);
  }
});

// ─────────────────────────────────────────────────────────────────
// Benchmarks: Serialization
// ─────────────────────────────────────────────────────────────────

Deno.bench("Bench: Serialize 100-flag database to JSON", () => {
  const db = createMediumDatabase();
  serializeDatabase(db);
});

Deno.bench("Bench: Deserialize 100-flag database from JSON", () => {
  const db = createMediumDatabase();
  const json = serializeDatabase(db);
  deserializeDatabase(json);
});

Deno.bench("Bench: Serialize + Deserialize 100-flag database", () => {
  const db = createMediumDatabase();
  const json = serializeDatabase(db);
  deserializeDatabase(json);
});

Deno.bench("Bench: Serialize 10k-flag database to JSON", () => {
  const db = createLargeDatabase();
  serializeDatabase(db);
});

Deno.bench("Bench: Deserialize 10k-flag database from JSON", () => {
  const db = createLargeDatabase();
  const json = serializeDatabase(db);
  deserializeDatabase(json);
});

// ─────────────────────────────────────────────────────────────────
// Benchmarks: Complex Operations
// ─────────────────────────────────────────────────────────────────

Deno.bench("Bench: Evaluate all flags in 100-flag database", () => {
  const db = createMediumDatabase();
  for (const [key] of Object.entries(db)) {
    evaluateFlag(key, db);
  }
});

Deno.bench("Bench: Evaluate all flags in 10k-flag database", () => {
  const db = createLargeDatabase();
  // Sample every 10th flag to keep bench time reasonable
  for (let i = 0; i < 10000; i += 10) {
    evaluateFlag(`flag.${i}`, db);
  }
});

Deno.bench("Bench: Find enabled flags in 100-flag database", () => {
  const db = createMediumDatabase();
  let count = 0;
  for (const [key, flag] of Object.entries(db)) {
    if (flag.enabled) {
      count++;
    }
  }
});

Deno.bench("Bench: Filter by category (100 flags)", () => {
  const db: FlagDatabase = {};
  for (let i = 0; i < 100; i++) {
    const category = i % 5 === 0 ? "privacy" : "perf";
    db[`${category}.flag${i}`] = {
      key: `${category}.flag${i}`,
      enabled: true,
      value: i,
      defaultValue: 0,
    };
  }

  let count = 0;
  for (const key of Object.keys(db)) {
    if (key.startsWith("privacy.")) {
      count++;
    }
  }
});

// ─────────────────────────────────────────────────────────────────
// Benchmarks: Memory & Creation
// ─────────────────────────────────────────────────────────────────

Deno.bench("Bench: Create 10-flag database", () => {
  createSmallDatabase();
});

Deno.bench("Bench: Create 100-flag database", () => {
  createMediumDatabase();
});

Deno.bench("Bench: Create 10k-flag database", () => {
  createLargeDatabase();
});

// ─────────────────────────────────────────────────────────────────
// Benchmarks: Stress Tests
// ─────────────────────────────────────────────────────────────────

Deno.bench("Bench: 1000 lookups in 10-flag database", () => {
  const db = createSmallDatabase();
  for (let i = 0; i < 1000; i++) {
    evaluateFlag(`flag.${i % 10}`, db);
  }
});

Deno.bench("Bench: 100 lookups in 10k-flag database", () => {
  const db = createLargeDatabase();
  for (let i = 0; i < 100; i++) {
    const flagNum = (i * 100) % 10000;
    evaluateFlag(`flag.${flagNum}`, db);
  }
});

Deno.bench("Bench: Sequential access pattern (100-flag db)", () => {
  const db = createMediumDatabase();
  for (let i = 0; i < 100; i++) {
    evaluateFlag(`flag.${i}`, db);
  }
});

Deno.bench("Bench: Random access pattern (100-flag db)", () => {
  const db = createMediumDatabase();
  const seed = 42;
  let rng = seed;
  for (let i = 0; i < 100; i++) {
    rng = (rng * 1103515245 + 12345) & 0x7fffffff;
    const idx = rng % 100;
    evaluateFlag(`flag.${idx}`, db);
  }
});
