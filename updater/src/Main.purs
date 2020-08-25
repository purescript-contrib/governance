module Main where

import Prelude

import Effect (Effect)
import Updater.Cli as Cli
import Updater.Command as Command

main :: Effect Unit
main = Cli.run >>= Command.run
