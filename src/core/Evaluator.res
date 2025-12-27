// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2024 Jonathan D.A. Jewell <hyperpolymath>

/**
 * Flag Evaluation Engine
 *
 * Evaluates feature flags against contexts using targeting rules,
 * percentage rollouts, and consistent hashing for deterministic results.
 */

open Types

// Simple hash function for consistent bucketing
// Production should use SHA-256 via SubtleCrypto
let hashString = (input: string): int => {
  let hash = ref(5381)
  for i in 0 to String.length(input) - 1 {
    let char = String.charCodeAt(input, i)->Float.toInt
    hash := Int.land(Int.lsl(hash.contents, 5) + hash.contents + char, 0x7FFFFFFF)
  }
  hash.contents
}

// Compute bucket for percentage rollout (0-99)
let computeBucket = (~flagKey: string, ~userId: string, ~seed: string): int => {
  let hashInput = `${seed}:${flagKey}:${userId}`
  let hash = hashString(hashInput)
  mod(hash, 100)
}

// Evaluate percentage rollout
let evaluateRollout = (
  ~flagKey: string,
  ~userId: string,
  ~percentage: float,
  ~seed: string,
): bool => {
  let bucket = computeBucket(~flagKey, ~userId, ~seed)->Int.toFloat
  bucket < percentage
}

// Evaluate a single targeting rule against context
let evaluateRule = (rule: targetingRule, ctx: evaluationContext): bool => {
  let attrValue = Js.Dict.get(ctx.attributes, rule.attribute)

  let result = switch (attrValue, rule.operator) {
  | (None, _) => false
  | (Some(actual), Equals) => actual == rule.value
  | (Some(actual), NotEquals) => actual != rule.value
  | (Some(actual), Contains) => String.includes(actual, rule.value)
  | (Some(actual), StartsWith) => String.startsWith(actual, rule.value)
  | (Some(actual), EndsWith) => String.endsWith(actual, rule.value)
  | (Some(actual), In) =>
    String.split(rule.value, ",")->Array.some(v => String.trim(v) == actual)
  | (Some(actual), NotIn) =>
    !(String.split(rule.value, ",")->Array.some(v => String.trim(v) == actual))
  | (Some(actual), GreaterThan) =>
    switch (Float.fromString(actual), Float.fromString(rule.value)) {
    | (Some(a), Some(b)) => a > b
    | _ => false
    }
  | (Some(actual), GreaterThanOrEqual) =>
    switch (Float.fromString(actual), Float.fromString(rule.value)) {
    | (Some(a), Some(b)) => a >= b
    | _ => false
    }
  | (Some(actual), LessThan) =>
    switch (Float.fromString(actual), Float.fromString(rule.value)) {
    | (Some(a), Some(b)) => a < b
    | _ => false
    }
  | (Some(actual), LessThanOrEqual) =>
    switch (Float.fromString(actual), Float.fromString(rule.value)) {
    | (Some(a), Some(b)) => a <= b
    | _ => false
    }
  | (Some(actual), Regex) =>
    switch Js.Re.fromString(rule.value) {
    | re => Js.Re.test(re, actual)
    | exception _ => false
    }
  }

  rule.negate ? !result : result
}

// Evaluate all rules (AND logic)
let evaluateRules = (rules: array<targetingRule>, ctx: evaluationContext): option<int> => {
  let rec loop = (i: int): option<int> => {
    if i >= Array.length(rules) {
      None
    } else {
      switch rules[i] {
      | Some(rule) =>
        if evaluateRule(rule, ctx) {
          Some(i)
        } else {
          loop(i + 1)
        }
      | None => loop(i + 1)
      }
    }
  }
  loop(0)
}

// Main flag evaluation function
let evaluate = (flag: flagWithMeta, ctx: evaluationContext): evaluationResult => {
  let {flag: f, meta: _} = flag

  // Check if flag is disabled
  if f.state == Disabled || f.state == Archived {
    {
      flagKey: f.key,
      value: f.defaultValue,
      reason: "flag_disabled",
      ruleIndex: None,
      cached: false,
      stale: false,
    }
  } else {
    // Evaluate based on flag type
    switch f.flagType {
    | Boolean => {
        flagKey: f.key,
        value: f.value,
        reason: "fallthrough",
        ruleIndex: None,
        cached: false,
        stale: false,
      }

    | Variant => {
        flagKey: f.key,
        value: f.value,
        reason: "fallthrough",
        ruleIndex: None,
        cached: false,
        stale: false,
      }

    | Rollout =>
      switch (ctx.userId, f.percentage, f.hashSeed) {
      | (Some(userId), Some(percentage), Some(seed)) =>
        let isEnabled = evaluateRollout(~flagKey=f.key, ~userId, ~percentage, ~seed)
        {
          flagKey: f.key,
          value: Bool(isEnabled),
          reason: isEnabled ? "rollout_included" : "rollout_excluded",
          ruleIndex: None,
          cached: false,
          stale: false,
        }
      | (None, _, _) => {
          flagKey: f.key,
          value: f.defaultValue,
          reason: "no_user_id",
          ruleIndex: None,
          cached: false,
          stale: false,
        }
      | _ => {
          flagKey: f.key,
          value: f.defaultValue,
          reason: "rollout_config_missing",
          ruleIndex: None,
          cached: false,
          stale: false,
        }
      }

    | Segment =>
      switch f.rules {
      | Some(rules) =>
        switch evaluateRules(rules, ctx) {
        | Some(ruleIndex) => {
            flagKey: f.key,
            value: f.value,
            reason: "rule_match",
            ruleIndex: Some(ruleIndex),
            cached: false,
            stale: false,
          }
        | None => {
            flagKey: f.key,
            value: f.defaultValue,
            reason: "no_rule_match",
            ruleIndex: None,
            cached: false,
            stale: false,
          }
        }
      | None => {
          flagKey: f.key,
          value: f.defaultValue,
          reason: "no_rules",
          ruleIndex: None,
          cached: false,
          stale: false,
        }
      }
    }
  }
}

// Evaluate and extract boolean value
let evaluateBool = (flag: flagWithMeta, ctx: evaluationContext): bool => {
  let result = evaluate(flag, ctx)
  switch result.value {
  | Bool(b) => b
  | _ => false
  }
}

// Evaluate and extract string value
let evaluateString = (flag: flagWithMeta, ctx: evaluationContext): string => {
  let result = evaluate(flag, ctx)
  switch result.value {
  | String(s) => s
  | Bool(b) => b ? "true" : "false"
  | Int(i) => Int.toString(i)
  | Float(f) => Float.toString(f)
  | Json(j) => Js.Json.stringify(j)
  }
}

// Create a default context
let defaultContext = (): evaluationContext => {
  userId: None,
  sessionId: None,
  attributes: Js.Dict.empty(),
  timestamp: Date.now(),
}

// Create context with user ID
let contextWithUser = (userId: string): evaluationContext => {
  userId: Some(userId),
  sessionId: None,
  attributes: Js.Dict.empty(),
  timestamp: Date.now(),
}

// Add attribute to context
let withAttribute = (ctx: evaluationContext, key: string, value: string): evaluationContext => {
  let newAttrs = Js.Dict.fromArray(Js.Dict.entries(ctx.attributes))
  Js.Dict.set(newAttrs, key, value)
  {...ctx, attributes: newAttrs}
}
