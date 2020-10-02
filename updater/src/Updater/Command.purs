module Updater.Command
  ( Command(..)
  , GenerateOptions(..)
  , SyncLabelsOptions(..)
  , run
  ) where

import Prelude

import Control.Monad.Except (runExceptT, throwError)
import Control.Parallel (parTraverse_)
import Data.Array as Array
import Data.Either (Either(..))
import Data.Foldable (traverse_)
import Data.Interpolate (i)
import Data.List.Types (NonEmptyList)
import Data.Maybe (Maybe, fromMaybe, isJust, maybe)
import Data.String (joinWith)
import Data.String as String
import Data.String.Extra as String.Extra
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Aff as Aff
import Effect.Class (liftEffect)
import Effect.Class.Console (error, log)
import Node.Path (FilePath)
import Node.Process (exit)
import Updater.Generate.Changelog (appendReleaseInfoToChangelog)
import Updater.Generate.Template (allTemplates, docsChangelog, runTemplates, validateFiles)
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
  , repo :: Maybe String
  , mainBranch :: Maybe String
  , displayName :: Maybe String
  , displayTitle :: Maybe String
  , maintainers :: NonEmptyList String
  , files :: Maybe (NonEmptyList FilePath)
  }

-- | Generate templates in the repository, backing up any conflicting files
-- | that would be overwritten.
runGenerate :: GenerateOptions -> Aff Unit
runGenerate opts = do
  spago <- Utils.Dhall.readSpagoFile

  let
    toTitleCase =
      String.joinWith " "
        <<< map String.Extra.upperCaseFirst
        <<< String.split (String.Pattern "-")

    maintainerTemplate maintainer =
      i "[![Maintainer: " maintainer "](https://img.shields.io/badge/maintainer-" maintainer "-teal.svg)](https://github.com/" maintainer ")"

    variables =
      { owner: fromMaybe "purescript-contrib" opts.owner
      , repo: fromMaybe ("purescript-" <> spago.name) opts.repo
      , mainBranch: fromMaybe "main" opts.mainBranch
      , packageName: spago.name
      , displayName: fromMaybe ("`" <> spago.name <> "`") opts.displayName
      , displayTitle: fromMaybe (toTitleCase spago.name) opts.displayTitle
      , maintainers: map maintainerTemplate opts.maintainers
      , usesJS: opts.usesJS
      }

    validatedTemplates =
      maybe
        (Right allTemplates)
        (validateFiles { usesJS: opts.usesJS, templates: allTemplates })
        opts.files

  case validatedTemplates of
    Right templates -> do
      runTemplates variables templates

      when (isJust $ Array.find (eq docsChangelog) templates) $
        appendReleaseInfoToChangelog { owner: variables.owner, repo: variables.repo }

    Left msg -> do
       error msg
       liftEffect $ exit 1

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

  resp <- runExceptT do
    sifted <- SyncLabels.getLabels requestOpts

    let logPreview msg = log <<< append msg <<< joinWith ", " <<< map (show <<< _.name)

    when (not Array.null sifted.create) do
      logPreview "Creating: " sifted.create
      parTraverse_ (SyncLabels.createLabel requestOpts) sifted.create

    when (not Array.null sifted.update) do
      logPreview "Patching: " sifted.update
      parTraverse_ (SyncLabels.patchLabel requestOpts) sifted.update

    when (opts.deleteUnused && not Array.null sifted.delete) do
      logPreview "Deleting: " sifted.delete
      traverse_ (SyncLabels.deleteLabel requestOpts) sifted.delete

  case resp of
    Left e -> do
      log "Did not successfully create, update, and delete labels: "
      error (Aff.message e)
      log "You can retry this operation."
      throwError e

    Right _ ->
      log "Successfully completed syncing labels."
