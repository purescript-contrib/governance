module Updater.Cli
  ( run
  ) where

import Prelude

import Data.Foldable (fold)
import Data.Maybe (optional)
import Effect (Effect)
import Options.Applicative (Parser, (<**>))
import Options.Applicative as OA
import Updater.Command (Command(..))

-- | Parse command line arguments into a valid `Command`, if possible, or
-- | display the help menu or an error if the parser fails.
run :: Effect Command
run = OA.execParser $ OA.info (command <**> OA.helper) $ fold
  [ OA.fullDesc
  , OA.header
      """
      contrib-updater - a utility for managing Contributor libraries
      """
  ]

-- | Parse a `Command` from a set of command line arguments.
command :: Parser Command
command = OA.hsubparser $ fold
  [ OA.command "generate"
      $ OA.info generate
      $ OA.progDesc "Generate template files that follow the Contributors best practices"
  , OA.command "sync-labels"
      $ OA.info syncLabels
      $ OA.progDesc "Sync issue label names, descriptions, and colors with the standard set"
  ]
  where
  generate :: Parser Command
  generate = map Generate ado
    usesJS <- OA.switch $ fold
      [ OA.long "uses-js"
      , OA.help "Whether to generate files for working with JavaScript (linting, etc.)"
      ]

    owner <- optional $ OA.strOption $ fold
      [ OA.long "owner"
      , OA.metavar "STRING"
      , OA.help "The owner of this repository. Default: purescript-contrib"
      ]

    mainBranch <- optional $ OA.strOption $ fold
      [ OA.long "main-branch"
      , OA.metavar "STRING"
      , OA.help "The main branch of this repository. Default: main"
      ]

    displayName <- optional $ OA.strOption $ fold
      [ OA.long "display-name"
      , OA.metavar "STRING"
      , OA.help "How to render this library's name in .md files. Default: '`package-name`'"
      ]

    displayTitle <- optional $ OA.strOption $ fold
      [ OA.long "title"
      , OA.metavar "STRING"
      , OA.help "How to render this library's name in titles. Default: 'package-name'"
      ]

    maintainer <- OA.strOption $ fold
      [ OA.long "maintainer"
      , OA.metavar "STRING"
      , OA.help "The assigned maintainer for this repository (required). Ex: 'thomashoneyman'"
      ]

    in { usesJS, owner, mainBranch, displayName, displayTitle, maintainer }

-- type SyncLabelsOptions =
--   { token :: String
--   , repo :: String
--   , owner :: Maybe String
--   , deleteUnused :: Boolean
--   }
  syncLabels :: Parser Command
  syncLabels = map SyncLabels ado
    token <- OA.strOption $ fold
      [ OA.long "token"
      , OA.metavar "STRING"
      , OA.help "A personal access token for GitHub with at least public_repo scope"
      ]

    repo <- OA.strOption $ fold
      [ OA.long "repo"
      , OA.metavar "STRING"
      , OA.help "The repository to update labels for. Ex: purescript-machines"
      ]

    owner <- optional $ OA.strOption $ fold
      [ OA.long "owner"
      , OA.metavar "STRING"
      , OA.help "The repository owner. Default: purescript-contrib"
      ]

    deleteUnused <- OA.switch $ fold
      [ OA.long "delete-unused"
      , OA.help "Whether to delete issue labels not in the standard Contributors set."
      ]

    in { token, repo, owner, deleteUnused }
