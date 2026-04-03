// SPDX-License-Identifier: MPL-2.0
// (PMPL-1.0-or-later preferred; MPL-2.0 required for Firefox extension store)
// Copyright (C) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

/**
 * FireFlag Options Page
 */

const SETTINGS_KEY = 'fireflag_settings';
let currentSection = 'general';

document.addEventListener('DOMContentLoaded', async () => {
  await loadSettings();
  await loadBrowserInfo();
  setupNavigation();
  setupEventListeners();
});

async function loadSettings() {
  const result = await browser.storage.local.get(SETTINGS_KEY);
  const settings = result[SETTINGS_KEY] || {};

  // Apply settings to UI
  document.getElementById('auto-update-database').checked = settings.autoUpdateDatabase ?? false;
  document.getElementById('show-modified-badge').checked = settings.showModifiedBadge ?? true;
  document.getElementById('confirm-dangerous').checked = settings.confirmDangerous ?? true;
  document.getElementById('enable-tracking').checked = settings.enableTracking ?? true;
  document.getElementById('history-limit').value = settings.historyLimit ?? 100;
  document.getElementById('enable-metrics').checked = settings.enableMetrics ?? false;
  document.getElementById('devtools-integration').checked = settings.devtoolsIntegration ?? false;
  document.getElementById('verbose-logging').checked = settings.verboseLogging ?? false;
}

async function loadBrowserInfo() {
  const info = await browser.runtime.getBrowserInfo();
  const manifest = browser.runtime.getManifest();

  document.getElementById('version').textContent = `v${manifest.version}`;
  document.getElementById('about-version').textContent = manifest.version;
  document.getElementById('browser-info').textContent = `${info.name} ${info.version}`;

  await loadPermissions();
}

async function loadPermissions() {
  const manifest = browser.runtime.getManifest();
  const allPerms = await browser.permissions.getAll();

  const currentPermsEl = document.getElementById('current-permissions');
  const optionalPermsEl = document.getElementById('optional-permissions');

  // Show current permissions
  if (allPerms.permissions.length > 0) {
    safeSetHTML(currentPermsEl, allPerms.permissions.map(perm => `
      <div class="permission-item">
        <span class="permission-name">${perm}</span>
        <span class="permission-status granted">Granted</span>
      </div>
    `).join(''));
  } else {
    safeSetHTML(currentPermsEl, '<p class="setting-description">No permissions granted</p>');
  }

  // Show optional permissions
  const optionalPerms = manifest.optional_permissions || [];
  if (optionalPerms.length > 0) {
    safeSetHTML(optionalPermsEl, optionalPerms.map(perm => `
      <div class="permission-item">
        <span class="permission-name">${perm}</span>
        <button class="secondary-btn grant-perm-btn" data-perm="${perm}">Grant</button>
      </div>
    `).join(''));

    document.querySelectorAll('.grant-perm-btn').forEach(btn => {
      btn.addEventListener('click', async (e) => {
        const perm = e.target.dataset.perm;
        const granted = await browser.permissions.request({ permissions: [perm] });
        if (granted) {
          await loadPermissions();
        }
      });
    });
  }
}

function setupNavigation() {
  document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
      e.target.classList.add('active');
      currentSection = e.target.dataset.section;
      showSection(currentSection);
    });
  });
}

function showSection(section) {
  document.querySelectorAll('.options-section').forEach(s => s.style.display = 'none');
  const sectionEl = document.getElementById(`section-${section}`);
  if (sectionEl) {
    sectionEl.style.display = 'block';
  }
}

function setupEventListeners() {
  document.getElementById('save-settings-btn').addEventListener('click', saveSettings);
  document.getElementById('clear-all-data-btn')?.addEventListener('click', clearAllData);
  document.getElementById('reset-settings-btn')?.addEventListener('click', resetSettings);
}

async function saveSettings() {
  const settings = {
    autoUpdateDatabase: document.getElementById('auto-update-database').checked,
    showModifiedBadge: document.getElementById('show-modified-badge').checked,
    confirmDangerous: document.getElementById('confirm-dangerous').checked,
    enableTracking: document.getElementById('enable-tracking').checked,
    historyLimit: parseInt(document.getElementById('history-limit').value),
    enableMetrics: document.getElementById('enable-metrics').checked,
    devtoolsIntegration: document.getElementById('devtools-integration').checked,
    verboseLogging: document.getElementById('verbose-logging').checked
  };

  await browser.storage.local.set({ [SETTINGS_KEY]: settings });

  const statusEl = document.getElementById('save-status');
  statusEl.textContent = 'Settings saved!';
  setTimeout(() => statusEl.textContent = '', 3000);
}

async function clearAllData() {
  if (confirm('This will delete all flag states and tracking history. Continue?')) {
    await browser.storage.local.remove(['fireflag_state', 'fireflag_history']);
    alert('All data cleared!');
  }
}

async function resetSettings() {
  if (confirm('Reset all settings to defaults?')) {
    await browser.storage.local.remove(SETTINGS_KEY);
    await loadSettings();
    alert('Settings reset!');
  }
}
