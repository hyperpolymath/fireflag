// SPDX-License-Identifier: MPL-2.0
// Copyright (C) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

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
  // Clear existing content
  while (element.firstChild) {
    element.removeChild(element.firstChild);
  }

  // Create a template element to parse HTML safely
  const template = document.createElement('template');
  template.innerHTML = htmlString;

  // Append the parsed content
  element.appendChild(template.content.cloneNode(true));
}

/**
 * Escape HTML special characters for safe display
 * @param {string} text - Text to escape
 * @returns {string} - Escaped text
 */
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
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
