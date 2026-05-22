-- SPDX-License-Identifier: MPL-2.0
-- (MPL-2.0 preferred; MPL-2.0 required for Firefox extension store)
-- Copyright (C) 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>

||| FireFlag Safety Proofs
|||
||| Compile-time safety guarantees for flag management using dependent types.
module FlagSafety

import Data.Vect
import Data.So

%default total

||| Safety levels with ordering proof
public export
data SafetyLevel = Safe | Experimental | Dangerous

||| Ordering proof for safety levels
public export
Ord SafetyLevel where
  compare Safe Safe = EQ
  compare Safe _ = LT
  compare Dangerous Dangerous = EQ
  compare Dangerous _ = GT
  compare Experimental Safe = GT
  compare Experimental Experimental = EQ
  compare Experimental Dangerous = LT

||| Flag key must be non-empty
public export
data FlagKey : String -> Type where
  MkFlagKey : (s : String) -> {auto 0 nonEmpty : So (length s > 0)} -> FlagKey s

||| Permission list must be unique (no duplicates)
public export
data UniquePerms : Vect n String -> Type where
  NoPerms : UniquePerms []
  AddPerm : (p : String) ->
            {auto 0 notInTail : So (not (elem p ps))} ->
            UniquePerms ps ->
            UniquePerms (p :: ps)

||| Flag with safety proofs
public export
record SafeFlag where
  constructor MkSafeFlag
  key : String
  {auto 0 keyNonEmpty : So (length key > 0)}
  safety : SafetyLevel
  permissions : Vect n String
  {auto 0 permsUnique : UniquePerms permissions}

||| Proof that modifying a Safe flag requires no special permissions
public export
safeNeedsNoPerms : (f : SafeFlag) -> safety f = Safe -> permissions f = []
safeNeedsNoPerms f Refl = Refl

||| Proof that Dangerous flags must have at least one permission
public export
dangerousNeedsPerms : (f : SafeFlag) -> safety f = Dangerous -> LTE 1 (length (permissions f))
dangerousNeedsPerms (MkSafeFlag key safety [] permsUnique) Refl impossible
dangerousNeedsPerms (MkSafeFlag key safety (x :: xs) permsUnique) Refl = LTESucc LTEZero

||| Permission grant state
public export
data PermissionGrant : String -> Type where
  Granted : (perm : String) -> PermissionGrant perm
  Denied : (perm : String) -> PermissionGrant perm

||| All permissions granted proof
public export
data AllGranted : Vect n String -> Type where
  NoneNeeded : AllGranted []
  AddGranted : PermissionGrant p ->
               AllGranted ps ->
               AllGranted (p :: ps)

||| Flag can be safely modified if all permissions are granted
public export
data CanModify : SafeFlag -> Type where
  SafeModify : (f : SafeFlag) ->
               {auto 0 isSafe : safety f = Safe} ->
               CanModify f
  PermittedModify : (f : SafeFlag) ->
                    AllGranted (permissions f) ->
                    CanModify f

||| Proof that a flag change is reversible (can restore to default)
public export
record ReversibleChange where
  constructor MkReversible
  flag : SafeFlag
  originalValue : String
  newValue : String
  {auto 0 canModify : CanModify flag}
  {auto 0 valuesDistinct : So (originalValue /= newValue)}
