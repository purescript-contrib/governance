module Updater.SyncLabels.Request
  ( IssueLabelRequestOpts(..)
  , listAllLabels
  , Sifted(..)
  , getLabels
  , getSiftedLabels
  , createLabel
  , patchLabel
  , deleteLabel
  ) where

import Prelude

import Affjax (URL)
import Affjax as AX
import Affjax.RequestBody (RequestBody(..))
import Affjax.RequestHeader (RequestHeader(..))
import Affjax.ResponseFormat as AXRF
import Affjax.StatusCode (StatusCode(..))
import Control.Monad.Except (ExceptT(..), throwError)
import Control.Parallel (parTraverse)
import Data.Array (filter, sort)
import Data.Array as Array
import Data.Bifunctor (lmap)
import Data.Codec (encode, (<~<))
import Data.Codec as Codec
import Data.Codec.Argonaut as CA
import Data.Codec.Argonaut.Migration as CAM
import Data.Either (Either(..))
import Data.Foldable (foldl, traverse_)
import Data.FoldableWithIndex (foldlWithIndex)
import Data.HTTP.Method (Method(..))
import Data.Interpolate (i)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), isNothing)
import Data.Symbol (SProxy(..))
import Data.Tuple (Tuple(..), fst, snd)
import Effect.Aff (Aff, Error, error)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Record as Record
import Updater.SyncLabels.IssueLabel (IssueLabel, issueLabelCodec)
import Updater.SyncLabels.IssueLabel as IssueLabel
import Updater.SyncLabels.IssueLabel as Issuelabel
import Updater.SyncLabels.Repos (purescriptContribRepos, purescriptNodeRepos, purescriptRepos, purescriptWebRepos)

-- | The arguments necessary to construct a request to the GitHub API for issue
-- | labels.
type IssueLabelRequestOpts =
  { owner :: String
  , repo :: String
  , token :: String
  }

type Sifted =
  { create :: Array IssueLabel
  , update :: Array IssueLabel
  , delete :: Array IssueLabel
  }

listAllLabels :: String -> ExceptT Error Aff Unit
listAllLabels token = do
  let
    allRepos =
      map { owner: "purescript", repo: _ } purescriptRepos
        <> map { owner: "purescript-contrib", repo: _ } purescriptContribRepos
        <> map { owner: "purescript-web", repo: _ } purescriptWebRepos
        <> map { owner: "purescript-node", repo: _ } purescriptNodeRepos

    getRepoLabel = listLabel <<< (\{ owner, repo } -> { token, owner, repo })

  results <- parTraverse getRepoLabel allRepos

  let
    labelMap ::
      { labels :: Map String (Array String)
      , metadata :: Map String (Map { description :: String, color :: String } (Array String))
      }
    labelMap = foldl insertRepoForEachLabel emptyMaps results
      where
      emptyMaps = { labels: Map.empty, metadata: Map.empty }

      insertRepoForEachLabel accMap { owner, repo, labels } =
        foldl (handleInsert owner repo) accMap labels

      handleInsert owner repo accMap label@{ description, color } = { labels, metadata }
        where
        labels = Map.insertWith (<>) label.name [ repo ] accMap.labels
        metadata = Map.insertWith (Map.unionWith (<>)) label.name labelMetadata accMap.metadata
          where
          labelMetadata = Map.singleton { description, color } [ i owner "/" repo ]

  liftEffect do
    let
      uniqueLabelsSize = show $ Map.size labelMap.labels
      allLabels = show $ sort $ map fst $ (Map.toUnfoldableUnordered labelMap.labels :: Array _)

      unfoldedMap = Map.toUnfoldableUnordered labelMap.metadata
      noDifferences = filter (eq 1 <<< Map.size <<< snd) unfoldedMap
      noDifferencesSortedShown = show $ sort $ map fst noDifferences
      haveDiff = filter (not <<< eq 1 <<< Map.size <<< snd) unfoldedMap
      haveDiffNumber = Array.length haveDiff
      metadataDiff = foldl foldFn [] haveDiff
        where
        foldFn acc (Tuple labelName metadata) =
          acc
            <> [ i labelName " has " (Map.size metadata) " differences" ]
            <> (foldl foldFn2 [] $ sort $ Map.toUnfoldable metadata)
            <> [ "" ]

        foldFn2 acc (Tuple r repos) = acc <>
          [ i "Color: #" r.color " | Description: " r.description
          , i " ↳ Repos (" (Array.length repos) "): " $ show repos
          ]

      labelAppearancesInRepos = foldlWithIndex foldFn [] labelMap.labels
        where
        foldFn labelName acc repos = acc <>
          [ i "Label '" labelName "' appears in " (Array.length repos) " repos:"
          , show repos
          , ""
          ]

      finalReport =
        [ i "# of Unique Labels: " uniqueLabelsSize
        , i "Label names: " allLabels
        , "----------------"
        ]
          <> labelAppearancesInRepos
          <>
            [ "----------------"
            , "Labels with no differences in metadata:"
            , noDifferencesSortedShown
            , "----------------"
            , i haveDiffNumber " labels have differences in metadata:"
            ]
          <> metadataDiff

    traverse_ log finalReport

  where
  listLabel opts@{ owner, repo } = do
    resp <- ExceptT $ map (lmap (error <<< AX.printError)) $ AX.request $ AX.defaultRequest
      { headers = mkHeaders opts
      , responseFormat = AXRF.json
      , url = mkApiUrl opts
      }

    unless (resp.status == StatusCode 200) do
      throwError $ error $ i "Did not receive StatusCode 200 when getting labels for: " opts.owner "/" opts.repo

    let decoded = Codec.decode (CA.array issueLabelCodec) resp.body

    labels <- ExceptT $ pure $ lmap (error <<< CA.printJsonDecodeError) decoded
    pure { owner, repo, labels }

-- | Fetch all labels for the repository.
getLabels :: IssueLabelRequestOpts -> ExceptT Error Aff (Array IssueLabel)
getLabels opts = do
  resp <- ExceptT $ map (lmap (error <<< AX.printError)) $ AX.request $ AX.defaultRequest
    { headers = mkHeaders opts
    , responseFormat = AXRF.json
    , url = mkApiUrl opts
    }

  unless (resp.status == StatusCode 200) do
    throwError $ error "Did not receive StatusCode 200 when getting labels."

  let decoded = Codec.decode (CA.array issueLabelCodec) resp.body

  ExceptT $ pure $ lmap (error <<< CA.printJsonDecodeError) decoded

-- | Fetch all labels for the repository.
getSiftedLabels :: IssueLabelRequestOpts -> ExceptT Error Aff Sifted
getSiftedLabels opts = do
  sift <$> getLabels opts

-- | Reconcile the labels received from the API with the actions that should be
-- | taken for each label (create missing labels, patch existing labels, or
-- | delete extraneous labels).
sift :: Array IssueLabel -> Sifted
sift =
  Record.delete (SProxy :: _ "accept")
    <<< fillMissing
    <<< Record.insert (SProxy :: _ "create") []
    <<< foldl checkApiLabel { update: [], delete: [], accept: [] }
  where
  checkApiLabel acc apiLabel =
    -- This label is already correct, so do nothing (add to the 'accept' array)
    case Array.find (eq apiLabel) Issuelabel.labels of
      Just v ->
        acc { accept = Array.cons v acc.accept }
      Nothing -> case Array.find (eq apiLabel.name <<< _.name) IssueLabel.labels of
        -- this label matches a contrib label, but not all information matches,
        -- so patch the label
        Just v ->
          acc { update = Array.cons v acc.update }
        -- this label does not exist in the contrib set, so it should be deleted
        -- (if that option was selected)
        Nothing ->
          acc { delete = Array.cons apiLabel acc.delete }

  -- Any API labels that don't already exist or need to be patched will need to
  -- be created.
  fillMissing sifted = sifted
    { create =
        Issuelabel.labels # Array.filter \{ name } ->
          isNothing (Array.find (eq name <<< _.name) sifted.update)
            && isNothing (Array.find (eq name <<< _.name) sifted.accept)
    }

-- | Create a new label. Note: if updating a label, use `patchLabel` instead.
createLabel :: IssueLabelRequestOpts -> IssueLabel -> ExceptT Error Aff Unit
createLabel opts label = do
  resp <- ExceptT $ map (lmap (error <<< AX.printError)) $ AX.request $ AX.defaultRequest
    { method = Left POST
    , headers = mkHeaders opts
    , url = mkApiUrl opts
    , content = Just $ Json $ encode issueLabelCodec label
    }

  unless (resp.status == StatusCode 201) do
    throwError $ error $ "Did not receive StatusCode 201 when creating label: " <> label.name

-- | Update a label which already exists to a new value.
-- |
-- | The patch endpoint for labels uses `new_name` instead of `name` for the
-- | label name, so we need to migrate our codec before making the request.
-- |
-- | See: https://developer.github.com/v3/issues/labels/#update-a-label
patchLabel :: IssueLabelRequestOpts -> IssueLabel -> ExceptT Error Aff Unit
patchLabel opts label = do
  resp <- ExceptT $ map (lmap (error <<< AX.printError)) $ AX.request $ AX.defaultRequest
    { method = Left PATCH
    , headers = mkHeaders opts
    , url = i (mkApiUrl opts) "/" label.name
    , content =
        Just
          $ Json
          $ flip encode label
          $ issueLabelCodec <~< CAM.renameField "new_name" "name"
    }

  unless (resp.status == StatusCode 200) do
    throwError $ error $ "Did not receive StatusCode 200 when patching label: " <> label.name

-- | Delete a particular label.
deleteLabel :: IssueLabelRequestOpts -> IssueLabel -> ExceptT Error Aff Unit
deleteLabel opts label = do
  resp <- ExceptT $ map (lmap (error <<< AX.printError)) $ AX.request $ AX.defaultRequest
    { method = Left DELETE
    , headers = mkHeaders opts
    , url = i (mkApiUrl opts) "/" label.name
    }

  unless (resp.status == StatusCode 204) do
    throwError $ error $ "Did not receive StatusCode 204 when deleting label: " <> label.name

-- | Construct the GitHub API base endpoint for issue labels given a repository
-- | owner and nmae.
mkApiUrl :: forall r. { owner :: String, repo :: String | r } -> URL
mkApiUrl { owner, repo } =
  i "https://api.github.com/repos/" owner "/" repo "/labels"

-- | Construct the authentication header for the GitHub API given a personal
-- | access token with repo scope.
mkHeaders :: forall r. { token :: String | r } -> Array RequestHeader
mkHeaders { token } =
  [ RequestHeader "authorization" (i "token " token) ]
