;; SPDX-License-Identifier: MPL-2.0
;; Guix channel for FireFlag reproducible builds

(channel
  (name 'fireflag)
  (url "https://github.com/hyperpolymath/fireflag")
  (branch "main")
  (introduction
    (make-channel-introduction
      "commitish-hash-will-be-set-on-first-push"
      (openpgp-fingerprint
        "FINGERPRINT-WILL-BE-SET"))))

;; Package definition for FireFlag
(use-modules
  (guix packages)
  (guix download)
  (guix build-system trivial)
  (guix licenses)
  ((guix licenses) #:prefix license:))

(define-public fireflag
  (package
    (name "fireflag")
    (version "0.1.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/hyperpolymath/fireflag"
                                  "/releases/download/v" version
                                  "/fireflag-" version ".tar.gz"))
              (sha256
               (base32
                "0000000000000000000000000000000000000000000000000000"))))
    (build-system trivial-build-system)
    (native-inputs
      `(("deno" ,deno)
        ("idris2" ,idris2)
        ("zig" ,zig)
        ("node" ,node)))
    (synopsis "Safe Firefox/Gecko flag management extension")
    (description
     "FireFlag is a Firefox/Gecko browser extension that helps users and
developers safely manage browser flags (about:config, experimental features,
developer flags) with safety classification, tracking, and analytics.")
    (home-page "https://github.com/hyperpolymath/fireflag")
    (license license:mpl2.0)))

fireflag
