// [STEP 001] RI-Ausstellungsorte-geo erstellen
LOAD CSV WITH HEADERS FROM 'https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/data/places/RI-Places.csv'
AS line
WITH line
  WHERE line.normalisiertDeutsch IS NOT null
WITH line
CALL (line) {
MATCH (r:Regesta {origPlaceOfIssue:line.Original})
MERGE (p:Place {normalizedGerman:line.normalisiertDeutsch})
  ON CREATE SET
  p:Entity,
  p.uuid = randomUUID(),
  p.label = line.normalisiertDeutsch
SET
p.longitude = line.Long,
p.latitude = line.Lat,
p.wikidataId = line.wikidataId ,
p.latLong = line.Lat + ',' + line.Long,
p.nLatLong = point({latitude: tofloat(p.latitude), longitude: tofloat(p.longitude)})

WITH r, p, line
CREATE (r)-[:HAS_ANNOTATION]->(a:Annotation:RegestaAnnotation { uuid: randomUUID(), label: 'placeOfIssue', type: 'ri:placeOfIssue' })-[:REFERS_TO]->(p)
SET a.original = line.Original
SET a.alternativeName = line.Alternativname
SET a.commentary = line.Kommentar
SET a.allocation = line.Zuordnung
SET a.state = line.Lage
SET a.certainty = line.Sicherheit
SET a.institutionInCity = line.InstInDerStadt

// Regesten mit neo4j-Koordinaten der Ausstellungsorte versehen
SET
r.nLatLong = p.nLatLong,
r.placeOfIssue = p.normalizedGerman,
r.latitude = p.latitude,
r.longitude = p.longitude,
r.latLong = p.latLong

} IN TRANSACTIONS OF 1000 ROWS;

// [STEP 002] Heinrich 7 Entities


CALL apoc.load.xml("https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/archive/RegestenUndRegister/abt-06/ri_06,4-heinrich_vii_gesamtregister/xml/gesamtregister.xml?inline=false", "/document/body/section/Stufe0", {}, false)
YIELD value AS s0

WITH s0,
[c IN coalesce(s0._children, [])
WHERE c._type STARTS WITH "Stufe" AND c.id IS NOT NULL] AS children

WITH [{raw: s0, parentId: null}] +
[c IN children | {raw: c, parentId: s0.id}] AS rows

UNWIND rows AS row
WITH row
WHERE NOT row.raw.typ STARTS WITH 'xref'
CALL (row) {
WITH row.raw AS raw, row.parentId AS parentId

WITH raw,
parentId,
head([c IN coalesce(raw._children, []) WHERE c._type = "Inhalt"]) AS inhalt,
head([c IN coalesce(raw._children, []) WHERE c._type = "idno" AND c.type = "wikidata"]) AS wikidata,
head([c IN coalesce(raw._children, []) WHERE c._type = "idno" AND c.type = "geonames"]) AS geonames

WITH raw,
parentId,
wikidata,
geonames,
inhalt,
coalesce(inhalt._children, []) AS contentParts

WITH raw,
parentId,
wikidata,
geonames


MERGE (i:Entity {id: raw.id})
ON CREATE SET i.uuid = randomUUID()
SET i.parentId = parentId,
i.lat = CASE WHEN raw.lat IS NULL THEN null ELSE toFloat(raw.lat) END,
i.long = CASE
WHEN coalesce(raw.long, raw.lon) IS NULL THEN null
ELSE toFloat(coalesce(raw.long, raw.lon))
END,
i.wikidataId = wikidata._text,
i.geonames = geonames._text,
i.type = raw.typ,
i._importTest = "H7"
} IN TRANSACTIONS OF 500 ROWS;


WITH "https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/archive/RegestenUndRegister/abt-06/ri_06,4-heinrich_vii_gesamtregister/xml/gesamtregister.xml?inline=false" AS url
CALL apoc.load.csv(url, {sep: "\u0000"})
YIELD list
WITH apoc.text.join([row IN collect(list) | row[0]], "\n") AS xml

MATCH (e:Entity)
WHERE e.id STARTS WITH "RI006-004_"
WITH collect({
id: e.id,
rawInhaltXml: apoc.text.regexGroups(
xml,
'(?s)<Stufe[0-9][^>]*\\sid="' + e.id + '"[^>]*>.*?<Inhalt>(.*?)</Inhalt>'
)
}) AS rows

UNWIND rows AS row
WITH row
WHERE size(row.rawInhaltXml) > 0

WITH collect({
id: row.id,
rawInhaltXml: row.rawInhaltXml[0][1]
}) AS rows

CALL (rows) {
UNWIND rows AS row

MATCH (e:Entity {id: row.id})
WITH e,
trim(
apoc.text.replace(
apoc.text.replace(
row.rawInhaltXml,
'(?s)<Regestennummer>.*?</Regestennummer>',
''
),
'\\s+',
' '
)
) AS label

SET e.label = label,
e.origLabel = coalesce(e.origLabel, label),
e._labelImport = "raw-inhalt-without-regestennummer"
} IN TRANSACTIONS OF 500 ROWS;




CALL apoc.load.xml("https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/archive/RegestenUndRegister/abt-06/ri_06,4-heinrich_vii_gesamtregister/xml/gesamtregister.xml?inline=false", "/document/body/section/Stufe0", {}, false)
YIELD value AS s0

UNWIND [c IN coalesce(s0._children, [])
WHERE c._type STARTS WITH "Stufe" AND c.id IS NOT NULL] AS child

WITH child.id AS childId, s0.id AS parentId
CALL (childId, parentId) {
MATCH (child:Entity {id: childId})
MATCH (parent:Entity {id: parentId})
MERGE (child)-[:HAS_ANNOTATION]->(a:Annotation { label: 'ri:isSubOf', type: 'ri:isSubOf' })-[:REFERS_TO]->(parent)
ON CREATE SET a.uuid = randomUUID()
} IN TRANSACTIONS OF 500 ROWS;


CALL apoc.load.xml("https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/archive/RegestenUndRegister/abt-06/ri_06,4-heinrich_vii_gesamtregister/xml/gesamtregister.xml?inline=false", "/document/body/section/Stufe0", {}, false)
YIELD value AS s0

WITH s0,
[c IN coalesce(s0._children, [])
WHERE c._type STARTS WITH "Stufe" AND c.id IS NOT NULL] AS children

WITH [s0] + children AS stufen
UNWIND stufen AS stufe

WITH stufe,
head([c IN coalesce(stufe._children, [])
WHERE valueType(c) = "MAP"
AND c._type = "Inhalt"]) AS inhalt

UNWIND [r IN coalesce(inhalt._children, [])
WHERE valueType(r) = "MAP"
AND r._type = "Regestennummer"] AS regestennummer

UNWIND [nr IN coalesce(regestennummer._children, [])
WHERE valueType(nr) = "MAP"
AND nr._type = "nr"] AS nr

WITH stufe.id AS entityId,
trim(toString(nr._text)) AS regestaNumber,
nr.type AS relType,
nr.source_type AS sourceType,
{
`nennung`: 'APPEARS_IN_REGESTATEXT',
`zeuge`: 'APPEARS_AS_WITNESS_IN',
`adressat`: 'APPEARS_AS_ADRESSEE_IN',
`p_ueblieferung`: 'APPEARS_IN_ARCHIVAL_HISTORY',
`kommentar`: 'APPEARS_IN_COMMENTARY',
`austOrt`: 'APPEARS_AS_PLACE_OF_ISSUE_IN',
`notIns`: 'APPEARS_AS_NOTARIAL_INSTRUMENT_IN',
`abwesend`: 'APPEARS_AS_ABSENT_IN',
`ab`: 'APPEARS_AS_ABSENT_IN',
`aussteller`: 'APPEARS_AS_ISSUER_IN',
`datOrt`: 'APPEARS_AS_OPPOSITES_PLACE_OF_ISSUE_IN',
`notar`: 'APPEARS_AS_NOTARY_IN',
`p_tot`: 'APPEARS_AS_DEAD_PERSON_IN',
`rekogneszent`: 'APPEARS_AS_RECOGNECENT_IN',
`empfaenger`: 'APPEARS_AS_RECEIVER_IN'
} AS typeMap

CALL (entityId, regestaNumber, relType, sourceType, typeMap) {
MATCH (i:Entity {id: entityId})
MATCH (r:Regesta)
WHERE r.identifier STARTS WITH "RI VI,"
AND r.regestaNumber = regestaNumber
CREATE (r)-[:HAS_ANNOTATION]->(a:Annotation { label: 'ri:appearsIn', type: 'ri:appearsIn', role: relType })-[:REFERS_TO]->(i)
SET a.label = typeMap[relType],
a.sourceType = sourceType,
a.regestaNumber = regestaNumber
} IN TRANSACTIONS OF 500 ROWS;


// Entity mit weiteren Labels ausstatten
MATCH (e:Entity)
WHERE e.type = 'person'
WITH e
CALL apoc.create.addLabels(id(e), ['Person']) YIELD node
RETURN node;

MATCH (e:Entity)
WHERE e.type = 'ereignis'
WITH e
CALL apoc.create.addLabels(id(e), ['Event']) YIELD node
RETURN node;

MATCH (e:Entity)
WHERE e.type = 'sache'
WITH e
CALL apoc.create.addLabels(id(e), ['Thing']) YIELD node
RETURN node;

MATCH (e:Entity)
WHERE e.type = 'ort'
WITH e
CALL apoc.create.addLabels(id(e), ['Place']) YIELD node
RETURN node;



// [STEP 003] RI13 Entities
// RegID und HeftId für F3-Hefte als Property erstellen
MATCH (reg:Regesta)
WHERE NOT reg.identifier CONTAINS 'Supplement'
AND reg.identifier STARTS WITH "[RI XIII]"
UNWIND apoc.text.regexGroups(reg.identifier, ".* (\\S+) n. (\\S+).*") as link
SET reg.registerId = ("#" + link[1] + "-" + link[2])
SET reg.heftId = link[1]
SET reg.shortNumber = ("#" + link[1] + "-" + link[2]);

// RegID und HeftId für Chmel-Regesten als Property erstellen
MATCH (reg:Regesta)
WHERE reg.identifier STARTS WITH "Chmel, Anh"
UNWIND apoc.text.regexGroups(reg.identifier, ".*Chmel, Anh. n. (\\S+)") as link
SET reg.registerId = ("#0" + "-" + link[1])
SET reg.heftId = 'CHMEL'
SET reg.shortNumber = ("#0" + "-" + link[1]);

// RegID und HeftId für Chmel-Anhang-Regesten als Property erstellen
MATCH (reg:Regesta)
WHERE reg.identifier STARTS WITH "Chmel "
UNWIND apoc.text.regexGroups(reg.identifier, ".*Chmel n. (\\S+)") as link
SET reg.registerId = ("#0" + "-" + link[1])
SET reg.heftId = 'CHMEL'
SET reg.shortNumber = ("#0" + "-" + link[1]);

// IndexEntries erstellen
CYPHER runtime=slotted
CALL apoc.load.xml('https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/data/indexes/RI_013.xml?inline=false','',{}, true) yield value as xmlFile
//CALL apoc.load.xml('https://exist.regesta-imperii.de/exist/rest/apps/rixqlib/xql/getRegister.xql?registerName=013','',{}, true) yield value as xmlFile
UNWIND xmlFile._register AS wdata
CREATE (e:Entity {
uuid:       randomUUID(),
xmlId:      wdata.id,
type:       wdata.typ,
parentId:   wdata.parent,
latitude:   wdata.lat,
longitude:  wdata.lon,
wikidataId: wdata.wikidata,
geonames:   wdata.geonames
})
RETURN count(e);

// label bei den IndexEntries ergänzen
CYPHER runtime=slotted
CALL apoc.load.xml('https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/data/indexes/RI_013.xml','',{}, true) yield value as xmlFile
//CALL apoc.load.xml('https://exist.regesta-imperii.de/exist/rest/apps/rixqlib/xql/getRegister.xql?registerName=013','',{}, true) yield value as xmlFile
UNWIND xmlFile._register AS lemma
WITH lemma.id AS xmlId,
[x in lemma._lemma where x._type="label" | x._text][0] AS label,
[y in [x in lemma._lemma where x._type ="numbers" | x._numbers][0] where y.type="nennung" | y._text] AS nennung,
[y in [x in lemma._lemma where x._type ="numbers" | x._numbers][0] where y.type="empfaenger" | y._text] AS empfaenger
MATCH (i:Entity {xmlId:xmlId})
SET i.origLabel = label, i.label = label;

//IS_SUB_OF erstellen
MATCH (i:Entity), (p:Entity)
WHERE i.parentId = p.xmlId
MERGE (i)-[:HAS_ANNOTATION]->(a:Annotation { label: 'ri:isSubOf', type: 'ri:isSubOf' })-[:REFERS_TO]->(p)
ON CREATE SET a.uuid = randomUUID();

// wikidataId ergänzen
CYPHER runtime=slotted
CALL
apoc.load.xml('https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/data/indexes/RI_013.xml','',{}, true) yield value as xmlFile
//CALL apoc.load.xml('https://exist.regesta-imperii.de/exist/rest/apps/rixqlib/xql/getRegister.xql?registerName=013','',{}, true) yield value as xmlFile
UNWIND xmlFile._register AS lemma
WITH lemma.id AS xmlId,
[x in lemma._lemma WHERE x._type='idno' AND x.type='wikidata'| x._text][0] AS wikidataId
WITH wikidataId, xmlId WHERE wikidataId IS NOT NULL
MATCH (i:Entity {xmlId:xmlId})
SET i.wikidataId = wikidataId
RETURN count(i);

// APPEARS_IN erstellen
CYPHER runtime=slotted
CALL
apoc.load.xml('https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/data/indexes/RI_013.xml?inline=false','',{}, true) yield value as xmlFile
UNWIND xmlFile._register AS wdata
UNWIND wdata._lemma AS lemma
UNWIND lemma._numbers AS number
MATCH (e:Entity {xmlId:wdata.id})
MATCH (r:Regesta  {registerId:number._text})
WHERE r.identifier STARTS WITH "Chmel, Anh"
OR r.identifier STARTS WITH "[RI XIII]"
OR r.identifier STARTS WITH "Chmel "
WITH wdata,e,r,number
// WHERE number.type = "nennung"
CREATE (r)-[:HAS_ANNOTATION]->(a:Annotation { label: 'ri:appearsIn', type: 'ri:appearsIn', role: number.type, uuid: randomUUID() })-[:REFERS_TO]->(e)
RETURN count(a);

// Indexeinträge mit neo4j-Koordinaten der Ausstellungsorte versehen
MATCH (e:Entity)
WHERE e.latitude IS NOT NULL
SET e.nlatLong = point({latitude: tofloat(e.latitude), longitude: tofloat(e.longitude)});

// Indexeinträge mit kommagetrennten Koordinaten der Ausstellungsorte versehen
MATCH (e:Entity)
WHERE e.latitude IS NOT NULL
SET e.latLong = e.latitude + ',' + e.longitude ;
