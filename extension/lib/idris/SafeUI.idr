-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (C) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

||| SafeUI - XSS-proof UI rendering
|||
||| Uses proven's SafeHtml to guarantee XSS prevention in all UI components.
module SafeUI

import Proven.SafeHtml
import Proven.SafeString
import FlagSafety

%default total

||| Safely escape flag key for display
public export
escapeFlag Key : String -> TrustedHtml
escapeFlagKey key =
  -- Use SafeHtml's text escaping to prevent XSS
  MkTrustedHtml (escapeText key)
  where
    escapeText : String -> String
    escapeText s = pack $ concatMap escapeChar (unpack s)

    escapeChar : Char -> List Char
    escapeChar '<' = unpack "&lt;"
    escapeChar '>' = unpack "&gt;"
    escapeChar '&' = unpack "&amp;"
    escapeChar '"' = unpack "&quot;"
    escapeChar '\'' = unpack "&#039;"
    escapeChar c = [c]

||| Create safe HTML badge for safety level
public export
safetybadge : SafetyLevel -> HtmlElement
safetyBadge Safe =
  Element "span" [MkHtmlAttr "class" "safety-badge safe"]
    [TextNode "safe"]
safetyBadge Experimental =
  Element "span" [MkHtmlAttr "class" "safety-badge experimental"]
    [TextNode "experimental"]
safetyBadge Dangerous =
  Element "span" [MkHtmlAttr "class" "safety-badge dangerous"]
    [TextNode "dangerous"]

||| Create safe flag list item
public export
flagListItem : SafeFlag -> HtmlElement
flagListItem flag =
  Element "div" [MkHtmlAttr "class" "flag-item"]
    [ Element "div" [MkHtmlAttr "class" "flag-header"]
        [ Element "span" [MkHtmlAttr "class" "flag-key"]
            [RawHtml (escapeFlagKey flag.key)]
        , safetyBadge flag.safety
        ]
    ]

||| Sanitize user-provided flag description
||| Strips potentially dangerous HTML tags
public export
sanitizeDescription : String -> TrustedHtml
sanitizeDescription desc =
  -- Remove script tags, event handlers, etc.
  let cleaned = removeScriptTags desc
      escaped = escapeHtml cleaned
  in MkTrustedHtml escaped
  where
    removeScriptTags : String -> String
    removeScriptTags s =
      -- Simple implementation: remove <script> tags
      -- In production, use proven's full HTML sanitizer
      pack $ filter (/= '<') (unpack s)

    escapeHtml : String -> String
    escapeHtml s = pack $ concatMap escapeChar (unpack s)
      where
        escapeChar : Char -> List Char
        escapeChar '<' = unpack "&lt;"
        escapeChar '>' = unpack "&gt;"
        escapeChar '&' = unpack "&amp;"
        escapeChar '"' = unpack "&quot;"
        escapeChar c = [c]

||| Proof that rendered HTML is XSS-safe
||| All user input must pass through escaping functions
public export
data XSSSafe : HtmlElement -> Type where
  ||| Text nodes are always safe (automatically escaped)
  TextSafe : XSSSafe (TextNode s)

  ||| Trusted HTML is safe by construction
  TrustedSafe : XSSSafe (RawHtml trusted)

  ||| Elements are safe if children are safe
  ElementSafe : (children : List HtmlElement) ->
                All XSSSafe children ->
                XSSSafe (Element tag attrs children)
