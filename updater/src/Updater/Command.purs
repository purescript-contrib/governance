module Updater.Command
  ( Command(..)
  , GenerateOptions(..)
  , run
  ) where

import Prelude

import Data.Interpolate (i)
import Data.Maybe (Maybe, fromMaybe)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class.Console (log)
import Updater.Template (runBaseTemplates, runJsTemplates)
import Updater.Utils.Dhall as Utils.Dhall

-- | The data type which describes what tasks this CLI tool can assist with. See
data Command
  = Generate GenerateOptions

type GenerateOptions =
  { usesJS :: Boolean
  , owner :: Maybe String
  , mainBranch :: Maybe String
  , displayName :: Maybe String
  , displayTitle :: Maybe String
  , maintainer :: String
  }

-- | Run a command, performing updates to the current library
run :: Command -> Effect Unit
run = launchAff_ <<< case _ of
  Generate opts ->
    runGenerate opts

-- | Generate
runGenerate :: GenerateOptions -> Aff Unit
runGenerate opts = do
  spago <- Utils.Dhall.readSpagoFile

  let
    variables =
      { owner: fromMaybe "purescript-contrib" opts.owner
      , mainBranch: fromMaybe "main" opts.mainBranch
      , packageName: spago.name
      , displayName: fromMaybe (i '`' spago.name '`') opts.displayName
      , displayTitle: fromMaybe spago.name opts.displayTitle
      , maintainer: opts.maintainer
      }

  runBaseTemplates variables

  when opts.usesJS do
    runJsTemplates variables

  log
    """
    Finished generating files. You should verify any contents in the backups
    directory and remove that directory before committing your changes.

    !! NOT ALL TEMPLATE AREAS HAVE BEEN FILLED IN !!

    You should now grep for `{{` to find text content that you should still
    fill in with correct contents (mostly in README files).
    """
