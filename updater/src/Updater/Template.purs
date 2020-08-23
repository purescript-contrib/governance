module Updater.Template
  ( runBaseTemplates
  , runJsTemplates
  ) where

import Prelude

import Control.Alternative ((<|>))
import Data.Foldable (traverse_)
import Data.Interpolate (i)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Node.Encoding (Encoding(..))
import Node.FS.Aff as FS
import Node.FS.Aff.Extra as FS.Extra
import Node.Globals (__dirname)
import Node.Path (FilePath, resolve)
import Node.Process (cwd)
import Updater.Variable (Variables, replaceVariables)

-- | Generate the standard templates for a PureScript Contributor project into
-- | the correct file locations, backing up any existing files that would
-- | conflict (you will need to manually reconcile those files).
runBaseTemplates :: Variables -> Aff Unit
runBaseTemplates = runTemplates baseTemplates
  where
  baseTemplates :: Array Template
  baseTemplates =
    [ gitignore
    , editorconfig
    , repoReadme
    , docsReadme
    , docsChangelog
    , githubIssueBugReport
    , githubIssueChangeRequest
    , githubWorkflowCI
    , githubContributing
    , githubPullRequest
    , githubStale
    ]

-- | Generate the templates for Contributor projects that rely on JS files (for
-- | example, via the FFI) into the correct file locations, backing up any
-- | existing files that would conflict (you will need to manually reconcile
-- | those files).
runJsTemplates :: Variables -> Aff Unit
runJsTemplates = runTemplates jsTemplates
  where
  jsTemplates :: Array Template
  jsTemplates =
    [ jsGithubWorkflowCI
    , jsEslintrc
    , jsPackageJson
    ]

-- | Run a selection of templates.
runTemplates :: Array Template -> Variables -> Aff Unit
runTemplates templates variables = do
  backupsDir <- getBackupsDirectory
  templatesDir <- liftEffect $ resolve [ __dirname, ".." ] "templates"
  let runTemplateOptions = { backupsDir, templatesDir, variables }
  traverse_ (runTemplate runTemplateOptions) templates

type RunTemplateOptions =
  { templatesDir :: FilePath
  , backupsDir :: FilePath
  , variables :: Variables
  }

-- | Run an individual template. This consists of:
-- |
-- | 1. Backing up any existing files that would be overwritten
-- | 2. Reading the contents of the template file
-- | 3. Updating those contents by replacing any dynamic content (variables)
-- | 4. Writing the new contents into the correct directory location
runTemplate :: RunTemplateOptions -> Template -> Aff Unit
runTemplate opts (Template { from, to }) = do
  exists <- FS.exists to
  when exists do
    backupFile { relativeFilePath: to, backupsDir: opts.backupsDir }

  templatePath <- liftEffect $ resolve [ opts.templatesDir ] from
  templateContents <- FS.readTextFile UTF8 templatePath

  FS.Extra.writeTextFile to (replaceVariables templateContents opts.variables)

-- | The source and destination for a given template. Templates will be copied
-- | from their source to destination, with text replacement applied along the way.
newtype Template = Template { from :: FilePath, to :: FilePath }

-- | Backs up a file by copying it into the backups directory
backupFile :: { relativeFilePath :: FilePath, backupsDir :: FilePath } -> Aff Unit
backupFile { relativeFilePath, backupsDir } = do
  contents <- FS.readTextFile UTF8 relativeFilePath
  newPath <- liftEffect $ resolve [ backupsDir ] relativeFilePath
  FS.Extra.writeTextFile newPath contents
  FS.unlink relativeFilePath

-- | The directory name where conflicting files will be stored when writing new
-- | templates. Any existing files which a template would overwrite will be
-- | copied into this directory.
backupsDirname :: String
backupsDirname = "backups"

-- | Creates the backup directory if it does not already exist and returns the
-- | full path to the created directory.
getBackupsDirectory :: Aff FilePath
getBackupsDirectory = do
  current <- liftEffect cwd
  log $ i "Creating directory '" backupsDirname "' for conflicting files."
  path <- liftEffect $ resolve [ current ] backupsDirname
  FS.mkdir path <|> pure unit
  pure path

gitignore :: Template
gitignore = Template { from: "base/.gitignore", to: ".gitignore" }

editorconfig :: Template
editorconfig = Template { from: "base/.editorconfig", to: ".editorconfig" }

repoReadme :: Template
repoReadme = Template { from: "base/README.md", to: "README.md" }

docsReadme :: Template
docsReadme = Template { from: "base/docs/README.md", to: "docs/README.md" }

docsChangelog :: Template
docsChangelog = Template
  { from: "base/docs/CHANGELOG.md"
  , to: "docs/CHANGELOG.md"
  }

githubIssueBugReport :: Template
githubIssueBugReport = Template
  { from: "base/.github/ISSUE_TEMPLATE/bug-report.md"
  , to: ".github/ISSUE_TEMPLATE/bug-report.md"
  }

githubIssueChangeRequest :: Template
githubIssueChangeRequest = Template
  { from: "base/.github/ISSUE_TEMPLATE/change-request.md"
  , to: ".github/ISSUE_TEMPLATE/change-request.md"
  }

githubWorkflowCI :: Template
githubWorkflowCI = Template
  { from: "base/.github/workflows/ci.yml"
  , to: ".github/workflows/ci.yml"
  }

githubContributing :: Template
githubContributing = Template
  { from: "base/.github/CONTRIBUTING.md"
  , to: ".github/CONTRIBUTING.md"
  }

githubPullRequest :: Template
githubPullRequest = Template
  { from: "base/.github/PULL_REQUEST_TEMPLATE.md"
  , to: ".github/PULL_REQUEST_TEMPLATE.md"
  }

githubStale :: Template
githubStale = Template
  { from: "base/.github/stale.yml"
  , to: ".github/stale.yml"
  }

jsGithubWorkflowCI :: Template
jsGithubWorkflowCI = Template
  { from: "js/.github/workflows/ci.yml"
  , to: ".github/workflows/ci.yml"
  }

jsEslintrc :: Template
jsEslintrc = Template { from: "js/.eslintrc.json", to: ".eslintrc.json" }

jsPackageJson :: Template
jsPackageJson = Template { from: "js/package.json", to: "package.json" }
