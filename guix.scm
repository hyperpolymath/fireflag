;; SPDX-License-Identifier: MPL-2.0
;; Guix package definition for FireFlag

(use-modules
  (guix packages)
  (guix download)
  (guix git-download)
  (guix build-system gnu)
  (guix licenses)
  ((guix licenses) #:prefix license:)
  (gnu packages)
  (gnu packages base)
  (gnu packages bash)
  (gnu packages idris)
  (gnu packages zig)
  (gnu packages node)
  (gnu packages gnupg)
  (gnu packages image)
  (gnu packages version-control))

(define-public fireflag
  (package
    (name "fireflag")
    (version "0.1.0")
    (source (local-file "." "fireflag-checkout"
                        #:recursive? #t
                        #:select? (git-predicate (dirname (current-filename)))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (delete 'configure)  ; No configure script
         (replace 'build
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((deno (assoc-ref inputs "deno"))
                    (idris2 (assoc-ref inputs "idris2"))
                    (zig (assoc-ref inputs "zig")))
               ;; Build ReScript code
               (invoke "deno" "run" "-A" "npm:rescript" "build")

               ;; Check Idris2 proofs
               (with-directory-excursion "extension/lib/idris"
                 (invoke "idris2" "--check" "FlagSafety.idr")
                 (invoke "idris2" "--check" "FlagTransaction.idr")
                 (invoke "idris2" "--check" "SafeUI.idr"))

               ;; Build extension
               (with-directory-excursion "extension"
                 (invoke "deno" "run" "-A" "npm:web-ext" "build" "--overwrite-dest")))
             #t))
         (replace 'check
           (lambda _
             ;; Lint extension
             (with-directory-excursion "extension"
               (invoke "deno" "run" "-A" "npm:web-ext" "lint"))
             #t))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (share (string-append out "/share/fireflag")))
               ;; Install built extension
               (install-file "extension/web-ext-artifacts/*.xpi" share)
               (install-file "LICENSE" share)
               (install-file "README.adoc" share))
             #t)))))
    (native-inputs
     `(("bash" ,bash)
       ("deno" ,deno)
       ("idris2" ,idris2)
       ("zig" ,zig)
       ("node" ,node)
       ("git" ,git)
       ("gnupg" ,gnupg)
       ("imagemagick" ,imagemagick)))
    (synopsis "Safe Firefox/Gecko flag management extension")
    (description
     "FireFlag is a Firefox/Gecko browser extension that helps users and
developers safely manage browser flags (about:config, experimental features,
developer flags) with safety classification, tracking, and analytics.

Features:
@itemize
@item 105+ well-researched Firefox flags with safety levels
@item Automated weekly database updates from Mozilla source
@item Granular permission system with UI feedback
@item Developer tools integration (tracking, export, DevTools panel)
@item Type-safe ReScript + Idris2 safety proofs
@item Support for Firefox, Librewolf, Waterfox, Pale Moon
@end itemize")
    (home-page "https://github.com/hyperpolymath/fireflag")
    (license license:mpl2.0)))  ; MPL-2.0 fallback for Mozilla Add-ons

fireflag
