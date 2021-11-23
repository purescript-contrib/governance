module Updater.SyncLabels.IssueLabel where

import Data.Argonaut.Core (Json, fromString, isString)
import Data.Codec ((<~<))
import Data.Codec.Argonaut as CA
import Data.Codec.Argonaut.Migration as CAM
import Data.Codec.Argonaut.Record as CAR
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Set (Set)
import Data.Set as Set
import Data.String (drop)
import Data.Tuple.Nested ((/\))

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

-- | Maps a label from an old name to a new one
renameLabelMapping :: Map String IssueLabel
renameLabelMapping =
  Map.fromFoldable
    [ "breaking change" /\ breakingChangeLabel
    , "bug" /\ bugLabel
    , "document me" /\ documentationLabel
    , "documentation" /\ documentationLabel
    , "enhancement" /\ enhancementLabel
    , "fix before 0.14" /\ fixBefore0_14Label
    , "good first issue" /\ goodFirstIssueLabel
    , "merge before 0.14" /\ mergeBefore0_14Label
    , "question" /\ questionLabel
    , "wontfix" /\ wontfixLabel
    ]

-- | The set of labels to delete
deleteLabels :: Set String
deleteLabels = Set.fromFoldable
  [ "help wanted"
  , "invalid"
  , "reference"
  , "stale"
  ]

-- | The full set of issue labels supported by Contributor libraries.
labels :: Array IssueLabel
labels =
  [ breakingChangeLabel
  , bugLabel
  , regressionLabel
  , enhancementLabel
  , documentationLabel
  , abandonedLabel
  , blockedLabel
  , needsMoreInfoLabel
  , needsReviewLabel
  , needsApprovalLabel
  , goodFirstIssueLabel
  , duplicateLabel
  , wontfixLabel
  , houseKeepingLabel
  , questionLabel
  , mergeBefore0_14Label
  , fixBefore0_14Label
  ]

dropColorHashSym :: IssueLabel -> IssueLabel
dropColorHashSym r = r { color = drop 1 r.color }

breakingChangeLabel :: IssueLabel
breakingChangeLabel = dropColorHashSym
  { name: "type: breaking change"
  , color: "#e99695"
  , description: "A change that requires a major version bump"
  }

bugLabel :: IssueLabel
bugLabel = dropColorHashSym
  { name: "type: bug"
  , color: "#d73a4a"
  , description: "Something that should function correctly isn't"
  }

regressionLabel :: IssueLabel
regressionLabel = dropColorHashSym
  { name: "type: regression"
  , color: "#e4d0f0"
  , description: "Something that worked previously no longer works"
  }

enhancementLabel :: IssueLabel
enhancementLabel = dropColorHashSym
  { name: "type: enhancement"
  , color: "#a6e1ea"
  , description: "A new feature or addition"
  }

documentationLabel :: IssueLabel
documentationLabel = dropColorHashSym
  { name: "type: documentation"
  , color: "#0000ff"
  , description: "Improvements or additions to documentation"
  }

abandonedLabel :: IssueLabel
abandonedLabel = dropColorHashSym
  { name: "status: abandoned"
  , color: "#000000"
  , description: "This PR is no longer being worked on. Another can use it as a base for continuing the work."
  }

blockedLabel :: IssueLabel
blockedLabel = dropColorHashSym
  { name: "status: blocked"
  , color: "#c09000"
  , description: "This issue or PR is blocked by something and cannot make progress."
  }

needsMoreInfoLabel :: IssueLabel
needsMoreInfoLabel = dropColorHashSym
  { name: "status: needs more info"
  , color: "#e0a000"
  , description: "This issue needs more info before any action can be done."
  }

needsReviewLabel :: IssueLabel
needsReviewLabel = dropColorHashSym
  { name: "status: needs review"
  , color: "#006000"
  , description: "This PR needs a review."
  }

needsApprovalLabel :: IssueLabel
needsApprovalLabel = dropColorHashSym
  { name: "status: needs approval"
  , color: "#00b000"
  , description: "This PR needs approval before it can be merged."
  }

goodFirstIssueLabel :: IssueLabel
goodFirstIssueLabel = dropColorHashSym
  { name: "good first issue"
  , color: "#7007ff"
  , description: "First-time contributors who are looking to help should work on these issues."
  }

duplicateLabel :: IssueLabel
duplicateLabel = dropColorHashSym
  { name: "duplicate"
  , color: "#cccccc"
  , description: "This issue or pull request already exists."
  }

wontfixLabel :: IssueLabel
wontfixLabel = dropColorHashSym
  { name: "status: wontfix"
  , color: "#ffffff"
  , description: "The maintainers of this library don't think the issue is actually a problem."
  }

houseKeepingLabel :: IssueLabel
houseKeepingLabel = dropColorHashSym
  { name: "type: housekeeping"
  , color: "#ebea04"
  , description: "Repo-related things (e.g. fixing CI) that need to be done."
  }

questionLabel :: IssueLabel
questionLabel = dropColorHashSym
  { name: "type: question"
  , color: "#fbca04"
  , description: ""
  }

mergeBefore0_14Label :: IssueLabel
mergeBefore0_14Label = dropColorHashSym
  { name: "merge before 0.14"
  , color: "#404040"
  , description: "A reminder to merge this PR before we release PureScript v0.14.0"
  }

fixBefore0_14Label :: IssueLabel
fixBefore0_14Label = dropColorHashSym
  { name: "fix before 0.14"
  , color: "#404040"
  , description: "A reminder to address this issue before we release PureScript v0.14.0"
  }
