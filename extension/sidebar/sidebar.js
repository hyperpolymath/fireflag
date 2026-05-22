// SPDX-License-Identifier: MPL-2.0
// (MPL-2.0 preferred; MPL-2.0 required for Firefox extension store)
// Copyright (C) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

/**
 * FireFlag Sidebar
 *
 * Detailed view with tracking, analytics, and export features.
 */

const STORAGE_KEY = 'fireflag_state';
const HISTORY_KEY = 'fireflag_history';

let flagDatabase = null;
let currentView = 'flags';
let exportFormat = 'json';

// Initialize sidebar
document.addEventListener('DOMContentLoaded', async () => {
  await loadFlagDatabase();
  setupNavigation();
  setupExportControls();
  await renderCurrentView();
});

// Load flag database
async function loadFlagDatabase() {
  const response = await fetch('../data/flags-database.json');
  flagDatabase = await response.json();
}

// Setup navigation
function setupNavigation() {
  document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
      e.target.classList.add('active');
      currentView = e.target.dataset.view;
      renderCurrentView();
    });
  });
}

// Setup export controls
function setupExportControls() {
  document.querySelectorAll('.format-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      document.querySelectorAll('.format-btn').forEach(b => b.classList.remove('active'));
      e.target.classList.add('active');
      exportFormat = e.target.dataset.format;
    });
  });

  document.getElementById('generate-export-btn').addEventListener('click', generateExport);
  document.getElementById('download-export-btn')?.addEventListener('click', downloadExport);
  document.getElementById('copy-export-btn')?.addEventListener('click', copyExport);
  document.getElementById('clear-history-btn')?.addEventListener('click', clearHistory);
}

// Render current view
async function renderCurrentView() {
  // Hide all views
  document.querySelectorAll('.view-container').forEach(v => v.style.display = 'none');

  // Show current view
  const viewElement = document.getElementById(`view-${currentView}`);
  if (viewElement) {
    viewElement.style.display = 'block';
  }

  // Render view content
  switch (currentView) {
    case 'flags':
      await renderFlagsView();
      break;
    case 'tracking':
      await renderTrackingView();
      break;
    case 'analytics':
      await renderAnalyticsView();
      break;
    case 'export':
      // Export view is static
      break;
  }
}

// Render flags view
async function renderFlagsView() {
  const grid = document.getElementById('flags-grid');
  const categoryFilter = document.getElementById('category-filter');
  const safetyFilter = document.getElementById('safety-filter');

  const renderGrid = async () => {
    const category = categoryFilter.value;
    const safety = safetyFilter.value;
    const states = await browser.storage.local.get(STORAGE_KEY);
    const flagStates = states[STORAGE_KEY] || {};

    let filtered = flagDatabase.flags.filter(flag => {
      if (category !== 'all' && flag.category !== category) return false;
      if (safety !== 'all' && flag.safetyLevel !== safety) return false;
      return true;
    });

    safeSetHTML(grid, filtered.map(flag => createFlagCard(flag, flagStates[flag.key])).join(''));
  };

  categoryFilter.addEventListener('change', renderGrid);
  safetyFilter.addEventListener('change', renderGrid);

  await renderGrid();
}

// Create flag card HTML
function createFlagCard(flag, state) {
  const positiveEffects = flag.effects.positive.map(e => `<li>${escapeHtml(e)}</li>`).join('');
  const negativeEffects = flag.effects.negative.map(e => `<li>${escapeHtml(e)}</li>`).join('');
  const interestingEffects = flag.effects.interesting.map(e => `<li>${escapeHtml(e)}</li>`).join('');

  return `
    <div class="flag-card">
      <div class="flag-card-header">
        <span class="flag-card-key">${escapeHtml(flag.key)}</span>
        <span class="safety-badge ${flag.safetyLevel}">${flag.safetyLevel}</span>
      </div>
      <div class="flag-card-description">${escapeHtml(flag.description)}</div>
      <div class="flag-card-effects">
        ${positiveEffects ? `
          <div class="effect-section">
            <span class="effect-label positive">✓ Positive</span>
            <ul class="effect-list">${positiveEffects}</ul>
          </div>
        ` : ''}
        ${negativeEffects ? `
          <div class="effect-section">
            <span class="effect-label negative">✗ Negative</span>
            <ul class="effect-list">${negativeEffects}</ul>
          </div>
        ` : ''}
        ${interestingEffects ? `
          <div class="effect-section">
            <span class="effect-label interesting">★ Interesting</span>
            <ul class="effect-list">${interestingEffects}</ul>
          </div>
        ` : ''}
      </div>
    </div>
  `;
}

// Render tracking view
async function renderTrackingView() {
  const result = await browser.storage.local.get([STORAGE_KEY, HISTORY_KEY]);
  const states = result[STORAGE_KEY] || {};
  const history = result[HISTORY_KEY] || [];

  // Update stats
  document.getElementById('stat-total').textContent = history.length;
  document.getElementById('stat-active').textContent = Object.keys(states).length;

  if (history.length > 0) {
    const lastChange = history[history.length - 1];
    const date = new Date(lastChange.timestamp);
    document.getElementById('stat-last').textContent = date.toLocaleString();
  } else {
    document.getElementById('stat-last').textContent = 'Never';
  }

  // Render timeline
  const timeline = document.getElementById('timeline');
  if (history.length === 0) {
    safeSetHTML(timeline, '<p class="placeholder">No flag changes tracked yet.</p>');
  } else {
    safeSetHTML(timeline, history.slice().reverse().map(change => {
      const date = new Date(change.timestamp);
      return `
        <div class="timeline-item">
          <div class="timeline-time">${date.toLocaleString()}</div>
          <div class="timeline-change">${escapeHtml(change.key)}</div>
          <div class="timeline-details">
            Changed from <code>${JSON.stringify(change.beforeValue)}</code>
            to <code>${JSON.stringify(change.afterValue)}</code>
            by ${change.source || 'unknown'}
          </div>
        </div>
      `;
    }).join(''));
  }
}

// Render analytics view
async function renderAnalyticsView() {
  const result = await browser.storage.local.get(STORAGE_KEY);
  const states = result[STORAGE_KEY] || {};

  // Count effects
  const effectsCount = { positive: 0, negative: 0, interesting: 0 };

  Object.keys(states).forEach(key => {
    const flag = flagDatabase.flags.find(f => f.key === key);
    if (flag && states[key].value) {
      effectsCount.positive += flag.effects.positive.length;
      effectsCount.negative += flag.effects.negative.length;
      effectsCount.interesting += flag.effects.interesting.length;
    }
  });

  const summaryEl = document.getElementById('effects-summary');
  safeSetHTML(summaryEl, `
    <div class="tracking-stats">
      <div class="stat-card">
        <span class="stat-label">Positive Effects</span>
        <span class="stat-value" style="color: var(--safe-color);">${effectsCount.positive}</span>
      </div>
      <div class="stat-card">
        <span class="stat-label">Negative Effects</span>
        <span class="stat-value" style="color: var(--dangerous-color);">${effectsCount.negative}</span>
      </div>
      <div class="stat-card">
        <span class="stat-label">Interesting Notes</span>
        <span class="stat-value" style="color: var(--experimental-color);">${effectsCount.interesting}</span>
      </div>
    </div>
  `);
}

// Generate export
async function generateExport() {
  const includeFlags = document.getElementById('export-flags').checked;
  const includeHistory = document.getElementById('export-history').checked;
  const includeEffects = document.getElementById('export-effects').checked;
  const includeMetrics = document.getElementById('export-metrics').checked;
  const notes = document.getElementById('export-notes').value;

  const result = await browser.storage.local.get([STORAGE_KEY, HISTORY_KEY]);
  const states = result[STORAGE_KEY] || {};
  const history = result[HISTORY_KEY] || [];

  const browserInfo = await browser.runtime.getBrowserInfo();

  const report = {
    timestamp: new Date().toISOString(),
    browserVersion: browserInfo.version,
    geckoVersion: browserInfo.buildID,
    notes: notes || null,
  };

  if (includeFlags) {
    report.flags = states;
  }

  if (includeHistory) {
    report.flagChanges = history;
  }

  if (includeEffects) {
    report.effects = Object.keys(states)
      .filter(key => states[key].value)
      .map(key => {
        const flag = flagDatabase.flags.find(f => f.key === key);
        return flag ? { key, effects: flag.effects } : null;
      })
      .filter(Boolean);
  }

  if (includeMetrics) {
    report.performanceMetrics = {
      flagCount: Object.keys(states).length,
      activeFlags: Object.keys(states).filter(k => states[k].value).length,
      memoryUsage: performance.memory ? {
        usedJSHeapSize: performance.memory.usedJSHeapSize,
        totalJSHeapSize: performance.memory.totalJSHeapSize,
        jsHeapSizeLimit: performance.memory.jsHeapSizeLimit
      } : null,
      collectedAt: new Date().toISOString()
    };
  }

  let exportContent = '';
  switch (exportFormat) {
    case 'json':
      exportContent = JSON.stringify(report, null, 2);
      break;
    case 'markdown':
      exportContent = generateMarkdown(report);
      break;
    case 'csv':
      exportContent = generateCSV(report);
      break;
  }

  document.getElementById('export-content').textContent = exportContent;
  document.getElementById('export-preview').style.display = 'block';
}

// Generate Markdown export
function generateMarkdown(report) {
  let md = `# FireFlag Report\n\n`;
  md += `**Generated:** ${report.timestamp}\n\n`;
  md += `**Browser:** ${report.browserVersion} (${report.geckoVersion})\n\n`;

  if (report.notes) {
    md += `## Notes\n\n${report.notes}\n\n`;
  }

  if (report.flags) {
    md += `## Active Flags\n\n`;
    Object.entries(report.flags).forEach(([key, state]) => {
      md += `- \`${key}\`: ${state.value}\n`;
    });
    md += `\n`;
  }

  if (report.flagChanges && report.flagChanges.length > 0) {
    md += `## Change History\n\n`;
    report.flagChanges.forEach(change => {
      const date = new Date(change.timestamp).toLocaleString();
      md += `- **${date}**: \`${change.key}\` changed from \`${change.beforeValue}\` to \`${change.afterValue}\`\n`;
    });
  }

  return md;
}

// Generate CSV export
function generateCSV(report) {
  let csv = 'Flag Key,Current Value,Last Modified,Modified By\n';

  if (report.flags) {
    Object.entries(report.flags).forEach(([key, state]) => {
      csv += `"${key}","${state.value}","${new Date(state.timestamp).toISOString()}","${state.modifiedBy}"\n`;
    });
  }

  return csv;
}

// Download export
function downloadExport() {
  const content = document.getElementById('export-content').textContent;
  const extension = exportFormat === 'markdown' ? 'md' : exportFormat;
  const filename = `fireflag-report-${Date.now()}.${extension}`;

  const blob = new Blob([content], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);

  browser.downloads.download({
    url: url,
    filename: filename,
    saveAs: true
  });
}

// Copy export to clipboard
async function copyExport() {
  const content = document.getElementById('export-content').textContent;
  await navigator.clipboard.writeText(content);
  alert('Export copied to clipboard!');
}

// Clear history
async function clearHistory() {
  if (confirm('Are you sure you want to clear all tracking history? This cannot be undone.')) {
    await browser.storage.local.remove(HISTORY_KEY);
    renderTrackingView();
  }
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
