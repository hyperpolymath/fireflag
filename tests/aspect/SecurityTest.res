// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//
// Security aspect tests for fireflag extension.
//
// Tests cross-cutting security concerns:
//   - Flag ID injection protection (path traversal, etc.)
//   - XSS prevention in flag values (HTML escaping)
//   - Unauthorized modification prevention (readonly flags)
//   - DevTools injection protection (malformed JSON handling)
//
// Transpiled from tests/aspect/security_test.ts (2026-04-18).

open Bindings

type unknown

external toU: 'a => unknown = "%identity"

// ─────────────────────────────────────────────────────────────────
// Type definitions
// ─────────────────────────────────────────────────────────────────

// `mutable value` lets the TS `flag.value = newValue` mutation pattern
// port directly; the extension runtime uses the same shape.
type flag = {
  key: string,
  enabled: bool,
  mutable value: unknown,
  defaultValue: unknown,
  readonly_: bool,
}

type flagDatabase = Dict.t<flag>

type modifyResult = {
  success: bool,
  error: option<string>,
}

// ─────────────────────────────────────────────────────────────────
// Security Implementation
// ─────────────────────────────────────────────────────────────────

@scope("JSON") @val external stringify: 'a => string = "stringify"
@scope("JSON") @val external parse: string => 'a = "parse"

let idRegex = %re("/^[a-zA-Z0-9._-]+$/")

let isValidFlagId = (id: string): bool => {
  if Js.typeof(id) !== "string" || String.length(id) == 0 {
    false
  } else {
    Js.Re.test_(idRegex, id)
  }
}

// Replacement callback for escapeHtml — kept as a plain dict lookup
// to mirror the TS map.
let htmlEntityMap: Dict.t<string> = {
  let d = Dict.make()
  Dict.set(d, "&", "&amp;")
  Dict.set(d, "<", "&lt;")
  Dict.set(d, ">", "&gt;")
  Dict.set(d, "\"", "&quot;")
  Dict.set(d, "'", "&#039;")
  d
}

let htmlEscapeRegex = %re(`/[&<>"']/g`)

let escapeHtml = (text: 'a): string => {
  if Js.typeof(text) !== "string" {
    // Uses String(text) coercion in TS — reproduce via raw JS
    %raw(`function(x){return String(x)}`)(text)
  } else {
    let s: string = Obj.magic(text)
    s->Js.String2.replaceByRe(htmlEscapeRegex, %raw(`function(ch){
      const map = {"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#039;"};
      return map[ch];
    }`))
  }
}

let getSafeValue = (flag: flag): string => {
  if flag.enabled {
    let value = flag.value
    if Js.typeof(value) === "string" {
      escapeHtml(value)
    } else {
      escapeHtml(stringify(value))
    }
  } else {
    escapeHtml(stringify(flag.defaultValue))
  }
}

let validateJson = (json: string): bool => {
  try {
    let _: 'a = parse(json)
    true
  } catch {
  | _ => false
  }
}

let safeParseJson = (json: string, fallback: 'a): 'a => {
  try {
    parse(json)
  } catch {
  | _ => fallback
  }
}

let isFlagReadonly = (flag: flag): bool => flag.readonly_

let modifyFlag = (flagId: string, newValue: unknown, database: flagDatabase): modifyResult => {
  if !isValidFlagId(flagId) {
    {success: false, error: Some("Invalid flag ID")}
  } else {
    switch Dict.get(database, flagId) {
    | None => {success: false, error: Some("Flag not found")}
    | Some(flag) =>
      if isFlagReadonly(flag) {
        {success: false, error: Some("Flag is readonly")}
      } else {
        flag.value = newValue
        {success: true, error: None}
      }
    }
  }
}

let mkFlag = (~key, ~enabled, ~value, ~defaultValue, ~readonly=false, ()): flag => {
  key,
  enabled,
  value,
  defaultValue,
  readonly_: readonly,
}

let singleton = (key, flag) => {
  let d = Dict.make()
  Dict.set(d, key, flag)
  d
}

// ─────────────────────────────────────────────────────────────────
// Security Tests: Flag ID Injection
// ─────────────────────────────────────────────────────────────────

test("Security: reject path traversal in flag IDs", () => {
  let maliciousIds = [
    "../../../etc/passwd",
    "..\\..\\..\\windows\\system32",
    "flag./../../../config",
    "feature/../../../../secrets",
  ]
  maliciousIds->Array.forEach(id => assertEquals(isValidFlagId(id), false))
})

test("Security: reject null bytes in flag IDs", () => {
  assertEquals(isValidFlagId("flag\x00injection"), false)
  assertEquals(isValidFlagId("flag\u0000injection"), false)
})

test("Security: reject special shell characters in flag IDs", () => {
  let shellChars = [
    "flag;rm -rf /",
    "flag$(whoami)",
    "flag`id`",
    "flag|cat",
    "flag&sleep 10",
    "flag>output.txt",
  ]
  shellChars->Array.forEach(id => assertEquals(isValidFlagId(id), false))
})

test("Security: accept valid flag IDs", () => {
  let validIds = [
    "privacy.tracking",
    "perf.cache",
    "feature_new",
    "flag-123",
    "x",
    "A1.b2_c3-d4",
  ]
  validIds->Array.forEach(id => assertEquals(isValidFlagId(id), true))
})

test("Security: reject empty flag IDs", () => {
  assertEquals(isValidFlagId(""), false)
  assertEquals(isValidFlagId(" "), false)
})

// ─────────────────────────────────────────────────────────────────
// Security Tests: XSS Prevention
// ─────────────────────────────────────────────────────────────────

test("Security: escape HTML in flag values", () => {
  let xssPayloads = [
    "<script>alert(\"xss\")</script>",
    "<img src=x onerror=\"alert(1)\">",
    "<svg onload=\"alert(1)\">",
    "\"><script>alert(1)</script>",
    "javascript:alert(1)",
  ]
  xssPayloads->Array.forEach(payload => {
    let escaped = escapeHtml(payload)
    assertEquals(escaped->String.includes("<"), false)
    assertEquals(escaped->String.includes(">"), false)
    assertEquals(String.length(escaped) > 0, true)
  })
})

test("Security: escapeHtml preserves content", () => {
  let original = "Hello & <World> \"Test\""
  let escaped = escapeHtml(original)
  assertStringIncludes(escaped, "Hello")
  assertStringIncludes(escaped, "World")
  assertStringIncludes(escaped, "Test")
})

test("Security: getSafeValue escapes string flags", () => {
  let flag = mkFlag(
    ~key="test",
    ~enabled=true,
    ~value=toU("<script>alert(\"xss\")</script>"),
    ~defaultValue=toU("default"),
    (),
  )
  let safe = getSafeValue(flag)
  assertEquals(safe->String.includes("<script>"), false)
  assertEquals(safe->String.includes("&lt;script&gt;"), true)
})

test("Security: getSafeValue returns default when disabled", () => {
  let flag = mkFlag(
    ~key="test",
    ~enabled=false,
    ~value=toU("<script>alert(\"xss\")</script>"),
    ~defaultValue=toU("safe-default"),
    (),
  )
  let safe = getSafeValue(flag)
  assertStringIncludes(safe, "safe-default")
})

test("Security: non-string values safely stringified", () => {
  let cases = [
    (toU(123), "number"),
    (toU(true), "boolean"),
    (%raw(`null`), "null"),
    (toU({"key": "value"}), "object"),
    (toU([1, 2, 3]), "array"),
  ]
  cases->Array.forEach(((v, _desc)) => {
    let flag = mkFlag(~key="test", ~enabled=true, ~value=v, ~defaultValue=toU("default"), ())
    let safe = getSafeValue(flag)
    assertEquals(Js.typeof(safe), "string")
    assertEquals(String.length(safe) > 0, true)
  })
})

// ─────────────────────────────────────────────────────────────────
// Security Tests: Unauthorized Modification
// ─────────────────────────────────────────────────────────────────

test("Security: readonly flags cannot be modified", () => {
  let db = singleton(
    "system.immutable",
    mkFlag(
      ~key="system.immutable",
      ~enabled=true,
      ~value=toU("original"),
      ~defaultValue=toU("default"),
      ~readonly=true,
      (),
    ),
  )
  let result = modifyFlag("system.immutable", toU("new-value"), db)
  assertEquals(result.success, false)
  assertEquals(result.error, Some("Flag is readonly"))
  // Value should not have changed — assert by-value on the raw JS side.
  let flag = Dict.get(db, "system.immutable")->Option.getUnsafe
  assertEquals(flag.value, toU("original"))
})

test("Security: writable flags can be modified", () => {
  let db = singleton(
    "feature.mutable",
    mkFlag(
      ~key="feature.mutable",
      ~enabled=true,
      ~value=toU("original"),
      ~defaultValue=toU("default"),
      ~readonly=false,
      (),
    ),
  )
  let result = modifyFlag("feature.mutable", toU("new-value"), db)
  assertEquals(result.success, true)
  let flag = Dict.get(db, "feature.mutable")->Option.getUnsafe
  assertEquals(flag.value, toU("new-value"))
})

test("Security: reject modification of nonexistent flags", () => {
  let db = Dict.make()
  let result = modifyFlag("nonexistent.flag", toU("value"), db)
  assertEquals(result.success, false)
  assertEquals(result.error, Some("Flag not found"))
})

test("Security: reject modification with invalid flag ID", () => {
  let db = singleton(
    "valid.flag",
    mkFlag(
      ~key="valid.flag",
      ~enabled=true,
      ~value=toU("original"),
      ~defaultValue=toU("default"),
      (),
    ),
  )
  let result = modifyFlag("../../../etc/passwd", toU("malicious"), db)
  assertEquals(result.success, false)
  assertEquals(result.error, Some("Invalid flag ID"))
})

// ─────────────────────────────────────────────────────────────────
// Security Tests: DevTools Injection
// ─────────────────────────────────────────────────────────────────

test("Security: reject malformed JSON from DevTools", () => {
  let malformed = [
    "{invalid json}",
    "{'single': 'quotes'}",
    "{incomplete:",
    "{\"key\": undefined}",
    "{\"key\": function() {}}",
  ]
  malformed->Array.forEach(json => assertEquals(validateJson(json), false))
})

test("Security: accept valid JSON from DevTools", () => {
  let validJson = [
    "{}",
    "{\"key\":\"value\"}",
    "[1,2,3]",
    "{\"nested\":{\"deep\":\"value\"}}",
    "null",
    "true",
    "123",
    "\"string\"",
  ]
  validJson->Array.forEach(json => assertEquals(validateJson(json), true))
})

test("Security: safeParseJson returns fallback on invalid JSON", () => {
  let fallback = {"default": "value"}
  let result1 = safeParseJson("{invalid}", fallback)
  assertEquals(result1, fallback)

  let result2: {"valid": string} = safeParseJson("{\"valid\":\"json\"}", Obj.magic(fallback))
  assertEquals(result2["valid"], "json")
})

test("Security: DevTools cannot inject arbitrary code", () => {
  let injectedJson = stringify({
    "key": "test",
    "constructor": {"prototype": {"polluted": true}},
  })
  let result: 'a = safeParseJson(injectedJson, Obj.magic(%raw(`{}`)))
  assertEquals(Js.typeof(result), "object")

  // Property pollution should not affect other objects.
  let clean = %raw(`{}`)
  let polluted: bool = %raw(`function(o){return Object.prototype.hasOwnProperty.call(o,"polluted")}`)(
    clean,
  )
  assertEquals(polluted, false)
})

// ─────────────────────────────────────────────────────────────────
// Security Tests: Combined Threats
// ─────────────────────────────────────────────────────────────────

test("Security: combined threat - malicious ID + XSS + JSON injection", () => {
  let db = singleton(
    "safe.flag",
    mkFlag(
      ~key="safe.flag",
      ~enabled=true,
      ~value=toU("normal"),
      ~defaultValue=toU("default"),
      (),
    ),
  )

  let maliciousId = "../../../etc/passwd"
  let xssValue = toU("<script>alert(\"xss\")</script>")
  let result1 = modifyFlag(maliciousId, xssValue, db)
  assertEquals(result1.success, false)
  let flag = Dict.get(db, "safe.flag")->Option.getUnsafe
  assertEquals(flag.value, toU("normal"))

  let invalidJson = "{corrupted}"
  let fallback = {"safe": true}
  let result2: {"safe": bool} = safeParseJson(invalidJson, fallback)
  assertEquals(result2["safe"], true)
})

test("Security: escapeHtml handles edge cases", () => {
  let cases = [
    ("", ""),
    ("normal text", "normal text"),
    ("&", "&amp;"),
    ("&&", "&amp;&amp;"),
    ("<>", "&lt;&gt;"),
    ("\"\"", "&quot;&quot;"),
    ("''", "&#039;&#039;"),
    ("&<>\"'", "&amp;&lt;&gt;&quot;&#039;"),
  ]
  cases->Array.forEach(((input, expected)) => {
    let result = escapeHtml(input)
    assertEquals(result, expected)
  })
})

test("Security: all readonly flags remain protected", () => {
  let db = Dict.make()
  Dict.set(
    db,
    "system.flag1",
    mkFlag(
      ~key="system.flag1",
      ~enabled=true,
      ~value=toU("v1"),
      ~defaultValue=toU("d1"),
      ~readonly=true,
      (),
    ),
  )
  Dict.set(
    db,
    "system.flag2",
    mkFlag(
      ~key="system.flag2",
      ~enabled=true,
      ~value=toU("v2"),
      ~defaultValue=toU("d2"),
      ~readonly=true,
      (),
    ),
  )
  Dict.set(
    db,
    "user.flag",
    mkFlag(
      ~key="user.flag",
      ~enabled=true,
      ~value=toU("v3"),
      ~defaultValue=toU("d3"),
      ~readonly=false,
      (),
    ),
  )

  assertEquals(modifyFlag("system.flag1", toU("hacked"), db).success, false)
  assertEquals(modifyFlag("system.flag2", toU("hacked"), db).success, false)
  assertEquals(modifyFlag("user.flag", toU("allowed"), db).success, true)

  assertEquals(Dict.get(db, "system.flag1")->Option.getUnsafe->(f => f.value), toU("v1"))
  assertEquals(Dict.get(db, "system.flag2")->Option.getUnsafe->(f => f.value), toU("v2"))
  assertEquals(Dict.get(db, "user.flag")->Option.getUnsafe->(f => f.value), toU("allowed"))
})
