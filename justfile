# SPDX-License-Identifier: AGPL-3.0-or-later
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
