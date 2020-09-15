module Updater.SyncLabels.IssueLabel where

import Data.Argonaut.Core (Json, fromString, isString)
import Data.Codec ((<~<))
import Data.Codec.Argonaut as CA
import Data.Codec.Argonaut.Migration as CAM
import Data.Codec.Argonaut.Record as CAR
import Data.Maybe (Maybe(..))

-- | A GitHub issue label consisting of three parts:
-- |
-- | `name` is the name of the label, which can contain emojis and spaces
-- | `description` is the description of the label, displayed in help contents
-- | `color` is a hexadecimal value without the leading '#' representing a color
type IssueLabel =
  { name :: String
  , description :: String
  , color :: String
  }

issueLabelCodec :: CA.JsonCodec IssueLabel
issueLabelCodec =
  CAR.object "IssueLabel"
    { name: CA.string
    , description: CA.string
    , color: CA.string
    } <~< CAM.addDefaultOrUpdateField "description" fixNull
  where
  fixNull :: Maybe Json -> Json
  fixNull = case _ of
    Just v | isString v -> v
    _ -> fromString ""

-- | The full set of issue labels supported by Contributor libraries.
labels :: Array IssueLabel
labels =
  [ { name: "breaking change"
    , description: "Change will require a major version bump"
    , color: "e99695"
    }
  , { name: "bug"
    , description: "Something isn't working"
    , color: "d73a4a"
    }
  , { name: "document me"
    , description: "Improvements or additions to documentation"
    , color: "0075ca"
    }
  , { name: "enhancement"
    , description: "New feature or request"
    , color: "a6e1ea"
    }
  , { name: "good first issue"
    , description: "Good for newcomers"
    , color: "7057ff"
    }
  , { name: "help wanted"
    , description: "Extra attention is needed"
    , color: "006b75"
    }
  , { name: "question"
    , description: "Question that needs an answer"
    , color: "fbca04"
    }
  ]
