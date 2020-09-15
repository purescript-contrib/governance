module Updater.Generate.Template
  ( Variables(..)
  , runBaseTemplates
  , runJsTemplates
  ) where

import Prelude

import Control.Alternative ((<|>))
import Data.Foldable (traverse_)
import Data.Interpolate (i)
import Data.List.NonEmpty as NEL
import Data.List.Types (NonEmptyList)
import Data.String as String
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Node.Encoding (Encoding(..))
import Node.FS.Aff as FS
import Node.FS.Aff.Extra as FS.Extra
import Node.Globals (__dirname)
import Node.Path (FilePath, resolve)
import Node.Process (cwd)

-- | The variables supported when generating templates. See the documentation
-- | for more details on these variables and correct syntax.
type Variables =
  { owner :: String
  , mainBranch :: String
  , packageName :: String
  , displayName :: String
  , displayTitle :: String
  , maintainers :: NonEmptyList String
  }

-- | Replace each variable in the provided file contents, returning the updated
-- | file to be written.
replaceVariables :: Variables -> String -> String
replaceVariables vars contents = do
  contents
    # replaceOne "owner" vars.owner
    # replaceOne "mainBranch" vars.mainBranch
    # replaceOne "packageName" vars.packageName
    # replaceOne "displayName" vars.displayName
    # replaceOne "displayTitle" vars.displayTitle
    # replaceMany "maintainers" vars.maintainers
  where
  format str = i "{{" str "}}"

  -- Variables which admit only one value should be replaced inline:
  --
  --   "This package is {{packageName}} in the registry"
  --   where packageName = my-package becomes
  --   "This package is my-package in the registry"
  replaceOne k v =
    String.replaceAll
      (String.Pattern (format k))
      (String.Replacement v)

  -- Variables which admit many values should be replaced multiple times with
  -- newlines in between:
  --
  --   "{{maintainers}}"
  --   where maintainers = [ "a", "b" ] becomes
  --   "a\nb"
  replaceMany k vs =
    String.replaceAll
      (String.Pattern (format k))
      (String.Replacement (String.joinWith "\n" (NEL.toUnfoldable vs)))

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
    , githubIssueConfig
    , githubWorkflowCI
    , githubContributing
    , githubPullRequest
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
    , jsGitignore
    ]

-- | The directory name where conflicting files will be stored when writing new
-- | templates. Any existing files which a template would overwrite will be
-- | copied into this directory.
backupsDirname :: String
backupsDirname = "backups"

-- | Run a selection of templates.
runTemplates :: Array Template -> Variables -> Aff Unit
runTemplates templates variables = do
  backupsDir <- getBackupsDirectory
  templatesDir <- liftEffect $ resolve [ __dirname, ".." ] "templates"
  let runTemplateOptions = { backupsDir, templatesDir, variables }
  traverse_ (runTemplate runTemplateOptions) templates
  where
  getBackupsDirectory :: Aff FilePath
  getBackupsDirectory = do
    current <- liftEffect cwd
    log $ i "Creating directory '" backupsDirname "' for conflicting files."
    path <- liftEffect $ resolve [ current ] backupsDirname
    FS.mkdir path <|> pure unit
    pure path

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
  templatePath <- liftEffect $ resolve [ opts.templatesDir ] from
  templateContents <- FS.readTextFile UTF8 templatePath

  exists <- FS.exists to
  when exists do
    existingContents <- FS.readTextFile UTF8 to
    -- Only back up a conflicting file if it differs from the existing file.
    unless (templateContents == existingContents) do
      backupsPath <- liftEffect $ resolve [ opts.backupsDir ] to
      FS.Extra.writeTextFile backupsPath existingContents
      FS.unlink to

  FS.Extra.writeTextFile to (replaceVariables opts.variables templateContents)

-- | The source and destination for a given template. Templates will be copied
-- | from their source to destination, with text replacement applied along the way.
newtype Template = Template { from :: FilePath, to :: FilePath }

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

githubIssueConfig :: Template
githubIssueConfig = Template
  { from: "base/.github/ISSUE_TEMPLATE/config.yml"
  , to: ".github/ISSUE_TEMPLATE/config.yml"
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

jsGithubWorkflowCI :: Template
jsGithubWorkflowCI = Template
  { from: "js/.github/workflows/ci.yml"
  , to: ".github/workflows/ci.yml"
  }

jsEslintrc :: Template
jsEslintrc = Template { from: "js/.eslintrc.json", to: ".eslintrc.json" }

jsPackageJson :: Template
jsPackageJson = Template { from: "js/package.json", to: "package.json" }

jsGitignore :: Template
jsGitignore = Template { from: "js/.gitignore", to: ".gitignore" }
