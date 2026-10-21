// [STEP T01] Mark nodes to keep and their annotations (rest will be removed)
// Briefe
//   Lubieniecki_Stanislaw
//     Raue (with everything inside)
//   Ruarus_Martin (with everything inside)
MATCH (briefe:Corpus:Collection {
  uuid: 'ed_bad3fd94-1788-4d9e-93fd-9417888d9ed4'
})

MATCH (lubieniecki:Corpus:Collection {
  uuid: 'ed_a4ec9069-16da-4851-ac90-6916da085135'
})-[:PART_OF]->(briefe)

MATCH (raue:Corpus:Collection {
  uuid: 'ed_917946c6-1aa7-455d-b946-c61aa7355db1'
})-[:PART_OF]->(lubieniecki)

MATCH (ruarus:Corpus:Collection {
  uuid: 'ed_ee7f1d86-a19b-4ae6-bf1d-86a19b5ae651'
})-[:PART_OF]->(briefe)

MATCH (node:Collection|Content)-[:PART_OF*0..]->(root)
WHERE root IN [
  raue,
  ruarus
]

WITH
  briefe,
  lubieniecki,
  collect(DISTINCT node) AS subtreeNodes

UNWIND apoc.coll.toSet(
  [
    briefe,
    lubieniecki
  ] + subtreeNodes
) AS node

SET node:TruncateKeep

WITH node

OPTIONAL MATCH (node)-[:HAS_ANNOTATION]->(annotation:Annotation)

SET annotation:TruncateKeep

RETURN
  count(DISTINCT node) AS keptNodes,
  count(DISTINCT annotation) AS keptAnnotations;


// [STEP T02] Remove all other Collection nodes and Content nodes in the PART_OF hierarchy, with their annotations
:auto
MATCH (node:Collection|Content)
WHERE NOT node:TruncateKeep
  // Content without PART_OF (comments, notes, descriptions) is checked in T03
  AND (
    node:Collection
    OR EXISTS {
      MATCH (node)-[:PART_OF]->()
    }
  )

CALL (node) {
  OPTIONAL MATCH (node)-[:HAS_ANNOTATION]->(annotation:Annotation)
  WHERE NOT annotation:TruncateKeep

  WITH
    node,
    collect(DISTINCT annotation) AS annotations

  FOREACH (annotation IN annotations |
    DETACH DELETE annotation
  )

  DETACH DELETE node
} IN TRANSACTIONS OF 500 ROWS

RETURN count(*) AS removedNodes;


// [STEP T03] Remove abandoned Content nodes with their annotations
// (no incoming REFERS_TO and no outgoing PART_OF)
:auto
MATCH (content:Content)
WHERE NOT EXISTS {
    MATCH ()-[:REFERS_TO]->(content)
  }
  AND NOT EXISTS {
    MATCH (content)-[:PART_OF]->()
  }

CALL (content) {
  OPTIONAL MATCH (content)-[:HAS_ANNOTATION]->(annotation:Annotation)
  WHERE NOT annotation:TruncateKeep

  WITH
    content,
    collect(DISTINCT annotation) AS annotations

  FOREACH (annotation IN annotations |
    DETACH DELETE annotation
  )

  DETACH DELETE content
} IN TRANSACTIONS OF 500 ROWS

RETURN count(*) AS removedContents;


// [STEP T04] Remove temporary keep marker
:auto
MATCH (node:TruncateKeep)

CALL (node) {
  REMOVE node:TruncateKeep
} IN TRANSACTIONS OF 1000 ROWS

RETURN count(*) AS unmarkedNodes;
