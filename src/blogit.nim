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
import strutils
import strtabs
import sequtils
import sugar
import os
import logging

type
  Metadata = object
    title: string
    date: string
    summary: string
    draft: bool
    tags: seq[string]

type
  SequenceParseError = object of ValueError

proc parseSeq(s: string): seq[string] =
  ## Takes a seq-like string and produces a sequence based on its contents.
  ## Example: "[1, 2, 3]" will be parsed as @["1", "2", "3"]
  if not s.startsWith("[") or not s.endswith("]"):
    raise newException(SequenceParseError, fmt"string '{s}' is not sequence-like")

  # don't use first "[" and last "]"
  let sq = s[1 .. ^2]
  let values = sq
    .split(",")
    .map(v => v.strip().replace("\""))

  return values

proc parseMetadata(contents: string): Metadata =
  # Files with metadata always start with '---' and end with another '---' somewhere.
  let metadata = contents.split("---")[1]
  let metadata_fields = @["title", "date", "summary", "draft", "tags"]
  let metadata_lines = metadata
    .splitLines()
    .filter(l => l.split(":")[0] in metadata_fields)

  # TODO: this can be done with a macro, i think
  let fields = newStringTable()
  for line in metadata_lines:
    let splt = line.split(":")
    let key = splt[0]
    let value = splt[1].strip()
    fields[key] = value

  return Metadata(
    title: fields["title"],
    date: fields["date"],
    summary: fields["summary"],
    draft: parseBool(fields["draft"]),
    tags: parseSeq(fields["tags"])
  )

let logger = newConsoleLogger(fmtStr="[$datetime] - $appname - $levelname: ")
addHandler(logger)

let args = docopt(doc, version="Blogit 0.1.0")

echo welcome_message

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
    error fmt"There was an error trying to open the file. Error: {e.msg}"

  let metadata = parseMetadata(entireFile)
  echo metadata
