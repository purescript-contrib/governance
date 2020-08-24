module Updater.SyncLabels.Request
  ( IssueLabelRequestOpts(..)
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
import Data.Argonaut.Core (Json)
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
import Effect.Aff (Aff)
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
  , accept :: Array IssueLabel
  }

-- | Fetch all labels for the repository.
getLabels :: IssueLabelRequestOpts -> Aff (Either String Sifted)
getLabels opts =
  map (map sift <<< decodeResponse (CA.array issueLabelCodec)) $ AX.request $ AX.defaultRequest
    { headers = mkHeaders opts
    , responseFormat = AXRF.json
    , url = mkApiUrl opts
    }
  where
  -- don't code late at night!
  sift :: Array IssueLabel -> Sifted
  sift = shouldCreate <<< foldl fn { create: [], update: [], delete: [], accept: [] }
    where
    -- Decide what contrib labels need to be patched or created
    fn acc apiLabel =
      -- this label is already correct, so do nothing
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
    shouldCreate args = args
      { create =
          Issuelabel.labels # Array.filter \{ name } ->
            isNothing (Array.find (eq name <<< _.name) args.update)
              && isNothing (Array.find (eq name <<< _.name) args.accept)
      }

-- | Create a new label. Note: if updating a label, use `patchLabel` instead.
createLabel :: IssueLabelRequestOpts -> IssueLabel -> Aff Boolean
createLabel opts label =
  map (checkRequestSucceeded (StatusCode 201)) $ AX.request $ AX.defaultRequest
    { method = Left POST
    , headers = mkHeaders opts
    , url = mkApiUrl opts
    , content = Just $ Json $ encode issueLabelCodec label
    }

-- | Update a label which already exists to a new value.
-- |
-- | The patch endpoint for labels uses `new_name` instead of `name` for the
-- | label name, so we need to migrate our codec before making the request.
-- |
-- | See: https://developer.github.com/v3/issues/labels/#update-a-label
patchLabel :: IssueLabelRequestOpts -> IssueLabel -> Aff Boolean
patchLabel opts label =
  map (checkRequestSucceeded (StatusCode 200)) $ AX.request $ AX.defaultRequest
    { method = Left PATCH
    , headers = mkHeaders opts
    , url = i (mkApiUrl opts) "/" label.name
    , content =
        Just
          $ Json
          $ flip encode label
          $ issueLabelCodec <~< CAM.renameField "new_name" "name"
    }

-- | Delete a particular label.
deleteLabel :: IssueLabelRequestOpts -> IssueLabel -> Aff Boolean
deleteLabel opts label =
  map (checkRequestSucceeded (StatusCode 204)) $ AX.request $ AX.defaultRequest
    { method = Left DELETE
    , headers = mkHeaders opts
    , url = i (mkApiUrl opts) "/" label.name
    }

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

-- | Decode a response, flattening all errors into a single `String` value in
-- | the case of failure.
decodeResponse
  :: forall a
   . CA.JsonCodec a
  -> Either AX.Error (AX.Response Json)
  -> Either String a
decodeResponse codec api = do
  { body } <- lmap AX.printError api
  lmap CA.printJsonDecodeError $ Codec.decode codec body

-- | Check whether the request completed successfully by verifying the correct
-- | status code was returned. Note: not all requestst return a 200 for success.
checkRequestSucceeded
  :: StatusCode
  -> Either AX.Error (AX.Response Unit)
  -> Boolean
checkRequestSucceeded code = case _ of
  Right { status } | status == code -> true
  _ -> false
