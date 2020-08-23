module Updater.Utils.Dhall
  ( readSpagoFile
  ) where

import Prelude

import Data.Argonaut.Core (Json)
import Data.Argonaut.Parser (jsonParser)
import Data.Codec.Argonaut (printJsonDecodeError)
import Data.Codec.Argonaut as CA
import Data.Codec.Argonaut.Record as CAR
import Data.Either (Either(..))
import Data.Interpolate (i)
import Data.Maybe (Maybe(..), isNothing)
import Data.String as String
import Effect.Aff (Aff)
import Effect.Aff as Aff
import Effect.Class.Console (error)
import Node.ChildProcess as CP
import Node.Encoding (Encoding(..))
import Node.FS.Aff as FS
import Node.Path (FilePath)
import Sunde as S

-- | The contents of the `spago.dhall` file. Projects are required to use Spago.
type SpagoContents = { name :: String }

-- | Read the `spago.dhall` file in the root of the repository and parse its
-- | contents.
readSpagoFile :: Aff SpagoContents
readSpagoFile = do
  expr <- readDhallFile "./spago.dhall"
  json <- runDhallToJson expr

  let
    -- Decode a Spago.dhall file,
    codec = CAR.object "Spago" { name: CA.string }

  case CA.decode codec json of
    Left e -> do
      let e' = printJsonDecodeError e
      error "A valid spago.dhall file is required."
      error e'
      Aff.throwError $ Aff.error e'

    Right v ->
      pure v

-- | Read a file with a .dhall extension as a Dhall expression
readDhallFile :: FilePath -> Aff DhallExpr
readDhallFile filePath = do
  when (isNothing (String.stripSuffix (String.Pattern ".dhall") filePath)) do
    Aff.throwError $ Aff.error do
      i "readDhallFile requires a .dhall extension but got " filePath

  map DhallExpr $ FS.readTextFile UTF8 filePath

-- | The type of a valid Dhall expression
newtype DhallExpr = DhallExpr String

-- | Run the `dhall-json` executable and parse the resulting JSON value. If this
-- | fails, you probably aren't in the Nix shell, which provides that executable.
runDhallToJson :: DhallExpr -> Aff Json
runDhallToJson (DhallExpr expr) = do
  result <- S.spawn
    { cmd: "dhall-to-json", args: [], stdin: Just expr }
    CP.defaultSpawnOptions

  case result.exit of
    CP.Normally 0 -> do
      case jsonParser result.stdout of
        Left e -> do
          error e
          Aff.throwError $ Aff.error e

        Right v ->
          pure v

    _ -> do
      error $ i "Error running dhall-to-json: " (show result.exit)
      error result.stderr
      Aff.throwError $ Aff.error result.stderr
