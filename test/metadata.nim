import std/unittest
import results
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

  test "optional fields are automatically added":
    let contents = """
---
title: This is a title.
date: 2022-05-26T18:04:45-03:00
summary: This is a summary.
---
"""
    let metadata = parseMetadata(contents).get()

    check metadata.draft == false
    check metadata.tags.len == 0

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
    check metadataInvalidStart.isErr
    check metadataInvalidStart.error.kind == mekMissingSeparator
    check metadataInvalidStart.error.position == spkBeginning

    let metadataInvalidEnd = parseMetadata(contentsMissingEnd)
    check metadataInvalidEnd.isErr
    check metadataInvalidEnd.error.kind == mekMissingSeparator
    check metadataInvalidEnd.error.position == spkEnd

  test "non-existent fields give errors":
    let contents = """
---
title: This is a valid field.
date: 2022-05-26T18:04:45-03:00
summary: This is a summary.
bizcocho: woops! This field doesn't exist..
---
"""
    let parseResult = parseMetadata(contents)
    check parseResult.isErr
    check parseResult.error.kind == mekInvalidField
    check parseResult.error.field == "bizcocho"

  test "empty fields give errors":
    let contents = """
---
title: OK, title is given
date:
---
"""
    let parseResult = parseMetadata(contents)
    check parseResult.isErr
    check parseResult.error.kind == mekEmptyField
    check parseResult.error.field == "date"
