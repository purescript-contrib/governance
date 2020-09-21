module Updater.Generate.Changelog where

import Prelude

import Affjax as AX
import Affjax.ResponseFormat as RF
import Data.Codec (decode)
import Data.Codec.Argonaut (JsonCodec, array, printJsonDecodeError)
import Data.Codec.Argonaut as CA
import Data.Codec.Argonaut.Record as CAR
import Data.Either (Either(..))
import Data.Foldable (fold, for_)
import Data.String.CodeUnits (takeWhile)
import Data.String.Common (joinWith, trim)
import Effect.Aff (Aff, error, throwError)
import Node.Encoding (Encoding(..))
import Node.FS.Aff as FSA

type ReleaseInfo =
  { tag_name :: String
  , html_url :: String
  , body :: String
  , published_at :: String
  }

releaseCodec :: JsonCodec ReleaseInfo
releaseCodec =
  CAR.object "ReleaseInfo" $
    { tag_name: CA.string
    , html_url: CA.string
    , body: CA.string
    , published_at: CA.string
    }

appendReleaseInfoToChangelog :: forall r. { owner :: String, repo :: String | r } -> Aff Unit
appendReleaseInfoToChangelog gh = do
  -- For example
  -- https://api.github.com/repos/purescript-contrib/purescript-http-methods/releases
  let url = "https://api.github.com/repos/" <> gh.owner <> "/" <> gh.repo <> "/releases"

  result <- AX.get RF.json url
  case result of
    Left err -> do
      throwError (error $ AX.printError err)
    Right { body } ->
      case decode (array releaseCodec) body of
        Left e -> do
          throwError $ error $ printJsonDecodeError e
        Right releases -> do
          for_ releases \rec -> do
            let dateWithoutTimeZone = takeWhile (_ /= 'T') rec.published_at
            FSA.appendTextFile UTF8 "./CHANGELOG.md" $ joinWith "\n"
              [ "## [" <> rec.tag_name <> "](" <> rec.html_url <> ") - " <> dateWithoutTimeZone
              , ""
              , trim rec.body
              , ""
              , ""
              ]
