{ name = "contrib-updater"
, dependencies =
  [ "affjax"
  , "argonaut-core"
  , "codec-argonaut"
  , "console"
  , "effect"
  , "interpolate"
  , "node-fs-aff"
  , "node-process"
  , "optparse"
  , "psci-support"
  , "strings-extra"
  , "sunde"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
