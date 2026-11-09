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
  SET collection.label = CASE
    WHEN collection:Witness
    THEN 'Textzeuge'

    ELSE ''
  END
} IN TRANSACTIONS OF 1000 ROWS

RETURN count(*) AS updatedCollections;

// [STEP F03a] Convert startIndex/endIndex to selector
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

// [STEP F03b] Check: Any remaining Annotations with startIndex/endIndex? Should be 0.
:auto
MATCH (a:Annotation)
WHERE a.startIndex IS NOT NULL OR a.endIndex IS NOT NULL
RETURN count(a) AS remainingWithIndices;

