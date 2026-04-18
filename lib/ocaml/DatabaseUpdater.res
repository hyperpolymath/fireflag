// SPDX-License-Identifier: MPL-2.0
// (PMPL-1.0-or-later preferred; MPL-2.0 required for Firefox extension store)
// Copyright (C) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

/**
 * Flag Database Auto-Updater
 *
 * Keeps flag database current with Mozilla's changes:
 * - Weekly checks for database updates from GitHub
 * - Detects deprecated/removed flags
 * - Validates against current Firefox version
 * - Community contribution pipeline
 */

open Types

// Fetch API bindings (browser global)
module Fetch = {
  type response

  @val external fetch: string => promise<response> = "fetch"

  module Response = {
    @get external ok: response => bool = "ok"
    @send external json: response => promise<JSON.t> = "json"
  }
}

type databaseVersion = {
  version: string,
  lastUpdated: string,
  minimumGeckoVersion: string,
  maximumGeckoVersion: option<string>,
}

type updateSource =
  | GitHub(string) // GitHub release URL
  | Community(string) // Community PR URL
  | Manual(string) // Manual update file

type updateStatus =
  | UpToDate
  | UpdateAvailable(databaseVersion)
  | UpdateRequired(string) // Reason for requirement
  | UpdateFailed(string) // Error message

// --- JSON parsing helpers (must be defined before callers) ---

// Parse safety level string to variant
let parseSafetyLevel = (s: string): safetyLevel =>
  switch s {
  | "safe" => Safe
  | "dangerous" => Dangerous
  | _ => Experimental
  }

// Parse value type string to variant
let parseValueType = (s: string): flagValueType =>
  switch s {
  | "boolean" => Boolean
  | "string" => String
  | "integer" => Integer
  | "float" => Float
  | _ => Boolean
  }

// Parse category string to variant
let parseCategory = (s: string): flagCategory =>
  switch s {
  | "privacy" => Privacy
  | "performance" => Performance
  | "experimental" => ExperimentalFeatures
  | "developer" => Developer
  | "ui" => UserInterface
  | "network" => Network
  | _ => ExperimentalFeatures
  }

// Parse permission string to variant
let parsePermission = (s: string): option<browserPermission> =>
  switch s {
  | "browserSettings" => Some(BrowserSettings)
  | "privacy" => Some(PrivacyPermission)
  | "tabs" => Some(Tabs)
  | "notifications" => Some(Notifications)
  | "downloads" => Some(Downloads)
  | _ => None
  }

// Safely extract a string from a JSON dict
let getString = (dict: Js.Dict.t<Js.Json.t>, key: string): option<string> =>
  Js.Dict.get(dict, key)->Option.flatMap(Js.Json.decodeString)

// Safely extract an optional string
let getOptString = (dict: Js.Dict.t<Js.Json.t>, key: string): option<string> =>
  Js.Dict.get(dict, key)->Option.flatMap(v =>
    switch Js.Json.classify(v) {
    | Js.Json.JSONNull => None
    | _ => Js.Json.decodeString(v)
    }
  )

// Safely extract an optional int
let getOptInt = (dict: Js.Dict.t<Js.Json.t>, key: string): option<int> =>
  Js.Dict.get(dict, key)->Option.flatMap(Js.Json.decodeNumber)->Option.map(Float.toInt)

// Safely extract a string array
let getStringArray = (dict: Js.Dict.t<Js.Json.t>, key: string): array<string> =>
  Js.Dict.get(dict, key)
  ->Option.flatMap(Js.Json.decodeArray)
  ->Option.map(arr => arr->Array.filterMap(Js.Json.decodeString))
  ->Option.getOr([])

// Parse a single flag from JSON
let parseFlag = (json: Js.Json.t): option<flag> =>
  switch Js.Json.decodeObject(json) {
  | None => None
  | Some(obj) =>
    switch (getString(obj, "key"), getString(obj, "description")) {
    | (Some(key), Some(description)) =>
      let effectsObj =
        Js.Dict.get(obj, "effects")
        ->Option.flatMap(Js.Json.decodeObject)
        ->Option.getOr(Js.Dict.empty())

      let permStrings = getStringArray(obj, "permissions")

      Some({
        key,
        valueType: getString(obj, "type")->Option.map(parseValueType)->Option.getOr(Boolean),
        category: getString(obj, "category")->Option.map(parseCategory)->Option.getOr(ExperimentalFeatures),
        safetyLevel: getString(obj, "safetyLevel")->Option.map(parseSafetyLevel)->Option.getOr(Experimental),
        defaultValue: Js.Dict.get(obj, "defaultValue")->Option.getOr(Js.Json.boolean(false)),
        description,
        effects: {
          positive: getStringArray(effectsObj, "positive"),
          negative: getStringArray(effectsObj, "negative"),
          interesting: getStringArray(effectsObj, "interesting"),
        },
        permissions: permStrings->Array.filterMap(parsePermission),
        geckoMinVersion: getOptString(obj, "geckoMinVersion"),
        geckoMaxVersion: getOptString(obj, "geckoMaxVersion"),
        documentation: getOptString(obj, "documentation"),
        bugNumber: getOptInt(obj, "bugNumber"),
      })
    | _ => None
    }
  }

// Parse flag database from JSON with full validation
let parseFlagDatabase = (json: Js.Json.t): flagDatabase =>
  switch Js.Json.decodeObject(json) {
  | None => {
      version: "0.0.0",
      lastUpdated: Js.Date.now()->Js.Date.fromFloat->Js.Date.toISOString,
      categories: Js.Dict.empty(),
      flags: [],
    }
  | Some(obj) =>
    let version = getString(obj, "version")->Option.getOr("0.0.0")
    let lastUpdated =
      getString(obj, "lastUpdated")->Option.getOr(
        Js.Date.now()->Js.Date.fromFloat->Js.Date.toISOString,
      )

    let categories = switch Js.Dict.get(obj, "categories")->Option.flatMap(Js.Json.decodeObject) {
    | None => Js.Dict.empty()
    | Some(catsObj) =>
      let result: Js.Dict.t<categoryMeta> = Js.Dict.empty()
      Js.Dict.keys(catsObj)->Array.forEach(catKey => {
        switch Js.Dict.get(catsObj, catKey)->Option.flatMap(Js.Json.decodeObject) {
        | Some(catObj) =>
          switch (getString(catObj, "name"), getString(catObj, "description")) {
          | (Some(name), Some(description)) =>
            Js.Dict.set(result, catKey, {name, description})
          | _ => ()
          }
        | None => ()
        }
      })
      result
    }

    let flags =
      Js.Dict.get(obj, "flags")
      ->Option.flatMap(Js.Json.decodeArray)
      ->Option.map(arr => arr->Array.filterMap(parseFlag))
      ->Option.getOr([])

    {version, lastUpdated, categories, flags}
  }

// --- Version comparison (must be before validateFlagForBrowser) ---

// Compare semantic versions (returns -1, 0, or 1)
let compareVersions = (a: string, b: string): int => {
  let parseVersion = v =>
    v
    ->String.split(".")
    ->Array.map(s => Int.fromString(s)->Option.getOr(0))

  let aParts = parseVersion(a)
  let bParts = parseVersion(b)
  let lenA = Array.length(aParts)
  let lenB = Array.length(bParts)
  let maxLen = lenA > lenB ? lenA : lenB

  let rec compare = (i: int): int => {
    if i >= maxLen {
      0
    } else {
      let aVal = Array.get(aParts, i)->Option.getOr(0)
      let bVal = Array.get(bParts, i)->Option.getOr(0)

      if aVal < bVal {
        -1
      } else if aVal > bVal {
        1
      } else {
        compare(i + 1)
      }
    }
  }

  compare(0)
}

// --- Network and validation functions ---

// Check for database updates from GitHub releases
let checkForUpdates = async (currentVersion: string): updateStatus => {
  try {
    let response = await Fetch.fetch(
      "https://api.github.com/repos/hyperpolymath/fireflag/releases/latest",
    )

    if !(response->Fetch.Response.ok) {
      UpdateFailed("Failed to fetch update information")
    } else {
      let json = await response->Fetch.Response.json
      let latestVersion = json
        ->Js.Json.decodeObject
        ->Option.flatMap(obj => Js.Dict.get(obj, "tag_name"))
        ->Option.flatMap(Js.Json.decodeString)
        ->Option.getOr(currentVersion)

      if latestVersion > currentVersion {
        UpdateAvailable({
          version: latestVersion,
          lastUpdated: Js.Date.now()->Js.Date.fromFloat->Js.Date.toISOString,
          minimumGeckoVersion: "109.0",
          maximumGeckoVersion: None,
        })
      } else {
        UpToDate
      }
    }
  } catch {
  | JsExn(exn) => UpdateFailed(JsExn.message(exn)->Option.getOr("Unknown error"))
  | _ => UpdateFailed("Unknown error")
  }
}

// Download and validate updated database
let downloadDatabase = async (version: databaseVersion): result<flagDatabase, string> => {
  try {
    let url = `https://github.com/hyperpolymath/fireflag/releases/download/${version.version}/flags-database.json`

    let response = await Fetch.fetch(url)

    if !(response->Fetch.Response.ok) {
      Error("Failed to download database")
    } else {
      let json = await response->Fetch.Response.json
      let db = parseFlagDatabase(json)

      Ok(db)
    }
  } catch {
  | JsExn(exn) => Error(JsExn.message(exn)->Option.getOr("Download failed"))
  | _ => Error("Download failed")
  }
}

// Validate flag availability against current browser version
let validateFlagForBrowser = (flag: flag, browserVersion: string): bool => {
  let meetsMin = switch flag.geckoMinVersion {
  | Some(minVer) => compareVersions(browserVersion, minVer) >= 0
  | None => true
  }

  let meetsMax = switch flag.geckoMaxVersion {
  | Some(maxVer) => compareVersions(browserVersion, maxVer) <= 0
  | None => true
  }

  meetsMin && meetsMax
}

// Filter database for current browser version
let filterDatabaseForBrowser = (db: flagDatabase, browserVersion: string): flagDatabase => {
  {
    ...db,
    flags: db.flags->Array.filter(flag => validateFlagForBrowser(flag, browserVersion)),
  }
}

// Detect deprecated flags (have maxVersion)
let findDeprecatedFlags = (db: flagDatabase): array<flag> => {
  db.flags->Array.filter(flag => flag.geckoMaxVersion->Option.isSome)
}

// Detect flags unavailable in current version
let findUnavailableFlags = (db: flagDatabase, browserVersion: string): array<flag> => {
  db.flags->Array.filter(flag => !validateFlagForBrowser(flag, browserVersion))
}

// Auto-update workflow
let autoUpdate = async (currentVersion: string, enableAutoUpdate: bool): result<
  flagDatabase,
  string,
> => {
  if !enableAutoUpdate {
    Error("Auto-update disabled")
  } else {
    let status = await checkForUpdates(currentVersion)

    switch status {
    | UpToDate => Error("Already up to date")
    | UpdateFailed(msg) => Error(msg)
    | UpdateRequired(reason) => Error(`Update required: ${reason}`)
    | UpdateAvailable(version) => await downloadDatabase(version)
    }
  }
}
