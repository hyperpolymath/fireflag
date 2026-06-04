<!--
SPDX-License-Identifier: MPL-2.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# Proof Requirements

## Current state
- ABI directory exists (template-level)
- No dangerous patterns
- Claims: safety ratings for 105+ Firefox flags, rollback protection

## What needs proving
- **Safety rating consistency**: Prove the safety classification (Safe/Moderate/Advanced/Experimental) is consistent — no flag rated "Safe" that modifies security-relevant settings
- **Rollback correctness**: Prove that rollback restores the exact previous flag state (no partial rollback, no stale values)
- **Flag conflict detection**: Prove that enabling conflicting flags is detected and reported (no silent undefined behavior from flag combinations)

## Recommended prover
- **Idris2** — Small enough domain that a complete flag-property model is feasible

## Priority
- **LOW** — FireFlag is a browser extension with safety ratings. The risk is user confusion rather than data loss. Proofs would increase credibility but are not urgently needed.
