// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

/**
 * End-to-End lifecycle tests for browser extension
 *
 * Tests complete user workflows:
 * - Initialize extension → load flag database → evaluate flag
 * - Update flag database → re-evaluate → verify changes reflected
 * - DevTools open → inspect flags → list all → count matches
 * - Flag changed → extension notified → state updated
 */

import { assertEquals, assertExists, assertStrictEquals } from "std/assert";

// Type definitions
interface Flag {
  key: string;
  enabled: boolean;
  value: unknown;
  defaultValue: unknown;
}

type FlagDatabase = Record<string, Flag>;

interface ExtensionState {
  initialized: boolean;
  databaseLoaded: boolean;
  database: FlagDatabase;
  flagChanges: Array<{ key: string; timestamp: number }>;
}

interface DevToolsPanel {
  visible: boolean;
  flags: Flag[];
  selectedFlag?: string;
}

// ─────────────────────────────────────────────────────────────────
// Mock Extension Implementation
// ─────────────────────────────────────────────────────────────────

class FireflagExtension {
  state: ExtensionState;
  devToolsPanel: DevToolsPanel;

  constructor() {
    this.state = {
      initialized: false,
      databaseLoaded: false,
      database: {},
      flagChanges: [],
    };
    this.devToolsPanel = {
      visible: false,
      flags: [],
    };
  }

  // Initialize extension
  async initialize(): Promise<void> {
    this.state.initialized = true;
  }

  // Load flag database
  async loadDatabase(db: FlagDatabase): Promise<void> {
    this.state.database = { ...db };
    this.state.databaseLoaded = true;
  }

  // Evaluate a flag
  evaluateFlag(flagId: string): unknown {
    const flag = this.state.database[flagId];
    if (!flag) return undefined;
    if (!flag.enabled) return flag.defaultValue;
    return flag.value;
  }

  // Update database
  async updateDatabase(newDb: FlagDatabase): Promise<void> {
    const oldDb = this.state.database;

    // Track changes
    for (const [key, newFlag] of Object.entries(newDb)) {
      const oldFlag = oldDb[key];
      if (!oldFlag || JSON.stringify(oldFlag) !== JSON.stringify(newFlag)) {
        this.state.flagChanges.push({ key, timestamp: Date.now() });
      }
    }

    this.state.database = { ...newDb };
  }

  // Get all flags
  getAllFlags(): Flag[] {
    return Object.values(this.state.database);
  }

  // Filter flags by category
  getFlagsByCategory(category: string): Flag[] {
    return Object.values(this.state.database).filter((f) =>
      f.key.startsWith(`${category}.`)
    );
  }

  // Open DevTools panel
  async openDevToolsPanel(): Promise<void> {
    this.devToolsPanel.visible = true;
    this.devToolsPanel.flags = this.getAllFlags();
  }

  // Inspect a specific flag in DevTools
  inspectFlag(flagId: string): void {
    this.devToolsPanel.selectedFlag = flagId;
  }

  // Count flags matching a predicate
  countFlags(predicate: (flag: Flag) => boolean): number {
    return this.getAllFlags().filter(predicate).length;
  }

  // Notify extension of flag change
  notifyFlagChanged(flagId: string, newValue: unknown): void {
    const flag = this.state.database[flagId];
    if (flag) {
      flag.value = newValue;
      this.state.flagChanges.push({ key: flagId, timestamp: Date.now() });
    }
  }

  // Get change history
  getChangeHistory(): Array<{ key: string; timestamp: number }> {
    return this.state.flagChanges;
  }

  // Reset for testing
  reset(): void {
    this.state = {
      initialized: false,
      databaseLoaded: false,
      database: {},
      flagChanges: [],
    };
    this.devToolsPanel = {
      visible: false,
      flags: [],
    };
  }
}

// ─────────────────────────────────────────────────────────────────
// E2E Tests: Extension Initialization
// ─────────────────────────────────────────────────────────────────

Deno.test("E2E: initialize extension", async () => {
  const ext = new FireflagExtension();
  assertEquals(ext.state.initialized, false);

  await ext.initialize();
  assertEquals(ext.state.initialized, true);

  ext.reset();
});

Deno.test("E2E: load flag database after initialization", async () => {
  const ext = new FireflagExtension();

  const db: FlagDatabase = {
    "privacy.tracking": {
      key: "privacy.tracking",
      enabled: true,
      value: false,
      defaultValue: true,
    },
  };

  await ext.initialize();
  assertEquals(ext.state.databaseLoaded, false);

  await ext.loadDatabase(db);
  assertEquals(ext.state.databaseLoaded, true);
  assertEquals(Object.keys(ext.state.database).length, 1);

  ext.reset();
});

// ─────────────────────────────────────────────────────────────────
// E2E Tests: Flag Evaluation
// ─────────────────────────────────────────────────────────────────

Deno.test("E2E: initialize → load database → evaluate flag", async () => {
  const ext = new FireflagExtension();

  const db: FlagDatabase = {
    "feature.new": {
      key: "feature.new",
      enabled: true,
      value: true,
      defaultValue: false,
    },
  };

  // Initialize
  await ext.initialize();
  assertExists(ext.state.initialized);

  // Load database
  await ext.loadDatabase(db);
  assertExists(ext.state.database["feature.new"]);

  // Evaluate flag
  const result = ext.evaluateFlag("feature.new");
  assertStrictEquals(result, true);

  ext.reset();
});

Deno.test("E2E: evaluate multiple flags", async () => {
  const ext = new FireflagExtension();

  const db: FlagDatabase = {
    "feature.one": {
      key: "feature.one",
      enabled: true,
      value: "first",
      defaultValue: "default",
    },
    "feature.two": {
      key: "feature.two",
      enabled: false,
      value: "second",
      defaultValue: "default",
    },
    "feature.three": {
      key: "feature.three",
      enabled: true,
      value: 42,
      defaultValue: 0,
    },
  };

  await ext.initialize();
  await ext.loadDatabase(db);

  assertEquals(ext.evaluateFlag("feature.one"), "first");
  assertEquals(ext.evaluateFlag("feature.two"), "default");
  assertEquals(ext.evaluateFlag("feature.three"), 42);
  assertEquals(ext.evaluateFlag("nonexistent"), undefined);

  ext.reset();
});

// ─────────────────────────────────────────────────────────────────
// E2E Tests: Database Updates
// ─────────────────────────────────────────────────────────────────

Deno.test("E2E: update database → re-evaluate → see new values", async () => {
  const ext = new FireflagExtension();

  const db1: FlagDatabase = {
    "feature.beta": {
      key: "feature.beta",
      enabled: true,
      value: false,
      defaultValue: false,
    },
  };

  await ext.initialize();
  await ext.loadDatabase(db1);

  // Initial evaluation
  let result = ext.evaluateFlag("feature.beta");
  assertStrictEquals(result, false);

  // Update database with new values
  const db2: FlagDatabase = {
    "feature.beta": {
      key: "feature.beta",
      enabled: true,
      value: true, // Changed!
      defaultValue: false,
    },
  };

  await ext.updateDatabase(db2);

  // Re-evaluate after update
  result = ext.evaluateFlag("feature.beta");
  assertStrictEquals(result, true);

  ext.reset();
});

Deno.test("E2E: database update tracks changes", async () => {
  const ext = new FireflagExtension();

  const db1: FlagDatabase = {
    "feature.a": {
      key: "feature.a",
      enabled: true,
      value: 1,
      defaultValue: 0,
    },
    "feature.b": {
      key: "feature.b",
      enabled: true,
      value: 2,
      defaultValue: 0,
    },
  };

  await ext.initialize();
  await ext.loadDatabase(db1);

  // Update with changes
  const db2: FlagDatabase = {
    "feature.a": {
      key: "feature.a",
      enabled: true,
      value: 100, // Changed
      defaultValue: 0,
    },
    "feature.b": {
      key: "feature.b",
      enabled: true,
      value: 2, // Unchanged
      defaultValue: 0,
    },
    "feature.c": {
      key: "feature.c",
      enabled: true,
      value: 3, // New
      defaultValue: 0,
    },
  };

  await ext.updateDatabase(db2);

  const history = ext.getChangeHistory();
  assertEquals(history.length >= 2, true); // At least feature.a and feature.c changed
  assertEquals(
    history.some((h) => h.key === "feature.a"),
    true
  );
  assertEquals(
    history.some((h) => h.key === "feature.c"),
    true
  );

  ext.reset();
});

// ─────────────────────────────────────────────────────────────────
// E2E Tests: DevTools Panel
// ─────────────────────────────────────────────────────────────────

Deno.test("E2E: open DevTools panel", async () => {
  const ext = new FireflagExtension();

  const db: FlagDatabase = {
    "feature.test": {
      key: "feature.test",
      enabled: true,
      value: true,
      defaultValue: false,
    },
  };

  await ext.initialize();
  await ext.loadDatabase(db);

  assertEquals(ext.devToolsPanel.visible, false);

  await ext.openDevToolsPanel();

  assertEquals(ext.devToolsPanel.visible, true);
  assertEquals(ext.devToolsPanel.flags.length, 1);

  ext.reset();
});

Deno.test("E2E: DevTools inspect flag", async () => {
  const ext = new FireflagExtension();

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

  await ext.initialize();
  await ext.loadDatabase(db);
  await ext.openDevToolsPanel();

  // Inspect specific flag
  ext.inspectFlag("privacy.tracking");

  assertEquals(ext.devToolsPanel.selectedFlag, "privacy.tracking");

  ext.reset();
});

Deno.test("E2E: DevTools list all flags", async () => {
  const ext = new FireflagExtension();

  const db: FlagDatabase = {
    "privacy.tracking": {
      key: "privacy.tracking",
      enabled: true,
      value: false,
      defaultValue: true,
    },
    "privacy.cookies": {
      key: "privacy.cookies",
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

  await ext.initialize();
  await ext.loadDatabase(db);
  await ext.openDevToolsPanel();

  assertEquals(ext.devToolsPanel.flags.length, 3);

  ext.reset();
});

Deno.test("E2E: DevTools count matches", async () => {
  const ext = new FireflagExtension();

  const db: FlagDatabase = {
    "privacy.tracking": {
      key: "privacy.tracking",
      enabled: true,
      value: false,
      defaultValue: true,
    },
    "privacy.cookies": {
      key: "privacy.cookies",
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
    "perf.network": {
      key: "perf.network",
      enabled: true,
      value: true,
      defaultValue: false,
    },
  };

  await ext.initialize();
  await ext.loadDatabase(db);

  // Count enabled flags
  const enabledCount = ext.countFlags((f) => f.enabled);
  assertEquals(enabledCount, 3);

  // Count privacy flags
  const privacyFlags = ext.getFlagsByCategory("privacy");
  assertEquals(privacyFlags.length, 2);

  // Count perf flags
  const perfFlags = ext.getFlagsByCategory("perf");
  assertEquals(perfFlags.length, 2);

  ext.reset();
});

// ─────────────────────────────────────────────────────────────────
// E2E Tests: Flag Change Notifications
// ─────────────────────────────────────────────────────────────────

Deno.test("E2E: flag changed → extension notified → state updated", async () => {
  const ext = new FireflagExtension();

  const db: FlagDatabase = {
    "feature.experimental": {
      key: "feature.experimental",
      enabled: true,
      value: false,
      defaultValue: false,
    },
  };

  await ext.initialize();
  await ext.loadDatabase(db);

  // Initial value
  assertEquals(ext.evaluateFlag("feature.experimental"), false);

  // Flag changed
  ext.notifyFlagChanged("feature.experimental", true);

  // State updated
  assertEquals(ext.evaluateFlag("feature.experimental"), true);

  // Change tracked
  const history = ext.getChangeHistory();
  assertEquals(history.some((h) => h.key === "feature.experimental"), true);

  ext.reset();
});

Deno.test("E2E: multiple flag changes tracked", async () => {
  const ext = new FireflagExtension();

  const db: FlagDatabase = {
    "flag.a": {
      key: "flag.a",
      enabled: true,
      value: 1,
      defaultValue: 0,
    },
    "flag.b": {
      key: "flag.b",
      enabled: true,
      value: 2,
      defaultValue: 0,
    },
    "flag.c": {
      key: "flag.c",
      enabled: true,
      value: 3,
      defaultValue: 0,
    },
  };

  await ext.initialize();
  await ext.loadDatabase(db);

  // Make changes
  ext.notifyFlagChanged("flag.a", 10);
  ext.notifyFlagChanged("flag.b", 20);
  ext.notifyFlagChanged("flag.c", 30);

  // Verify changes
  assertEquals(ext.evaluateFlag("flag.a"), 10);
  assertEquals(ext.evaluateFlag("flag.b"), 20);
  assertEquals(ext.evaluateFlag("flag.c"), 30);

  // Verify all tracked
  const history = ext.getChangeHistory();
  assertEquals(history.length, 3);

  ext.reset();
});

// ─────────────────────────────────────────────────────────────────
// E2E Tests: Complex Workflows
// ─────────────────────────────────────────────────────────────────

Deno.test("E2E: complete workflow: init → load → devtools → update → verify", async () => {
  const ext = new FireflagExtension();

  // 1. Initialize
  await ext.initialize();
  assertExists(ext.state.initialized);

  // 2. Load initial database
  const db1: FlagDatabase = {
    "feature.alpha": {
      key: "feature.alpha",
      enabled: true,
      value: "v1",
      defaultValue: "default",
    },
    "feature.beta": {
      key: "feature.beta",
      enabled: false,
      value: "v2",
      defaultValue: "disabled",
    },
  };

  await ext.loadDatabase(db1);
  assertEquals(Object.keys(ext.state.database).length, 2);

  // 3. Evaluate flags
  assertEquals(ext.evaluateFlag("feature.alpha"), "v1");
  assertEquals(ext.evaluateFlag("feature.beta"), "disabled");

  // 4. Open DevTools and inspect
  await ext.openDevToolsPanel();
  assertEquals(ext.devToolsPanel.visible, true);
  assertEquals(ext.devToolsPanel.flags.length, 2);

  ext.inspectFlag("feature.alpha");
  assertEquals(ext.devToolsPanel.selectedFlag, "feature.alpha");

  // 5. Update database
  const db2: FlagDatabase = {
    "feature.alpha": {
      key: "feature.alpha",
      enabled: true,
      value: "v1-updated",
      defaultValue: "default",
    },
    "feature.beta": {
      key: "feature.beta",
      enabled: true, // Now enabled!
      value: "v2-updated",
      defaultValue: "disabled",
    },
    "feature.gamma": {
      key: "feature.gamma",
      enabled: true,
      value: "v3",
      defaultValue: "default",
    },
  };

  await ext.updateDatabase(db2);

  // 6. Verify changes reflected
  assertEquals(ext.evaluateFlag("feature.alpha"), "v1-updated");
  assertEquals(ext.evaluateFlag("feature.beta"), "v2-updated");
  assertEquals(ext.evaluateFlag("feature.gamma"), "v3");

  // 7. Verify DevTools updated
  const updatedFlags = ext.getAllFlags();
  assertEquals(updatedFlags.length, 3);

  ext.reset();
});
