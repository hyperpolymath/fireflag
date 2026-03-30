# Test & Benchmark Requirements

## Current State
- Unit tests: NONE
- Integration tests: NONE
- E2E tests: NONE
- Benchmarks: NONE
- panic-attack scan: NEVER RUN

## What's Missing
### Point-to-Point (P2P)
12 ReScript + 16 JavaScript + 9 Idris2 source files with ZERO tests:

#### Extension (ReScript — 4 unique modules, duplicated in lib/):
- Types.res — no tests
- BrowserAPI.res — no tests
- DevTools.res — no tests
- DatabaseUpdater.res — no tests

#### Extension (JavaScript — 16 files):
- All JS files untested

#### Idris2 ABI (9 files):
- No verification tests

Note: Files appear duplicated across extension/lib/rescript/, lib/bs/, lib/ocaml/ — suggests build output mixed with source. Clean separation needed.

### End-to-End (E2E)
- Browser extension lifecycle: install -> configure -> activate -> flag features
- Feature flag evaluation: check flag -> apply -> verify correct behavior
- DevTools panel: open -> inspect flags -> modify -> verify
- Database update: fetch new flags -> update local store -> apply
- Cross-browser compatibility (Firefox / Chrome)

### Aspect Tests
- [ ] Security (flag injection via DevTools, unauthorized flag modification, XSS in extension UI)
- [ ] Performance (flag evaluation latency, database update speed)
- [ ] Concurrency (flag changes during evaluation, database update races)
- [ ] Error handling (network failure during update, corrupt flag database)
- [ ] Accessibility (DevTools panel keyboard navigation, screen reader)

### Build & Execution
- [ ] ReScript build — not verified
- [ ] Extension loads in Firefox — not verified
- [ ] Extension loads in Chrome — not verified
- [ ] DevTools panel renders — not verified
- [ ] Self-diagnostic — none

### Benchmarks Needed
- Flag evaluation latency (should be sub-millisecond)
- Database update speed
- Extension memory footprint
- Impact on page load time

### Self-Tests
- [ ] panic-attack assail on own repo
- [ ] Extension self-test on known test page
- [ ] Clean up build output mixed with source files

## Priority
- **HIGH** — Browser extension (12 ReScript + 16 JS + 9 Idris2 files) with ZERO tests. Feature flag systems need absolute correctness — a wrong flag evaluation can break production features for users. The codebase also has build artifacts mixed with source (lib/bs/, lib/ocaml/ appear to be ReScript build output), which needs cleanup.

## FAKE-FUZZ ALERT

- `tests/fuzz/placeholder.txt` is a scorecard placeholder inherited from rsr-template-repo — it does NOT provide real fuzz testing
- Replace with an actual fuzz harness (see rsr-template-repo/tests/fuzz/README.adoc) or remove the file
- Priority: P2 — creates false impression of fuzz coverage
