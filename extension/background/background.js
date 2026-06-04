// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
// (MPL-2.0 preferred; MPL-2.0 required for Firefox extension store)

/**
 * FireFlag Background Service Worker
 *
 * Handles flag modifications and message passing between UI components.
 */

const STORAGE_KEY = 'fireflag_state';
const HISTORY_KEY = 'fireflag_history';
const SETTINGS_KEY = 'fireflag_settings';

// Initialize extension
browser.runtime.onInstalled.addListener(async (details) => {
  if (details.reason === 'install') {
    console.log('FireFlag installed');
    await initializeSettings();
  } else if (details.reason === 'update') {
    console.log('FireFlag updated to', browser.runtime.getManifest().version);
  }
});

// Initialize default settings
async function initializeSettings() {
  const defaultSettings = {
    autoUpdateDatabase: false,
    showModifiedBadge: true,
    confirmDangerous: true,
    enableTracking: true,
    historyLimit: 100,
    enableMetrics: false,
    devtoolsIntegration: false,
    verboseLogging: false
  };

  await browser.storage.local.set({
    [SETTINGS_KEY]: defaultSettings
  });
}

// Message handler
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
  handleMessage(message).then(sendResponse);
  return true; // Keep channel open for async response
});

// Handle messages from UI
async function handleMessage(message) {
  try {
    switch (message.type) {
      case 'SET_FLAG':
        return await setFlag(message.key, message.value);

      case 'GET_FLAG':
        return await getFlag(message.key);

      case 'RESET_FLAG':
        return await resetFlag(message.key);

      case 'GET_SETTINGS':
        return await getSettings();

      case 'UPDATE_SETTINGS':
        return await updateSettings(message.settings);

      default:
        return { success: false, error: 'Unknown message type' };
    }
  } catch (error) {
    console.error('Message handler error:', error);
    return { success: false, error: error.message };
  }
}

// Set flag value
async function setFlag(key, value) {
  try {
    const settings = await getSettings();
    const result = await browser.storage.local.get(STORAGE_KEY);
    const states = result[STORAGE_KEY] || {};

    const beforeValue = states[key]?.value ?? null;
    const timestamp = Date.now();

    // Update state
    states[key] = {
      value,
      timestamp,
      modifiedBy: 'extension'
    };

    await browser.storage.local.set({ [STORAGE_KEY]: states });

    // Track change if enabled
    if (settings.enableTracking) {
      await trackFlagChange(key, beforeValue, value, timestamp);
    }

    // Log if verbose
    if (settings.verboseLogging) {
      console.log(`Flag set: ${key} = ${value}`);
    }

    return { success: true, key, value };
  } catch (error) {
    console.error('Failed to set flag:', error);
    return { success: false, error: error.message };
  }
}

// Get flag value
async function getFlag(key) {
  try {
    const result = await browser.storage.local.get(STORAGE_KEY);
    const states = result[STORAGE_KEY] || {};

    return {
      success: true,
      key,
      value: states[key]?.value ?? null,
      timestamp: states[key]?.timestamp ?? null
    };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

// Reset flag to default
async function resetFlag(key) {
  try {
    const result = await browser.storage.local.get(STORAGE_KEY);
    const states = result[STORAGE_KEY] || {};

    delete states[key];
    await browser.storage.local.set({ [STORAGE_KEY]: states });

    return { success: true, key };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

// Track flag change in history
async function trackFlagChange(key, beforeValue, afterValue, timestamp) {
  try {
    const result = await browser.storage.local.get([HISTORY_KEY, SETTINGS_KEY]);
    const history = result[HISTORY_KEY] || [];
    const settings = result[SETTINGS_KEY] || {};

    // Add change to history
    history.push({
      key,
      beforeValue,
      afterValue,
      timestamp,
      source: 'extension'
    });

    // Trim history if needed
    const limit = settings.historyLimit || 100;
    if (history.length > limit) {
      history.splice(0, history.length - limit);
    }

    await browser.storage.local.set({ [HISTORY_KEY]: history });
  } catch (error) {
    console.error('Failed to track flag change:', error);
  }
}

// Get settings
async function getSettings() {
  const result = await browser.storage.local.get(SETTINGS_KEY);
  return result[SETTINGS_KEY] || {};
}

// Update settings
async function updateSettings(newSettings) {
  try {
    const current = await getSettings();
    const updated = { ...current, ...newSettings };

    await browser.storage.local.set({ [SETTINGS_KEY]: updated });

    return { success: true, settings: updated };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

console.log('FireFlag background service worker initialized');
