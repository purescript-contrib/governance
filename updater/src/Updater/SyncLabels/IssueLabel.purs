module Updater.SyncLabels.IssueLabel where

import Data.Codec.Argonaut as CA
import Data.Codec.Argonaut.Record as CAR

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
    }

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
    -- This label needs to be treated with care because it is also used in the
    -- 'Stale' GitHub Action. If it is updated here make sure to update the
    -- template as well.
  , { name: "stale"
    , description: "This has become stale and will be closed without further activity"
    , color: "ffffff"
    }
  ]
