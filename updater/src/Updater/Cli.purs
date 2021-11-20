module Updater.Cli
  ( run
  ) where

import Prelude

import Data.Foldable (fold)
import Data.List.NonEmpty (fromFoldable)
import Data.Maybe (optional)
import Data.String.Pattern (Pattern(..))
import Effect (Effect)
import Options.Applicative (Parser, (<**>))
import Options.Applicative as OA
import Updater.Command (Command(..))
import Updater.Utils.Options (multiString)

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
  , OA.command "list-labels"
      $ OA.info listLabels
      $ OA.progDesc "List all labels across all core, contrib, web, and node libraries."
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

    repo <- optional $ OA.strOption $ fold
      [ OA.long "repo"
      , OA.metavar "STRING"
      , OA.help "The repository to use for updating the changelog. Ex: purescript-machines"
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
      [ OA.long "display-title"
      , OA.metavar "STRING"
      , OA.help "How to render this library's name in .md file titles. Default: 'Package Name'"
      ]

    maintainers <- OA.some $ OA.strOption $ fold
      [ OA.long "maintainer"
      , OA.metavar "STRING"
      , OA.help "The assigned maintainer(s) for this repository (required). Ex: 'thomashoneyman'"
      ]

    files <- (fromFoldable =<< _) <$>
      ( optional $ OA.option (multiString $ Pattern ",") $ fold
          [ OA.long "files"
          , OA.metavar "file1,..,fileN"
          , OA.help "Generate only these files from the template. Uses the JS version when --uses-js is true. Ex: 'README.md,docs/README.md'"
          ]
      )

    in { usesJS, owner, repo, mainBranch, displayName, displayTitle, maintainers, files }

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

  listLabels :: Parser Command
  listLabels = map ListLabels ado
    token <- OA.strOption $ fold
      [ OA.long "token"
      , OA.metavar "STRING"
      , OA.help "A personal access token for GitHub with at least public_repo scope"
      ]
    in { token }
