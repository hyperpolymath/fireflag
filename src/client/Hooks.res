// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2024 Jonathan D.A. Jewell <hyperpolymath>

/**
 * React-like Hooks for Feature Flags
 *
 * Provides reactive hooks for use with React, Dioxus, or similar
 * component frameworks. Automatically re-renders when flags change.
 *
 * Usage (React):
 *   let darkMode = useFlag(client, "dark-mode", false)
 *   let variant = useFlagString(client, "theme", "light")
 *   let inExperiment = useRollout(client, "new-ui", userId)
 */

open Types

// Hook state for flag subscriptions
type hookState<'a> = {
  mutable value: 'a,
  mutable unsubscribe: option<unit => unit>,
}

// Create a flag hook that returns current value and subscribes to changes
// This is a framework-agnostic implementation; actual React hooks would use useState
let useFlag = (client: Client.t, key: string, defaultValue: bool): bool => {
  switch Client.getFlag(client, key) {
  | None => defaultValue
  | Some(flag) =>
    switch flag.flag.value {
    | Bool(b) => b
    | _ => defaultValue
    }
  }
}

// Hook for string flags
let useFlagString = (client: Client.t, key: string, defaultValue: string): string => {
  switch Client.getFlag(client, key) {
  | None => defaultValue
  | Some(flag) =>
    switch flag.flag.value {
    | String(s) => s
    | Bool(b) => b ? "true" : "false"
    | Int(i) => Int.toString(i)
    | Float(f) => Float.toString(f)
    | Json(j) => Js.Json.stringify(j)
    }
  }
}

// Hook for variant flags
let useFlagVariant = (client: Client.t, key: string, defaultValue: string): string => {
  useFlagString(client, key, defaultValue)
}

// Hook for rollout flags (requires userId)
let useRollout = (client: Client.t, key: string, userId: string): bool => {
  Client.evaluateRollout(client, key, ~userId)
}

// Hook for full evaluation result
let useFlagEvaluation = (client: Client.t, key: string): evaluationResult => {
  Client.evaluate(client, key)
}

// Hook for connection state
let useConnectionState = (client: Client.t): Client.connectionState => {
  Client.getConnectionState(client)
}

// Hook for checking if client is ready
let useIsReady = (client: Client.t): bool => {
  Client.isReady(client)
}

// Subscription-based hook creator (for frameworks with effect hooks)
type subscription<'a> = {
  getValue: unit => 'a,
  subscribe: ('a => unit) => unit => unit,
}

// Create a subscription for a boolean flag
let createBoolSubscription = (client: Client.t, key: string, defaultValue: bool): subscription<bool> => {
  {
    getValue: () => useFlag(client, key, defaultValue),
    subscribe: callback => {
      let listener = (value: flagValue) => {
        switch value {
        | Bool(b) => callback(b)
        | _ => ()
        }
      }
      Client.subscribeToFlag(client, key, listener)
      () => Client.unsubscribeFromFlag(client, key, listener)
    },
  }
}

// Create a subscription for a string flag
let createStringSubscription = (
  client: Client.t,
  key: string,
  defaultValue: string,
): subscription<string> => {
  {
    getValue: () => useFlagString(client, key, defaultValue),
    subscribe: callback => {
      let listener = (value: flagValue) => {
        let strValue = switch value {
        | String(s) => s
        | Bool(b) => b ? "true" : "false"
        | Int(i) => Int.toString(i)
        | Float(f) => Float.toString(f)
        | Json(j) => Js.Json.stringify(j)
        }
        callback(strValue)
      }
      Client.subscribeToFlag(client, key, listener)
      () => Client.unsubscribeFromFlag(client, key, listener)
    },
  }
}

// React-specific: Hook implementation using external React bindings
// This would be used with rescript-react

module React = {
  // React useState binding
  @module("react")
  external useState: 'a => ('a, ('a => 'a) => unit) = "useState"

  // React useEffect binding
  @module("react")
  external useEffect1: (unit => option<unit => unit>, array<'a>) => unit = "useEffect"

  // React useCallback binding
  @module("react")
  external useCallback1: ('a => 'b, array<'c>) => 'a => 'b = "useCallback"

  // Actual React hook for boolean flag
  let useFlag = (client: Client.t, key: string, defaultValue: bool): bool => {
    let (value, setValue) = useState(useFlag(client, key, defaultValue))

    useEffect1(
      () => {
        let listener = (flagValue: flagValue) => {
          switch flagValue {
          | Bool(b) => setValue(_ => b)
          | _ => ()
          }
        }
        Client.subscribeToFlag(client, key, listener)
        Some(() => Client.unsubscribeFromFlag(client, key, listener))
      },
      [key],
    )

    value
  }

  // React hook for string flag
  let useFlagString = (client: Client.t, key: string, defaultValue: string): string => {
    let (value, setValue) = useState(useFlagString(client, key, defaultValue))

    useEffect1(
      () => {
        let listener = (flagValue: flagValue) => {
          let strValue = switch flagValue {
          | String(s) => s
          | Bool(b) => b ? "true" : "false"
          | Int(i) => Int.toString(i)
          | Float(f) => Float.toString(f)
          | Json(j) => Js.Json.stringify(j)
          }
          setValue(_ => strValue)
        }
        Client.subscribeToFlag(client, key, listener)
        Some(() => Client.unsubscribeFromFlag(client, key, listener))
      },
      [key],
    )

    value
  }

  // React hook for rollout
  let useRollout = (client: Client.t, key: string, userId: string): bool => {
    let (value, setValue) = useState(useRollout(client, key, userId))

    useEffect1(
      () => {
        let listener = (_flagValue: flagValue) => {
          // Re-evaluate rollout when flag changes
          let newValue = Client.evaluateRollout(client, key, ~userId)
          setValue(_ => newValue)
        }
        Client.subscribeToFlag(client, key, listener)
        Some(() => Client.unsubscribeFromFlag(client, key, listener))
      },
      [key, userId],
    )

    value
  }

  // React hook for connection state
  let useConnectionState = (client: Client.t): Client.connectionState => {
    let (state, setState) = useState(Client.getConnectionState(client))

    useEffect1(
      () => {
        let listener = (event: Client.clientEvent) => {
          switch event {
          | Client.ConnectionChanged(newState) => setState(_ => newState)
          | _ => ()
          }
        }
        Client.addEventListener(client, listener)
        Some(() => Client.removeEventListener(client, listener))
      },
      [],
    )

    state
  }

  // React hook for ready state
  let useIsReady = (client: Client.t): bool => {
    let (ready, setReady) = useState(Client.isReady(client))

    useEffect1(
      () => {
        let listener = (event: Client.clientEvent) => {
          switch event {
          | Client.Ready => setReady(_ => true)
          | _ => ()
          }
        }
        Client.addEventListener(client, listener)
        Some(() => Client.removeEventListener(client, listener))
      },
      [],
    )

    ready
  }
}

// Preact-compatible hooks (same API as React)
module Preact = React

// Solid.js-style signals (framework-agnostic reactive primitives)
module Signals = {
  type signal<'a> = {
    get: unit => 'a,
    subscribe: ('a => unit) => unit => unit,
  }

  // Create a signal for a boolean flag
  let createFlagSignal = (client: Client.t, key: string, defaultValue: bool): signal<bool> => {
    {
      get: () => useFlag(client, key, defaultValue),
      subscribe: callback => {
        let listener = (value: flagValue) => {
          switch value {
          | Bool(b) => callback(b)
          | _ => ()
          }
        }
        Client.subscribeToFlag(client, key, listener)
        () => Client.unsubscribeFromFlag(client, key, listener)
      },
    }
  }

  // Create a signal for a string flag
  let createStringSignal = (client: Client.t, key: string, defaultValue: string): signal<string> => {
    {
      get: () => useFlagString(client, key, defaultValue),
      subscribe: callback => {
        let listener = (value: flagValue) => {
          let strValue = switch value {
          | String(s) => s
          | Bool(b) => b ? "true" : "false"
          | Int(i) => Int.toString(i)
          | Float(f) => Float.toString(f)
          | Json(j) => Js.Json.stringify(j)
          }
          callback(strValue)
        }
        Client.subscribeToFlag(client, key, listener)
        () => Client.unsubscribeFromFlag(client, key, listener)
      },
    }
  }
}
