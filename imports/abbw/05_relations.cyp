// [STEP G01] Validate person IDs
LOAD CSV WITH HEADERS FROM
'https://docs.google.com/spreadsheets/d/e/2PACX-1vQPngiwCLRgfZ95o8vbNT-zGWtSY_ZnGb-_xT13fTMJwrGiRYSIY7kjDGayielh4MF_zwaTpGIuJBo8/pub?gid=1588145193&single=true&output=csv'
AS row
WITH trim(coalesce(row.ID, '')) AS uuid,
     trim(coalesce(row.label, '')) AS name
OPTIONAL MATCH (person:Entity {uuid: uuid})
WITH collect(CASE WHEN uuid = '' OR person IS NULL
                  THEN name + ' [ID: ' + uuid + ']'
                  ELSE null END) AS missing
CALL apoc.util.validate(
  size(missing) > 0,
  'Missing person entities: %s',
  [apoc.text.join(missing, '; ')]
)
RETURN size(missing) AS missingPersons;

// [STEP G02] Validate relationship endpoints
LOAD CSV WITH HEADERS FROM
'https://docs.google.com/spreadsheets/d/e/2PACX-1vQPngiwCLRgfZ95o8vbNT-zGWtSY_ZnGb-_xT13fTMJwrGiRYSIY7kjDGayielh4MF_zwaTpGIuJBo8/pub?gid=157599467&single=true&output=csv'
AS row
WITH trim(coalesce(row.source, '')) AS sourceId,
     trim(coalesce(row.target, '')) AS targetId,
     trim(coalesce(row.Person1, '')) AS sourceName,
     trim(coalesce(row.Person2, '')) AS targetName
OPTIONAL MATCH (source:Entity {uuid: sourceId})
OPTIONAL MATCH (target:Entity {uuid: targetId})
WITH collect(CASE WHEN sourceId = '' OR source IS NULL
                  THEN 'source: ' + sourceName + ' [ID: ' + sourceId + ']'
                  ELSE null END) AS missingSources,
     collect(CASE WHEN targetId = '' OR target IS NULL
                  THEN 'target: ' + targetName + ' [ID: ' + targetId + ']'
                  ELSE null END) AS missingTargets
WITH missingSources + missingTargets AS missing
CALL apoc.util.validate(
  size(missing) > 0,
  'Missing relationship persons: %s',
  [apoc.text.join(missing, '; ')]
)
RETURN size(missing) AS missingEndpoints;

// [STEP G03] Update existing persons
LOAD CSV WITH HEADERS FROM
'https://docs.google.com/spreadsheets/d/e/2PACX-1vQPngiwCLRgfZ95o8vbNT-zGWtSY_ZnGb-_xT13fTMJwrGiRYSIY7kjDGayielh4MF_zwaTpGIuJBo8/pub?gid=1588145193&single=true&output=csv'
AS row
WITH trim(coalesce(row.ID, '')) AS uuid,
     trim(coalesce(row.label, '')) AS personLabel,
     trim(coalesce(row.dates, '')) AS dates,
     trim(coalesce(row.note, '')) AS personNote
MATCH (person:Entity {uuid: uuid})
SET person.label = CASE WHEN personLabel <> '' AND trim(coalesce(toString(person.label), '')) = ''
                        THEN personLabel ELSE person.label END,
    person.dates = CASE WHEN dates <> '' AND trim(coalesce(toString(person.dates), '')) = ''
                        THEN dates ELSE person.dates END,
    person.sheetPersonNote = CASE WHEN personNote <> '' THEN personNote ELSE person.sheetPersonNote END
RETURN count(person) AS updatedPersons;

// [STEP G04] Check relationship vocabulary
LOAD CSV WITH HEADERS FROM
'https://docs.google.com/spreadsheets/d/e/2PACX-1vQPngiwCLRgfZ95o8vbNT-zGWtSY_ZnGb-_xT13fTMJwrGiRYSIY7kjDGayielh4MF_zwaTpGIuJBo8/pub?gid=775246259&single=true&output=csv'
AS row
WITH collect(DISTINCT trim(coalesce(row.Beziehungstyp, ''))) AS declared
LOAD CSV WITH HEADERS FROM
'https://docs.google.com/spreadsheets/d/e/2PACX-1vQPngiwCLRgfZ95o8vbNT-zGWtSY_ZnGb-_xT13fTMJwrGiRYSIY7kjDGayielh4MF_zwaTpGIuJBo8/pub?gid=157599467&single=true&output=csv'
AS relation
WITH declared, collect(DISTINCT trim(coalesce(relation.Beziehung, ''))) AS used
RETURN [kind IN used WHERE kind <> '' AND NOT kind IN declared] AS undeclaredKinds;

// [STEP G05] Import relationship annotations
LOAD CSV WITH HEADERS FROM
'https://docs.google.com/spreadsheets/d/e/2PACX-1vQPngiwCLRgfZ95o8vbNT-zGWtSY_ZnGb-_xT13fTMJwrGiRYSIY7kjDGayielh4MF_zwaTpGIuJBo8/pub?gid=157599467&single=true&output=csv'
AS row
WITH DISTINCT trim(coalesce(row.source, '')) AS sourceId,
              trim(coalesce(row.target, '')) AS targetId,
              trim(coalesce(row.Beziehung, '')) AS kind,
              trim(coalesce(row.note, '')) AS note
WHERE sourceId <> '' AND targetId <> '' AND kind <> ''
MATCH (source:Entity {uuid: sourceId})
MATCH (target:Entity {uuid: targetId})
OPTIONAL MATCH (source)-[:HAS_ANNOTATION]->(existing:Annotation {type: 'relation', kind: kind})-[:REFERS_TO]->(target)
WHERE trim(coalesce(existing.note, '')) = note
WITH source, target, sourceId, targetId, kind, note, head(collect(existing)) AS existing
WHERE existing IS NULL
MERGE (annotation:Annotation {uuid: 'bilder-metadaten:relation:' + apoc.util.md5([sourceId, targetId, kind, note])})
SET annotation.type = 'relation', annotation.kind = kind, annotation.note = note
MERGE (source)-[:HAS_ANNOTATION]->(annotation)
MERGE (annotation)-[:REFERS_TO]->(target)
RETURN count(DISTINCT annotation) AS createdAnnotations;
