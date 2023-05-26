import std/unittest
import results
import yaml
import ../src/metadata

suite "metadata is parsed correctly":

  test "fields have proper data types":
    let contents = """
---
title: This is a title.
date: 2022-05-26T18:04:45-03:00
summary: This is a summary.
draft: false
tags: ["hello"]
---
"""
    let metadata = parseMetadata(contents).get()

    check:
      metadata.title == "This is a title."
      metadata.date == "2022-05-26T18:04:45-03:00"
      metadata.summary == "This is a summary."
      metadata.draft == false
      metadata.tags.len == 1

  test "missing separators return different error types":
    let contentsMissingStart = """
Missing initial separator!
---
"""
    let contentsMissingEnd = """
---
Missing ending separator!
"""

    let metadataInvalidStart = parseMetadata(contentsMissingStart)
    let metadataInvalidEnd = parseMetadata(contentsMissingEnd)
    check metadataInvalidStart.isErr
    check metadataInvalidEnd.isErr
    check metadataInvalidStart.error.kind == pekMissingInitialSeparator
    check metadataInvalidEnd.error.kind == pekMissingEndingSeparator

  test "non-existent fields give errors":
    let contents = """
---
title: This is a valid field.
date: 2022-05-26T18:04:45-03:00
summary: This is a summary.
bizcocho: This is not.
---
"""
    try:
      discard parseMetadata(contents)
    except YamlConstructionError as e:
      check e.lineContent == "bizcocho: This is not.\n"
