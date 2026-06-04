// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
// (MPL-2.0 preferred; MPL-2.0 required for Firefox extension store)

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
