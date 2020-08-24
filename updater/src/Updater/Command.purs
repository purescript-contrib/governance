module Updater.Command
  ( Command(..)
  , GenerateOptions(..)
  , run
  ) where

import Prelude

import Data.Maybe (Maybe, fromMaybe)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class.Console (log)
import Updater.Generate.Template (runBaseTemplates, runJsTemplates)
import Updater.Utils.Dhall as Utils.Dhall

-- | The data type which describes what tasks this CLI tool can assist with. See
-- | the library documentation for a full description of what these commands are
-- | intended to accomplish.
data Command
  = Generate GenerateOptions

-- | Run a command, performing any relevant updates.
run :: Command -> Effect Unit
run = launchAff_ <<< case _ of
  Generate opts ->
    runGenerate opts

-- | Possible flags to control how library templates should be generated. These
-- | are largely the same as the set of supported variables (see the documentation
-- | for the `Generate` command for more details).
type GenerateOptions =
  { usesJS :: Boolean
  , owner :: Maybe String
  , mainBranch :: Maybe String
  , displayName :: Maybe String
  , displayTitle :: Maybe String
  , maintainer :: String
  }

-- | Generate templates in the repository, backing up any conflicting files
-- | that would be overwritten.
runGenerate :: GenerateOptions -> Aff Unit
runGenerate opts = do
  spago <- Utils.Dhall.readSpagoFile

  let
    variables =
      { owner: fromMaybe "purescript-contrib" opts.owner
      , mainBranch: fromMaybe "main" opts.mainBranch
      , packageName: spago.name
      , displayName: fromMaybe ("`" <> spago.name <> "`") opts.displayName
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
