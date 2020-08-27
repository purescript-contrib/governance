module Updater.Generate.Template
  ( Variables(..)
  , runBaseTemplates
  , runJsTemplates
  ) where

import Prelude

import Control.Alternative ((<|>))
import Data.Foldable (traverse_)
import Data.Interpolate (i)
import Data.String as String
import Data.Symbol (class IsSymbol, SProxy, reflectSymbol)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Heterogeneous.Folding (class FoldingWithIndex, class HFoldlWithIndex, hfoldlWithIndex)
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
  , maintainer :: String
  }

data ReplaceVariables = ReplaceVariables

instance replaceVariables' ::
  IsSymbol sym =>
  FoldingWithIndex ReplaceVariables (SProxy sym) String String String where
  foldingWithIndex ReplaceVariables key acc val = do
    replace (reflectSymbol key) val acc
    where
    -- | TODO: This find/replace method could probably be done better via `parsing`
    replace k v = String.replaceAll (String.Pattern (format k)) (String.Replacement v)
    format str = i "{{" str "}}"

-- | Given a file's contents and a record of variables to replace, replaces all
-- | variables in those contents.
replaceVariables
  :: HFoldlWithIndex ReplaceVariables String Variables String
  => String
  -> Variables
  -> String
replaceVariables = hfoldlWithIndex ReplaceVariables

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
    , githubWorkflowStale
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

  FS.Extra.writeTextFile to (replaceVariables templateContents opts.variables)

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

githubWorkflowCI :: Template
githubWorkflowCI = Template
  { from: "base/.github/workflows/ci.yml"
  , to: ".github/workflows/ci.yml"
  }

githubWorkflowStale :: Template
githubWorkflowStale = Template
  { from: "base/.github/workflows/stale.yml"
  , to: ".github/workflows/stale.yml"
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
