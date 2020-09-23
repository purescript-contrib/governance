module Updater.Generate.Changelog where

import Prelude

import Affjax as AX
import Affjax.ResponseFormat as RF
import Affjax.StatusCode (StatusCode(..))
import Data.Array (filter, null)
import Data.Codec (decode)
import Data.Codec.Argonaut (JsonCodec, array, printJsonDecodeError)
import Data.Codec.Argonaut as CA
import Data.Codec.Argonaut.Record as CAR
import Data.Either (Either(..))
import Data.Foldable (foldl)
import Data.Maybe (Maybe(..))
import Data.Monoid (power)
import Data.String (Pattern(..))
import Data.String.CodeUnits (drop, indexOf, length, takeWhile)
import Data.String.Common (joinWith, trim)
import Data.String.Utils (lines)
import Effect.Aff (Aff, error, throwError)
import Effect.Class.Console as Console
import Node.Encoding (Encoding(..))
import Node.FS.Aff as FSA

type ReleaseInfo =
  { tag_name :: String
  , html_url :: String
  , body :: String
  , published_at :: String
  , draft :: Boolean
  }

releaseCodec :: JsonCodec ReleaseInfo
releaseCodec =
  CAR.object "ReleaseInfo" $
    { tag_name: CA.string
    , html_url: CA.string
    , body: CA.string
    , published_at: CA.string
    , draft: CA.boolean
    }

appendReleaseInfoToChangelog :: forall r. { owner :: String, repo :: String | r } -> Aff Unit
appendReleaseInfoToChangelog gh = do
  releases <- recursivelyFetchReleases [] 1 gh
  let
    realReleases = filter (\r -> r.draft == false) releases
    appendContent = foldl addReleaseInfo "" realReleases
  FSA.appendTextFile UTF8 "./CHANGELOG.md" $ joinWith "\n"
    [ ""
    , appendContent
    ]
  where
    addReleaseInfo :: String -> ReleaseInfo -> String
    addReleaseInfo acc rec =
      let
        dateWithoutTimeZone = takeWhile (_ /= 'T') rec.published_at
        bodyWithFixedHeaders = fixHeaders $ trim rec.body
      in acc <> joinWith "\n"
        [ "## [" <> rec.tag_name <> "](" <> rec.html_url <> ") - " <> dateWithoutTimeZone
        , ""
        , bodyWithFixedHeaders
        , ""
        , ""
        ]

    fixHeaders :: String -> String
    fixHeaders s =
      let
        replaceAllHeaders =
          replaceHeaderWithBoldedText 5
            >>> replaceHeaderWithBoldedText 4
            >>> replaceHeaderWithBoldedText 3
            >>> replaceHeaderWithBoldedText 2
            >>> replaceHeaderWithBoldedText 1
      in
        joinWith "\n" $ map replaceAllHeaders (lines s)

    replaceHeaderWithBoldedText :: Int -> String -> String
    replaceHeaderWithBoldedText level line =
      let
        prefix = (power "#" level) <> " "
      in case indexOf (Pattern prefix) line of
        Nothing -> line
        Just _ -> "**" <> drop (length prefix) line <> "**"

recursivelyFetchReleases :: forall r. Array ReleaseInfo -> Int -> { owner :: String, repo :: String | r } -> Aff (Array ReleaseInfo)
recursivelyFetchReleases accumulator page gh = do
  pageNResult <- fetchNextPageOfReleases page gh
  case pageNResult of
    Nothing -> pure accumulator
    Just arr -> recursivelyFetchReleases (accumulator <> arr) (page + 1) gh

fetchNextPageOfReleases :: forall r. Int -> { owner :: String, repo :: String | r } -> Aff (Maybe (Array ReleaseInfo))
fetchNextPageOfReleases page gh = do
  -- For example
  -- https://api.github.com/repos/purescript-contrib/purescript-http-methods/releases
  let url = "https://api.github.com/repos/" <> gh.owner <> "/" <> gh.repo <> "/releases?per_page=100&page=" <> show page

  result <- AX.get RF.json url
  case result of
    Left err -> do
      throwError (error $ AX.printError err)
    Right { body, status } | status == (StatusCode 200) ->
      case decode (array releaseCodec) body of
        Left e -> do
          Console.error "Failed to decode releases response"
          throwError $ error $ printJsonDecodeError e
        Right releases | null releases ->
          pure Nothing
        Right releases -> do
          pure $ Just releases
    Right { status: StatusCode status } ->
      throwError $ error $ "Failed to fetch releases. Status " <> show status
