#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Generate SVG mockup screenshots for FireFlag

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOCKUP_DIR="$SCRIPT_DIR/mockups"

mkdir -p "$MOCKUP_DIR"

echo "Generating FireFlag mockup screenshots..."
echo ""

# 1. POPUP MOCKUP
cat > "$MOCKUP_DIR/01-popup-overview.svg" <<'EOF'
<svg width="400" height="600" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .bg { fill: #ffffff; }
      .text { font-family: system-ui, -apple-system, sans-serif; fill: #333; }
      .header { fill: #0060df; }
      .safe { fill: #00c851; }
      .experimental { fill: #ff8800; }
      .dangerous { fill: #ff4444; }
      .card { fill: #f9f9fa; stroke: #d7d7db; stroke-width: 1; }
    </style>
  </defs>

  <!-- Background -->
  <rect width="400" height="600" class="bg"/>

  <!-- Header -->
  <rect width="400" height="60" class="header"/>
  <text x="20" y="35" class="text" fill="#fff" font-size="18" font-weight="bold">FireFlag</text>
  <text x="20" y="52" class="text" fill="#fff" font-size="11" opacity="0.9">Safe Firefox Flag Management</text>

  <!-- Search bar -->
  <rect x="15" y="70" width="370" height="36" rx="4" fill="#fff" stroke="#d7d7db" stroke-width="1"/>
  <text x="25" y="92" class="text" font-size="13" opacity="0.6">Search flags...</text>

  <!-- Filter buttons -->
  <rect x="15" y="116" width="80" height="28" rx="4" fill="#0060df"/>
  <text x="32" y="135" class="text" fill="#fff" font-size="11">All (105)</text>

  <rect x="105" y="116" width="60" height="28" rx="4" fill="#fff" stroke="#d7d7db" stroke-width="1"/>
  <text x="115" y="135" class="text" font-size="11">Privacy</text>

  <rect x="175" y="116" width="85" height="28" rx="4" fill="#fff" stroke="#d7d7db" stroke-width="1"/>
  <text x="182" y="135" class="text" font-size="11">Performance</text>

  <!-- Flag cards -->
  <g transform="translate(15, 160)">
    <!-- Card 1: Safe flag -->
    <rect width="370" height="90" rx="6" class="card"/>
    <rect x="8" y="8" width="50" height="18" rx="3" class="safe"/>
    <text x="15" y="20" fill="#fff" font-size="9" font-weight="bold">SAFE</text>

    <text x="8" y="38" class="text" font-size="13" font-weight="600">privacy.resistFingerprinting</text>
    <text x="8" y="55" class="text" font-size="11" opacity="0.7">Enable fingerprinting resistance to make</text>
    <text x="8" y="70" class="text" font-size="11" opacity="0.7">browser tracking harder</text>

    <circle cx="350" cy="45" r="12" fill="#0060df"/>
    <text x="346" y="50" fill="#fff" font-size="16">✓</text>
  </g>

  <g transform="translate(15, 260)">
    <!-- Card 2: Experimental flag -->
    <rect width="370" height="90" rx="6" class="card"/>
    <rect x="8" y="8" width="90" height="18" rx="3" class="experimental"/>
    <text x="12" y="20" fill="#fff" font-size="9" font-weight="bold">EXPERIMENTAL</text>

    <text x="8" y="38" class="text" font-size="13" font-weight="600">gfx.webrender.all</text>
    <text x="8" y="55" class="text" font-size="11" opacity="0.7">Force WebRender on all windows</text>
    <text x="8" y="70" class="text" font-size="11" opacity="0.7">(GPU-accelerated rendering)</text>

    <circle cx="350" cy="45" r="12" fill="#d7d7db"/>
  </g>

  <g transform="translate(15, 360)">
    <!-- Card 3: Dangerous flag -->
    <rect width="370" height="90" rx="6" class="card"/>
    <rect x="8" y="8" width="75" height="18" rx="3" class="dangerous"/>
    <text x="12" y="20" fill="#fff" font-size="9" font-weight="bold">DANGEROUS</text>

    <text x="8" y="38" class="text" font-size="13" font-weight="600">devtools.debugger.remote-enabled</text>
    <text x="8" y="55" class="text" font-size="11" opacity="0.7">Enable remote debugging protocol</text>
    <text x="8" y="70" class="text" font-size="11" opacity="0.7">⚠ Major security risk if exposed</text>

    <circle cx="350" cy="45" r="12" fill="#d7d7db"/>
  </g>

  <g transform="translate(15, 460)">
    <!-- Card 4: Safe flag -->
    <rect width="370" height="90" rx="6" class="card"/>
    <rect x="8" y="8" width="50" height="18" rx="3" class="safe"/>
    <text x="15" y="20" fill="#fff" font-size="9" font-weight="bold">SAFE</text>

    <text x="8" y="38" class="text" font-size="13" font-weight="600">network.http.http3.enable</text>
    <text x="8" y="55" class="text" font-size="11" opacity="0.7">Enable HTTP/3 protocol support</text>
    <text x="8" y="70" class="text" font-size="11" opacity="0.7">(QUIC transport)</text>

    <circle cx="350" cy="45" r="12" fill="#0060df"/>
    <text x="346" y="50" fill="#fff" font-size="16">✓</text>
  </g>

  <!-- Footer -->
  <text x="200" y="585" class="text" font-size="10" opacity="0.5" text-anchor="middle">105 flags loaded</text>
</svg>
EOF

# 2. SIDEBAR MOCKUP
cat > "$MOCKUP_DIR/02-sidebar-flags-tab.svg" <<'EOF'
<svg width="350" height="700" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .bg { fill: #ffffff; }
      .text { font-family: system-ui, -apple-system, sans-serif; fill: #333; }
      .header { fill: #0060df; }
      .tab-active { fill: #0060df; }
      .tab-inactive { fill: #e0e0e0; }
      .card { fill: #f9f9fa; stroke: #d7d7db; stroke-width: 1; }
      .positive { fill: #00c851; }
      .negative { fill: #ff4444; }
      .interesting { fill: #2196f3; }
    </style>
  </defs>

  <!-- Background -->
  <rect width="350" height="700" class="bg"/>

  <!-- Header -->
  <rect width="350" height="50" class="header"/>
  <text x="15" y="32" class="text" fill="#fff" font-size="16" font-weight="bold">FireFlag Sidebar</text>

  <!-- Tabs -->
  <g transform="translate(0, 50)">
    <rect width="87.5" height="40" class="tab-active"/>
    <text x="44" y="25" class="text" fill="#fff" font-size="11" text-anchor="middle">Flags</text>

    <rect x="87.5" width="87.5" height="40" class="tab-inactive"/>
    <text x="131" y="25" class="text" font-size="11" text-anchor="middle">Tracking</text>

    <rect x="175" width="87.5" height="40" class="tab-inactive"/>
    <text x="218.5" y="25" class="text" font-size="11" text-anchor="middle">Analytics</text>

    <rect x="262.5" width="87.5" height="40" class="tab-inactive"/>
    <text x="306" y="25" class="text" font-size="11" text-anchor="middle">Export</text>
  </g>

  <!-- Flag detail card -->
  <g transform="translate(10, 105)">
    <rect width="330" height="550" rx="8" class="card"/>

    <text x="15" y="25" class="text" font-size="14" font-weight="bold">privacy.resistFingerprinting</text>
    <rect x="15" y="30" width="50" height="16" rx="3" class="positive"/>
    <text x="22" y="42" fill="#fff" font-size="9" font-weight="bold">SAFE</text>

    <text x="15" y="65" class="text" font-size="11" opacity="0.8">Enable fingerprinting resistance to make browser tracking harder</text>

    <!-- Effects section -->
    <text x="15" y="95" class="text" font-size="12" font-weight="600">✓ Positive Effects</text>
    <text x="20" y="112" class="text" font-size="10">• Reduces browser fingerprinting</text>
    <text x="20" y="127" class="text" font-size="10">• Enhances privacy against tracking</text>
    <text x="20" y="142" class="text" font-size="10">• Spoofs timezone to UTC</text>
    <text x="20" y="157" class="text" font-size="10">• Reports generic screen resolution</text>

    <text x="15" y="185" class="text" font-size="12" font-weight="600">✗ Negative Effects</text>
    <text x="20" y="202" class="text" font-size="10">• May break websites relying on accurate timezone</text>
    <text x="20" y="217" class="text" font-size="10">• Can affect canvas-based visualizations</text>
    <text x="20" y="232" class="text" font-size="10">• Some web apps may malfunction</text>

    <text x="15" y="260" class="text" font-size="12" font-weight="600">ℹ Interesting Details</text>
    <text x="20" y="277" class="text" font-size="10">• Part of Tor Browser's privacy model</text>
    <text x="20" y="292" class="text" font-size="10">• Randomizes canvas data</text>
    <text x="20" y="307" class="text" font-size="10">• Limits high-resolution timers</text>

    <!-- Metadata -->
    <rect x="15" y="330" width="300" height="1" fill="#d7d7db"/>

    <text x="15" y="350" class="text" font-size="10" opacity="0.6">Type:</text>
    <text x="80" y="350" class="text" font-size="10">boolean</text>

    <text x="15" y="370" class="text" font-size="10" opacity="0.6">Category:</text>
    <text x="80" y="370" class="text" font-size="10">Privacy & Security</text>

    <text x="15" y="390" class="text" font-size="10" opacity="0.6">Default:</text>
    <text x="80" y="390" class="text" font-size="10">false</text>

    <text x="15" y="410" class="text" font-size="10" opacity="0.6">Min Version:</text>
    <text x="80" y="410" class="text" font-size="10">Firefox 58.0+</text>

    <text x="15" y="430" class="text" font-size="10" opacity="0.6">Permissions:</text>
    <text x="80" y="430" class="text" font-size="10">privacy</text>

    <!-- Toggle button -->
    <rect x="15" y="460" width="300" height="40" rx="6" fill="#0060df"/>
    <text x="165" y="485" class="text" fill="#fff" font-size="13" font-weight="600" text-anchor="middle">Enable Flag</text>

    <text x="165" y="525" class="text" font-size="9" opacity="0.5" text-anchor="middle">Documentation: wiki.mozilla.org/Security/Fingerprinting</text>
  </g>
</svg>
EOF

# 3. OPTIONS PAGE MOCKUP
cat > "$MOCKUP_DIR/05-options-general.svg" <<'EOF'
<svg width="1280" height="800" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .bg { fill: #ffffff; }
      .sidebar { fill: #f9f9fa; }
      .text { font-family: system-ui, -apple-system, sans-serif; fill: #333; }
      .header { fill: #0060df; }
      .card { fill: #ffffff; stroke: #d7d7db; stroke-width: 1; }
      .section-active { fill: #e0e0e0; }
    </style>
  </defs>

  <!-- Background -->
  <rect width="1280" height="800" class="bg"/>

  <!-- Sidebar -->
  <rect width="250" height="800" class="sidebar"/>

  <!-- Header in sidebar -->
  <text x="20" y="40" class="text" font-size="20" font-weight="bold">FireFlag Settings</text>

  <!-- Navigation -->
  <g transform="translate(20, 80)">
    <rect width="210" height="40" rx="4" class="section-active"/>
    <text x="15" y="25" class="text" font-size="13">⚙ General</text>

    <text x="15" y="70" class="text" font-size="13" opacity="0.6">📊 Tracking</text>
    <text x="15" y="110" class="text" font-size="13" opacity="0.6">🔐 Permissions</text>
    <text x="15" y="150" class="text" font-size="13" opacity="0.6">🔧 Advanced</text>
    <text x="15" y="190" class="text" font-size="13" opacity="0.6">ℹ About</text>
  </g>

  <!-- Main content area -->
  <g transform="translate(270, 0)">
    <!-- Page header -->
    <text x="30" y="50" class="text" font-size="24" font-weight="bold">General Settings</text>

    <!-- Auto-update section -->
    <g transform="translate(30, 90)">
      <rect width="950" height="140" rx="8" class="card"/>

      <text x="20" y="30" class="text" font-size="16" font-weight="600">Auto-Update</text>
      <text x="20" y="50" class="text" font-size="12" opacity="0.7">Keep flag database current with Mozilla changes</text>

      <g transform="translate(20, 70)">
        <rect width="20" height="20" rx="4" fill="#0060df"/>
        <text x="3" y="15" fill="#fff" font-size="14">✓</text>
        <text x="30" y="15" class="text" font-size="13">Enable automatic database updates</text>
      </g>

      <text x="50" y="105" class="text" font-size="11" opacity="0.6">Check for updates: Weekly</text>
      <text x="50" y="122" class="text" font-size="11" opacity="0.6">Last update: 2026-02-04 14:30 UTC</text>
    </g>

    <!-- UI Preferences section -->
    <g transform="translate(30, 250)">
      <rect width="950" height="200" rx="8" class="card"/>

      <text x="20" y="30" class="text" font-size="16" font-weight="600">User Interface</text>
      <text x="20" y="50" class="text" font-size="12" opacity="0.7">Customize how FireFlag appears</text>

      <g transform="translate(20, 70)">
        <rect width="20" height="20" rx="4" fill="#0060df"/>
        <text x="3" y="15" fill="#fff" font-size="14">✓</text>
        <text x="30" y="15" class="text" font-size="13">Show safety badges</text>
      </g>

      <g transform="translate(20, 105)">
        <rect width="20" height="20" rx="4" fill="#0060df"/>
        <text x="3" y="15" fill="#fff" font-size="14">✓</text>
        <text x="30" y="15" class="text" font-size="13">Display flag effects inline</text>
      </g>

      <g transform="translate(20, 140)">
        <rect width="20" height="20" rx="4" stroke="#d7d7db" stroke-width="1" fill="#fff"/>
        <text x="30" y="15" class="text" font-size="13">Compact view mode</text>
      </g>
    </g>

    <!-- Search preferences -->
    <g transform="translate(30, 470)">
      <rect width="950" height="140" rx="8" class="card"/>

      <text x="20" y="30" class="text" font-size="16" font-weight="600">Search & Filtering</text>
      <text x="20" y="50" class="text" font-size="12" opacity="0.7">Control search behavior</text>

      <g transform="translate(20, 70)">
        <rect width="20" height="20" rx="4" fill="#0060df"/>
        <text x="3" y="15" fill="#fff" font-size="14">✓</text>
        <text x="30" y="15" class="text" font-size="13">Search flag keys</text>
      </g>

      <g transform="translate(20, 105)">
        <rect width="20" height="20" rx="4" fill="#0060df"/>
        <text x="3" y="15" fill="#fff" font-size="14">✓</text>
        <text x="30" y="15" class="text" font-size="13">Search descriptions and effects</text>
      </g>
    </g>

    <!-- Save button -->
    <g transform="translate(30, 640)">
      <rect width="120" height="40" rx="6" fill="#0060df"/>
      <text x="60" y="26" class="text" fill="#fff" font-size="14" font-weight="600" text-anchor="middle">Save Settings</text>
    </g>
  </g>
</svg>
EOF

# 4. DEVTOOLS MOCKUP
cat > "$MOCKUP_DIR/06-devtools-active-flags.svg" <<'EOF'
<svg width="1280" height="400" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .bg { fill: #1e1e1e; }
      .text { font-family: 'Consolas', 'Monaco', monospace; fill: #d4d4d4; }
      .header { fill: #2d2d2d; }
      .toolbar { fill: #252525; }
      .active { fill: #00c851; }
    </style>
  </defs>

  <!-- Background -->
  <rect width="1280" height="400" class="bg"/>

  <!-- Toolbar -->
  <rect width="1280" height="35" class="toolbar"/>
  <text x="15" y="22" class="text" font-size="12" fill="#888">Active Flags</text>
  <text x="140" y="22" class="text" font-size="12" fill="#666">Performance</text>
  <text x="265" y="22" class="text" font-size="12" fill="#666">Impact Analysis</text>
  <text x="430" y="22" class="text" font-size="12" fill="#666">Console</text>

  <!-- Content area -->
  <g transform="translate(15, 50)">
    <text x="0" y="20" class="text" font-size="13" fill="#4ec9b0">Flags Active on This Page:</text>

    <!-- Flag 1 -->
    <g transform="translate(0, 40)">
      <circle cx="5" cy="5" r="4" class="active"/>
      <text x="15" y="10" class="text" font-size="12" fill="#9cdcfe">privacy.resistFingerprinting</text>
      <text x="350" y="10" class="text" font-size="11" fill="#888">= true</text>
      <text x="450" y="10" class="text" font-size="11" fill="#ce9178">[Safe]</text>
    </g>

    <!-- Flag 2 -->
    <g transform="translate(0, 70)">
      <circle cx="5" cy="5" r="4" class="active"/>
      <text x="15" y="10" class="text" font-size="12" fill="#9cdcfe">network.http.http3.enable</text>
      <text x="350" y="10" class="text" font-size="11" fill="#888">= true</text>
      <text x="450" y="10" class="text" font-size="11" fill="#ffa500">[Experimental]</text>
    </g>

    <!-- Flag 3 -->
    <g transform="translate(0, 100)">
      <circle cx="5" cy="5" r="4" class="active"/>
      <text x="15" y="10" class="text" font-size="12" fill="#9cdcfe">gfx.webrender.all</text>
      <text x="350" y="10" class="text" font-size="11" fill="#888">= true</text>
      <text x="450" y="10" class="text" font-size="11" fill="#ffa500">[Experimental]</text>
    </g>

    <!-- Effects section -->
    <text x="0" y="160" class="text" font-size="13" fill="#4ec9b0">Observed Effects:</text>

    <text x="15" y="185" class="text" font-size="11">• Canvas fingerprinting blocked (privacy.resistFingerprinting)</text>
    <text x="15" y="205" class="text" font-size="11">• GPU acceleration active (gfx.webrender.all)</text>
    <text x="15" y="225" class="text" font-size="11">• HTTP/3 connection established (network.http.http3.enable)</text>

    <!-- Action buttons -->
    <g transform="translate(0, 260)">
      <rect width="140" height="30" rx="4" fill="#0e639c"/>
      <text x="70" y="20" class="text" font-size="12" text-anchor="middle">Start Recording</text>

      <rect x="160" width="100" height="30" rx="4" stroke="#666" stroke-width="1" fill="none"/>
      <text x="210" y="20" class="text" font-size="12" text-anchor="middle">Export Log</text>
    </g>
  </g>
</svg>
EOF

echo "✓ Generated 4 mockup screenshots"
echo ""

# Convert SVGs to PNGs if imagemagick is available
if command -v convert &> /dev/null; then
    echo "Converting SVGs to PNGs..."
    for svg in "$MOCKUP_DIR"/*.svg; do
        png="${svg%.svg}.png"
        convert -density 150 "$svg" "$png"
        echo "  ✓ $(basename "$png")"
    done
    echo ""
    echo "✓ PNG versions created"
else
    echo "⚠ ImageMagick not installed - SVG mockups only"
    echo "  Install: sudo apt install imagemagick"
fi

echo ""
echo "Mockups generated in: $MOCKUP_DIR/"
echo ""
echo "Next steps:"
echo "  1. Review mockups"
echo "  2. Capture real screenshots: deno run --allow-read --allow-write --allow-net --allow-run --allow-env .screenshots/capture-screenshots.js"
echo "  3. Replace mockups with real screenshots"
echo ""
