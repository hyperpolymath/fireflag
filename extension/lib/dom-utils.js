// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
/**
 * DOM utility functions for safe HTML manipulation
 * Replaces innerHTML with safer alternatives
 * Global functions (no modules) for browser extension compatibility
 *
 * Security Notes:
 * - Uses template elements to prevent script injection
 * - All content is controlled by the extension (no user input)
 * - CSP restricts script sources to 'self'
 */

/**
 * Safely set HTML content by creating DOM elements
 * Uses template elements for secure HTML parsing (no script execution)
 * @param {HTMLElement} element - Target element
 * @param {string} htmlString - HTML string to set
 */
function safeSetHTML(element, htmlString) {
  const parser = new DOMParser();
  const doc = parser.parseFromString(htmlString, 'text/html');
  // Use modern replaceChildren to clear and append in one go
  element.replaceChildren(...doc.body.childNodes);
}

/**
 * Escape HTML special characters for safe display
 * @param {string} text - Text to escape
 * @returns {string} - Escaped text
 */
function escapeHtml(text) {
  if (!text) return text;
  return String(text)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

/**
 * Sanitize URL for safe use in extension UI
 * @param {string} url - URL to sanitize
 * @returns {string} - Sanitized URL or empty string if invalid
 */
function sanitizeUrl(url) {
  try {
    const parsed = new URL(url);
    // Only allow http, https, and extension protocols
    if (['http:', 'https:', 'moz-extension:'].includes(parsed.protocol)) {
      return parsed.href;
    }
    return '';
  } catch (e) {
    return '';
  }
}

// Make functions globally available
window.safeSetHTML = safeSetHTML;
window.escapeHtmlUtil = escapeHtml;
window.sanitizeUrl = sanitizeUrl;
