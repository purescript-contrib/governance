module Updater.SyncLabels.Request
  ( IssueLabelRequestOpts(..)
  , Sifted(..)
  , getLabels
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
import Data.Array as Array
import Data.Bifunctor (lmap)
import Data.Codec (encode, (<~<))
import Data.Codec as Codec
import Data.Codec.Argonaut as CA
import Data.Codec.Argonaut.Migration as CAM
import Data.Either (Either(..))
import Data.Foldable (foldl)
import Data.HTTP.Method (Method(..))
import Data.Interpolate (i)
import Data.Maybe (Maybe(..), isNothing)
import Data.Symbol (SProxy(..))
import Effect.Aff (Aff, Error, error)
import Record as Record
import Updater.SyncLabels.IssueLabel (IssueLabel, issueLabelCodec)
import Updater.SyncLabels.IssueLabel as IssueLabel
import Updater.SyncLabels.IssueLabel as Issuelabel

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

-- | Fetch all labels for the repository.
getLabels :: IssueLabelRequestOpts -> ExceptT Error Aff Sifted
getLabels opts = do
  resp <- ExceptT $ map (lmap (error <<< AX.printError)) $ AX.request $ AX.defaultRequest
    { headers = mkHeaders opts
    , responseFormat = AXRF.json
    , url = mkApiUrl opts
    }

  unless (resp.status == StatusCode 200) do
    throwError $ error "Did not receive StatusCode 200 when getting labels."

  let decoded = Codec.decode (CA.array issueLabelCodec) resp.body

  labels <- ExceptT $ pure $ lmap (error <<< CA.printJsonDecodeError) decoded
  pure $ sift labels

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
mkHeaders { token }=
  [ RequestHeader "authorization" (i "token " token) ]
