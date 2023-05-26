const doc = """
Blogit - A custom, awesome and fun static site generator.

Usage:
  blogit generate <filename>

Options:
  -h --help    Show this message.
  --version    Show version.
"""

const welcome_message = """
╔═════════════════════════════════════════════════════════════════════════╗
╠═ 🐱 Blogit v0.1.0 - a custom, awesome and fun static site generator 🐱 ═╣
╚═════════════════════════════════════════════════════════════════════════╝
"""

import docopt
import strformat
import os
import logging
import metadata

let logger = newConsoleLogger(fmtStr="[$datetime] - $appname - $levelname: ")
addHandler(logger)

let args = docopt(doc, version="Blogit 0.1.0")

echo welcome_message

when isMainModule:
  if args["generate"]:
    let file = args["<filename>"]

    if not fileExists($file):
      error fmt"File '{file}' not found; exiting"
      quit -1

    if splitFile($file).ext != ".md":
      error "File given is not a Markdown file; exiting"
      quit -1

    var entireFile: string
    try:
      entireFile = readFile($file)
    except IOError as e:
      error fmt"There was an error trying to open the file. Error: {e.msg}; exiting"
      quit -1

    let metadata = parseMetadata(entireFile)
    echo metadata
