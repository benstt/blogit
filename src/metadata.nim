## :Author: Benjamín García Roqués
##
## This module provides support for handling metadata (Frontmatter) in Markdown files.

import strformat
import strutils
import std/enumerate
import logging
import results
import sugar
import sequtils
import fusion/matching
import yaml/serialization

type
  Metadata* = object
    title*: string
    date*: string
    summary*: string
    draft*: bool
    tags*: seq[string]

type
  ParseErrorKind* = enum
    pekMissingInitialSeparator, pekMissingEndingSeparator
  ParseError = tuple[kind: ParseErrorKind, message: string]
  ParseMetadataBlockResult = Result[string, ParseError]
  ParseMetadataResult = Result[Metadata, ParseError]

const
  metadataBlockSeparator = "---"

proc parseMetadataBlock(contents: string): ParseMetadataBlockResult =
  let lines = contents.splitLines()

  if lines[0] != metadataBlockSeparator:
    return err (
      kind: pekMissingInitialSeparator,
      message: "Invalid metadata. Post files have to start with a metadata operator ('---')"
    )

  for i, line in enumerate(lines[1 .. ^1]):
    if line == metadataBlockSeparator:
      return ok lines[1 .. i].join("\n")

  return err (
    kind: pekMissingEndingSeparator,
    message: "Metadata start was found... but never ended"
  )

proc parseMetadata*(contents: string): ParseMetadataResult =
  ## Takes metadata content in frontmatter format and generates a Metadata object. For example,
  ##
  ## .. code-block:: yaml
  ##
  ##  ---
  ##  title: "My awesome blog post!"
  ##  date: "1970-01-01T00:00:00-03:00"
  ##  summary: "...an awesome description for my awesome blog post!"
  ##  draft: false
  ##  tags: ["...some", "...awesome", "...tags", "...ugh"]
  ##  ---
  ##
  ## gets parsed as
  ##
  ## .. code-block::
  ##
  ##  Metadata(
  ##    title: "My awesome blog post!",
  ##    date: "1970-01-01T00:00:00-03:00",
  ##    summary: "...an awesome description for my awesome blog post!",
  ##    draft: false,
  ##    tags: @["...some", "...awesome", "...tags", "...ugh"]
  ##  )
  var metadata: Metadata
  let parseResult = parseMetadataBlock(contents)

  if parseResult.isErr:
    logging.error parseResult.error.message
    return err (
      kind: parseResult.error.kind,
      message: fmt("Couldn't parse metadata out of given contents:\n{contents}")
    )

  let yamlContents = parseResult.get()
  yamlContents.load(metadata)

  return ok metadata
