// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
// (MPL-2.0 preferred; MPL-2.0 required for Firefox extension store)

/**
 * FireFlag Popup UI
 *
 * Quick access interface for flag management with permission feedback.
 */

const STORAGE_KEY = 'fireflag_state';
let flagDatabase = null;
let currentFilter = 'all';
let searchQuery = '';

// Initialize popup
document.addEventListener('DOMContentLoaded', async () => {
  try {
    await loadFlagDatabase();
    await loadFlagStates();
    setupEventListeners();
    renderFlags();
  } catch (error) {
    console.error('Failed to initialize popup:', error);
    showError('Failed to load FireFlag. Please try again.');
  }
});

// Load flag database from JSON
async function loadFlagDatabase() {
  try {
    const response = await fetch('../data/flags-database.json');
    flagDatabase = await response.json();
  } catch (error) {
    throw new Error('Failed to load flag database: ' + error.message);
  }
}

// Load current flag states from storage
async function loadFlagStates() {
  try {
    const result = await browser.storage.local.get(STORAGE_KEY);
    return result[STORAGE_KEY] || {};
  } catch (error) {
    console.error('Failed to load flag states:', error);
    return {};
  }
}

// Save flag state to storage
async function saveFlagState(key, value, timestamp) {
  const states = await loadFlagStates();
  states[key] = {
    value,
    timestamp,
    modifiedBy: 'extension'
  };
  await browser.storage.local.set({ [STORAGE_KEY]: states });
}

// Setup event listeners
function setupEventListeners() {
  // Filter buttons
  document.querySelectorAll('.filter-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
      e.target.classList.add('active');
      currentFilter = e.target.dataset.filter;
      renderFlags();
    });
  });

  // Search input
  const searchInput = document.getElementById('search-input');
  searchInput.addEventListener('input', (e) => {
    searchQuery = e.target.value.toLowerCase();
    renderFlags();
  });

  // Footer buttons
  document.getElementById('open-sidebar').addEventListener('click', () => {
    browser.sidebarAction.open();
  });

  document.getElementById('open-options').addEventListener('click', () => {
    browser.runtime.openOptionsPage();
  });
}

// Render flags list
async function renderFlags() {
  const flagsList = document.getElementById('flags-list');
  const states = await loadFlagStates();

  // Filter flags
  let filteredFlags = flagDatabase.flags.filter(flag => {
    // Filter by category/safety
    if (currentFilter === 'safe' && flag.safetyLevel !== 'safe') return false;
    if (currentFilter === 'experimental' && flag.safetyLevel !== 'experimental') return false;
    if (currentFilter === 'modified' && !states[flag.key]) return false;

    // Filter by search query
    if (searchQuery && !flag.key.toLowerCase().includes(searchQuery) &&
        !flag.description.toLowerCase().includes(searchQuery)) {
      return false;
    }

    return true;
  });

  if (filteredFlags.length === 0) {
    safeSetHTML(flagsList, '<div class="loading">No flags found matching your criteria.</div>');
    return;
  }

  safeSetHTML(flagsList, filteredFlags.map(flag => createFlagItem(flag, states[flag.key])).join(''));

  // Add toggle event listeners
  flagsList.querySelectorAll('.flag-toggle input').forEach(toggle => {
    toggle.addEventListener('change', (e) => handleFlagToggle(e.target.dataset.key, e.target.checked));
  });
}

// Create flag item HTML
function createFlagItem(flag, state) {
  const isModified = state !== undefined;
  const currentValue = isModified ? state.value : flag.defaultValue;

  return `
    <div class="flag-item">
      <div class="flag-header">
        <span class="flag-key">${escapeHtml(flag.key)}</span>
        <span class="safety-badge ${flag.safetyLevel}">${flag.safetyLevel}</span>
      </div>
      <div class="flag-description">${escapeHtml(flag.description)}</div>
      <div class="flag-toggle">
        <label class="toggle-switch">
          <input type="checkbox"
                 ${currentValue ? 'checked' : ''}
                 data-key="${escapeHtml(flag.key)}"
                 data-permissions="${flag.permissions.join(',')}">
          <span class="toggle-slider"></span>
        </label>
        <span class="toggle-label">${currentValue ? 'Enabled' : 'Disabled'}</span>
        ${isModified ? '<span style="color: var(--primary-color); font-size: 11px; margin-left: 8px;">●</span>' : ''}
      </div>
    </div>
  `;
}

// Handle flag toggle
async function handleFlagToggle(key, newValue) {
  const flag = flagDatabase.flags.find(f => f.key === key);
  if (!flag) return;

  // Check if permissions are needed
  if (flag.permissions.length > 0) {
    const hasPermissions = await checkPermissions(flag.permissions);
    if (!hasPermissions) {
      const granted = await requestPermissions(flag.permissions, flag);
      if (!granted) {
        // Revert toggle
        renderFlags();
        return;
      }
    }
  }

  try {
    // Apply flag change via background script
    const response = await browser.runtime.sendMessage({
      type: 'SET_FLAG',
      key: flag.key,
      value: newValue
    });

    if (response.success) {
      await saveFlagState(key, newValue, Date.now());
      showNotification(`Flag ${newValue ? 'enabled' : 'disabled'}: ${key}`, 'success');
    } else {
      throw new Error(response.error || 'Failed to set flag');
    }
  } catch (error) {
    console.error('Failed to toggle flag:', error);
    showNotification(`Failed to modify flag: ${error.message}`, 'error');
    renderFlags(); // Revert UI
  }
}

// Check if permissions are granted
async function checkPermissions(permissions) {
  if (permissions.length === 0) return true;

  try {
    return await browser.permissions.contains({
      permissions: permissions
    });
  } catch (error) {
    console.error('Failed to check permissions:', error);
    return false;
  }
}

// Request permissions from user
async function requestPermissions(permissions, flag) {
  // Show permission notice
  const notice = document.getElementById('permission-notice');
  const noticeText = notice.querySelector('.notice-text');

  noticeText.textContent = `Modifying "${flag.key}" requires permissions: ${permissions.join(', ')}. These will allow the extension to change browser settings.`;
  notice.style.display = 'block';

  return new Promise((resolve) => {
    const grantBtn = notice.querySelector('.grant-permission-btn');
    const handler = async () => {
      try {
        const granted = await browser.permissions.request({
          permissions: permissions
        });
        notice.style.display = 'none';
        grantBtn.removeEventListener('click', handler);
        resolve(granted);
      } catch (error) {
        console.error('Permission request failed:', error);
        notice.style.display = 'none';
        grantBtn.removeEventListener('click', handler);
        resolve(false);
      }
    };

    grantBtn.addEventListener('click', handler);
  });
}

// Show notification
function showNotification(message, type = 'info') {
  browser.notifications.create({
    type: 'basic',
    title: 'FireFlag',
    message: message,
    iconUrl: '../icons/fireflag-48.png'
  });
}

// Show error message
function showError(message) {
  const flagsList = document.getElementById('flags-list');
  safeSetHTML(flagsList, `
    <div style="padding: 40px 20px; text-align: center; color: var(--dangerous-color);">
      <p style="font-weight: 600; margin-bottom: 8px;">Error</p>
      <p style="font-size: 12px;">${escapeHtml(message)}</p>
    </div>
  `);
}

// Escape HTML to prevent XSS
function escapeHtml(unsafe) {
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}
