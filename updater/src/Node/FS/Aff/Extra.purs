module Node.FS.Aff.Extra
  ( writeTextFile
  , mkdir
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Function.Uncurried (Fn2, Fn3, runFn3)
import Data.Nullable (Nullable)
import Effect (Effect)
import Effect.Aff (Aff, makeAff, nonCanceler)
import Effect.Exception (Error)
import Node.Encoding as Encoding
import Node.FS.Aff as FS
import Node.FS.Async (Callback)
import Node.FS.Internal (mkEffect, unsafeRequireFS)
import Node.Path (FilePath)
import Node.Path as Path

-- | A version of Node.FS.Aff.writeTextFile which recursively creates directories
-- | along the way to the file's target path in the file system if they do not
-- | already exist.
writeTextFile :: FilePath -> String -> Aff Unit
writeTextFile file contents = do
  let
    targetDirectory = Path.dirname file

  exists <- FS.exists targetDirectory

  unless exists do
    mkdir targetDirectory

  FS.writeTextFile Encoding.UTF8 file contents

-- | A version of Node.FS.Aff.mkdir which recursively creates directories along
-- | a file path.
mkdir :: FilePath -> Aff Unit
mkdir = toAff1 \file cb -> mkEffect \_ -> runFn3 fs.mkdir file { recursive: true } (handleCallback cb)

toAff :: forall a. (Callback a -> Effect Unit) -> Aff a
toAff p = makeAff \k -> p k $> nonCanceler

toAff1 :: forall a x. (x -> Callback a -> Effect Unit) -> x -> Aff a
toAff1 f a = toAff (f a)

type JSCallback a = Fn2 (Nullable Error) Unit a

foreign import handleCallbackImpl
  :: forall a. Fn3 (Error -> Either Error a) (a -> Either Error a) (Callback a) (JSCallback a)

handleCallback :: forall a. (Callback a) -> JSCallback a
handleCallback cb = runFn3 handleCallbackImpl Left Right cb

fs :: { mkdir :: Fn3 FilePath { recursive :: Boolean } (JSCallback Unit) Unit }
fs = unsafeRequireFS
