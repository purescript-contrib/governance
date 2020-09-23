module Updater.Generate.Template
  ( Variables(..)
  , TemplateSource
  , TemplateSourceType
  , allTemplates
  , docsChangelog
  , runTemplates
  , validateFiles
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
  , repo :: String -- not used
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
      templates = filterByType { usesJS: variables.usesJS, templates: templateSources }
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
runTemplate :: RunTemplateOptions -> TemplateSource -> Aff Unit
runTemplate opts template = do
  let from = templateSourcePath { usesJS: opts.variables.usesJS } template
      to = template.destination
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
filterByType :: { usesJS :: Boolean, templates :: Array TemplateSource } -> Array TemplateSource
filterByType { usesJS: true, templates } = templates
filterByType { usesJS: false, templates } =
  filter (not <<< eq JS <<< _.sourceType) templates

-- | Define the source of a given template by its type and destination path.
-- | Common templates default to base unless using JS.
templateSourcePath :: { usesJS :: Boolean } -> TemplateSource -> FilePath
templateSourcePath { usesJS: true } { sourceType: Common, destination } = "js/" <> destination
templateSourcePath _ { sourceType: JS, destination } = "js/" <> destination
templateSourcePath _ { destination } = "base/" <> destination

-- | Validate that the given paths of templates to run exist and for JS
-- | templates that only are provided together with '--uses-js'
validateFiles
  :: { usesJS :: Boolean, templates :: Array TemplateSource }
  -> NonEmptyList FilePath
  -> Either String (Array TemplateSource)
validateFiles { usesJS, templates } files = fromFoldable <$> traverse validateFile files
  where
  validateFile :: FilePath -> Either String TemplateSource
  validateFile path =
    case find (eq path <<< _.destination) templates of
      Nothing -> Left $ "Path '" <> path <> "' is not a valid template"
      Just { sourceType: JS } | not usesJS ->
        Left $ "Path '" <> path <> "' is a JS only template. Did you forget '--uses-js'?"
      Just template -> Right template

-- | Template types:
-- |
-- | - Base: standard template.
-- | - JS: template project which relies on JS (for example via FFI)
-- | - Common: common for both templates. Defaults to Base, unless using JS.
data TemplateSourceType = Base | JS | Common

derive instance eqTemplateSourceType :: Eq TemplateSourceType

-- | The source and type for a given template.
type TemplateSource = { sourceType :: TemplateSourceType, destination :: FilePath }

gitignore :: TemplateSource
gitignore = { sourceType: Common, destination: ".gitignore" }

editorconfig :: TemplateSource
editorconfig = { sourceType: Base, destination: ".editorconfig" }

repoReadme :: TemplateSource
repoReadme = { sourceType: Base, destination: "README.md" }

docsReadme :: TemplateSource
docsReadme = { sourceType: Base, destination: "docs/README.md" }

docsChangelog :: TemplateSource
docsChangelog = { sourceType: Base, destination: "CHANGELOG.md" }

githubWorkflowCI :: TemplateSource
githubWorkflowCI =
  { sourceType: Common, destination: ".github/workflows/ci.yml" }

githubIssueBugReport :: TemplateSource
githubIssueBugReport =
  { sourceType: Base, destination: ".github/ISSUE_TEMPLATE/bug-report.md" }

githubIssueChangeRequest :: TemplateSource
githubIssueChangeRequest =
  { sourceType: Base, destination: ".github/ISSUE_TEMPLATE/change-request.md" }

githubIssueConfig :: TemplateSource
githubIssueConfig =
  { sourceType: Base, destination: ".github/ISSUE_TEMPLATE/config.yml" }

githubContributing :: TemplateSource
githubContributing = { sourceType: Base, destination: "CONTRIBUTING.md" }

githubPullRequest :: TemplateSource
githubPullRequest =
  { sourceType: Base, destination: ".github/PULL_REQUEST_TEMPLATE.md" }

jsEslintrc :: TemplateSource
jsEslintrc = { sourceType: JS, destination: ".eslintrc.json" }

jsPackageJson :: TemplateSource
jsPackageJson = { sourceType: JS, destination: "package.json" }
