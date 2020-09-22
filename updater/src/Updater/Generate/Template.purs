module Updater.Generate.Template
  ( Variables(..)
  , TemplateSource
  , runTemplates
  , validateFiles
  , allTemplates
  ) where

import Prelude

import Control.Alternative ((<|>))
import Data.Array (filter, fromFoldable)
import Data.Either (Either(..))
import Data.Foldable (find, traverse_)
import Data.Interpolate (i)
import Data.List.NonEmpty as NEL
import Data.List.Types (NonEmptyList)
import Data.Maybe (Maybe(..))
import Data.String as String
import Data.Traversable (traverse)
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
  , usesJS :: Boolean
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

allTemplates :: Array TemplateSource
allTemplates =
  [ gitignore
  , repoReadme
  , docsReadme
  , docsChangelog
  , githubIssueBugReport
  , githubIssueChangeRequest
  , githubIssueConfig
  , githubContributing
  , githubPullRequest
  , editorconfig
  , githubWorkflowCI
  , jsEslintrc
  , jsPackageJson
  ]

-- | The directory name where conflicting files will be stored when writing new
-- | templates. Any existing files which a template would overwrite will be
-- | copied into this directory.
backupsDirname :: String
backupsDirname = "backups"

-- | Generate the templates for a PureScript Contributor project into
-- | the correct file locations, backing up any existing files that would
-- | conflict (you will need to manually reconcile those files).
runTemplates :: Variables -> Array TemplateSource -> Aff Unit
runTemplates variables templateSources = do
  backupsDir <- getBackupsDirectory
  templatesDir <- liftEffect $ resolve [ __dirname, ".." ] "templates"
  let runTemplateOptions = { backupsDir, templatesDir, variables }
      templates = filterByType variables.usesJS templateSources
                    # map (templateFromSource variables.usesJS)
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

-- | Keep JS only templates when using JS.
filterByType :: Boolean -> Array TemplateSource -> Array TemplateSource
filterByType true templates = templates
filterByType false templates = filter (not <<< (JS == _) <<< sourceType) templates

-- | Define the source and destination of a given template by its type and
-- | source path. Common templates default to _base_ unless using JS.
templateFromSource :: Boolean -> TemplateSource -> Template
templateFromSource true (TemplateSource Common path) =
  Template { from: "js/" <> path, to: path }
templateFromSource false (TemplateSource Common path) =
  Template { from: "base/" <> path, to: path }
templateFromSource _ (TemplateSource JS path) =
  Template { from: "js/" <> path, to: path }
templateFromSource _ (TemplateSource Base path) =
  Template { from: "base/" <> path, to: path }

-- | Validate that the given paths of templates to run exist and for JS
-- | templates that only are provided together with '--uses-js'
validateFiles :: Boolean -> Array TemplateSource -> NonEmptyList FilePath -> Either String (Array TemplateSource)
validateFiles usesJS templates files = fromFoldable <$> traverse validateFile files
  where
  validateFile :: FilePath -> Either String TemplateSource
  validateFile path =
    case find ((path == _) <<< sourcePath) templates of
      Nothing -> Left $ "Path '" <> path <> "' is not a valid template"
      Just (TemplateSource JS _) | not usesJS ->
        Left $ "Path '" <> path <> "' is a JS only template. Did you forget '--uses-js'?"
      Just template -> Right template

data TemplateSourceType = Base | JS | Common

derive instance eqTemplateSourceType :: Eq TemplateSourceType

-- | The source and destination for a given template. Templates will be copied
-- | from their source to destination, with text replacement applied along the way.
newtype Template = Template { from :: FilePath, to :: FilePath }

-- | The source and and type for a given template.
data TemplateSource = TemplateSource TemplateSourceType FilePath

sourceType :: TemplateSource -> TemplateSourceType
sourceType (TemplateSource t _) = t

sourcePath :: TemplateSource -> FilePath
sourcePath (TemplateSource _ path) = path

gitignore :: TemplateSource
gitignore = TemplateSource Common ".gitignore" 

editorconfig :: TemplateSource
editorconfig = TemplateSource Base ".editorconfig"

repoReadme :: TemplateSource
repoReadme = TemplateSource Base "README.md"

docsReadme :: TemplateSource
docsReadme = TemplateSource Base "docs/README.md"

docsChangelog :: TemplateSource
docsChangelog = TemplateSource Base "CHANGELOG.md"

githubWorkflowCI :: TemplateSource
githubWorkflowCI = TemplateSource Common ".github/workflows/ci.yml"

githubIssueBugReport :: TemplateSource
githubIssueBugReport =
  TemplateSource Base ".github/ISSUE_TEMPLATE/bug-report.md"

githubIssueChangeRequest :: TemplateSource
githubIssueChangeRequest =
  TemplateSource Base ".github/ISSUE_TEMPLATE/change-request.md"

githubIssueConfig :: TemplateSource
githubIssueConfig = TemplateSource Base ".github/ISSUE_TEMPLATE/config.yml"

githubContributing :: TemplateSource
githubContributing = TemplateSource Base "CONTRIBUTING.md"

githubPullRequest :: TemplateSource
githubPullRequest = TemplateSource Base ".github/PULL_REQUEST_TEMPLATE.md"

jsEslintrc :: TemplateSource
jsEslintrc = TemplateSource JS ".eslintrc.json"

jsPackageJson :: TemplateSource
jsPackageJson = TemplateSource JS "package.json"
