// SPDX-License-Identifier: MPL-2.0
// (PMPL-1.0-or-later preferred; MPL-2.0 required for Firefox extension store)
// Copyright (C) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

/**
 * FireFlag DevTools Entry Point
 *
 * Creates the DevTools panel when DevTools is opened.
 */

browser.devtools.panels.create(
  "FireFlag",
  "../icons/fireflag-32.png",
  "devtools/panel.html"
).then((panel) => {
  console.log("FireFlag DevTools panel created");
}).catch((error) => {
  console.error("Failed to create FireFlag DevTools panel:", error);
});
