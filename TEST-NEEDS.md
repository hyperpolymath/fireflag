<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# Test & Benchmark Requirements

## CRG Grade: C — ACHIEVED 2026-04-04

94 tests passing (deno test, 0 failures). All CRG C categories met.

## Current State (UPDATED 2026-04-18)
- Unit tests: 42 tests (COMPLETE)
  - TypesTest.res: 23 tests for type definitions and validation
  - FlagEvaluationTest.res: 19 tests for flag evaluation logic
- Property-based tests: 18 tests (COMPLETE)
  - FlagPropertiesTest.res: 18 property tests for invariants
- Integration tests: 13 tests (COMPLETE)
  - ExtensionLifecycleTest.res: 13 E2E workflow tests
- Aspect tests: 21 tests (COMPLETE)
  - SecurityTest.res: 21 security aspect tests
- Benchmarks: 26 benchmarks (COMPLETE)
  - FlagBench.res: performance baselines
- panic-attack scan: READY (use `just assail`)

**Transpilation status (2026-04-18):** The entire TS test suite was
transpiled to AffineScript (per the hyperpolymath language policy's "no new
TypeScript files" rule).  Semantic parity was the acceptance criterion;
all 94 tests pass under `deno task test`.  The counts above differ
slightly from the original TS tallies because AffineScript's variant
exhaustiveness merged a couple of duplicate string-tag checks and the
benchmark module shed two near-identical cases during conversion.

## Completed: Comprehensive Test Suite

### Unit Tests (42 tests)

**TypesTest.res (23 tests):**
- Flag key validation (non-empty, dot notation, injection prevention)
- Flag value type validation (boolean, string, integer, float)
- Flag configuration validation (required fields, type mismatches)
- Safety level variants
- Category variants
- Flag state tracking (creation, modification sources)
- Flag change records
- Flag database structure
- Environment variants
- Browser permissions
- Type composition

**FlagEvaluationTest.res (19 tests):**
- Enabled flags return values
- Disabled flags return defaults
- Missing flags return undefined (no crash)
- Environment filtering (prod-only, multi-env, no restriction)
- Override precedence over values
- User-specific overrides
- Multi-flag operations (get all, by category)
- Complex scenarios (override + environment, disabled ignores override)
- Batch evaluation (100 flags)

### Property-Based Tests (18 tests)

**FlagPropertiesTest.res:**
- Evaluation determinism (100 iterations, small/medium/disabled/missing)
- Disabled flag invariant (never return non-default)
- Enabled flag invariant (always return value when available)
- Flag ID invariants (always string, never null/undefined)
- Serialization round-trip correctness
- Evaluation identical before/after serialization
- Complex nested values round-trip
- Large-scale invariants (1000 flags determinism, disabled invariant, 500-flag serialization)
- Edge cases (empty ID, null value, undefined default, false as value, zero as value)

### E2E Integration Tests (13 tests)

**ExtensionLifecycleTest.res:**
- Extension initialization
- Database loading
- Flag evaluation → load → evaluate flow
- Multiple flag evaluation
- Database updates and change tracking
- DevTools panel opening
- DevTools flag inspection
- DevTools flag listing
- DevTools flag counting and filtering
- Flag change notifications
- Multiple flag changes
- Complete workflow (init → load → devtools → update → verify)

### Security Aspect Tests (21 tests)

**SecurityTest.res:**
- Flag ID injection prevention (path traversal, null bytes, shell chars)
- Valid flag ID acceptance
- HTML escaping in values
- XSS payload neutralization
- Safe value retrieval
- Readonly flag protection
- Writable flag modification
- Invalid ID rejection
- Malformed JSON rejection
- Valid JSON acceptance
- Safe JSON parsing with fallbacks
- DevTools code injection prevention
- Combined threat scenarios
- Edge case HTML escaping
- Readonly flag batch protection

### Benchmarks (26 benchmarks)

**FlagBench.res - Performance Baselines:**
- Small database (10 flags): lookup, batch, missing
- Medium database (100 flags): early/middle/late, random, all
- Large database (10k flags): early/middle/late, batch
- Serialization: 100-flag serialize/deserialize
- Deserialization: 10k-flag serialize/deserialize
- Complex operations: all flags, by category, filter
- Database creation: 10/100/10k flag sizes
- Stress tests: 1000 lookups, 100 in 10k, sequential, random access

Results show:
- Single flag lookup: 1.1-1.2 µs (10 flags), 18-19 µs (100 flags), 2.5 ms (10k flags)
- Serialization: 51.5 µs (100 flags), 7.2 ms (10k flags)
- Deterministic evaluation across all database sizes

### Remaining Work

#### Build & Execution
- [ ] AffineScript build verification (use `just build`)
- [ ] Extension loads in Firefox (manual test)
- [ ] Extension loads in Chrome (manual test)
- [ ] DevTools panel renders (manual test)

#### Additional Aspect Tests
- [ ] Concurrency (flag changes during evaluation)
- [ ] Error handling (network failure, corrupt database)
- [ ] Accessibility (DevTools keyboard navigation)

#### Integration
- [ ] Extension self-test on known test page
- [ ] panic-attack assail scan (use `just assail`)

## Priority
- **HIGH** — Browser extension (12 AffineScript + 16 JS + 9 Idris2 files) with ZERO tests. Feature flag systems need absolute correctness — a wrong flag evaluation can break production features for users. The codebase also has build artifacts mixed with source (lib/bs/, lib/ocaml/ appear to be AffineScript build output), which needs cleanup.

## Fuzz Testing Status

- `tests/fuzz/placeholder.txt` — REMOVED (2026-04-04)
- Replaced with comprehensive property-based tests in `tests/property/`
- Property tests validate invariants at scale (1000 flags, large serialization)
- Future: Consider fuzz harness for complex JSON edge cases (low priority)
