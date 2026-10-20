// [STEP C01] Import corpora and corpus hierarchy
CALL apoc.load.json(
  // FIX: load local data instead of GitLab
  'file:///ramen/sections.json'
)
YIELD value AS json

CALL (json) {
  // FIX: keep node order to resolve duplicate labels in C10b
  UNWIND range(0, size(json.nodes) - 1) AS sourceOrder

  WITH
    json.nodes[sourceOrder] AS sourceNode,
    sourceOrder

  CREATE (corpus:Corpus:Collection {
    // FIX: source IDs are stored as guid
    uuid: sourceNode.guid,
    label: sourceNode.label,
    sourceOrder: sourceOrder
  })

  RETURN count(corpus) AS importedCorpora
}

CALL (json) {
  UNWIND json.edges AS edge

  MATCH (source:Corpus:Collection {
    uuid: edge.source
  })

  MATCH (target:Corpus:Collection {
    uuid: edge.target
  })

  CREATE (source)-[:PART_OF]->(target)

  RETURN count(*) AS importedCorpusRelations
}

RETURN
  importedCorpora,
  importedCorpusRelations;


// [STEP C02] Import letters, documents and figures
:auto
CALL apoc.load.json(
  // FIX: load local data instead of GitLab
  'file:///ramen/letters.json',
  '$.record[*]',
  {
    pathOptions: []
  }
)
YIELD value AS record

WITH record
WHERE record.metadata.generalMetadataIsPresent = true
  // FIX: source IDs are stored as guid
  AND trim(
    coalesce(
      toString(
        record.metadata.generalMetadata.attributes.guid
      ),
      ''
    )
  ) <> ''

CALL (record) {
  WITH
    record.metadata.generalMetadata AS generalMetadata,
    record.metadata.communication AS communication

  // FIX: source IDs are stored as guid
  MERGE (resource:Collection {
    uuid: generalMetadata.attributes.guid
  })

  SET resource += apoc.map.clean(
    apoc.map.merge(
      // FIX: do not copy guid as property
      apoc.map.removeKeys(
        apoc.convert.toMap(generalMetadata.attributes),
        ['guid']
      ),
      {
        // FIX: download URL is stored as download
        xmlDownload: communication.attributes.download
      }
    ),
    [],
    ['', null]
  )

  // FIX: resource type is stored as doctype
  FOREACH (_ IN CASE
    WHEN toLower(generalMetadata.attributes.doctype) = 'letter'
    THEN [1]
    ELSE []
  END |
    SET resource:Letter
  )

  FOREACH (_ IN CASE
    WHEN toLower(generalMetadata.attributes.doctype) = 'document'
    THEN [1]
    ELSE []
  END |
    SET resource:Document
  )

  FOREACH (_ IN CASE
    WHEN toLower(generalMetadata.attributes.doctype) = 'image'
    THEN [1]
    ELSE []
  END |
    SET resource:Figure
  )
} IN TRANSACTIONS OF 100 ROWS

RETURN count(*) AS processedResourceRecords;


// [STEP C03] Create all variants listed by their parent resources
:auto
CALL apoc.load.json(
  // FIX: load local data instead of GitLab
  'file:///ramen/letters.json',
  '$.record[*]',
  {
    pathOptions: []
  }
)
YIELD value AS record

WITH record
WHERE record.metadata.generalMetadataIsPresent = true
  // FIX: source IDs are stored as guid
  AND trim(
    coalesce(
      toString(
        record.metadata.generalMetadata.attributes.guid
      ),
      ''
    )
  ) <> ''

WITH
  // FIX: source IDs are stored as guid
  record.metadata.generalMetadata.attributes.guid AS resourceUuid,
  // FIX: variants are listed as HAS_TEXT relations
  [
    relation IN coalesce(
      apoc.convert.toList(
        record.metadata.generalMetadata.outgoingRelations.relation
      ),
      []
    )
    WHERE relation.relationType = 'HAS_TEXT'
    | relation.guid
  ] AS variantUuids

UNWIND variantUuids AS variantUuid

WITH
  resourceUuid,
  variantUuid
WHERE trim(
  coalesce(
    toString(variantUuid),
    ''
  )
) <> ''

CALL (
  resourceUuid,
  variantUuid
) {
  MATCH (resource:Collection {
    uuid: resourceUuid
  })

  MERGE (variant:Variant:Collection {
    uuid: variantUuid
  })

  MERGE (variant)-[:PART_OF]->(resource)
} IN TRANSACTIONS OF 100 ROWS

RETURN count(*) AS processedVariantRelations;


// [STEP C04] Import metadata for every variant record
:auto
CALL apoc.load.json(
  // FIX: load local data instead of GitLab
  'file:///ramen/letters.json',
  '$.record[*]',
  {
    pathOptions: []
  }
)
YIELD value AS record

WITH
  record.metadata.variantMetadata.attributes AS variantAttributes

// FIX: source IDs are stored as guid
WHERE trim(
  coalesce(
    toString(variantAttributes.guid),
    ''
  )
) <> ''

CALL (variantAttributes) {
  // FIX: source IDs are stored as guid
  MERGE (variant:Variant:Collection {
    uuid: variantAttributes.guid
  })

  WITH
    variant,
    // FIX: do not copy guid as property
    apoc.map.removeKeys(
      apoc.convert.toMap(variantAttributes),
      ['guid']
    ) AS attributes

  // FIX: drop metadata prefix from variant properties
  SET variant += apoc.map.clean(
    apoc.map.fromPairs([
      key IN keys(attributes) |
      [
        CASE
          WHEN key STARTS WITH 'metadata'
            AND size(key) > 8
          THEN toLower(substring(key, 8, 1)) + substring(key, 9)

          ELSE key
        END,
        attributes[key]
      ]
    ]),
    [],
    ['', null]
  )
} IN TRANSACTIONS OF 100 ROWS

RETURN count(*) AS processedVariantRecords;


// [STEP C05] Import abstracts with texts and annotations
:auto
CALL apoc.load.json(
  // FIX: load local data instead of GitLab
  'file:///ramen/letters.json',
  '$.record[*]',
  {
    pathOptions: []
  }
)
YIELD value AS record

WITH record
WHERE record.metadata.generalMetadataIsPresent = true
  // FIX: filter on doctype and metadataIsReference
  AND toLower(record.metadata.generalMetadata.attributes.doctype) = 'letter'
  AND record.metadata.variantMetadata.attributes.metadataIsReference = true
  AND trim(
    coalesce(
      toString(record.texts.abstract.text),
      ''
    )
  ) <> ''

CALL (record) {
  // FIX: source IDs are stored as guid
  MATCH (letter:Letter:Collection {
    uuid: record.metadata.generalMetadata.attributes.guid
  })

  WITH
    letter,
    record.texts.abstract AS abstract

  CREATE (abstractCollection:Abstract:Collection {
    uuid: randomUUID(),
    label: 'Abstract zu ' + coalesce(
      letter.label,
      letter.uuid
    )
  })

  CREATE (abstractCollection)-[:PART_OF]->(letter)

  CREATE (textNode:Text:Content {
    // FIX: source IDs are stored as guid
    uuid: CASE
      WHEN abstract.guid IS NOT NULL
        AND trim(toString(abstract.guid)) <> ''
      THEN trim(toString(abstract.guid))

      ELSE randomUUID()
    END,
    text: abstract.text
  })

  CREATE (textNode)-[:PART_OF]->(
    abstractCollection
  )

  WITH
    textNode,
    abstract

  UNWIND coalesce(
    apoc.convert.toList(abstract.properties),
    []
  ) AS property

  WITH
    textNode,
    property,
    apoc.convert.toMap(property) AS propertyMap,
    coalesce(
      apoc.convert.toMap(property.attributes),
      {}
    ) AS attributes

  MERGE (annotation:Annotation {
    // FIX: source IDs are stored as guid
    uuid: CASE
      WHEN property.guid IS NOT NULL
        AND trim(toString(property.guid)) <> ''
      THEN trim(toString(property.guid))

      ELSE randomUUID()
    END
  })

  SET annotation += apoc.map.removeKeys(
    propertyMap,
    [
      'attributes',
      'uuid',
      'guid',
      'startIndex',
      'endIndex'
    ]
  )

  SET annotation += attributes

  SET
    annotation.startIndex = CASE
      WHEN property.startIndex IS NULL
      THEN null
      ELSE toInteger(property.startIndex)
    END,
    annotation.endIndex = CASE
      WHEN property.endIndex IS NULL
      THEN null
      ELSE toInteger(property.endIndex)
    END

  SET annotation.type = CASE
    WHEN property.teiType IS NULL
    THEN annotation.type

    WHEN annotation.type IS NULL
      OR trim(toString(annotation.type)) = ''
    THEN property.teiType

    WHEN annotation.type = property.teiType
    THEN annotation.type

    WHEN annotation.type STARTS WITH property.teiType + '-'
    THEN annotation.type

    ELSE property.teiType + '-' + annotation.type
  END

  MERGE (textNode)-[:HAS_ANNOTATION]->(
    annotation
  )
} IN TRANSACTIONS OF 5 ROWS

RETURN count(*) AS processedAbstractRecords;


// [STEP C06] Import variant main texts and annotations
:auto
CALL apoc.load.json(
  // FIX: load local data instead of GitLab
  'file:///ramen/letters.json',
  '$.record[*]',
  {
    pathOptions: []
  }
)
YIELD value AS record

WITH
  // FIX: source IDs are stored as guid
  record.metadata.variantMetadata.attributes.guid AS variantUuid,
  record.texts.variant.main_text AS mainText

WHERE trim(
  coalesce(
    toString(variantUuid),
    ''
  )
) <> ''
  AND mainText IS NOT NULL
  AND mainText.text IS NOT NULL

CALL (
  variantUuid,
  mainText
) {
  MATCH (variant:Variant:Collection {
    uuid: variantUuid
  })

  CREATE (textNode:Text:Content {
    // FIX: source IDs are stored as guid
    uuid: CASE
      WHEN mainText.guid IS NOT NULL
        AND trim(toString(mainText.guid)) <> ''
      THEN trim(toString(mainText.guid))

      ELSE randomUUID()
    END
  })

  SET textNode += apoc.map.clean(
    {
      text: mainText.text
    },
    [],
    ['', null]
  )

  CREATE (textNode)-[:PART_OF]->(variant)

  WITH
    textNode,
    mainText

  UNWIND coalesce(
    apoc.convert.toList(mainText.properties),
    []
  ) AS property

  WITH
    textNode,
    property,
    apoc.convert.toMap(property) AS propertyMap,
    coalesce(
      apoc.convert.toMap(property.attributes),
      {}
    ) AS attributes

  CREATE (annotation:Annotation {
    // FIX: source IDs are stored as guid
    uuid: CASE
      WHEN property.guid IS NOT NULL
        AND trim(toString(property.guid)) <> ''
      THEN trim(toString(property.guid))

      ELSE randomUUID()
    END
  })

  SET annotation += apoc.map.removeKeys(
    propertyMap,
    [
      'attributes',
      'uuid',
      'guid',
      'startIndex',
      'endIndex'
    ]
  )

  SET annotation += attributes

  SET
    annotation.startIndex = CASE
      WHEN property.startIndex IS NULL
      THEN null

      ELSE toInteger(property.startIndex)
    END,
    annotation.endIndex = CASE
      WHEN property.endIndex IS NULL
      THEN null

      ELSE toInteger(property.endIndex)
    END

  SET annotation.type = CASE
    WHEN property.teiType IS NULL
    THEN annotation.type

    WHEN annotation.type IS NULL
      OR trim(toString(annotation.type)) = ''
    THEN property.teiType

    WHEN annotation.type = property.teiType
    THEN annotation.type

    WHEN annotation.type STARTS WITH property.teiType + '-'
    THEN annotation.type

    ELSE property.teiType + '-' + annotation.type
  END

  CREATE (textNode)-[:HAS_ANNOTATION]->(
    annotation
  )
} IN TRANSACTIONS OF 5 ROWS

RETURN count(*) AS processedMainTexts;


// [STEP C07] Import variant editorial notes as annotations
:auto
CALL apoc.load.json(
  // FIX: load local data instead of GitLab
  'file:///ramen/letters.json',
  '$.record[*]',
  {
    pathOptions: []
  }
)
YIELD value AS record

WITH
  // FIX: source IDs are stored as guid
  record.metadata.variantMetadata.attributes.guid AS variantUuid,
  record.texts.note AS note

WHERE trim(
  coalesce(
    toString(variantUuid),
    ''
  )
) <> ''
  AND trim(
    coalesce(
      toString(note.text),
      ''
    )
  ) <> ''

CALL (
  variantUuid,
  note
) {
  MATCH (variant:Variant:Collection {
    uuid: variantUuid
  })

  CREATE (editorialAnnotation:Annotation {
    // FIX: source IDs are stored as guid
    uuid: CASE
      WHEN note.guid IS NOT NULL
        AND trim(toString(note.guid)) <> ''
      THEN trim(toString(note.guid))

      ELSE randomUUID()
    END,
    type: 'editorial_comment'
  })

  CREATE (variant)-[:HAS_ANNOTATION]->(
    editorialAnnotation
  )

  CREATE (noteText:Text:Content {
    uuid: randomUUID(),
    text: note.text
  })

  CREATE (editorialAnnotation)-[:REFERS_TO]->(
    noteText
  )

  WITH
    noteText,
    note

  UNWIND coalesce(
    apoc.convert.toList(note.properties),
    []
  ) AS property

  WITH
    noteText,
    property,
    apoc.convert.toMap(property) AS propertyMap,
    coalesce(
      apoc.convert.toMap(property.attributes),
      {}
    ) AS attributes

  CREATE (annotation:Annotation {
    // FIX: source IDs are stored as guid
    uuid: CASE
      WHEN property.guid IS NOT NULL
        AND trim(toString(property.guid)) <> ''
      THEN trim(toString(property.guid))

      ELSE randomUUID()
    END
  })

  SET annotation += apoc.map.removeKeys(
    propertyMap,
    [
      'attributes',
      'uuid',
      'guid',
      'startIndex',
      'endIndex'
    ]
  )

  SET annotation += attributes

  SET
    annotation.startIndex = CASE
      WHEN property.startIndex IS NULL
      THEN null

      ELSE toInteger(property.startIndex)
    END,
    annotation.endIndex = CASE
      WHEN property.endIndex IS NULL
      THEN null

      ELSE toInteger(property.endIndex)
    END

  SET annotation.type = CASE
    WHEN property.teiType IS NULL
    THEN annotation.type

    WHEN annotation.type IS NULL
      OR trim(toString(annotation.type)) = ''
    THEN property.teiType

    WHEN annotation.type = property.teiType
    THEN annotation.type

    WHEN annotation.type STARTS WITH property.teiType + '-'
    THEN annotation.type

    ELSE property.teiType + '-' + annotation.type
  END

  CREATE (noteText)-[:HAS_ANNOTATION]->(
    annotation
  )
} IN TRANSACTIONS OF 5 ROWS

RETURN count(*) AS processedEditorialNotes;


// [STEP C08] Import editorial comments and their annotations
:auto
CALL apoc.load.json(
  // FIX: load local data instead of GitLab
  'file:///ramen/letters.json',
  '$.record[*]',
  {
    pathOptions: []
  }
)
YIELD value AS record

UNWIND coalesce(
  apoc.convert.toList(
    record.texts.variant.editorial_comments
  ),
  []
) AS comment

WITH comment
// FIX: source IDs are stored as guid
WHERE trim(
  coalesce(
    toString(comment.guid),
    ''
  )
) <> ''

CALL (comment) {
  // FIX: source IDs are stored as guid
  MERGE (commentText:Text:Content {
    uuid: comment.guid
  })

  SET commentText += apoc.map.clean(
    {
      text: comment.text
    },
    [],
    ['', null]
  )

  WITH
    commentText,
    comment

  UNWIND coalesce(
    apoc.convert.toList(comment.properties),
    []
  ) AS property

  WITH
    commentText,
    property,
    apoc.convert.toMap(property) AS propertyMap,
    coalesce(
      apoc.convert.toMap(property.attributes),
      {}
    ) AS attributes

  MERGE (annotation:Annotation {
    // FIX: source IDs are stored as guid
    uuid: CASE
      WHEN property.guid IS NOT NULL
        AND trim(toString(property.guid)) <> ''
      THEN trim(toString(property.guid))

      ELSE randomUUID()
    END
  })

  SET annotation += apoc.map.removeKeys(
    propertyMap,
    [
      'attributes',
      'uuid',
      'guid',
      'startIndex',
      'endIndex'
    ]
  )

  SET annotation += attributes

  SET
    annotation.startIndex = CASE
      WHEN property.startIndex IS NULL
      THEN null
      ELSE toInteger(property.startIndex)
    END,
    annotation.endIndex = CASE
      WHEN property.endIndex IS NULL
      THEN null
      ELSE toInteger(property.endIndex)
    END

  SET annotation.type = CASE
    WHEN property.teiType IS NULL
    THEN annotation.type

    WHEN annotation.type IS NULL
      OR trim(toString(annotation.type)) = ''
    THEN property.teiType

    WHEN annotation.type = property.teiType
    THEN annotation.type

    WHEN annotation.type STARTS WITH property.teiType + '-'
    THEN annotation.type

    ELSE property.teiType + '-' + annotation.type
  END

  MERGE (commentText)-[:HAS_ANNOTATION]->(
    annotation
  )
} IN TRANSACTIONS OF 5 ROWS

RETURN count(*) AS processedEditorialComments;


// [STEP C09] Import corpus introductions
// FIX: old corpus UUIDs replaced by current guids
UNWIND [
  {
    corpusUuid: 'ed_a4ec9069-16da-4851-ac90-6916da085135',
    file: 'Lubieniecki.json'
  },
  {
    corpusUuid: 'ed_36c44f66-dea9-4f5b-844f-66dea92f5b7d',
    file: 'Lubieniecki_Hevelius.json'
  },
  {
    corpusUuid: 'ed_183e3dbe-e5b5-40c3-be3d-bee5b5b0c390',
    file: 'Lubieniecki_Schletzer.json'
  },
  {
    corpusUuid: 'ed_8855b58d-e7d0-4552-95b5-8de7d0555265',
    file: 'Lubieniecki_Roetlin.json'
  },
  {
    corpusUuid: 'ed_f406dd92-a698-4290-86dd-92a69842904b',
    file: 'Lubieniecki_Reyher.json'
  },
  {
    corpusUuid: 'ed_76276d64-5f3a-42a9-a76d-645f3ab2a920',
    file: 'Lubieniecki_Grau.json'
  },
  // FIX: Guericke der Ältere (dae) -> GdA (assumed)
  {
    corpusUuid: 'ed_396aed05-8a79-4ba1-aaed-058a79bba196',
    file: 'Lubieniecki_Guericke_dae.json'
  },
  // FIX: Guericke der Jüngere (dj) -> GdJ (assumed)
  {
    corpusUuid: 'ed_c76bd63c-c7af-403e-abd6-3cc7afb03e5b',
    file: 'Lubieniecki_Guericke_dj.json'
  },
  {
    corpusUuid: 'ed_5d465242-2720-43f9-8652-42272033f98d',
    file: 'Lubieniecki_Sivers.json'
  },
  {
    corpusUuid: 'ed_bb14f453-686a-4bf7-94f4-53686a3bf748',
    file: 'Lubieniecki_Stegmann_dj.json'
  },
  {
    corpusUuid: 'ed_aed5e9ed-ed43-48a9-95e9-eded4318a995',
    file: 'Lubieniecki_Rautenstein.json'
  },
  {
    corpusUuid: 'ed_95856cc0-b775-4c8e-856c-c0b7751c8e14',
    file: 'Lubieniecki_Placentinus.json'
  },
  {
    corpusUuid: 'ed_00e05f36-34b9-43be-a05f-3634b943be6b',
    file: 'Lubieniecki_Mueller.json'
  },
  {
    corpusUuid: 'ed_16bdcae7-05d3-4b92-bdca-e705d36b92ca',
    file: 'Lubieniecki_Olearius.json'
  },
  {
    corpusUuid: 'ed_109de9b1-4981-4ad0-9de9-b14981fad0c4',
    file: 'Lubieniecki_Riccioli.json'
  },
  {
    corpusUuid: 'ed_36ed4fae-d507-49b0-ad4f-aed50719b065',
    file: 'Lubieniecki_Boulliau.json'
  },
  {
    corpusUuid: 'ed_00dd26cd-7dc1-490e-9d26-cd7dc1190eca',
    file: 'Ruarus_Kirchmann.json'
  },
  {
    corpusUuid: 'ed_869e70ed-e4d9-4b1a-9e70-ede4d9cb1afb',
    file: 'Ruarus_Peuschel.json'
  }
] AS source

CALL apoc.load.json(
  'https://gitlab.rlp.net/adwmainz/digicademy/sbw/csv-data-dump/-/raw/main/meta-texts/section-introductions/'
  + source.file
)
YIELD value AS json

MATCH (corpus:Corpus:Collection {
  uuid: source.corpusUuid
})

CREATE (textNode:Text:Content {
  uuid: CASE
    WHEN json.uuid IS NOT NULL
      AND trim(toString(json.uuid)) <> ''
    THEN trim(toString(json.uuid))

    ELSE randomUUID()
  END,
  text: json.text
})

CREATE (textNode)-[:PART_OF]->(corpus)

WITH
  textNode,
  json

UNWIND coalesce(
  apoc.convert.toList(json.properties),
  []
) AS property

WITH
  textNode,
  property,
  apoc.convert.toMap(property) AS propertyMap,
  coalesce(
    apoc.convert.toMap(property.attributes),
    {}
  ) AS attributes

MERGE (annotation:Annotation {
  uuid: CASE
    WHEN property.uuid IS NOT NULL
      AND trim(toString(property.uuid)) <> ''
    THEN trim(toString(property.uuid))

    ELSE randomUUID()
  END
})

SET annotation += apoc.map.removeKeys(
  propertyMap,
  [
    'attributes',
    'uuid',
    'guid',
    'startIndex',
    'endIndex'
  ]
)

SET annotation += attributes

SET
  annotation.startIndex = CASE
    WHEN property.startIndex IS NULL
    THEN null
    ELSE toInteger(property.startIndex)
  END,
  annotation.endIndex = CASE
    WHEN property.endIndex IS NULL
    THEN null
    ELSE toInteger(property.endIndex)
  END

SET annotation.type = CASE
  WHEN property.teiType IS NULL
  THEN annotation.type

  WHEN annotation.type IS NULL
    OR trim(toString(annotation.type)) = ''
  THEN property.teiType

  WHEN annotation.type = property.teiType
  THEN annotation.type

  WHEN annotation.type STARTS WITH property.teiType + '-'
  THEN annotation.type

  ELSE property.teiType + '-' + annotation.type
END

MERGE (textNode)-[:HAS_ANNOTATION]->(
  annotation
)

RETURN
  count(DISTINCT textNode) AS importedIntroductionTexts,
  count(annotation) AS importedIntroductionAnnotations;


// [STEP C09] Import correspondence annotations
:auto
CALL apoc.load.json(
  // FIX: load local data instead of GitLab
  'file:///ramen/letters.json',
  '$.record[*]',
  {
    pathOptions: []
  }
)
YIELD value AS record

WITH record
WHERE record.metadata.generalMetadataIsPresent = true
  // FIX: filter on doctype and metadataIsReference
  AND toLower(record.metadata.generalMetadata.attributes.doctype) = 'letter'
  AND record.metadata.variantMetadata.attributes.metadataIsReference = true

UNWIND coalesce(
  apoc.convert.toList(
    record.metadata.generalMetadata.correspDesc.correspAction
  ),
  []
) AS action

CALL (record, action) {
  // FIX: source IDs are stored as guid
  MATCH (letter:Letter:Collection {
    uuid: record.metadata.generalMetadata.attributes.guid
  })

  WITH
    letter,
    action,
    apoc.convert.toMap(action.attributes) AS attributes

  MERGE (annotation:Annotation {
    // FIX: source IDs are stored as guid
    uuid: CASE
      WHEN action.guid IS NOT NULL
        AND trim(toString(action.guid)) <> ''
      THEN trim(toString(action.guid))

      WHEN attributes.guid IS NOT NULL
        AND trim(toString(attributes.guid)) <> ''
      THEN trim(toString(attributes.guid))

      ELSE randomUUID()
    END
  })

  SET annotation += apoc.map.clean(
    // FIX: do not copy guid as property
    apoc.map.removeKeys(
      attributes,
      ['guid']
    ),
    [],
    ['', null]
  )

  // FIX: correspondence type is stored on the action
  SET annotation.type = toLower(action.type)

  MERGE (letter)-[:HAS_ANNOTATION]->(
    annotation
  )

  WITH
    annotation,
    action

  UNWIND coalesce(
    apoc.convert.toList(
      action.outgoingRelations.relation
    ),
    []
  ) AS relation

  // FIX: source IDs are stored as guid
  MATCH (target:Entity {
    uuid: relation.guid
  })

  CALL apoc.create.relationship(
    annotation,
    relation.relationType,
    {},
    target
  )
  YIELD rel

  RETURN count(rel) AS importedRelations
} IN TRANSACTIONS OF 20 ROWS

RETURN count(*) AS processedCorrespondenceActions;


// [STEP C10a] Mark corpus roots as start of folder paths
// FIX: sections.json lacks sub-corpus and letter edges, derive them from folder paths
MATCH (root:Corpus:Collection)
WHERE EXISTS {
  MATCH (:Corpus:Collection)-[:PART_OF]->(root)
}
  AND NOT EXISTS {
  MATCH (root)-[:PART_OF]->(:Corpus:Collection)
}

SET root.sourcePath = ''

RETURN count(root) AS markedCorpusRoots;


// [STEP C10b] Build corpus hierarchy from letter folder paths
// FIX: sections.json lacks sub-corpus and letter edges, derive them from folder paths
:auto
CALL apoc.load.json(
  // FIX: load local data instead of GitLab
  'file:///ramen/letters.json',
  '$.record[*]',
  {
    pathOptions: []
  }
)
YIELD value AS record

WITH record
WHERE record.metadata.generalMetadataIsPresent = true
  // FIX: filter on doctype and metadataIsReference
  AND toLower(record.metadata.generalMetadata.attributes.doctype) = 'letter'
  AND record.metadata.variantMetadata.attributes.metadataIsReference = true
  AND record.file CONTAINS '/'

WITH split(record.file, '/') AS parts

WITH parts[0..size(parts) - 1] AS folders

UNWIND range(1, size(folders)) AS depth

WITH DISTINCT folders[0..depth] AS folderPath

ORDER BY size(folderPath)

CALL (folderPath) {
  WITH
    folderPath,
    reduce(
      path = '',
      folder IN folderPath[0..size(folderPath) - 1] | path + '/' + folder
    ) AS parentPath,
    reduce(
      path = '',
      folder IN folderPath | path + '/' + folder
    ) AS childPath

  MATCH (parent:Corpus:Collection {
    sourcePath: parentPath
  })

  MATCH (child:Corpus:Collection {
    label: last(folderPath)
  })
  WHERE child.sourceOrder > parent.sourceOrder
    AND child.sourcePath IS NULL
    AND (
      EXISTS {
        MATCH (child)-[:PART_OF]->(parent)
      }
      OR NOT EXISTS {
        MATCH (child)-[:PART_OF]->(:Corpus:Collection)
      }
    )

  WITH
    parent,
    child,
    childPath
  ORDER BY child.sourceOrder
  LIMIT 1

  MERGE (child)-[:PART_OF]->(parent)

  SET child.sourcePath = childPath
} IN TRANSACTIONS OF 1 ROWS

RETURN count(*) AS processedFolderPaths;


// [STEP C10c] Connect letters to their folder corpus
// FIX: sections.json lacks sub-corpus and letter edges, derive them from folder paths
:auto
CALL apoc.load.json(
  // FIX: load local data instead of GitLab
  'file:///ramen/letters.json',
  '$.record[*]',
  {
    pathOptions: []
  }
)
YIELD value AS record

WITH record
WHERE record.metadata.generalMetadataIsPresent = true
  // FIX: filter on doctype and metadataIsReference
  AND toLower(record.metadata.generalMetadata.attributes.doctype) = 'letter'
  AND record.metadata.variantMetadata.attributes.metadataIsReference = true
  AND record.file CONTAINS '/'

WITH
  record,
  split(record.file, '/') AS parts

WITH
  record,
  reduce(
    path = '',
    folder IN parts[0..size(parts) - 1] | path + '/' + folder
  ) AS folderPath

CALL (record, folderPath) {
  // FIX: source IDs are stored as guid
  MATCH (letter:Letter:Collection {
    uuid: record.metadata.generalMetadata.attributes.guid
  })

  MATCH (corpus:Corpus:Collection {
    sourcePath: folderPath
  })

  MERGE (letter)-[:PART_OF]->(corpus)
} IN TRANSACTIONS OF 250 ROWS

RETURN count(*) AS processedLetterRecords;


// [STEP C10d] Remove temporary corpus path information
// FIX: sections.json lacks sub-corpus and letter edges, derive them from folder paths
MATCH (corpus:Corpus:Collection)
WHERE corpus.sourceOrder IS NOT NULL
   OR corpus.sourcePath IS NOT NULL

REMOVE
  corpus.sourceOrder,
  corpus.sourcePath

RETURN count(corpus) AS cleanedCorpora;


// [STEP C11] Import attachment collections
:auto
CALL apoc.load.json(
  // FIX: load local data instead of GitLab
  'file:///ramen/letters.json',
  '$.record[*]',
  {
    pathOptions: []
  }
)
YIELD value AS record

WITH
  record,
  // FIX: attachments are listed as HAS_ATTACHMENT relations
  [
    relation IN coalesce(
      apoc.convert.toList(
        record.metadata.communication.outgoingRelations.relation
      ),
      []
    )
    WHERE relation.relationType = 'HAS_ATTACHMENT'
    | relation.guid
  ] AS attachmentUuids

WHERE record.metadata.generalMetadataIsPresent = true
  // FIX: filter on doctype and metadataIsReference
  AND toLower(record.metadata.generalMetadata.attributes.doctype) = 'letter'
  AND record.metadata.variantMetadata.attributes.metadataIsReference = true
  AND size(attachmentUuids) > 0

CALL (record, attachmentUuids) {
  // FIX: source IDs are stored as guid
  MATCH (letter:Letter:Collection {
    uuid: record.metadata.generalMetadata.attributes.guid
  })

  CREATE (attachmentGroup:Attachment:Collection {
    uuid: randomUUID(),
    label: 'Attachments zu ' + coalesce(
      letter.label,
      letter.uuid
    )
  })

  CREATE (attachmentGroup)-[:PART_OF]->(
    letter
  )

  WITH
    attachmentGroup,
    attachmentUuids

  UNWIND attachmentUuids AS attachmentUuid

  MATCH (attachment:Collection {
    uuid: attachmentUuid
  })

  MERGE (attachment)-[:PART_OF]->(
    attachmentGroup
  )
} IN TRANSACTIONS OF 20 ROWS

RETURN count(*) AS processedAttachmentGroups;


// [STEP C12] Resolve annotation references
:auto
MATCH (annotation:Annotation)
WHERE trim(
  coalesce(
    toString(annotation.key),
    ''
  )
) <> ''

UNWIND split(
  trim(toString(annotation.key)),
  ' '
) AS rawKey

WITH
  annotation,
  CASE
    WHEN annotation.type = 'commented'
    THEN 'comment'

    WHEN annotation.type = 'rs-comment'
      AND rawKey CONTAINS '/#'
    THEN 'comment'

    ELSE 'generic'
  END AS targetKind,
  CASE
    WHEN annotation.type = 'rs-comment'
      AND rawKey CONTAINS '/#'
    THEN split(rawKey, '/#')[1]

    ELSE replace(rawKey, '#', '')
  END AS targetUuid

WHERE trim(
  coalesce(
    targetUuid,
    ''
  )
) <> ''

CALL (
  annotation,
  targetKind,
  targetUuid
) {
  OPTIONAL MATCH (entity:Entity {
    uuid: targetUuid
  })
  WHERE targetKind = 'generic'

  OPTIONAL MATCH (collection:Collection {
    uuid: targetUuid
  })
  WHERE targetKind = 'generic'

  OPTIONAL MATCH (commentText:Text:Content {
    uuid: targetUuid
  })
  WHERE targetKind = 'comment'

  FOREACH (_ IN CASE
    WHEN entity IS NULL
    THEN []
    ELSE [1]
  END |
    MERGE (annotation)-[:REFERS_TO]->(entity)
  )

  FOREACH (_ IN CASE
    WHEN collection IS NULL
    THEN []
    ELSE [1]
  END |
    MERGE (annotation)-[:REFERS_TO]->(
      collection
    )
  )

  FOREACH (_ IN CASE
    WHEN commentText IS NULL
    THEN []
    ELSE [1]
  END |
    MERGE (annotation)-[:REFERS_TO]->(
      commentText
    )
  )
} IN TRANSACTIONS OF 250 ROWS

RETURN count(*) AS processedAnnotationReferences;


// [STEP C13] Remove resolved source keys
:auto
MATCH (annotation:Annotation)
WHERE annotation.key IS NOT NULL

CALL (annotation) {
  REMOVE annotation.key
} IN TRANSACTIONS OF 1000 ROWS

RETURN count(*) AS cleanedAnnotationKeys;
