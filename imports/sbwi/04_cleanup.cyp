// [STEP F01] Set missing Annotation UUIDs
:auto
MATCH (annotation:Annotation)
WHERE annotation.uuid IS NULL
   OR trim(toString(annotation.uuid)) = ''

CALL (annotation) {
  SET annotation.uuid = randomUUID()
} IN TRANSACTIONS OF 1000 ROWS

RETURN count(*) AS updatedAnnotations;


// [STEP F02] Set missing Collection labels
:auto
MATCH (collection:Collection)
WHERE collection.label IS NULL
   OR trim(toString(collection.label)) = ''

CALL (collection) {
  SET collection.label = collection.uuid
} IN TRANSACTIONS OF 1000 ROWS

RETURN count(*) AS updatedCollections;


// [STEP F03] Move table start indexes behind preceding headings
:auto
MATCH (content:Content)-[:HAS_ANNOTATION]->(
  table:Annotation {
    type: 'table'
  }
)

MATCH (content)-[:HAS_ANNOTATION]->(
  heading:Annotation {
    type: 'head'
  }
)

WHERE heading.startIndex = table.startIndex
  AND heading.endIndex IS NOT NULL
  AND table.endIndex IS NOT NULL
  AND heading.endIndex < table.endIndex

WITH
  table,
  max(heading.endIndex) AS headingEnd

CALL (
  table,
  headingEnd
) {
  SET table.startIndex = headingEnd + 1
} IN TRANSACTIONS OF 1000 ROWS

RETURN count(*) AS updatedTableAnnotations;


// [STEP F04] Move list start indexes behind preceding headings
:auto
MATCH (content:Content)-[:HAS_ANNOTATION]->(
  list:Annotation {
    type: 'list'
  }
)

MATCH (content)-[:HAS_ANNOTATION]->(
  heading:Annotation {
    type: 'head'
  }
)

WHERE heading.startIndex = list.startIndex
  AND heading.endIndex IS NOT NULL
  AND list.endIndex IS NOT NULL
  AND heading.endIndex < list.endIndex

WITH
  list,
  max(heading.endIndex) AS headingEnd

CALL (
  list,
  headingEnd
) {
  SET list.startIndex = headingEnd + 1
} IN TRANSACTIONS OF 1000 ROWS

RETURN count(*) AS updatedListAnnotations;

// [STEP F05a] Convert startIndex/endIndex to selector
:auto
MATCH (a:Annotation)
WHERE a.startIndex IS NOT NULL AND a.endIndex IS NOT NULL

CALL (a) {
  WITH 
    a, 
    toInteger(a.startIndex) AS s, 
    toInteger(a.endIndex) AS e
  SET a.selector = '{"type":"TextPositionSelector","start":' + toString(s) + ',"end":' + toString(e) + '}'
  REMOVE a.startIndex, a.endIndex
} IN TRANSACTIONS OF 10000 ROWS;

// [STEP F05b] Check: Any remaining Annotations with startIndex/endIndex? Should be 0.
:auto
MATCH (a:Annotation)
WHERE a.startIndex IS NOT NULL OR a.endIndex IS NOT NULL
RETURN count(a) AS remainingWithIndices;
