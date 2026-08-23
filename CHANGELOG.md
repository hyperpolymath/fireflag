<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# Changelog

All notable changes to `fireflag` will be documented in this file.

This file is generated from conventional commits by the
[`changelog-reusable.yml`](https://github.com/hyperpolymath/standards/blob/main/.github/workflows/changelog-reusable.yml)
workflow (`hyperpolymath/standards#206`). Adopt the workflow in this repo's CI to keep this file in sync automatically — see
[`templates/cliff.toml`](https://github.com/hyperpolymath/standards/blob/main/templates/cliff.toml)
for the canonical config.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- feat: add PRIVACY.html for GitHub Pages (#19)
- feat: add browser-extension mode panic-attacker report
- feat: address panic-attacker findings
- feat: add panic-attacker assail report
- feat: add privacy policy URL to manifest.json
- feat(crg): add crg-grade and crg-badge justfile recipes
- feat: add stapeln.toml container definition
- feat: deploy UX Manifesto infrastructure
- feat: add CLADE.a2ml — clade taxonomy declaration
- feat(android): enable Firefox Android support with min version 142

### Fixed

- fix(ci): bump a2ml/k9-validate-action pins to canonical (#27)
- fix(ci): sync hypatia-scan.yml to canonical (#26)
- fix(ci): adopt canonical hypatia-scan.yml (#25)
- fix(ci): Phase-2 fleet submission must not fail the security gate (#24)
- fix(ci): hypatia-scan workdir (${{ env.HOME }} resolves empty) (#23)
- fix(ci): move secret-scanner Cargo.toml gate from job-level if: to step-level (#21)
- fix(scorecard): enforce granular permissions and add fuzzing placeholder
- fix(ci): Resolve workflow-linter self-matching and metadata issues
- fix(scorecard): enforce granular permissions and add fuzzing placeholder
- fix(ci): Resolve workflow-linter self-matching and metadata issues

### Changed

- refactor(tests): transpile TS test suite to AffineScript
- refactor: migrate 6SCM → 6A2 (.scm → .a2ml format)

### Documentation

- docs(tests): sync STATE.a2ml + TEST-NEEDS + CRG audit to AffineScript tests
- docs(governance): CRG v2.0 STRICT audit — C (declared) -> D (honest)
- docs: add submission ready checklist
- docs: add release notes for v0.1.0
- docs: update submission description with actual screenshots
- docs: add Mozilla submission documents
- docs: substantive CRG C annotation (EXPLAINME.adoc)
- docs: add TEST-NEEDS.md and/or PROOF-NEEDS.md from audit
- docs: add EXPLAINME.adoc — prove-it file backing README claims
- docs: add security compliance analysis

### CI

- ci: redistribute concurrency-cancel guard to read-only check workflows (#28)
- ci(secret-scanner): drop duplicate --fail from trufflehog extra_args (#20)
- ci: SHA-pin hyperpolymath validate-actions in dogfood-gate
- ci: restore Dependabot security path + wire auto-merge
- ci: deploy dogfood-gate, fix hypatia-scan, add pre-commit hooks

## Pre-history

Prior commits to this file's introduction are recorded in git history but not formally classified into Keep-a-Changelog sections. To backfill, run `git cliff -o CHANGELOG.md` locally using the canonical [`cliff.toml`](https://github.com/hyperpolymath/standards/blob/main/templates/cliff.toml) — this is one-shot mechanical work.

---

<!-- This file was seeded by the 2026-05-26 estate tech-debt audit follow-up (Row-2 Phase 3); see [`hyperpolymath/standards/docs/audits/2026-05-26-estate-documentation-debt.md`](https://github.com/hyperpolymath/standards/blob/main/docs/audits/2026-05-26-estate-documentation-debt.md). -->
