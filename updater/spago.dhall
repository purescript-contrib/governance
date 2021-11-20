{ name = "contrib-updater"
, dependencies =
  [ "aff"
  , "affjax"
  , "argonaut-core"
  , "arrays"
  , "bifunctors"
  , "codec"
  , "codec-argonaut"
  , "console"
  , "control"
  , "effect"
  , "either"
  , "exceptions"
  , "foldable-traversable"
  , "functions"
  , "http-methods"
  , "interpolate"
  , "lists"
  , "maybe"
  , "node-buffer"
  , "node-child-process"
  , "node-fs"
  , "node-fs-aff"
  , "node-path"
  , "node-process"
  , "nullable"
  , "optparse"
  , "ordered-collections"
  , "parallel"
  , "prelude"
  , "psci-support"
  , "record"
  , "strings"
  , "strings-extra"
  , "stringutils"
  , "sunde"
  , "transformers"
  , "tuples"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
