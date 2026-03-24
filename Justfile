# SPDX-License-Identifier: PMPL-1.0-or-later
# fireflag - Development Tasks
set shell := ["bash", "-uc"]
set dotenv-load := true

project := "fireflag"

# Show all recipes
default:
    @just --list --unsorted

# Build ReScript sources
build:
    deno run -A npm:rescript build

# Build in watch mode
watch:
    deno run -A npm:rescript build -w

# Clean build artifacts
clean:
    deno run -A npm:rescript clean
    rm -rf src/**/*.res.js src/**/*.bs.js

# Format ReScript code
fmt:
    deno run -A npm:rescript format src/**/*.res

# Type check
check:
    deno run -A npm:rescript build

# Run tests
test:
    deno test --allow-read

# Run example
example:
    deno run --allow-read src/example.js

# Lint (placeholder for future rescript-eslint)
lint:
    @echo "Lint: Type checking via rescript build"
    deno run -A npm:rescript build

# Extension development tasks
# --------------------------

# Build extension icons
icons:
    cd extension/icons && ./generate-icons.sh

# Lint extension with web-ext
lint-ext:
    cd extension && npx web-ext lint --warnings-as-errors

# Build extension .xpi
build-ext:
    cd extension && npx web-ext build --overwrite-dest

# Run extension in Firefox
run-ext:
    cd extension && npx web-ext run --firefox=firefox

# Sign extension for Mozilla Add-ons
sign-ext KEY SECRET:
    cd extension && npx web-ext sign \
        --api-key={{KEY}} \
        --api-secret={{SECRET}} \
        --channel=listed

# Containerization tasks
# -----------------------

# Build in Guix environment (local)
guix-build:
    guix shell -m .containerization/guix-manifest.scm -- \
        bash -c "deno run -A npm:rescript build && cd extension && deno run -A npm:web-ext build"

# Build using Guix package definition
guix-package:
    guix build -f guix.scm

# Build with Docker/Podman (simple)
container-build:
    podman build -f .containerization/Containerfile -t fireflag:latest .

# Build with complete orchestration (recommended)
container-build-full:
    @echo "Running full containerized build with security scanning..."
    bash .containerization/build.sh

# Build and extract artifacts
container-extract:
    @echo "Building and extracting artifacts..."
    BUILD_TAG=fireflag:build bash .containerization/build.sh
    @echo "Artifacts available in build-output/"

# Clean container build artifacts
container-clean:
    rm -rf build-output/
    podman rmi fireflag:latest fireflag:build 2>/dev/null || true
    @echo "Container artifacts cleaned"

# Run cerro-terro orchestration (if cerro-terro installed)
cerro-build:
    @if command -v cerro-terro >/dev/null 2>&1; then \
        cerro-terro run .containerization/cerro-terro.yml; \
    else \
        echo "cerro-terro not installed, using build.sh instead"; \
        bash .containerization/build.sh; \
    fi

# Security scanning tasks
# ------------------------

# Run all security scans
security-scan:
    @echo "Running svalin static analysis..."
    bash -c 'cd .github/workflows && bash svalin-scan.yml'
    @echo "Running vordr verification..."
    bash -c 'cd .github/workflows && bash vordr-verify.yml'
    @echo "Running selur secrets detection..."
    bash -c 'cd .github/workflows && bash selur-secrets.yml'

# Check Idris2 proofs
check-proofs:
    cd extension/lib/idris && idris2 --check FlagSafety.idr
    cd extension/lib/idris && idris2 --check FlagTransaction.idr
    cd extension/lib/idris && idris2 --check SafeUI.idr

# Screenshots
# -----------

# Generate SVG mockup screenshots
generate-mockups:
    bash .screenshots/generate-mockups.sh

# Capture real screenshots (automated with prompts)
capture-screenshots:
    deno run --allow-all .screenshots/capture-screenshots.js

# Optimize screenshot images
optimize-screenshots:
    @echo "Optimizing screenshots..."
    @for img in .screenshots/*.png; do \
        if [ -f "$$img" ]; then \
            convert "$$img" -resize '1280x800>' -quality 85 "$$img"; \
            echo "  ✓ $$(basename $$img)"; \
        fi \
    done
    @echo "✓ Screenshots optimized"

# Full build pipeline
# --------------------

# Complete build: proofs -> build -> lint -> security -> package
full-build: check-proofs build icons lint-ext security-scan build-ext
    @echo "✓ Full build complete"
    @ls -lh extension/web-ext-artifacts/

# Run panic-attacker pre-commit scan
assail:
    @command -v panic-attack >/dev/null 2>&1 && panic-attack assail . || echo "panic-attack not found — install from https://github.com/hyperpolymath/panic-attacker"
