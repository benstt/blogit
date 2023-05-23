const doc = """
Blogit - A custom, awesome and fun static site generator.

Usage:
  blogit generate <filename>

Options:
  -h --help    Show this message.
  --version    Show version.
"""

const message = """
╔═════════════════════════════════════════════════════════════════════════╗
╠═ 🐱 Blogit v0.1.0 - a custom, awesome and fun static site generator 🐱 ═╣
╚═════════════════════════════════════════════════════════════════════════╝
"""

import docopt
import strutils
import std/[terminal, times, os, logging]

let logger = newConsoleLogger(fmtStr="[$datetime] - $appname - $levelname: ")
addHandler(logger)

let args = docopt(doc, version = "Blogit 0.1.0")

echo message

if args["generate"]:
  let file = args["<filename>"]
  
  if not fileExists($file):
    error "File not found; exiting"
    quit -1

  if splitFile($file).ext != ".md":
    error "File is not a Markdown file; exiting"
    quit -1

  try:
    let entireFile = readFile($file)
    echo entireFile
  except IOError as e:
    error "There was an error trying to open the file. Error: $#".format(e.msg)

