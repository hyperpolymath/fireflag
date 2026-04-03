// SPDX-License-Identifier: MPL-2.0
// (PMPL-1.0-or-later preferred; MPL-2.0 required for Firefox extension store)
// Copyright (C) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

/**
 * FireFlag DevTools Panel
 */

const STORAGE_KEY = 'fireflag_state';
let currentTab = 'flags';
let recording = false;
let baselineMetrics = null;

document.addEventListener('DOMContentLoaded', () => {
  setupTabs();
  setupActions();
  loadActiveFlags();
  logToConsole('FireFlag DevTools initialized', 'info');
});

// Setup tab navigation
function setupTabs() {
  document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));

      e.target.classList.add('active');
      currentTab = e.target.dataset.tab;
      document.getElementById(`tab-${currentTab}`).classList.add('active');

      if (currentTab === 'performance') {
        collectMetrics();
      }
    });
  });
}

// Setup action buttons
function setupActions() {
  document.getElementById('refresh-btn').addEventListener('click', () => {
    loadActiveFlags();
    if (currentTab === 'performance') {
      collectMetrics();
    }
  });

  document.getElementById('record-btn').addEventListener('click', toggleRecording);
  document.getElementById('export-btn').addEventListener('click', exportData);
  document.getElementById('collect-metrics-btn')?.addEventListener('click', collectMetrics);
  document.getElementById('clear-console-btn')?.addEventListener('click', clearConsole);
}

// Load active flags for inspected window
async function loadActiveFlags() {
  try {
    const result = await browser.storage.local.get(STORAGE_KEY);
    const states = result[STORAGE_KEY] || {};

    const tbody = document.getElementById('flags-tbody');
    const count = Object.keys(states).length;

    document.getElementById('flag-count').textContent = count;

    if (count === 0) {
      safeSetHTML(tbody, '<tr><td colspan="5" class="empty-state">No modified flags detected</td></tr>');
      return;
    }

    // Load flag database to get safety info
    const response = await fetch('../data/flags-database.json');
    const database = await response.json();

    safeSetHTML(tbody, Object.entries(states).map(([key, state]) => {
      const flag = database.flags.find(f => f.key === key);
      const safety = flag ? flag.safetyLevel : 'unknown';
      const modified = new Date(state.timestamp).toLocaleString();

      return `
        <tr>
          <td><code>${escapeHtml(key)}</code></td>
          <td><code>${JSON.stringify(state.value)}</code></td>
          <td><span class="safety-badge ${safety}">${safety}</span></td>
          <td>${modified}</td>
          <td>
            <button class="tool-btn inspect-btn" data-key="${escapeHtml(key)}">Inspect</button>
          </td>
        </tr>
      `;
    }).join(''));

    // Add inspect button handlers
    tbody.querySelectorAll('.inspect-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const key = e.target.dataset.key;
        inspectFlag(key);
      });
    });

    logToConsole(`Loaded ${count} active flags`, 'info');
  } catch (error) {
    logToConsole(`Failed to load flags: ${error.message}`, 'error');
  }
}

// Collect performance metrics from inspected window
async function collectMetrics() {
  try {
    const code = `
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
    `;

    const [result, error] = await browser.devtools.inspectedWindow.eval(code);

    if (error) {
      throw new Error(error.value || 'Evaluation failed');
    }

    // Display metrics
    document.getElementById('metric-dcl').textContent = formatTime(result.domContentLoaded);
    document.getElementById('metric-load').textContent = formatTime(result.loadComplete);
    document.getElementById('metric-fp').textContent = result.firstPaint ? formatTime(result.firstPaint) : 'N/A';
    document.getElementById('metric-fcp').textContent = result.firstContentfulPaint ? formatTime(result.firstContentfulPaint) : 'N/A';
    document.getElementById('metric-heap').textContent = result.jsHeapSize ? formatBytes(result.jsHeapSize) : 'N/A';
    document.getElementById('metric-memory').textContent = result.memoryUsage ? formatBytes(result.memoryUsage) : 'N/A';

    logToConsole('Performance metrics collected', 'info');

    return result;
  } catch (error) {
    logToConsole(`Failed to collect metrics: ${error.message}`, 'error');
  }
}

// Toggle impact recording
async function toggleRecording() {
  const btn = document.getElementById('record-btn');
  const status = document.getElementById('recording-status');

  if (!recording) {
    // Start recording - capture baseline
    baselineMetrics = await collectMetrics();
    recording = true;
    btn.textContent = '⏹ Stop Recording';
    safeSetHTML(status, '<span>⏺ Recording (change a flag and reload)</span>');
    status.classList.add('active');
    logToConsole('Started impact recording - baseline captured', 'info');
  } else {
    // Stop recording - capture after metrics and compare
    const afterMetrics = await collectMetrics();
    recording = false;
    btn.textContent = '⏺ Record Impact';
    safeSetHTML(status, '<span>⏸ Not Recording</span>');
    status.classList.remove('active');

    if (baselineMetrics && afterMetrics) {
      analyzeImpact(baselineMetrics, afterMetrics);
      logToConsole('Impact recording stopped - analysis complete', 'info');
    }

    baselineMetrics = null;
  }
}

// Analyze performance impact
function analyzeImpact(before, after) {
  const results = document.getElementById('impact-results');

  const loadChange = ((after.loadComplete - before.loadComplete) / before.loadComplete) * 100;
  const dclChange = ((after.domContentLoaded - before.domContentLoaded) / before.domContentLoaded) * 100;

  const improved = loadChange < 0;

  safeSetHTML(results, `
    <div class="impact-item">
      <div class="impact-header">
        <span class="impact-flag">Performance Impact Analysis</span>
        <span class="impact-badge ${improved ? 'improved' : 'degraded'}">
          ${improved ? '↓ Improved' : '↑ Degraded'} ${Math.abs(loadChange).toFixed(2)}%
        </span>
      </div>
      <div class="impact-metrics">
        <div>
          <strong>Load Complete:</strong><br>
          Before: ${formatTime(before.loadComplete)}<br>
          After: ${formatTime(after.loadComplete)}<br>
          Change: ${loadChange > 0 ? '+' : ''}${loadChange.toFixed(2)}%
        </div>
        <div>
          <strong>DOM Content Loaded:</strong><br>
          Before: ${formatTime(before.domContentLoaded)}<br>
          After: ${formatTime(after.domContentLoaded)}<br>
          Change: ${dclChange > 0 ? '+' : ''}${dclChange.toFixed(2)}%
        </div>
      </div>
    </div>
  `);
}

// Inspect specific flag
async function inspectFlag(key) {
  // Sanitize key to prevent code injection via string interpolation
  const sanitizedKey = key.replace(/[\\"'`$]/g, '');
  const code = `
    (function() {
      // Check if flag affects this page
      const flagKey = ${JSON.stringify(sanitizedKey)};
      console.log("Inspecting flag:", flagKey);

      // Return any relevant page state
      return {
        url: window.location.href,
        title: document.title,
        readyState: document.readyState
      };
    })()
  `;

  const [result] = await browser.devtools.inspectedWindow.eval(code);
  logToConsole(`Inspected flag: ${escapeHtml(key)} on ${result.url}`, 'info');
}

// Export DevTools data
async function exportData() {
  const result = await browser.storage.local.get(STORAGE_KEY);
  const states = result[STORAGE_KEY] || {};

  const exportData = {
    timestamp: new Date().toISOString(),
    tabId: browser.devtools.inspectedWindow.tabId,
    flags: states,
    metrics: baselineMetrics,
    console: getConsoleLogs()
  };

  const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);

  browser.downloads.download({
    url: url,
    filename: `fireflag-devtools-${Date.now()}.json`,
    saveAs: true
  });

  logToConsole('DevTools data exported', 'info');
}

// Log to DevTools console
function logToConsole(message, level = 'info') {
  const output = document.getElementById('console-output');
  const timestamp = new Date().toLocaleTimeString();

  const messageEl = document.createElement('div');
  messageEl.className = `console-message ${level}`;
  safeSetHTML(messageEl, `
    <span class="timestamp">[${timestamp}]</span>
    <span class="message">${escapeHtml(message)}</span>
  `);

  output.appendChild(messageEl);
  output.scrollTop = output.scrollHeight;
}

// Get console logs
function getConsoleLogs() {
  const output = document.getElementById('console-output');
  return Array.from(output.querySelectorAll('.console-message')).map(msg => {
    const timestamp = msg.querySelector('.timestamp').textContent;
    const message = msg.querySelector('.message').textContent;
    const level = msg.classList.contains('error') ? 'error' :
                  msg.classList.contains('warn') ? 'warn' : 'info';
    return { timestamp, message, level };
  });
}

// Clear console
function clearConsole() {
  const output = document.getElementById('console-output');
  while (output.firstChild) {
    output.removeChild(output.firstChild);
  }
  logToConsole('Console cleared', 'info');
}

// Format time in milliseconds
function formatTime(ms) {
  if (ms < 1000) {
    return `${ms.toFixed(0)}ms`;
  }
  return `${(ms / 1000).toFixed(2)}s`;
}

// Format bytes
function formatBytes(bytes) {
  if (bytes < 1024) return `${bytes}B`;
  if (bytes < 1048576) return `${(bytes / 1024).toFixed(2)}KB`;
  return `${(bytes / 1048576).toFixed(2)}MB`;
}

// Escape HTML
function escapeHtml(unsafe) {
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}
