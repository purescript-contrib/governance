module Updater.SyncLabels.Repos where

-- spago ls packages | grep 'com/purescript/' | sed -r 's/([ \t])+/ /g' |
--  \ cut -d ' ' -f 4 | sed 's/"//g' | sed 's;https://github.com/;;' |
--  \ sed -r 's/.git$//g' | cut -d '/' -f 2 | tr '\n' ' '
{-
spago ls packages | grep 'com/purescript/' | sed -r 's/([ \t])+/ /g' |
  \ cut -d ' ' -f 4 | sed 's/"//g' | sed 's;https://github.com/;;' |
  \ sed -r 's/.git$//g' | cut -d '/' -f 2 | tr '\n' ' ' |
  \ sed -r 's/([^ ]+)/"\1"/g' | sed -r 's/^(.+)$/\[ \1\n  \]/g' |
  \ sed 's/" "/"\n  , "/g'

-}
-- PureScript
purescriptRepos :: Array String
purescriptRepos =
  [ "purescript-arrays"
  , "purescript-assert"
  , "purescript-bifunctors"
  , "purescript-catenable-lists"
  , "purescript-console"
  , "purescript-const"
  , "purescript-contravariant"
  , "purescript-control"
  , "purescript-datetime"
  , "purescript-distributive"
  , "purescript-effect"
  , "purescript-either"
  , "purescript-enums"
  , "purescript-exceptions"
  , "purescript-exists"
  , "purescript-filterable"
  , "purescript-foldable-traversable"
  , "purescript-foreign"
  , "purescript-foreign-object"
  , "purescript-free"
  , "purescript-functions"
  , "purescript-functors"
  , "purescript-gen"
  , "purescript-graphs"
  , "purescript-identity"
  , "purescript-integers"
  , "purescript-invariant"
  , "purescript-lazy"
  , "purescript-lcg"
  , "purescript-lists"
  , "purescript-math"
  , "purescript-maybe"
  , "purescript-minibench"
  , "purescript-newtype"
  , "purescript-nonempty"
  , "purescript-numbers"
  , "purescript-ordered-collections"
  , "purescript-orders"
  , "purescript-parallel"
  , "purescript-partial"
  , "purescript-prelude"
  , "purescript-profunctor"
  , "purescript-psci-support"
  , "purescript-quickcheck"
  , "purescript-random"
  , "purescript-record"
  , "purescript-refs"
  , "purescript-safe-coerce"
  , "purescript-semirings"
  , "purescript-st"
  , "purescript-strings"
  , "purescript-tailrec"
  , "purescript-transformers"
  , "purescript-tuples"
  , "purescript-type-equality"
  , "purescript-typelevel-prelude"
  , "purescript-unfoldable"
  , "purescript-unsafe-coerce"
  , "purescript-validation"
  ]

{-
spago ls packages | grep 'com/purescript-contrib/' | sed -r 's/([ \t])+/ /g' |
  \ cut -d ' ' -f 4 | sed 's/"//g' | sed 's;https://github.com/;;' |
  \ sed -r 's/.git$//g' | cut -d '/' -f 2 | tr '\n' ' ' |
  \ sed -r 's/([^ ]+)/"\1"/g' | sed -r 's/^(.+)$/\[ \1\n  \]/g' |
  \ sed 's/" "/"\n  , "/g'

-}
purescriptContribRepos :: Array String
purescriptContribRepos =
  [ "purescript-ace"
  , "purescript-aff"
  , "purescript-aff-bus"
  , "purescript-aff-coroutines"
  , "purescript-affjax"
  , "purescript-argonaut"
  , "purescript-argonaut-codecs"
  , "purescript-argonaut-core"
  , "purescript-argonaut-generic"
  , "purescript-argonaut-traversals"
  , "purescript-arraybuffer-types"
  , "purescript-avar"
  , "purescript-concurrent-queues"
  , "purescript-coroutines"
  , "purescript-css"
  , "purescript-fixed-points"
  , "purescript-fork"
  , "purescript-form-urlencoded"
  , "purescript-formatters"
  , "purescript-freet"
  , "purescript-github-actions-toolkit"
  , "purescript-http-methods"
  , "purescript-js-date"
  , "purescript-js-timers"
  , "purescript-js-uri"
  , "purescript-machines"
  , "purescript-matryoshka"
  , "purescript-media-types"
  , "purescript-now"
  , "purescript-nullable"
  , "purescript-options"
  , "purescript-parsing"
  , "purescript-pathy"
  , "purescript-precise"
  , "purescript-profunctor-lenses"
  , "purescript-quickcheck-laws"
  , "purescript-react"
  , "purescript-react-dom"
  , "purescript-routing"
  , "purescript-string-parsers"
  , "purescript-strings-extra"
  , "purescript-these"
  , "purescript-unicode"
  , "purescript-unsafe-reference"
  , "purescript-uri"
  ]

{-
spago ls packages | grep 'com/purescript-web/' | sed -r 's/([ \t])+/ /g' |
  \ cut -d ' ' -f 4 | sed 's/"//g' | sed 's;https://github.com/;;' |
  \ sed -r 's/.git$//g' | cut -d '/' -f 2 | tr '\n' ' ' |
  \ sed -r 's/([^ ]+)/"\1"/g' | sed -r 's/^(.+)$/\[ \1\n  \]/g' |
  \ sed 's/" "/"\n  , "/g'

-}

purescriptNodeRepos :: Array String
purescriptNodeRepos =
  [ "purescript-node-buffer"
  , "purescript-node-child-process"
  , "purescript-node-fs"
  , "purescript-node-fs-aff"
  , "purescript-node-http"
  , "purescript-node-net"
  , "purescript-node-path"
  , "purescript-node-process"
  , "purescript-node-readline"
  , "purescript-node-streams"
  , "purescript-node-url"
  , "purescript-posix-types"
  ]

{-
spago ls packages | grep 'com/purescript-node/' | sed -r 's/([ \t])+/ /g' |
  \ cut -d ' ' -f 4 | sed 's/"//g' | sed 's;https://github.com/;;' |
  \ sed -r 's/.git$//g' | cut -d '/' -f 2 | tr '\n' ' ' |
  \ sed -r 's/([^ ]+)/"\1"/g' | sed -r 's/^(.+)$/\[ \1\n  \]/g' |
  \ sed 's/" "/"\n  , "/g'

-}

purescriptWebRepos :: Array String
purescriptWebRepos =
  [ "purescript-canvas"
  , "purescript-web-clipboard"
  , "purescript-web-cssom"
  , "purescript-web-dom"
  , "purescript-web-dom-parser"
  , "purescript-web-dom-xpath"
  , "purescript-web-encoding"
  , "purescript-web-events"
  , "purescript-web-fetch"
  , "purescript-web-file"
  , "purescript-web-html"
  , "purescript-web-promise"
  , "purescript-web-socket"
  , "purescript-web-storage"
  , "purescript-web-streams"
  , "purescript-web-touchevents"
  , "purescript-web-uievents"
  , "purescript-web-xhr"
  ]
