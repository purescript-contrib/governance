{ name = "contrib-updater"
, dependencies =
  [ "argonaut-core"
  , "codec-argonaut"
  , "console"
  , "effect"
  , "heterogeneous"
  , "interpolate"
  , "node-fs-aff"
  , "node-process"
  , "optparse"
  , "psci-support"
  , "sunde"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
