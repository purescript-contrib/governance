module Updater.Utils.Options
  ( multiString
  ) where

import Prelude

import Data.Array (filter)
import Data.Array (null) as Array
import Data.Either (Either(..))
import Data.String (null) as String
import Data.String.Common (split)
import Data.String.Pattern (Pattern)
import Options.Applicative.Types (ReadM)
import Options.Applicative.Builder (eitherReader)

multiString :: Pattern -> ReadM (Array String)
multiString splitPattern = eitherReader \s ->
  let strArray = filter (not <<< String.null) $ split splitPattern s
  in
    if Array.null strArray
      then Left "got empty string as input"
      else Right strArray
