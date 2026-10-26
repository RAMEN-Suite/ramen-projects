MATCH (n:Text)
WHERE n.uuid IS NULL
CALL (n) {
  SET n.uuid = randomUUID()
} IN TRANSACTIONS OF 100 ROWS
RETURN count(*);

MATCH (:Regesta)<-[:PART_OF]-(t:Text)
CALL (t) {
  WITH
    t,
    CASE
      WHEN t.text IS NOT NULL AND t.htmlText IS NULL THEN t.text
      ELSE null
    END AS newHtmlText

  SET t.htmlText = COALESCE(t.htmlText, newHtmlText)
  SET t.text =
      CASE
        WHEN newHtmlText IS NOT NULL THEN null
        ELSE t.text
      END
  WITH t
  CALL
    atag.text.import.html(
      t,
      'htmlText',
      'Annotation',
      'text',
      'HAS_ANNOTATION'
    )
    YIELD node

  WITH t
  LIMIT 1
  CALL atag.chains.fullChain(t, 'text')
} IN TRANSACTIONS OF 40 ROWS;

MATCH (:Regesta)<-[:PART_OF]-(t:Text)
CALL (t) {
  MATCH (t)-[:NEXT_CHARACTER*]->(c:Character)
  WITH collect(c) AS characters, t

  MATCH (t)-[:HAS_ANNOTATION]->(so:Annotation)
  WITH
    characters[toInteger(so.startIndex)] AS s,
    characters[toInteger(so.endIndex) - 1] AS e,
    so
  WHERE size(characters) > toInteger(so.endIndex)

  CREATE (so)-[:STANDOFF_START]->(s)
  CREATE (so)-[:STANDOFF_END]->(e)
} IN TRANSACTIONS OF 40 ROWS
