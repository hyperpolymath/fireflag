<!--
SPDX-License-Identifier: MPL-2.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# FireFlag — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              FIREFOX USER               │
                        │        (about:config Management)        │
                        └──────────┬───────────────────┬──────────┘
                                   │                   │
                                   ▼                   ▼
                        ┌───────────────────┐  ┌───────────────────┐
                        │ EXTENSION POPUP   │  │ SIDEBAR PANEL     │
                        │ (Search & Toggle) │  │ (History & Export)│
                        └──────────┬────────┘  └──────────┬────────┘
                                   │                      │
                                   └──────────┬───────────┘
                                              │
                                              ▼
                        ┌─────────────────────────────────────────┐
                        │           SERVICE WORKER (BG)           │
                        │    (Browser API, Storage Orchestrator)  │
                        └──────────┬───────────────────┬──────────┘
                                   │                   │
                                   ▼                   ▼
                        ┌───────────────────────┐  ┌────────────────────────────────┐
                        │ FLAG DATABASE         │  │ SECURITY & PROOFS              │
                        │ - 105+ Config Flags   │  │ - Idris2 Safety Proofs         │
                        │ - Safety Ratings      │  │ - CodeQL Static Analysis       │
                        │ - Documentation       │  │ - SLSA Level 3 Provenance      │
                        └──────────┬────────────┘  └────────────────────────────────┘
                                   │
                                   ▼
                        ┌─────────────────────────────────────────┐
                        │           FIREFOX GECKO CORE            │
                        │      (Pref Service, about:config)       │
                        └─────────────────────────────────────────┘

                        ┌─────────────────────────────────────────┐
                        │          REPO INFRASTRUCTURE            │
                        │  Justfile / web-ext .machine_readable/  │
                        │  Guix / Chainguard  RSR Gold (100%)     │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
EXTENSION UI
  Browser Action Popup              ██████████ 100%    Search & toggle stable
  Sidebar Panel                     ██████████ 100%    History & export verified
  DevTools Panel                    ██████████ 100%    Impact analysis active
  Options Page                      ██████████ 100%    Permission management stable

CORE & DATABASE
  Flag Database (105 flags)         ██████████ 100%    Safety documentation complete
  Background Service Worker         ██████████ 100%    Storage orchestration verified
  Idris2 Safety Proofs              ██████████ 100%    Verified ABI boundary

REPO INFRASTRUCTURE
  Justfile Automation               ██████████ 100%    Standard build/lint/run
  .machine_readable/                ██████████ 100%    STATE.scm tracking
  Guix / Chainguard Build           ██████████ 100%    Reproducible .xpi package

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            ██████████ 100%    v0.1.0 Ready for Submission
```

## Key Dependencies

```
Idris2 Proofs ───► Background ──────► Browser Storage ───► Firefox Prefs
     │                 │                   │
     ▼                 ▼                   ▼
ReScript Types ──► Extension UI ────► Flag Metadata
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
