;; SPDX-License-Identifier: MPL-2.0
;; Guix manifest for FireFlag development environment

(specifications->manifest
  '(;; Core build tools
    "deno"
    "node"
    "git"

    ;; Type systems and proof checkers
    "idris2"
    "zig"

    ;; Web extension tools
    ;; Note: web-ext installed via npm in Guix node environment

    ;; Security scanning
    "gnupg"

    ;; Documentation
    "asciidoc"

    ;; Utilities
    "bash"
    "coreutils"
    "findutils"
    "grep"
    "sed"
    "jq"
    "imagemagick"
    "librsvg"))
