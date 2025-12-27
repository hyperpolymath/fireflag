// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2024 Jonathan D.A. Jewell <hyperpolymath>

/**
 * Feature Flag Provider
 *
 * Context provider for React/Preact applications.
 * Wraps the client and provides flag access to child components.
 *
 * Usage:
 *   <FireflagProvider client={client}>
 *     <App />
 *   </FireflagProvider>
 *
 *   // In child components:
 *   let client = useFireflag()
 *   let darkMode = Hooks.React.useFlag(client, "dark-mode", false)
 */

// React context bindings
module React = {
  type context<'a>
  type element

  @module("react")
  external createContext: 'a => context<'a> = "createContext"

  @module("react")
  external useContext: context<'a> => 'a = "useContext"

  @module("react")
  external createElement: ('a, 'b, array<element>) => element = "createElement"

  @module("react")
  external useEffect0: (unit => option<unit => unit>) => unit = "useEffect"

  @module("react")
  external useState: 'a => ('a, ('a => 'a) => unit) = "useState"
}

// Fireflag context
let context: React.context<option<Client.t>> = React.createContext(None)

// Provider props
type providerProps = {
  client: Client.t,
  children: React.element,
}

// Provider component
let provider = (props: providerProps): React.element => {
  React.createElement(
    Obj.magic(context)["Provider"],
    {"value": Some(props.client)},
    [props.children],
  )
}

// Hook to get client from context
let useFireflag = (): Client.t => {
  switch React.useContext(context) {
  | None => Js.Exn.raiseError("useFireflag must be used within a FireflagProvider")
  | Some(client) => client
  }
}

// Optional hook that doesn't throw
let useFireflagOptional = (): option<Client.t> => {
  React.useContext(context)
}

// Higher-order component for class components
let withFireflag = (component: 'a): 'a => {
  Obj.magic((props: 'b) => {
    let client = useFireflag()
    React.createElement(component, Obj.magic({...Obj.magic(props), "fireflag": client}), [])
  })
}

// Feature flag gate component
type gateProps = {
  flag: string,
  children: React.element,
  fallback: option<React.element>,
}

let gate = (props: gateProps): React.element => {
  let client = useFireflag()
  let enabled = Hooks.React.useFlag(client, props.flag, false)

  if enabled {
    props.children
  } else {
    props.fallback->Option.getOr(Obj.magic(Js.null))
  }
}

// Rollout gate component (user-based)
type rolloutGateProps = {
  flag: string,
  userId: string,
  children: React.element,
  fallback: option<React.element>,
}

let rolloutGate = (props: rolloutGateProps): React.element => {
  let client = useFireflag()
  let enabled = Hooks.React.useRollout(client, props.flag, props.userId)

  if enabled {
    props.children
  } else {
    props.fallback->Option.getOr(Obj.magic(Js.null))
  }
}

// Variant component (renders based on flag value)
type variantProps = {
  flag: string,
  variants: Js.Dict.t<React.element>,
  defaultVariant: string,
}

let variant = (props: variantProps): React.element => {
  let client = useFireflag()
  let value = Hooks.React.useFlagString(client, props.flag, props.defaultVariant)

  Js.Dict.get(props.variants, value)->Option.getOr(
    Js.Dict.get(props.variants, props.defaultVariant)->Option.getOr(Obj.magic(Js.null)),
  )
}

// Loading wrapper while client initializes
type loadingWrapperProps = {
  client: Client.t,
  loading: React.element,
  children: React.element,
}

let loadingWrapper = (props: loadingWrapperProps): React.element => {
  let ready = Hooks.React.useIsReady(props.client)

  if ready {
    props.children
  } else {
    props.loading
  }
}

// Connection status indicator component
type connectionStatusProps = {
  renderConnected: unit => React.element,
  renderDisconnected: unit => React.element,
  renderConnecting: unit => React.element,
  renderReconnecting: unit => React.element,
}

let connectionStatus = (props: connectionStatusProps): React.element => {
  let client = useFireflag()
  let state = Hooks.React.useConnectionState(client)

  switch state {
  | Client.Connected => props.renderConnected()
  | Client.Disconnected => props.renderDisconnected()
  | Client.Connecting => props.renderConnecting()
  | Client.Reconnecting => props.renderReconnecting()
  }
}
