# Package

version       = "0.1.0"
author        = "Benjamín García Roqués"
description   = "A custom, awesome and fun static site generator."
license       = "MIT"
srcDir        = "src"
bin           = @["blogit"]


# Dependencies

requires "nim >= 1.6.12"
requires "docopt >= 0.7.0"
requires "yaml >= 1.1.0"
requires "results >= 0.4.0"
