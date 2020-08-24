module Updater.Command
  ( Command(..)
  , GenerateOptions(..)
  , SyncLabelsOptions(..)
  , run
  ) where

import Prelude

import Control.Monad.Except (throwError)
import Data.Array as Array
import Data.Either (Either(..))
import Data.Foldable (foldMap, traverse_)
import Data.Maybe (Maybe, fromMaybe)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Aff as Aff
import Effect.Class.Console (log)
import Updater.Generate.Template (runBaseTemplates, runJsTemplates)
import Updater.SyncLabels.Request (IssueLabelRequestOpts)
import Updater.SyncLabels.Request as SyncLabels
import Updater.Utils.Dhall as Utils.Dhall

-- | The data type which describes what tasks this CLI tool can assist with. See
-- | the library documentation for a full description of what these commands are
-- | intended to accomplish.
data Command
  = Generate GenerateOptions
  | SyncLabels SyncLabelsOptions

-- | Run a command, performing any relevant updates.
run :: Command -> Effect Unit
run = launchAff_ <<< case _ of
  Generate opts ->
    runGenerate opts

  SyncLabels opts ->
    runSyncLabels opts

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

    !! NOT ALL CONTENT IS COMPLETE !!

    You should now fill in the library's Summary and Quick Start sections in
    the README.md file in the root of the repository.
    """

type SyncLabelsOptions =
  { token :: String
  , repo :: String
  , owner :: Maybe String
  , deleteUnused :: Boolean
  }

-- | Update the issue labels used in the repository to match the colors, label
-- | names, and descriptions used across the Contributors libraries.
-- | that would be overwritten.
runSyncLabels :: SyncLabelsOptions -> Aff Unit
runSyncLabels opts = do
  let
    requestOpts :: IssueLabelRequestOpts
    requestOpts =
      { token: opts.token
      , repo: opts.repo
      , owner: fromMaybe "purescript-contrib" opts.owner
      }

  SyncLabels.getLabels requestOpts >>= case _ of
    Left e ->
      throwError $ Aff.error e

    Right { create, update, delete } -> do
      traverse_ (SyncLabels.createLabel requestOpts) create
      traverse_ (SyncLabels.patchLabel requestOpts) update

      when (opts.deleteUnused && not Array.null delete) do
        log $ "Deleting: " <> foldMap show delete
        traverse_ (SyncLabels.deleteLabel requestOpts) delete
