// SPDX-License-Identifier: MPL-2.0
// (MPL-2.0 preferred; MPL-2.0 required for Firefox extension store)
// Copyright (C) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

/**
 * DevTools Integration
 *
 * Provides Firefox DevTools panel for flag inspection and debugging.
 */

open Types

// DevTools panel API bindings
module DevToolsAPI = {
  type panel

  type panelOptions = {
    title: string,
    iconPath: string,
    url: string,
  }

  @scope(("browser", "devtools", "panels")) @val
  external create: (string, string, string) => promise<panel> = "create"

  @scope(("browser", "devtools", "inspectedWindow")) @val
  external eval: string => promise<(Js.Json.t, option<Js.Json.t>)> = "eval"

  @scope(("browser", "devtools", "inspectedWindow")) @val
  external tabId: int = "tabId"
}

// Performance metrics collection
type performanceMetrics = {
  navigationStart: float,
  domContentLoaded: float,
  loadComplete: float,
  firstPaint: option<float>,
  firstContentfulPaint: option<float>,
  memoryUsage: option<float>,
  jsHeapSize: option<float>,
}

// Collect performance metrics from inspected window
let collectPerformanceMetrics = async (): result<performanceMetrics, string> => {
  try {
    let script = `
      (function() {
        const perf = window.performance;
        const timing = perf.timing;
        const paint = perf.getEntriesByType('paint');
        const memory = performance.memory;

        return {
          navigationStart: timing.navigationStart,
          domContentLoaded: timing.domContentLoadedEventEnd - timing.navigationStart,
          loadComplete: timing.loadEventEnd - timing.navigationStart,
          firstPaint: paint.find(e => e.name === 'first-paint')?.startTime || null,
          firstContentfulPaint: paint.find(e => e.name === 'first-contentful-paint')?.startTime || null,
          memoryUsage: memory ? memory.usedJSHeapSize : null,
          jsHeapSize: memory ? memory.totalJSHeapSize : null
        };
      })()
    `

    let (result, error) = await DevToolsAPI.eval(script)

    switch error {
    | Some(_) => Error("Failed to collect performance metrics")
    | None =>
      switch Js.Json.decodeObject(result) {
      | None => Error("Failed to decode metrics object")
      | Some(dict) =>
        let getNum = key =>
          switch Js.Dict.get(dict, key) {
          | Some(v) => Js.Json.decodeNumber(v)
          | None => None
          }
        switch (getNum("navigationStart"), getNum("domContentLoaded"), getNum("loadComplete")) {
        | (Some(navStart), Some(dcl), Some(load)) =>
          let metrics: performanceMetrics = {
            navigationStart: navStart,
            domContentLoaded: dcl,
            loadComplete: load,
            firstPaint: getNum("firstPaint"),
            firstContentfulPaint: getNum("firstContentfulPaint"),
            memoryUsage: getNum("memoryUsage"),
            jsHeapSize: getNum("jsHeapSize"),
          }
          Ok(metrics)
        | _ => Error("Missing required metrics fields")
        }
      }
    }
  } catch {
  | JsExn(exn) => Error(JsExn.message(exn)->Option.getOr("Unknown error"))
  | _ => Error("Unknown error")
  }
}

// Flag impact analysis
type flagImpact = {
  flag: string,
  metricsBefore: option<performanceMetrics>,
  metricsAfter: option<performanceMetrics>,
  percentChange: float,
  improved: bool,
}

// Calculate performance impact of flag change
let calculateFlagImpact = (
  flag: string,
  before: performanceMetrics,
  after: performanceMetrics,
): flagImpact => {
  let beforeTime = before.loadComplete
  let afterTime = after.loadComplete
  let change = ((afterTime -. beforeTime) /. beforeTime) *. 100.0

  {
    flag: flag,
    metricsBefore: Some(before),
    metricsAfter: Some(after),
    percentChange: change,
    improved: change < 0.0, // Negative change = faster = improved
  }
}

// DevTools panel state
type panelState = {
  activeFlags: array<flag>,
  metrics: option<performanceMetrics>,
  impacts: array<flagImpact>,
  recording: bool,
}

// Initialize DevTools panel
let createDevToolsPanel = async (): result<DevToolsAPI.panel, string> => {
  try {
    let panel = await DevToolsAPI.create(
      "FireFlag",
      "../icons/fireflag-32.png",
      "../devtools/panel.html",
    )
    Ok(panel)
  } catch {
  | JsExn(exn) => Error(JsExn.message(exn)->Option.getOr("Failed to create DevTools panel"))
  | _ => Error("Failed to create DevTools panel")
  }
}

// Export metrics for analysis
let exportMetricsReport = (state: panelState): developerReport => {
  {
    timestamp: Js.Date.now(),
    browserVersion: "unknown", // Will be populated from runtime
    geckoVersion: "unknown",
    flagChanges: [],
    performanceMetrics: switch state.metrics {
    | Some(m) => {
        let dict: Js.Dict.t<float> = Js.Dict.empty()
        Js.Dict.set(dict, "navigationStart", m.navigationStart)
        Js.Dict.set(dict, "domContentLoaded", m.domContentLoaded)
        Js.Dict.set(dict, "loadComplete", m.loadComplete)
        Some(dict)
      }
    | None => None
    },
    notes: Some("DevTools performance analysis"),
  }
}
