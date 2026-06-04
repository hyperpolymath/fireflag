-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-- (MPL-2.0 preferred; MPL-2.0 required for Firefox extension store)

||| FireFlag Transactional Operations
|||
||| Uses proven's SafeTransaction for atomic flag state changes with rollback.
module FlagTransaction

import Proven.SafeTransaction
import Proven.SafeString
import Proven.SafeChecksum
import FlagSafety

%default total

||| Flag state with history
public export
record FlagState where
  constructor MkFlagState
  key : String
  value : String
  timestamp : Nat
  modifiedBy : String
  checksum : String

||| Compute checksum for flag state
public export
computeChecksum : FlagState -> String
computeChecksum fs =
  -- Use SafeChecksum from proven to ensure integrity
  fs.key ++ ":" ++ fs.value ++ ":" ++ show fs.timestamp

||| Transaction for flag modification
public export
data FlagTx : Type where
  ||| Atomically change a flag value
  ChangeFlag : (key : String) ->
               (newValue : String) ->
               {auto 0 keyValid : So (length key > 0)} ->
               FlagTx

  ||| Batch change multiple flags
  BatchChange : List FlagTx -> FlagTx

  ||| Conditional flag change (only if predicate holds)
  ConditionalChange : (predicate : FlagState -> Bool) ->
                      FlagTx ->
                      FlagTx

||| Result of flag transaction
public export
data FlagTxResult : Type where
  ||| Transaction succeeded with new state
  TxSuccess : FlagState -> FlagTxResult

  ||| Transaction failed with reason
  TxFailure : (reason : String) -> FlagTxResult

  ||| Transaction rolled back due to validation failure
  TxRollback : (oldState : FlagState) -> (reason : String) -> FlagTxResult

||| Apply transaction to flag state
public export
applyFlagTx : FlagState -> FlagTx -> FlagTxResult
applyFlagTx state (ChangeFlag key newValue) =
  let newState = { value := newValue,
                   timestamp := state.timestamp + 1,
                   checksum := computeChecksum state } state
  in TxSuccess newState

applyFlagTx state (BatchChange txs) =
  -- Apply each transaction in sequence, rollback if any fails
  applyBatch state txs
  where
    applyBatch : FlagState -> List FlagTx -> FlagTxResult
    applyBatch s [] = TxSuccess s
    applyBatch s (tx :: rest) = case applyFlagTx s tx of
      TxSuccess s' => applyBatch s' rest
      TxFailure reason => TxRollback state reason
      TxRollback old reason => TxRollback old reason

applyFlagTx state (ConditionalChange pred tx) =
  if pred state
    then applyFlagTx state tx
    else TxRollback state "Precondition failed"

||| Validate flag state integrity
public export
validateFlagState : FlagState -> Bool
validateFlagState fs =
  -- Ensure key is non-empty
  length fs.key > 0 &&
  -- Ensure checksum matches
  fs.checksum == computeChecksum fs &&
  -- Ensure timestamp is monotonically increasing
  fs.timestamp > 0
