module Updater.Variable where

import Data.Interpolate (i)
import Data.String as String
import Data.Symbol (class IsSymbol, SProxy, reflectSymbol)
import Heterogeneous.Folding (class FoldingWithIndex, class HFoldlWithIndex, hfoldlWithIndex)

-- | The variables supported when generating templates. Source files mult use
-- | the syntax '{{variableName}}'.
-- |
-- | See the templates README for more details on these variables.
type Variables =
  { owner :: String
  , mainBranch :: String
  , packageName :: String
  , displayName :: String
  , displayTitle :: String
  , maintainer :: String
  }

-- | Format a variable name according to the syntax used in the templates:
-- |
-- | format "variable" == "{{variable}}"
format :: String -> String
format str = i "{{" str "}}"

data ReplaceVariables = ReplaceVariables

instance replaceVariables' ::
  IsSymbol sym =>
  FoldingWithIndex ReplaceVariables (SProxy sym) String String String where
  foldingWithIndex ReplaceVariables key acc val = do
    let
      key' :: String
      key' = reflectSymbol key

    replace key' val acc
    where
    -- | TODO: This find/replace method could probably be done better via `parsing`
    replace k v = String.replaceAll (String.Pattern (format k)) (String.Replacement v)

-- | Given a file's contents and a record of variables to replace, replaces all
-- | variables in those contents.
replaceVariables
  :: HFoldlWithIndex ReplaceVariables String Variables String
  => String
  -> Variables
  -> String
replaceVariables = hfoldlWithIndex ReplaceVariables
