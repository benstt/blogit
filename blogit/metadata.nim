## :Author: Benjamín García Roqués
##
## This module provides support for handling metadata (Frontmatter) in Markdown files.

import strformat
import strutils
import std/enumerate
import logging
import results
import options
import sugar
import sequtils
import tables
import yaml/[serialization, dom]

const
  metadataBlockSeparator = "---"
  metadataFieldNames = @["title", "date", "summary", "draft", "tags"]
  metadataTitleDefault = "Title"
  metadataDateDefault = "1970-01-01T00:00:00-03:00"
  metadataSummaryDefault = "Summary"
  metadataDraftDefault = "false"
  metadataTagsDefault = "[]"

type
  SeparatorPositionKind* = enum
    spkBeginning, spkEnd
  MetadataErrorKind* = enum
    mekMissingSeparator,
    mekInvalidField,
    mekEmptyField

type
  Metadata* = object
    ## The metadata spec. Contains a field for every possible value in a YAML metadata block.
    title*: string
    date*: string
    summary*: string
    draft*: bool
    tags*: seq[string]

  MetadataError* = object
    message*: string
    case kind*: MetadataErrorKind
    of [mekInvalidField, mekEmptyField]:
      field*: string
    of mekMissingSeparator:
      position*: SeparatorPositionKind

func parseSeq(s: string): Result[seq[string], string] =
  ## Takes a seq-like string and produces a sequence based on its contents.
  ## Example: "[1, 2, 3]" will be parsed as @["1", "2", "3"]
  if not s.startsWith("[") or not s.endswith("]"):
    return err fmt"string '{s}' is not sequence-like"

  # don't use first "[" and last "]"
  let sq = s[1 .. ^2]
  let values = sq
    .split(",")
    .map(v => v.strip().replace("\""))
    .filter(v => not v.isEmptyOrWhitespace)

  return ok values

func parseMetadataBlock(contents: string): Result[string, MetadataError] =
  ## Returns the block of YAML content within a post (that usually contains more than YAML).
  ## Metadata blocks are separated by two occurrences of the YAML separator: '---'
  let lines = contents.splitLines()

  if lines[0] != metadataBlockSeparator:
    return err MetadataError(
      kind: mekMissingSeparator,
      position: spkBeginning,
      message: "Invalid metadata. Post files have to start with a metadata operator ('---')"
    )

  for i, line in enumerate(lines[1 .. ^1]):
    if line == metadataBlockSeparator:
      return ok lines[1 .. i].join("\n")

  return err MetadataError(
    kind: mekMissingSeparator,
    position: spkEnd,
    message: "Metadata start was found... but the block never ended"
  )

func parseMetadataTags(contents: YamlNode): seq[string] =
  ## Returns the tags field as an sequence of strings from a given YAML metadata block.
  # depending on the tag being present or not, we have to get their contents
  # via YAML Mappings or Sequences
  let tagsNode = contents["tags"]
  var tags: seq[string]
  # ySequence: tags were found and were automatically parsed as sequence
  # yMapping: tags were added during runtime and we need to parse the string contents
  if tagsNode.kind == ySequence:
    for node in tagsNode.elems:
      let elemAsString = node.content
      tags.add(elemAsString)
  elif tagsNode.kind == yMapping:
    tags = parseSeq(tagsNode.content).get

  return tags

proc getMetadataWithDefaults(contents: string): Result[YamlNode, MetadataError] =
  ## Adds missing fields from a metadata block and adds them to a final YamlNode.
  ## Missing fields will be stored with a default value for them.
  ## For example, in the following block, ``draft`` and ``tags`` are missing,
  ## so they will be added with their corresponding default values to the YamlNode.
  ##
  ## .. code-block:: yaml
  ##
  ##  ---
  ##  title: "My awesome blog post!"
  ##  date: "1970-01-01T00:00:00-03:00"
  ##  summary: "This is a summary for my blog post."
  ##  ---
  ##
  ## The final node will have all three above, and
  ##
  ## .. code-block::
  ##
  ##  draft: false
  ##  tags: []
  let node = loadAs[YamlNode](contents)
  var nodeKeys: seq[string] = @[]

  for key in node.fields.keys():
    nodeKeys.add(key.content)

  # return if any invalid field is found
  for field in nodeKeys:
    if field notin metadataFieldNames:
      return err MetadataError(
        kind: mekInvalidField,
        field: field,
        message: fmt"Invalid field '{field}' in file's metadata"
      )

  for field in metadataFieldNames:
    if field notin nodeKeys:
      debug fmt"'{field}' is missing from metadata, adding it"

      var nodeKey, nodeValue: YamlNode
      case field:
        of "title":
          nodeKey = newYamlNode("title")
          nodeValue = newYamlNode(metadataTitleDefault)
        of "date":
          nodeKey = newYamlNode("date")
          nodeValue = newYamlNode(metadataDateDefault)
        of "summary":
          nodeKey = newYamlNode("summary")
          nodeValue = newYamlNode(metadataSummaryDefault)
        of "draft":
          nodeKey = newYamlNode("draft")
          nodeValue = newYamlNode(metadataDraftDefault)
        of "tags":
          nodeKey = newYamlNode("tags")
          nodeValue = newYamlNode(metadataTagsDefault)

      node[nodeKey] = nodeValue

  return ok node

func getFirstEmptyField(contents: YamlNode): Option[string] =
  ## Returns the first occurrence of an empty field in a metadata block.
  for k, v in contents.pairs():
    if v.kind == yScalar and v.content.strip.isEmptyOrWhitespace:
      return some k.content

  return none string

proc parseMetadata*(contents: string): Result[Metadata, MetadataError] =
  ## Takes metadata content in frontmatter format and generates a Metadata object.
  ## Any missing field will be replaced with a default. Valid fields are:
  ## * `title` (default: "Title")
  ## * `date` (default: "1970-01-01T00:00:00-03:00")
  ## * `summary` (default: "Summary")
  ## * `draft` (default: false)
  ## * `tags` (default: [])
  ##
  ## For example,
  ##
  ## .. code-block:: yaml
  ##
  ##  ---
  ##  title: "My awesome blog post!"
  ##  summary: "...an awesome description for my awesome blog post!"
  ##  tags: ["...some", "...awesome", "...tags", "...ugh"]
  ##  ---
  ##
  ## gets parsed as
  ##
  ## .. code-block::
  ##
  ##  (
  ##    title: "My awesome blog post!",
  ##    date: "1970-01-01T00:00:00-03:00",
  ##    summary: "...an awesome description for my awesome blog post!",
  ##    draft: false,
  ##    tags: @["...some", "...awesome", "...tags", "...ugh"]
  ##  )
  let parseResult = parseMetadataBlock(contents)

  if parseResult.isErr:
    logging.error parseResult.error.message
    return err MetadataError(
      kind: mekMissingSeparator,
      position: parseResult.error.position,
      message: fmt("Couldn't parse metadata out of given contents:\n{contents}")
    )

  let yamlContents = parseResult.get()
  let defaultsResult = getMetadataWithDefaults(yamlContents)

  if defaultsResult.isErr:
    logging.error defaultsResult.error.message
    return err MetadataError(
      kind: mekInvalidField,
      field: defaultsResult.error.field,
      message: fmt("Couldn't parse metadata out of given contents:\n{contents}")
    )

  let metadataWithDefaults = defaultsResult.get()

  let emptyField = getFirstEmptyField(metadataWithDefaults)
  if emptyField.isSome:
    return err MetadataError(
      kind: mekEmptyField,
      field: emptyField.get,
      message: fmt"Missing value for metadata field: {emptyField.get}"
    )

  let metadata = Metadata(
    title: metadataWithDefaults["title"].content,
    date: metadataWithDefaults["date"].content,
    summary: metadataWithDefaults["summary"].content,
    draft: parseBool(metadataWithDefaults["draft"].content),
    tags: parseMetadataTags(metadataWithDefaults)
  )

  return ok metadata
