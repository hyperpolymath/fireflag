// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (C) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

/**
 * Firefox Browser API Bindings
 *
 * Type-safe bindings for Firefox WebExtension APIs.
 */

// Browser namespace (Firefox uses `browser`, Chrome uses `chrome`)
@val @scope("globalThis")
external browser: {..} = "browser"

module Storage = {
  type storageArea

  @send
  external get: (storageArea, array<string>) => promise<Js.Dict.t<Js.Json.t>> = "get"

  @send
  external set: (storageArea, Js.Dict.t<Js.Json.t>) => promise<unit> = "set"

  @send
  external remove: (storageArea, array<string>) => promise<unit> = "remove"

  @send
  external clear: storageArea => promise<unit> = "clear"

  @get
  external local: {..} => storageArea = "local"

  @get
  external sync: {..} => storageArea = "sync"
}

module BrowserSettings = {
  type setting<'a>

  type settingDetails = {
    value: Js.Json.t,
    levelOfControl: string,
  }

  @send
  external get: (setting<'a>, {..}) => promise<settingDetails> = "get"

  @send
  external set: (setting<'a>, {"value": Js.Json.t}) => promise<bool> = "set"

  @send
  external clear: (setting<'a>, {..}) => promise<bool> = "clear"
}

module Privacy = {
  type privacySetting<'a>

  @send
  external get: (privacySetting<'a>, {..}) => promise<BrowserSettings.settingDetails> = "get"

  @send
  external set: (privacySetting<'a>, {"value": Js.Json.t}) => promise<bool> = "set"
}

module Permissions = {
  type permissions = {
    permissions: option<array<string>>,
    origins: option<array<string>>,
  }

  @scope("browser") @val
  external request: permissions => promise<bool> = "permissions.request"

  @scope("browser") @val
  external contains: permissions => promise<bool> = "permissions.contains"

  @scope("browser") @val
  external remove: permissions => promise<bool> = "permissions.remove"

  @scope("browser") @val
  external getAll: unit => promise<permissions> = "permissions.getAll"
}

module Runtime = {
  type browserInfo = {
    name: string,
    vendor: string,
    version: string,
    buildID: string,
  }

  @scope("browser") @val
  external getBrowserInfo: unit => promise<browserInfo> = "runtime.getBrowserInfo"

  @scope("browser") @val
  external getManifest: unit => {..} = "runtime.getManifest"

  @scope("browser") @val
  external openOptionsPage: unit => promise<unit> = "runtime.openOptionsPage"

  type messageResponse

  @scope("browser") @val
  external sendMessage: Js.Json.t => promise<messageResponse> = "runtime.sendMessage"
}

module Tabs = {
  type tab = {
    id: option<int>,
    index: int,
    windowId: int,
    highlighted: bool,
    active: bool,
    pinned: bool,
    url: option<string>,
    title: option<string>,
  }

  @scope("browser") @val
  external query: {..} => promise<array<tab>> = "tabs.query"

  @scope("browser") @val
  external getCurrent: unit => promise<tab> = "tabs.getCurrent"

  @scope("browser") @val
  external create: {..} => promise<tab> = "tabs.create"
}

module Notifications = {
  type notificationOptions = {
    @as("type") notificationType: string,
    title: string,
    message: string,
    iconUrl: option<string>,
  }

  @scope("browser") @val
  external create: (option<string>, notificationOptions) => promise<string> = "notifications.create"

  @scope("browser") @val
  external clear: string => promise<bool> = "notifications.clear"
}

// Helper to check if running in Firefox
let isFirefox = () => {
  try {
    let _ = browser
    true
  } catch {
  | _ => false
  }
}

// Get browser compatibility info
let getBrowserCompat = async (): Types.browserCompatibility => {
  try {
    let info = await Runtime.getBrowserInfo()
    {
      isGecko: true,
      geckoVersion: Some(info.version),
      isFirefox: String.includes(info.name, "Firefox"),
      isLibrewolf: String.includes(info.name, "LibreWolf"),
      isWaterfox: String.includes(info.name, "Waterfox"),
      isPaleMoon: String.includes(info.name, "Pale Moon"),
      supportedFlags: [],
    }
  } catch {
  | _ => {
      isGecko: false,
      geckoVersion: None,
      isFirefox: false,
      isLibrewolf: false,
      isWaterfox: false,
      isPaleMoon: false,
      supportedFlags: [],
    }
  }
}
