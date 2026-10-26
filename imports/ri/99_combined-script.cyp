// [STEP 001] Create UUID constraints
CREATE CONSTRAINT entity_uuid_unique IF NOT EXISTS
FOR (node:Entity)
REQUIRE node.uuid IS UNIQUE;

CREATE CONSTRAINT collection_uuid_unique IF NOT EXISTS
FOR (node:Collection)
REQUIRE node.uuid IS UNIQUE;

CREATE CONSTRAINT content_uuid_unique IF NOT EXISTS
FOR (node:Content)
REQUIRE node.uuid IS UNIQUE;

CREATE CONSTRAINT annotation_uuid_unique IF NOT EXISTS
FOR (node:Annotation)
REQUIRE node.uuid IS UNIQUE;


// [STEP 002] Create lookup indexes
CREATE INDEX entity_label_index IF NOT EXISTS
FOR (node:Entity)
ON (node.label);

CREATE INDEX collection_label_index IF NOT EXISTS
FOR (node:Collection)
ON (node.label);

CREATE INDEX annotation_type_index IF NOT EXISTS
FOR (node:Annotation)
ON (node.type);

CREATE INDEX collection_uuid_index IF NOT EXISTS
FOR (node:Collection)
ON (node.uuid);

CREATE INDEX collection_identifier_index IF NOT EXISTS
FOR (node:Collection)
ON (node.identifier);

CREATE INDEX annotation_uuid_index IF NOT EXISTS
FOR (node:Annotation)
ON (node.uuid);

CREATE INDEX annotation_value_index IF NOT EXISTS
FOR (node:Annotation)
ON (node.value);

CREATE INDEX annotation_url_index IF NOT EXISTS
FOR (node:Annotation)
ON (node.url);

CREATE INDEX place_uuid_index IF NOT EXISTS
FOR (node:Place)
ON (node.uuid);

CREATE INDEX place_original_index IF NOT EXISTS
FOR (node:Place)
ON (node.original);

CREATE INDEX place_normalized_german_index IF NOT EXISTS
FOR (node:Place)
ON (node.normalizedGerman);

CREATE INDEX lemma_lemma_index IF NOT EXISTS
FOR (node:Lemma)
ON (node.lemma);

CREATE INDEX literature_literatur_index IF NOT EXISTS
FOR (node:Literature)
ON (node.literatur);

CREATE INDEX literature_url_index IF NOT EXISTS
FOR (node:Literature)
ON (node.url);

CREATE INDEX reference_reference_index IF NOT EXISTS
FOR (node:Reference)
ON (node.reference);

CREATE INDEX entity_xml_id_index IF NOT EXISTS
FOR (node:Entity)
ON (node.xmlId);

CREATE INDEX entity_node_id_index IF NOT EXISTS
FOR (node:Entity)
ON (node.nodeId);

CREATE INDEX entity_id_index IF NOT EXISTS
FOR (node:Entity)
ON (node.id);

CREATE INDEX entity_wikidata_id_index IF NOT EXISTS
FOR (node:Entity)
ON (node.wikidataId);

CREATE INDEX entity_normalized_german_index IF NOT EXISTS
FOR (node:Entity)
ON (node.normalizedGerman);

CREATE INDEX regesta_lat_long_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.latLong);

CREATE INDEX external_source_url_index IF NOT EXISTS
FOR (node:ExternalSource)
ON (node.url);

CREATE INDEX regesta_regid_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.regid);

CREATE INDEX regesta_register_id_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.registerId);

CREATE INDEX regesta_regesta_number_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.regestaNumber);

CREATE INDEX regesta_regesta_volume_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.regestaVolume);

CREATE INDEX regesta_orig_place_of_issue_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.origPlaceOfIssue);

CREATE INDEX regesta_start_date_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.startDate);

CREATE INDEX regesta_end_date_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.endDate);

CREATE INDEX regesta_title_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.title);

CREATE INDEX regesta_incipit_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.incipit);

CREATE INDEX regesta_original_date_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.originalDate);

CREATE INDEX regesta_external_links_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.externalLinks);

CREATE INDEX regesta_exchange_identifier_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.exchangeIdentifier);

CREATE INDEX regesta_urn_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.urn);

CREATE INDEX regesta_pid_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.pid);

CREATE INDEX regesta_uid_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.uid);

CREATE INDEX regesta_uuid_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.uuid);

CREATE INDEX regesta_sorting_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.sorting);

CREATE INDEX regesta_bandpk_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.bandpk);

CREATE INDEX regesta_laufendenummer_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.laufendenummer);

CREATE INDEX regesta_regestennummernorm_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.regestennummernorm);

CREATE INDEX regesta_identifier_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.identifier);

CREATE INDEX regesta_date_index IF NOT EXISTS
FOR (node:Regesta)
ON (node.date);

CREATE INDEX collection_type_index IF NOT EXISTS
FOR (node:Collection)
ON (node.type);

CREATE INDEX collection_department_index IF NOT EXISTS
FOR (node:Collection)
ON (node.department);

CREATE INDEX entity_parent_id_index IF NOT EXISTS
FOR (node:Entity)
ON (node.parentId);

CREATE INDEX entity_department_index IF NOT EXISTS
FOR (node:Entity)
ON (node.department);

CREATE INDEX entity_volume_index IF NOT EXISTS
FOR (node:Entity)
ON (node.volume);

CREATE INDEX text_uuid_index IF NOT EXISTS
FOR (node:Text)
ON (node.uuid);

CREATE INDEX entity_label_norm_index IF NOT EXISTS
FOR (node:Entity)
ON (node.labelNorm);

CREATE INDEX entity_orig_label_index IF NOT EXISTS
FOR (node:Entity)
ON (node.origLabel);

// [STEP 000] clean the regesta data and import all Regesta nodes
LOAD CSV WITH HEADERS FROM 'https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/data/regesta-csv/RI_alles.csv' AS line FIELDTERMINATOR '\t'
WITH line
// WHERE line.identifier =~ 'RI III,2,3 .*' // Regesten Heinrich IV.
// WHERE line.identifier =~ 'RI IV,4,4,.*' // RI 4 Papstregesten
// WHERE line.identifier =~ 'RI IV,2,.*' // Regesten Barbarossa
// WHERE line.identifier =~ "RI VI,4,.*" OR line.identifier =~ ".*Regg\. Heinrich VII\. n\..*" // Regesten Heinrich 7
// WHERE line.identifier STARTS WITH '[RI VII] ' // Regesten Ludwik der Bayer
// WHERE line.identifier STARTS WITH "[RI XIII]" OR  line.identifier STARTS WITH "Chmel" // Regesten Friedrich 3
WITH line
CALL {
  WITH line
  CREATE
    (r:Collection:Regesta
      {
        uuid: randomUUID(),
        label:
          coalesce(nullif(trim(line.`title`), ''), '-') +
          ' - ' +
          coalesce(nullif(trim(line.`identifier`), ''), '-') +
          ' ' +
          coalesce(nullif(trim(line.`date_string`), ''), '-') +
          ', ' +
          coalesce(nullif(trim(line.`locality_string`), ''), '-'),
        regid: line.persistent_identifier,
        origPlaceOfIssue: line.locality_string,
        startDate: line.start_date,
        endDate: line.end_date,
        externalLinks: line.external_links,
        archivalHistory: line.archival_history,
        exchangeIdentifier: line.exchange_identifier,
        urn: line.urn,
        pid: line.pid,
        uid: line.uid,
        sorting: line.sorting,
        bandpk: line.bandpk,
        laufendenummer: toInteger(line.laufendenummer),
        regestennummernorm: line.regestennummernorm,
        identifier: line.identifier,
        date: line.date_string
      })

  WITH
    r,
    line,
    CASE
      WHEN
        line.`title` IS NOT NULL
        THEN {l: 'title', lbl: ['Title'], t: line.`title`}
    END AS d0,
    CASE
      WHEN
        line.`identifier` IS NOT NULL
        THEN {l: 'identifier', lbl: ['Identifier'], t: line.`identifier`}
    END AS d1,
    CASE
      WHEN
        line.`date_string` IS NOT NULL
        THEN {l: 'date', lbl: ['Date'], t: line.`date_string`}
    END AS d2,
    CASE
      WHEN
        line.`locality_string` IS NOT NULL
        THEN
          {l: 'placeOfIssue', lbl: ['PlaceOfIssue'], t: line.`locality_string`}
    END AS d3,
    CASE
      WHEN
        line.`summary` IS NOT NULL
        THEN {l: 'summary', lbl: ['Summary'], t: line.`summary`}
    END AS d4,
    CASE
      WHEN
        line.`original_date` IS NOT NULL
        THEN {l: 'originalDate', lbl: ['OriginalDate'], t: line.`original_date`}
    END AS d5,
    CASE
      WHEN
        line.`verso_note` IS NOT NULL
        THEN {l: 'versoNote', lbl: ['VersoNote'], t: line.`verso_note`}
    END AS d6,
    CASE
      WHEN
        line.`witnesses` IS NOT NULL
        THEN {l: 'witnesses', lbl: ['Witnesses'], t: line.`witnesses`}
    END AS d7,
    CASE
      WHEN
        line.`incipit` IS NOT NULL
        THEN {l: 'incipit', lbl: ['Incipit'], t: line.`incipit`}
    END AS d8,
    CASE
      WHEN
        line.`clerk` IS NOT NULL
        THEN {l: 'clerk', lbl: ['Clerk'], t: line.`clerk`}
    END AS d9,
    CASE
      WHEN
        line.`recipient` IS NOT NULL
        THEN {l: 'recipient', lbl: ['Recipient'], t: line.`recipient`}
    END AS d10,
    CASE
      WHEN
        line.`chancellor` IS NOT NULL
        THEN {l: 'chancellor', lbl: ['Chancellor'], t: line.`chancellor`}
    END AS d11,
    CASE
      WHEN
        line.`signature` IS NOT NULL
        THEN {l: 'signature', lbl: ['Signature'], t: line.`signature`}
    END AS d12,
    CASE
      WHEN
        line.`signature_addition` IS NOT NULL
        THEN
          {
            l: 'signatureAddition',
            lbl: ['SignatureAddition'],
            t: line.`signature_addition`
          }
    END AS d13,
    CASE
      WHEN
        line.`archival_history` IS NOT NULL
        THEN
          {
            l: 'archivalHistory',
            lbl: ['ArchivalHistory'],
            t: line.`archival_history`
          }
    END AS d14,
    CASE
      WHEN
        line.`literature` IS NOT NULL
        THEN {l: 'literature', lbl: ['Literature'], t: line.`literature`}
    END AS d15,
    CASE
      WHEN
        line.`commentary` IS NOT NULL
        THEN {l: 'commentary', lbl: ['Commentary'], t: line.`commentary`}
    END AS d16,
    CASE
      WHEN
        line.`annotations` IS NOT NULL
        THEN {l: 'annotations', lbl: ['Annotations'], t: line.`annotations`}
    END AS d17,
    CASE
      WHEN
        line.`footnotes` IS NOT NULL
        THEN {l: 'footnotes', lbl: ['Footnotes'], t: line.`footnotes`}
    END AS d18

  WITH
    r,
    [
      x IN
      [
        d0,
        d1,
        d2,
        d3,
        d4,
        d5,
        d6,
        d7,
        d8,
        d9,
        d10,
        d11,
        d12,
        d13,
        d14,
        d15,
        d16,
        d17,
        d18
      ]
      WHERE x IS NOT NULL
    ] AS defs

  CALL {
    WITH r, defs
    UNWIND range(0, size(defs) - 1) AS i
    WITH r, defs[i] AS def, i

    // hochgestellte zeichen umklammern
    WITH
      r,
      def,
      i,
      apoc.text.replace(def.t, '<sup>(.*?)</sup>', '<sup>[$1]</sup>') AS textWithSuperscript

    // Nach jedem Listenelement einen Zeilenumbruch einfügen
    WITH
      r,
      def,
      i,
      apoc.text.replace(textWithSuperscript, '</li>', '</li>\n') AS formatedListsText

    // html Kommentare entfernen
    WITH
      r,
      def,
      i,
      apoc.text.replace(formatedListsText, '(?s)<!--.*?(-->|$)', '') AS rmHtmlCommentText

    // kaputte span elemente entfernen
    WITH
      r,
      def,
      i,
      apoc.text.replace(rmHtmlCommentText, '</</span>', '</span>') AS text

    CREATE (c:Content:Text {uuid: randomUUID(), label: def.l, text: text})
    CREATE (c)-[:PART_OF]->(r)
    WITH c, def
    SET c: $ (def.lbl)
    RETURN collect(c) AS nodes
  }

  WITH nodes
  UNWIND range(0, size(nodes) - 2) AS j
  WITH nodes[j] AS a, nodes[j + 1] AS b
  CREATE
    (a)-[:HAS_ANNOTATION]->
    (:Annotation:Next {uuid: randomUUID(), label: 'next', type: 'next'})-
      [:REFERS_TO]->
    (b)
} IN TRANSACTIONS OF 100 ROWS;

// Regestennummer einzeln erstellen
MATCH (reg:Regesta)
CALL (reg) {
  UNWIND apoc.text.regexGroups(reg.identifier, '.* n\\. (\\S+)$') AS n
  SET reg.regestaNumber = n[1]
} IN TRANSACTIONS OF 1000 ROWS;

// External Links erstellen
MATCH (reg:Regesta)
WHERE reg.externalLinks CONTAINS 'link'
WITH reg
CALL (reg) {
  UNWIND
    apoc.text.regexGroups(
      reg.externalLinks,
      '<link (\\S*?)( - \\S*?)>(.*?)</link>'
    ) AS link
  MERGE (ref:Annotation {url: link[1], type: "ri:externalLink"})
    ON CREATE SET ref :RegestaAnnotation, ref.url_title = link[3]
  MERGE (reg)-[:HAS_ANNOTATION]->(ref)
} IN TRANSACTIONS OF 1000 ROWS;

MATCH (reg:Regesta)
WHERE reg.startDate =~ '^\\d{3}-\\d{2}-\\d{2}$'
SET reg.startDate = '0' + reg.startDate;

MATCH (reg:Regesta)
WHERE reg.endDate =~ '^\\d{3}-\\d{2}-\\d{2}$'
SET reg.endDate = '0' + reg.endDate;

// Falsche Datumsangaben finden
MATCH (reg:Regesta)
WHERE
  reg.startDate IS NOT NULL AND NOT reg.startDate =~ '^\\d{4}-\\d{2}-\\d{2}$'
SET reg.startDateWrong = reg.startDate, reg.startDate = '2021-01-01';

// Falsch formatierte endDate-Werte abfangen
MATCH (reg:Regesta)
WHERE reg.endDate IS NOT NULL AND NOT reg.endDate =~ '^\\d{4}-\\d{2}-\\d{2}$'
SET reg.endDateWrong = reg.endDate, reg.endDate = '2021-01-01';

// Falsche startDate-Werte finden und ersetzen
MATCH (reg:Regesta)
WHERE reg.startDate IS NOT NULL AND reg.startDate =~ '^\\d{4}-\\d{2}-\\d{2}$'

WITH
  reg,
  toInteger(substring(reg.startDate, 0, 4)) AS year,
  toInteger(substring(reg.startDate, 5, 2)) AS month,
  toInteger(substring(reg.startDate, 8, 2)) AS day

WITH
  reg,
  year,
  month,
  day,
  CASE
    WHEN month IN [1, 3, 5, 7, 8, 10, 12] THEN 31
    WHEN month IN [4, 6, 9, 11] THEN 30
    WHEN
      month = 2 AND (year % 400 = 0 OR (year % 4 = 0 AND year % 100 <> 0))
      THEN 29
    WHEN month = 2 THEN 28
    ELSE 0
  END AS maxDay

WHERE month < 1 OR month > 12 OR day < 1 OR day > maxDay

SET reg.startDateWrong = reg.startDate, reg.startDate = '2021-01-01';

MATCH (reg:Regesta)
WHERE reg.endDate IS NOT NULL AND reg.endDate =~ '^\\d{4}-\\d{2}-\\d{2}$'

WITH
  reg,
  toInteger(substring(reg.endDate, 0, 4)) AS year,
  toInteger(substring(reg.endDate, 5, 2)) AS month,
  toInteger(substring(reg.endDate, 8, 2)) AS day

WITH
  reg,
  year,
  month,
  day,
  CASE
    WHEN month IN [1, 3, 5, 7, 8, 10, 12] THEN 31
    WHEN month IN [4, 6, 9, 11] THEN 30
    WHEN
      month = 2 AND (year % 400 = 0 OR (year % 4 = 0 AND year % 100 <> 0))
      THEN 29
    WHEN month = 2 THEN 28
    ELSE 0
  END AS maxDay

WHERE month < 1 OR month > 12 OR day < 1 OR day > maxDay

SET reg.endDateWrong = reg.endDate, reg.endDate = '2021-01-01';

// Datum als Neo4j-Datum ergänzen
// Datum als Neo4j-Datum ergänzen
MATCH (n:Regesta)
WITH n
CALL (n) {
  SET
    n.isoStartDate =
      CASE
        WHEN n.startDate IS NOT NULL THEN date(n.startDate)
        ELSE null
      END,
    n.isoEndDate =
      CASE
        WHEN n.endDate IS NOT NULL THEN date(n.endDate)
        ELSE null
      END
} IN TRANSACTIONS OF 100 ROWS;

// URLs für Regesten erstellen
MATCH (reg:Regesta)
WHERE reg.regid IS NOT NULL
WITH reg
CALL (reg) {
  SET reg.url = ("http://www.regesta-imperii.de/id/" + reg.regid)
} IN TRANSACTIONS OF 100 ROWS;

MATCH (reg:Regesta)
WHERE reg.persistentIdentifier IS NOT NULL
WITH reg
CALL (reg) {
  SET reg.url = ("http://www.regesta-imperii.de/id/" + reg.persistentIdentifier)
} IN TRANSACTIONS OF 100 ROWS;

// Literaturnetzwerk erstellen
MATCH (r:Regesta)
WHERE r.archivalHistory CONTAINS "link"
WITH r
CALL (r) {
  UNWIND
    apoc.text.regexGroups(
      r.archivalHistory,
      "<link (http.*?=)(.+?)>(.+?)<\\/link>"
    ) AS link
  MERGE (ref:Annotation {url: link[1] + link[2], type: 'ri:literature'})
    ON CREATE SET
      ref :RegestaAnnotation,
      ref.uuid = randomUUID(),
      ref.url_label = link[3],
      ref.url_title = link[2]
  MERGE (r)-[:HAS_ANNOTATION]->(ref)
} IN TRANSACTIONS OF 1000 ROWS;


// [STEP 001] RI-Ausstellungsorte-geo erstellen
LOAD CSV WITH HEADERS FROM 'https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/data/places/RI-Places.csv' AS line
WITH line
WHERE line.normalisiertDeutsch IS NOT NULL
WITH line
CALL (line) {
  MATCH (r:Regesta {origPlaceOfIssue: line.Original})
  MERGE (p:Place {normalizedGerman: line.normalisiertDeutsch})
    ON CREATE SET
      p :Entity,
      p.uuid = randomUUID(),
      p.label = line.normalisiertDeutsch
  SET
    p.longitude = line.Long,
    p.latitude = line.Lat,
    p.wikidataId = line.wikidataId,
    p.latLong = line.Lat + ',' + line.Long,
    p.nLatLong =
      point({latitude: tofloat(p.latitude), longitude: tofloat(p.longitude)})

  WITH r, p, line
  CREATE
    (r)-[:HAS_ANNOTATION]->
    (a:Annotation:RegestaAnnotation
      {uuid: randomUUID(), label: 'placeOfIssue', type: 'ri:placeOfIssue'})-
      [:REFERS_TO]->
    (p)
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
CALL
  apoc.load.xml(
    "https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/archive/RegestenUndRegister/abt-06/ri_06,4-heinrich_vii_gesamtregister/xml/gesamtregister.xml?inline=false",
    "/document/body/section/Stufe0",
    {},
    false
  )
  YIELD value AS s0

WITH
  s0,
  [
    c IN coalesce(s0._children, [])
    WHERE c._type STARTS WITH "Stufe" AND c.id IS NOT NULL
  ] AS children

WITH [{raw: s0, parentId: null}] + [c IN children | {raw: c, parentId: s0.id}] AS rows

UNWIND rows AS row
WITH row
WHERE NOT row.raw.typ STARTS WITH 'xref'
CALL (row) {
  WITH row.raw AS raw, row.parentId AS parentId

  WITH
    raw,
    parentId,
    head([c IN coalesce(raw._children, []) WHERE c._type = "Inhalt"]) AS inhalt,
    head(
      [
        c IN coalesce(raw._children, [])
        WHERE c._type = "idno" AND c.type = "wikidata"
      ]) AS wikidata,
    head(
      [
        c IN coalesce(raw._children, [])
        WHERE c._type = "idno" AND c.type = "geonames"
      ]) AS geonames

  WITH
    raw,
    parentId,
    wikidata,
    geonames,
    inhalt,
    coalesce(inhalt._children, []) AS contentParts

  WITH raw, parentId, wikidata, geonames

  MERGE (i:Entity {id: raw.id})
    ON CREATE SET i.uuid = randomUUID()
  SET
    i.parentId = parentId,
    i.lat =
      CASE
        WHEN raw.lat IS NULL THEN null
        ELSE toFloat(raw.lat)
      END,
    i.long =
      CASE
        WHEN coalesce(raw.long, raw.lon) IS NULL THEN null
        ELSE toFloat(coalesce(raw.long, raw.lon))
      END,
    i.wikidataId = wikidata._text,
    i.geonames = geonames._text,
    i.type = raw.typ,
    i._importTest = "H7"
} IN TRANSACTIONS OF 500 ROWS;

LOAD CSV FROM "https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/archive/RegestenUndRegister/abt-06/ri_06,4-heinrich_vii_gesamtregister/xml/gesamtregister.xml?inline=false" AS row FIELDTERMINATOR '\u0000'
WITH collect(row[0]) AS lines
WITH
  reduce(
    xml = '',
    line IN lines | xml +
      CASE
        WHEN xml = '' THEN ''
        ELSE '\n'
      END + line) AS xml

MATCH (e:Entity)
WHERE e.id STARTS WITH "RI006-004_"
WITH
  collect({
    id: e.id,
    rawInhaltXml:
      apoc.text.regexGroups(
        xml,
        '(?s)<Stufe[0-9][^>]*\\sid="' +
        e.id +
        '"[^>]*>.*?<Inhalt>(.*?)</Inhalt>'
      )
  }) AS rows

UNWIND rows AS row
WITH row
WHERE size(row.rawInhaltXml) > 0

WITH collect({id: row.id, rawInhaltXml: row.rawInhaltXml[0][1]}) AS rows

CALL (rows) {
  UNWIND rows AS row

  MATCH (e:Entity {id: row.id})
  WITH
    e,
    trim(apoc.text.replace(
      apoc.text.replace(
        row.rawInhaltXml,
        '(?s)<Regestennummer>.*?</Regestennummer>',
        ''
      ),
      '\\s+',
      ' '
    )) AS label

  SET
    e.label = label,
    e.origLabel = coalesce(e.origLabel, label),
    e._labelImport = "raw-inhalt-without-regestennummer"
} IN TRANSACTIONS OF 500 ROWS;

CALL
  apoc.load.xml(
    "https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/archive/RegestenUndRegister/abt-06/ri_06,4-heinrich_vii_gesamtregister/xml/gesamtregister.xml?inline=false",
    "/document/body/section/Stufe0",
    {},
    false
  )
  YIELD value AS s0

UNWIND
  [
    c IN coalesce(s0._children, [])
    WHERE c._type STARTS WITH "Stufe" AND c.id IS NOT NULL
  ] AS child

WITH child.id AS childId, s0.id AS parentId
CALL (childId, parentId) {
  MATCH (child:Entity {id: childId})
  MATCH (parent:Entity {id: parentId})
  MERGE
    (child)-[:HAS_ANNOTATION]->
    (a:Annotation {label: 'ri:isSubOf', type: 'ri:isSubOf'})-[:REFERS_TO]->
    (parent)
    ON CREATE SET a.uuid = randomUUID()
} IN TRANSACTIONS OF 500 ROWS;

CALL
  apoc.load.xml(
    "https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/archive/RegestenUndRegister/abt-06/ri_06,4-heinrich_vii_gesamtregister/xml/gesamtregister.xml?inline=false",
    "/document/body/section/Stufe0",
    {},
    false
  )
  YIELD value AS s0

WITH
  s0,
  [
    c IN coalesce(s0._children, [])
    WHERE c._type STARTS WITH "Stufe" AND c.id IS NOT NULL
  ] AS children

WITH [s0] + children AS stufen
UNWIND stufen AS stufe

WITH
  stufe,
  head(
    [
      c IN coalesce(stufe._children, [])
      WHERE valueType(c) = "MAP" AND c._type = "Inhalt"
    ]) AS inhalt

UNWIND
  [
    r IN coalesce(inhalt._children, [])
    WHERE valueType(r) = "MAP" AND r._type = "Regestennummer"
  ] AS regestennummer

UNWIND
  [
    nr IN coalesce(regestennummer._children, [])
    WHERE valueType(nr) = "MAP" AND nr._type = "nr"
  ] AS nr

WITH
  stufe.id AS entityId,
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
  WHERE r.identifier STARTS WITH "RI VI," AND r.regestaNumber = regestaNumber
  CREATE
    (i)-[:HAS_ANNOTATION]->
    (a:Annotation {label: 'ri:appearsIn', type: 'ri:appearsIn', role: relType})-
      [:REFERS_TO]->
    (r)
  SET
    a.label = typeMap[relType],
    a.sourceType = sourceType,
    a.regestaNumber = regestaNumber
} IN TRANSACTIONS OF 500 ROWS;

// Entity mit weiteren Labels ausstatten
MATCH (e:Entity)
WHERE e.type = 'person'
WITH e
SET e :Person
RETURN e;

MATCH (e:Entity)
WHERE e.type = 'ereignis'
WITH e
SET e :Event
RETURN e;

MATCH (e:Entity)
WHERE e.type = 'sache'
WITH e
SET e :Thing
RETURN e;

MATCH (e:Entity)
WHERE e.type = 'ort'
WITH e
SET e :Place
RETURN e;

// [STEP 003] RI13 Entities
// RegID und HeftId für F3-Hefte als Property erstellen
MATCH (reg:Regesta)
WHERE
  NOT reg.identifier CONTAINS 'Supplement' AND
  reg.identifier STARTS WITH "[RI XIII]"
UNWIND apoc.text.regexGroups(reg.identifier, ".* (\\S+) n. (\\S+).*") AS link
SET reg.registerId = ("#" + link[1] + "-" + link[2])
SET reg.heftId = link[1]
SET reg.shortNumber = ("#" + link[1] + "-" + link[2]);

// RegID und HeftId für Chmel-Regesten als Property erstellen
MATCH (reg:Regesta)
WHERE reg.identifier STARTS WITH "Chmel, Anh"
UNWIND apoc.text.regexGroups(reg.identifier, ".*Chmel, Anh. n. (\\S+)") AS link
SET reg.registerId = ("#0" + "-" + link[1])
SET reg.heftId = 'CHMEL'
SET reg.shortNumber = ("#0" + "-" + link[1]);

// RegID und HeftId für Chmel-Anhang-Regesten als Property erstellen
MATCH (reg:Regesta)
WHERE reg.identifier STARTS WITH "Chmel "
UNWIND apoc.text.regexGroups(reg.identifier, ".*Chmel n. (\\S+)") AS link
SET reg.registerId = ("#0" + "-" + link[1])
SET reg.heftId = 'CHMEL'
SET reg.shortNumber = ("#0" + "-" + link[1]);

// IndexEntries erstellen
CYPHER runtime = slotted
CALL
  apoc.load.xml(
    'https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/data/indexes/RI_013.xml?inline=false',
    '',
    {},
    true
  )
  YIELD value AS xmlFile
//CALL apoc.load.xml('https://exist.regesta-imperii.de/exist/rest/apps/rixqlib/xql/getRegister.xql?registerName=013','',{}, true) yield value as xmlFile
UNWIND xmlFile._register AS wdata
CREATE
  (e:Entity
    {
      uuid: randomUUID(),
      xmlId: wdata.id,
      type: wdata.typ,
      parentId: wdata.parent,
      latitude: wdata.lat,
      longitude: wdata.lon,
      wikidataId: wdata.wikidata,
      geonames: wdata.geonames
    })
RETURN count(e);

// Label bei den IndexEntries ergänzen
CYPHER runtime = slotted
CALL
  apoc.load.xml(
    'https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/data/indexes/RI_013.xml',
    '',
    {},
    true
  )
  YIELD value AS xmlFile

UNWIND xmlFile._register AS lemma

WITH
  lemma.id AS xmlId,
  [x IN lemma._lemma WHERE x._type = "label" | x._text][0] AS htmlLabel,
  [
    y IN [x IN lemma._lemma WHERE x._type = "numbers" | x._numbers][0]
    WHERE y.type = "nennung"
    | y._text
  ] AS nennung,
  [
    y IN [x IN lemma._lemma WHERE x._type = "numbers" | x._numbers][0]
    WHERE y.type = "empfaenger"
    | y._text
  ] AS empfaenger
MATCH (i:Entity {xmlId: xmlId})
WITH
  i,
  htmlLabel,
  trim(apoc.text.replace(htmlLabel, '<[^>]*>', '')) AS cleanLabel
SET
  i.htmlLabel = htmlLabel,
  i.htmlOrigLabel = htmlLabel,
  i.label = cleanLabel,
  i.origLabel = cleanLabel;

// wikidataId ergänzen
CYPHER runtime = slotted
CALL
  apoc.load.xml(
    'https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/data/indexes/RI_013.xml',
    '',
    {},
    true
  )
  YIELD value AS xmlFile
//CALL apoc.load.xml('https://exist.regesta-imperii.de/exist/rest/apps/rixqlib/xql/getRegister.xql?registerName=013','',{}, true) yield value as xmlFile
UNWIND xmlFile._register AS lemma
WITH
  lemma.id AS xmlId,
  [x IN lemma._lemma WHERE x._type = 'idno' AND x.type = 'wikidata' | x._text][0] AS wikidataId
WITH wikidataId, xmlId
WHERE wikidataId IS NOT NULL
MATCH (i:Entity {xmlId: xmlId})
SET i.wikidataId = wikidataId
RETURN count(i);

// APPEARS_IN erstellen
CYPHER runtime = slotted
CALL
  apoc.load.xml(
    'https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/data/indexes/RI_013.xml?inline=false',
    '',
    {},
    true
  )
  YIELD value AS xmlFile
UNWIND xmlFile._register AS wdata
UNWIND wdata._lemma AS lemma
UNWIND lemma._numbers AS number
MATCH (e:Entity {xmlId: wdata.id})
MATCH (r:Regesta {registerId: number._text})
WHERE
  r.identifier STARTS WITH "Chmel, Anh" OR
  r.identifier STARTS WITH "[RI XIII]" OR
  r.identifier STARTS WITH "Chmel "
WITH wdata, e, r, number
// WHERE number.type = "nennung"
CREATE
  (e)-[:HAS_ANNOTATION]->
  (a:Annotation
    {
      label: 'ri:appearsIn',
      type: 'ri:appearsIn',
      role: number.type,
      uuid: randomUUID()
    })-
    [:REFERS_TO]->
  (r)
RETURN count(a);

// [STEP 004] Heinrich IV Entities
// registerId erstellen
MATCH (reg:Regesta)
UNWIND apoc.text.regexGroups(reg.identifier, "RI III,2,3 n. (\\S+)") AS link
SET reg.registerId = link[1];

// entitäten erstellen
CYPHER runtime = slotted
CALL
  apoc.load.xml(
    'https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/archive/RegestenUndRegister/abt-03/ri_03,2,3-heinrich_iv/Register/RI_003-002.xml',
    '',
    {},
    true
  )
  YIELD value AS xmlFile
UNWIND xmlFile._register AS wdata
CREATE
  (e:Entity
    {
      xmlId: wdata.id,
      type: wdata.typ,
      parentId: wdata.parent,
      lat: wdata.lat,
      long: wdata.lon,
      wikidataId: wdata.wikidata,
      geonames: wdata.geonames,
      state: 'h4 import'
    })
RETURN count(e);

// Label bei den Entitäten ergänzen
CYPHER runtime = slotted
CALL
  apoc.load.xml(
    'https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/archive/RegestenUndRegister/abt-03/ri_03,2,3-heinrich_iv/Register/RI_003-002.xml',
    '',
    {},
    true
  )
  YIELD value AS xmlFile
UNWIND xmlFile._register AS lemma
WITH
  lemma.id AS xmlId,
  [x IN lemma._lemma WHERE x._type = "label" | x._text][0] AS label,
  [
    y IN [x IN lemma._lemma WHERE x._type = "numbers" | x._numbers][0]
    WHERE y.type = "nennung"
    | y._text
  ] AS nennung,
  [
    y IN [x IN lemma._lemma WHERE x._type = "numbers" | x._numbers][0]
    WHERE y.type = "empfaenger"
    | y._text
  ] AS empfaenger
MATCH (i:Entity {xmlId: xmlId})
SET i.origLabel = label;

// wikidataId ergänzen
CYPHER runtime = slotted
CALL
  apoc.load.xml(
    'https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/archive/RegestenUndRegister/abt-03/ri_03,2,3-heinrich_iv/Register/RI_003-002.xml',
    '',
    {},
    true
  )
  YIELD value AS xmlFile
UNWIND xmlFile._register AS lemma
WITH
  lemma.id AS xmlId,
  [x IN lemma._lemma WHERE x._type = 'idno' AND x.type = 'wikidata' | x._text][0] AS wikidataId
WITH wikidataId, xmlId
WHERE wikidataId IS NOT NULL
MATCH (i:Entity {xmlId: xmlId})
SET i.wikidataId = wikidataId
RETURN count(i);

//IS_SUB_OF erstellen
MATCH (c:Entity {state: 'h4 import'}), (p:Entity {state: 'h4 import'})
WHERE c.parentId = p.xmlId
MERGE (c)-[r:IS_SUB_OF]->(p)
RETURN count(r);

// label erstellen
MATCH
  (e0:Entity {state: 'h4 import'})<-[:IS_SUB_OF]-
  (e1:Entity {state: 'h4 import'})
SET e1.label = e0.origLabel + ' // ' + e1.origLabel;
MATCH
  (e0:Entity {pathLength: '0', state: 'h4 import'})<-[:IS_SUB_OF]-
  (e1:Entity {state: 'h4 import'})<-[:IS_SUB_OF]-
  (e2:Entity {state: 'h4 import'})
SET e2.label = e0.origLabel + ' // ' + e1.origLabel + ' // ' + e2.origLabel;
MATCH
  (e0:Entity {pathLength: '0', state: 'h4 import'})<-[:IS_SUB_OF]-
  (e1:Entity {state: 'h4 import'})<-[:IS_SUB_OF]-
  (e2:Entity {state: 'h4 import'})<-[:IS_SUB_OF]-
  (e3:Entity {state: 'h4 import'})
SET
  e3.label =
    e0.origLabel +
    ' // ' +
    e1.origLabel +
    ' // ' +
    e2.origLabel +
    ' // ' +
    e3.origLabel;
MATCH
  (e0:Entity {pathLength: '0', state: 'h4 import'})<-[:IS_SUB_OF]-
  (e1:Entity {state: 'h4 import'})<-[:IS_SUB_OF]-
  (e2:Entity {state: 'h4 import'})<-[:IS_SUB_OF]-
  (e3:Entity {state: 'h4 import'})<-[:IS_SUB_OF]-
  (e4:Entity {state: 'h4 import'})
SET
  e4.label =
    e0.origLabel +
    ' // ' +
    e1.origLabel +
    ' // ' +
    e2.origLabel +
    ' // ' +
    e3.origLabel +
    ' // ' +
    e4.origLabel;
MATCH
  (e0:Entity {pathLength: '0', state: 'h4 import'})<-[:IS_SUB_OF]-
  (e1:Entity {state: 'h4 import'})<-[:IS_SUB_OF]-
  (e2:Entity {state: 'h4 import'})<-[:IS_SUB_OF]-
  (e3:Entity {state: 'h4 import'})<-[:IS_SUB_OF]-
  (e4:Entity {state: 'h4 import'})<-[:IS_SUB_OF]-
  (e5:Entity {state: 'h4 import'})
SET
  e5.label =
    e0.origLabel +
    ' // ' +
    e1.origLabel +
    ' // ' +
    e2.origLabel +
    ' // ' +
    e3.origLabel +
    ' // ' +
    e4.origLabel +
    ' // ' +
    e5.origLabel;
MATCH
  (e0:Entity {pathLength: '0', state: 'h4 import'})<-[:IS_SUB_OF]-
  (e1:Entity {state: 'h4 import'})<-[:IS_SUB_OF]-
  (e2:Entity {state: 'h4 import'})<-[:IS_SUB_OF]-
  (e3:Entity {state: 'h4 import'})<-[:IS_SUB_OF]-
  (e4:Entity {state: 'h4 import'})<-[:IS_SUB_OF]-
  (e5:Entity {state: 'h4 import'})<-[:IS_SUB_OF]-
  (e6:Entity {state: 'h4 import'})
SET
  e6.label =
    e0.origLabel +
    ' // ' +
    e1.origLabel +
    ' // ' +
    e2.origLabel +
    ' // ' +
    e3.origLabel +
    ' // ' +
    e4.origLabel +
    ' // ' +
    e5.origLabel +
    ' // ' +
    e6.origLabel;

// Haupteinträge mit label versehen
MATCH (e:Entity {state: 'h4 import'})
WHERE e.label IS NULL AND e.origLabel IS NOT NULL
SET e.label = e.origLabel;

// APPEARS_IN erstellen
CYPHER runtime = slotted
CALL
  apoc.load.xml(
    "https://gitlab.rlp.net/adwmainz/regesta-imperii/lab/regesta-imperii-data/-/raw/main/archive/RegestenUndRegister/abt-03/ri_03,2,3-heinrich_iv/Register/RI_003-002.xml",
    '',
    {},
    true
  )
  YIELD value AS xmlFile
UNWIND xmlFile._register AS wdata
UNWIND wdata._lemma AS lemma
UNWIND lemma._numbers AS number
MATCH (e:Entity {state: 'h4 import', xmlId: wdata.id})
MATCH (r:Regesta {identifier: 'RI III,2,3 n. ' + number._text})
WITH wdata, e, r, number
// WHERE number.type = "nennung"
CREATE
  (e)-[:HAS_ANNOTATION]->
  (a:Annotation
    {
      label: 'ri:appearsIn',
      type: 'ri:appearsIn',
      role: number.type,
      uuid: randomUUID()
    })-
    [:REFERS_TO]->
  (r)
RETURN count(a);

// Is Sub Of Annotation erstellen
MATCH
  (c:Entity {state: 'h4 import'})-[r:IS_SUB_OF]->(p:Entity {state: 'h4 import'})
MERGE
  (c)-[:HAS_ANNOTATION]->
  (a:Annotation {label: 'ri:isSubOf', type: 'ri:isSubOf'})-[:REFERS_TO]->
  (p)
  ON CREATE SET a.uuid = randomUUID()
DELETE r;

MATCH (c:Entity {state: 'h4 import'})
REMOVE c.state;

// [STEP 00?] Finale Anpassungen
//IS_SUB_OF erstellen
MATCH (i:Entity), (p:Entity)
WHERE i.parentId = p.xmlId
MERGE
  (i)-[:HAS_ANNOTATION]->
  (a:Annotation {label: 'ri:isSubOf', type: 'ri:isSubOf'})-[:REFERS_TO]->
  (p)
  ON CREATE SET a.uuid = randomUUID();

// Indexeinträge mit neo4j-Koordinaten der Ausstellungsorte versehen
MATCH (e:Entity)
WHERE e.latitude IS NOT NULL
SET
  e.nlatLong =
    point({latitude: tofloat(e.latitude), longitude: tofloat(e.longitude)});

// Indexeinträge mit kommagetrennten Koordinaten der Ausstellungsorte versehen
MATCH (e:Entity)
WHERE e.latitude IS NOT NULL
SET e.latLong = e.latitude + ',' + e.longitude;

// Entity label von html bereinigen
MATCH (i:Entity)
WITH
  i,
  i.label AS htmlLabel,
  i.origLabel AS htmlOrigLabel,
  trim(apoc.text.replace(i.label, '<[^>]*>', '')) AS cleanLabel,
  trim(apoc.text.replace(i.origLabel, '<[^>]*>', '')) AS cleanOrigLabel
SET
  i.htmlLabel = htmlLabel,
  i.htmlOrigLabel = htmlOrigLabel,
  i.label = cleanLabel,
  i.origLabel = cleanOrigLabel;


// Entity mit weiteren Labels ausstatten
MATCH (e:Entity)
WHERE e.type = 'person'
WITH e
SET e :Person
RETURN e;

MATCH (e:Entity)
WHERE e.type = 'ereignis'
WITH e
SET e :Event
RETURN e;

MATCH (e:Entity)
WHERE e.type = 'sache'
WITH e
SET e :Thing
RETURN e;

MATCH (e:Entity)
WHERE e.type = 'ort'
WITH e
SET e :Place
RETURN e;

// Registerstufen anlegen
MATCH
  (child:Entity)-[:HAS_ANNOTATION]->
  (:Annotation {type: 'ri:isSubOf'})-[:REFERS_TO]->
  (parent:Entity)
MERGE (child)-[:IS_SUB_OF]->(parent);

MATCH (n1:Entity)
SET n1.pathLength = 'zero';
MATCH (n1:Entity)
WHERE NOT (n1)-[:IS_SUB_OF]->(:Entity)
SET n1.pathLength = '0', n1.origLabel = n1.label;
MATCH p = (n1:Entity {pathLength: '0'})<-[r:IS_SUB_OF*..8]-(n2)
WHERE n2.pathLength = 'zero'
SET n2.pathLength = length(p);

MATCH (e0:Entity)<-[:IS_SUB_OF]-(e1:Entity)
SET e1.label = e0.origLabel + ' // ' + e1.origLabel;
MATCH
  (e0:Entity {pathLength: '0'})<-[:IS_SUB_OF]-
  (e1:Entity)<-[:IS_SUB_OF]-
  (e2:Entity)
SET e2.label = e0.origLabel + ' // ' + e1.origLabel + ' // ' + e2.origLabel;
MATCH
  (e0:Entity {pathLength: '0'})<-[:IS_SUB_OF]-
  (e1:Entity)<-[:IS_SUB_OF]-
  (e2:Entity)<-[:IS_SUB_OF]-
  (e3:Entity)
SET
  e3.label =
    e0.origLabel +
    ' // ' +
    e1.origLabel +
    ' // ' +
    e2.origLabel +
    ' // ' +
    e3.origLabel;
MATCH
  (e0:Entity {pathLength: '0'})<-[:IS_SUB_OF]-
  (e1:Entity)<-[:IS_SUB_OF]-
  (e2:Entity)<-[:IS_SUB_OF]-
  (e3:Entity)<-[:IS_SUB_OF]-
  (e4:Entity)
SET
  e4.label =
    e0.origLabel +
    ' // ' +
    e1.origLabel +
    ' // ' +
    e2.origLabel +
    ' // ' +
    e3.origLabel +
    ' // ' +
    e4.origLabel;
MATCH
  (e0:Entity {pathLength: '0'})<-[:IS_SUB_OF]-
  (e1:Entity)<-[:IS_SUB_OF]-
  (e2:Entity)<-[:IS_SUB_OF]-
  (e3:Entity)<-[:IS_SUB_OF]-
  (e4:Entity)<-[:IS_SUB_OF]-
  (e5:Entity)
SET
  e5.label =
    e0.origLabel +
    ' // ' +
    e1.origLabel +
    ' // ' +
    e2.origLabel +
    ' // ' +
    e3.origLabel +
    ' // ' +
    e4.origLabel +
    ' // ' +
    e5.origLabel;
MATCH
  (e0:Entity {pathLength: '0'})<-[:IS_SUB_OF]-
  (e1:Entity)<-[:IS_SUB_OF]-
  (e2:Entity)<-[:IS_SUB_OF]-
  (e3:Entity)<-[:IS_SUB_OF]-
  (e4:Entity)<-[:IS_SUB_OF]-
  (e5:Entity)<-[:IS_SUB_OF]-
  (e6:Entity)
SET
  e6.label =
    e0.origLabel +
    ' // ' +
    e1.origLabel +
    ' // ' +
    e2.origLabel +
    ' // ' +
    e3.origLabel +
    ' // ' +
    e4.origLabel +
    ' // ' +
    e5.origLabel +
    ' // ' +
    e6.origLabel;

MATCH (child:Entity)-[r:IS_SUB_OF]->(parent:Entity)
DETACH DELETE r;

//RI I DATENMODELL STIMMT NICHT ÜBEREIN
MATCH (r:Regesta)
WITH r, r.identifier AS identifier
WHERE identifier STARTS WITH "RI I n." OR identifier STARTS WITH "RI I,"
WITH
  r,
  "RI01 - Karolinger 751-918 (926/962)" AS department,
  CASE
    WHEN identifier STARTS WITH "RI I n." THEN "1 - Karolinger 751-918 (924)"
    WHEN
      identifier STARTS WITH "RI I,2"
      THEN "2 - Karl der Kahle 840 (823)-877, Lfg. 1-2: 840 (823)-869"
    WHEN
      identifier STARTS WITH "RI I,3"
      THEN
        "3 - Die Karolinger im Regnum Italiae 840-962 & Die burgundischen Regna: Niederburgund 855-940er Jahre"
    WHEN identifier STARTS WITH "RI I,4" THEN "4 - Papstregesten 800-911"
    ELSE "no volume"
  END AS volume
SET r.department = department
SET r.volume = coalesce(r.volume, [])
SET
  r.volume =
    CASE
      WHEN NOT volume IN r.volume THEN r.volume + volume
      ELSE r.volume
    END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);

//RI II DATENMODELL STIMMT NICHT ÜBEREIN
MATCH (r:Regesta)
WITH r, r.identifier AS identifier
WHERE identifier STARTS WITH "RI II,"
WITH
  r,
  "RI02 - Sächsisches Haus (919-1024)" AS department,
  CASE
    WHEN identifier STARTS WITH "RI II,5" THEN "5 - Papstregesten"
    ELSE "1-4 - Heinrich I., Otto I., Otto II., Otto III., Heinrich II."
  END AS volume
SET r.department = department
SET r.volume = coalesce(r.volume, [])
SET
  r.volume =
    CASE
      WHEN NOT volume IN r.volume THEN r.volume + volume
      ELSE r.volume
    END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);

//RI III
MATCH (r:Regesta)
WITH r, r.identifier AS identifier
WHERE identifier STARTS WITH "RI III,"
WITH
  r,
  "RI03 - Salisches Haus (1024-1125)" AS department,
  CASE
    WHEN identifier STARTS WITH "RI III,5" THEN "5 - Papstregesten 1024-1058"
    ELSE split(split(identifier, ' n. ')[0], 'RI III,')[1]
  END AS volume
SET r.department = department
SET r.volume = coalesce(r.volume, [])
SET
  r.volume =
    CASE
      WHEN NOT volume IN r.volume THEN r.volume + volume
      ELSE r.volume
    END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);

//RI IV
MATCH (r:Regesta)
WITH r, r.identifier AS identifier
WHERE identifier STARTS WITH "RI IV,"
WITH
  r,
  "RI04 - Lothar III. und ältere Staufer (1125-1197)" AS department,
  CASE
    WHEN identifier STARTS WITH "RI IV,1,1" THEN "1,1 - Lothar III."
    WHEN identifier STARTS WITH "RI IV,1,2" THEN "1,2 - Konrad III."
    WHEN identifier STARTS WITH "RI IV,2," THEN "2 - Friedrich I."
    WHEN identifier STARTS WITH "RI IV,3" THEN "3 - Heinrich VI."
    WHEN identifier STARTS WITH "RI IV,4,4," THEN "4,4 - Papstregesten"
    ELSE split(split(identifier, ' n. ')[0], 'RI IV,')[1]
  END AS volume
SET r.department = department
SET r.volume = coalesce(r.volume, [])
SET
  r.volume =
    CASE
      WHEN NOT volume IN r.volume THEN r.volume + volume
      ELSE r.volume
    END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);

//RI V
MATCH (r:Regesta)
WITH r, r.identifier AS identifier
WHERE identifier STARTS WITH "RI V,"
WITH
  r,
  "RI05 - Jüngere Staufer (1198-1272)" AS department,
  CASE
    WHEN identifier STARTS WITH "RI V,1," THEN "1 - Staufer, Kaiser und Könige"
    WHEN
      identifier STARTS WITH "RI V,2,"
      THEN "2 - Staufer, Päpste und Reichssachen"
    WHEN
      identifier STARTS WITH "RI V,4,6"
      THEN "4,6 - Staufer, Nachträge und Ergänzungen"
    WHEN
      identifier STARTS WITH "RI V,4,1"
      THEN "4,1 - Staufer, Nachträge zu Friedrich II. und Konrad IV."
    ELSE split(split(identifier, ' n. ')[0], 'RI V,')[1]
  END AS volume
SET r.department = department
SET r.volume = coalesce(r.volume, [])
SET
  r.volume =
    CASE
      WHEN NOT volume IN r.volume THEN r.volume + volume
      ELSE r.volume
    END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);

//RI VI
MATCH (r:Regesta)
WITH r, r.identifier AS identifier
WHERE identifier STARTS WITH "RI VI,"
WITH
  r,
  "RI06 - Rudolf I. - Heinrich VII. (1273-1313)" AS department,
  CASE
    WHEN
      identifier STARTS WITH "RI VI,4,"
      THEN "4 - Heinrich VII. 1288/1308-1313"
    WHEN identifier STARTS WITH "RI VI,1" THEN "1 - Rudolf I. 1273-1291"
    WHEN identifier STARTS WITH "RI VI,2" THEN "2 - Adolf von Nassau 1291-1298"
    ELSE split(split(identifier, ' n. ')[0], 'RI V,')[1]
  END AS volume
SET r.department = department
SET r.volume = coalesce(r.volume, [])
SET
  r.volume =
    CASE
      WHEN NOT volume IN r.volume THEN r.volume + volume
      ELSE r.volume
    END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);
MATCH (r:Regesta)
WHERE r.identifier STARTS WITH "[RIplus] Regg. Heinrich VII. n. "
WITH
  r,
  r.identifier AS identifier,
  "RI06 - Rudolf I. - Heinrich VII. (1273-1313)" AS department,
  "[RIplus] Regg. Heinrich VII." AS volume
MATCH (c1:Collection {type: "department", label: department})
SET r.department = department
SET r.volume = coalesce(r.volume, [])
SET
  r.volume =
    CASE
      WHEN NOT volume IN r.volume THEN r.volume + volume
      ELSE r.volume
    END
WITH r, volume, department, c1
//MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})
MERGE (c2)-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);

// [Regesta Habsburgica 3]
MATCH (r:Regesta)
WITH r, r.identifier AS identifier
WHERE identifier STARTS WITH "[Regesta Habsburgica 3]"
WITH
  r,
  "Regesta Habsburgica 3" AS department,
  CASE
    WHEN
      identifier STARTS WITH "[Regesta Habsburgica 3]"
      THEN "Friedrich der Schöne"
    ELSE split(split(identifier, ' n. ')[0], '[Regesta Habsburgica 3]')[1]
  END AS volume
SET r.department = department
SET r.volume = coalesce(r.volume, [])
SET
  r.volume =
    CASE
      WHEN NOT volume IN r.volume THEN r.volume + volume
      ELSE r.volume
    END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);

//RI VII Department
MATCH (r:Regesta)
WITH r, r.identifier AS identifier
WHERE identifier STARTS WITH "[RI VII]"
WITH
  r,
  "RI07" AS department,
  split(split(identifier, ' n. ')[0], ' H. ')[1] AS volume
SET r.department = department
SET r.volume = coalesce(r.volume, [])
SET
  r.volume =
    CASE
      WHEN NOT volume IN r.volume THEN r.volume + volume
      ELSE r.volume
    END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)

MERGE (r)-[:PART_OF]->(c2);

//RI VIII Department

MATCH (r:Regesta)
WITH r, r.identifier AS identifier
WHERE identifier STARTS WITH "RI VIII"
WITH r, "RI08" AS department, "1" AS volume
SET r.department = department
SET r.volume = coalesce(r.volume, [])
SET
  r.volume =
    CASE
      WHEN NOT volume IN r.volume THEN r.volume + volume
      ELSE r.volume
    END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)

MERGE (r)-[:PART_OF]->(c2);

//Regg. Pfalzgrafen 2 Department
MATCH (r:Regesta)
WITH r, r.identifier AS identifier
WHERE identifier STARTS WITH "[Regg. Pfalzgrafen 2]"
WITH r, "Pfalzgrafen 2" AS department, "1" AS volume
SET r.department = department
SET r.volume = coalesce(r.volume, [])
SET
  r.volume =
    CASE
      WHEN NOT volume IN r.volume THEN r.volume + volume
      ELSE r.volume
    END
MERGE (c1:Collection {type: "department", label: department})

MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)

MERGE (r)-[:PART_OF]->(c2);

//RI XI Department
MATCH (r:Regesta)
WITH r, r.identifier AS identifier
WHERE identifier STARTS WITH "RI XI,"
WITH r, "RI11" AS department, "1" AS volume
SET r.department = department
SET r.volume = coalesce(r.volume, [])
SET
  r.volume =
    CASE
      WHEN NOT volume IN r.volume THEN r.volume + volume
      ELSE r.volume
    END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);

MATCH (r:Regesta)
WITH r, r.identifier AS identifier
WHERE identifier STARTS WITH "RI XI Neubearb"
WITH
  r,
  "RI11" AS department,
  split(split(identifier, ' n. ')[0], 'RI XI ')[1] AS volume
SET r.department = department
SET r.volume = coalesce(r.volume, [])
SET
  r.volume =
    CASE
      WHEN NOT volume IN r.volume THEN r.volume + volume
      ELSE r.volume
    END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);

//RI XII Department
MATCH (r:Regesta)
WITH r, r.identifier AS identifier
WHERE identifier STARTS WITH "RI XII "
WITH r, "RI12" AS department, "1" AS volume
SET r.department = department
SET r.volume = coalesce(r.volume, [])
SET
  r.volume =
    CASE
      WHEN NOT volume IN r.volume THEN r.volume + volume
      ELSE r.volume
    END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);

//RI XIII
MATCH (r:Regesta)
WITH r, r.identifier AS identifier
WHERE identifier STARTS WITH "[RI XIII] "
WITH
  r,
  "RI13" AS department,
  CASE
    WHEN
      identifier STARTS WITH "[RI XIII] H."
      THEN split(split(identifier, ' n. ')[0], ' H. ')[1]
    ELSE split(split(identifier, ' n. ')[0], '[RI XIII] ')[1]
  END AS volume
SET r.department = department
SET r.volume = coalesce(r.volume, [])
SET
  r.volume =
    CASE
      WHEN NOT volume IN r.volume THEN r.volume + volume
      ELSE r.volume
    END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);
MATCH (r:Regesta)
WITH r, r.identifier AS identifier
WHERE identifier STARTS WITH "Chmel"
WITH r, "RI13" AS department, "Chmel" AS volume
SET r.department = department
SET r.volume = coalesce(r.volume, [])
SET
  r.volume =
    CASE
      WHEN NOT volume IN r.volume THEN r.volume + volume
      ELSE r.volume
    END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);

//RI XIV
MATCH (r:Regesta)
WITH r, r.identifier AS identifier
WHERE identifier STARTS WITH "RI XIV,"
WITH r, "RI14" AS department, "Maximilian I." AS volume
SET r.department = department
SET r.volume = coalesce(r.volume, [])
SET
  r.volume =
    CASE
      WHEN NOT volume IN r.volume THEN r.volume + volume
      ELSE r.volume
    END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);

// Collections uuids geben
MATCH (n:Collection)
WHERE n.uuid IS NULL
SET n.uuid = randomUUID();

// numberOfChilds wird ermittelt
MATCH (n:Entity)
OPTIONAL MATCH
  (n)<-[:REFERS_TO]-
  (:Annotation {type: "ri:isSubOf"})<-[:HAS_ANNOTATION]-
  (sub:Entity)
WITH n, COLLECT(sub) AS directChildren
CALL {
  WITH n
  MATCH
    (n)<-[:REFERS_TO]-
    (:Annotation {type: "ri:isSubOf"})<-[:HAS_ANNOTATION]-
    (sub:Entity)
  CALL
    apoc.path.subgraphNodes(
      sub,
      {relationshipFilter: "HAS_ANNOTATION>|<REFERS_TO", minLevel: 1}
    )
    YIELD node
  RETURN COUNT(DISTINCT node) AS totalSubEntities
}
SET n.numberOfChilds = totalSubEntities;

// Creates the labelNorm Annotation on all Entities. Here all HTML-Tags are removed.
MATCH (n:Entity)
WHERE n.labelNorm IS NULL
SET
  n.labelNorm =
    apoc.text.replace(
      n.label,
      '<(?:"[^"]*"[\'"]*|\'[^\']*\'[\'"]*|[^\'">])+>',
      ''
    )
RETURN COUNT(n);

WITH [
  {from: '?', to: 'Stufe_unclear'},
  {from: 'Null', to: 'Stufe_unclear'},
  {from: 'IndexEvent', to: 'Event'},
  {from: 'Rolle', to: 'Role'},
  {from: 'Person und b', to: 'Person'},
  {from: 'Person, <i>vgl. auch</i>', to: 'Person'},
  {from: 'Ort und 4 (vgl. Nachtrag Lief. III und IV)', to: 'Place'},
  {from: 'Ort und b', to: 'Place'},
  {from: 'Ort(vgl. Nachtrag Lief. IV)', to: 'Place'},
  {from: 'Ort. ─ Abt:', to: 'Place'},
  {from: 'Ort. ─ Edle:', to: 'Place'},
  {from: 'Ort°', to: 'Place'},
  {from: 'Xref//*', to: 'Xref'}
] AS renames

UNWIND renames AS m
MATCH (n:Entity)
WHERE m.from IN labels(n)
SET n: $ (m.to)
REMOVE n: $ (m.from)
RETURN count(*) AS changed;

MATCH (n:Entity)
UNWIND labels(n) AS lbl
WITH n, lbl
WHERE lbl STARTS WITH 'Xref//'
SET n :Xref
REMOVE n: $ (lbl)
RETURN count(*) AS changed;

//// Jede Entity mit Regesta verbinden
//CYPHER runtime = slotted
//MATCH (n:Entity)
//
//CALL (n) {
//  CALL
//    apoc.path.subgraphNodes(
//      n,
//      {
//        relationshipFilter: "REFERS_TO|HAS_ANNOTATION",
//        labelFilter: "+Entity|Annotation",
//        minLevel: 0,
//        maxLevel: 10,
//        bfs: false,
//        uniqueness: "NODE_GLOBAL"
//      }
//    )
//    YIELD node
//
//  WITH DISTINCT n, node
//
//  MATCH (node)-[:HAS_ANNOTATION]->(:Annotation)-[:REFERS_TO]->(rc)
//  WHERE
//    rc:Regesta OR (rc:Collection AND toLower(coalesce(rc.type, "")) = "regesta")
//
//  WITH DISTINCT n, rc
//
//  WHERE
//    NOT EXISTS {
//      MATCH
//        (n)-[:HAS_ANNOTATION]->
//        (:Annotation {type: "ri:appearsIn"})-[:REFERS_TO]->
//        (rc)
//    }
//
//  CREATE (a:Annotation {type: "ri:appearsIn", uuid: randomUUID()})
//
//  CREATE (n)-[:HAS_ANNOTATION]->(a)
//  CREATE (a)-[:REFERS_TO]->(rc)
//
//} IN TRANSACTIONS OF 50 ROWS;

MATCH (n:Entity)
WHERE n.htmlLabel IS NULL
SET n.htmlLabel = n.label
SET
  n.label =
    apoc.text.replace(
      n.label,
      '<(?:"[^"]*"[\'"]*|\'[^\']*\'[\'"]*|[^\'">])+>',
      ''
    )
RETURN COUNT(n);

MATCH
  (c1:Collection {type: "department"})<-[r:PART_OF]-
  (c2:Collection {type: "volume"})
SET c1 :Department, c2 :Volume;

MATCH (n:Entity)
CALL {
  WITH n
  UNWIND keys(n) AS key
  WITH n, key
  WHERE
    key <> 'uuid' AND
    key <> 'numberOfChilds' AND
    key <> 'label' AND
    key <> 'pathLength' AND
    NOT key STARTS WITH '_'

  CREATE (a:Annotation {uuid: randomUUID(), type: key, value: n[key]})
  MERGE (n)-[:HAS_ANNOTATION]->(a)
  REMOVE n[key]
} IN TRANSACTIONS OF 1000 ROWS;

RETURN count(*);

// NEXT Kanten zwischen Department Nodes
WITH [
  'RI01 - Karolinger 751-918 (926/962)',
  'RI02 - Sächsisches Haus (919-1024)',
  'RI03 - Salisches Haus (1024-1125)',
  'RI04 - Lothar III. und ältere Staufer (1125-1197)',
  'RI05 - Jüngere Staufer (1198-1272)',
  'RI06 - Rudolf I. - Heinrich VII. (1273-1313)',
  'Regesta Habsburgica 3',
  'RI07',
  'RI08',
  'Pfalzgrafen 2',
  'RI11',
  'RI12',
  'RI13',
  'RI14'
] AS departmentLabels
UNWIND range(0, size(departmentLabels) - 2) AS i

MATCH (c1:Collection {type: 'department', label: departmentLabels[i]})

MATCH (c2:Collection {type: 'department', label: departmentLabels[i + 1]})

MERGE (c1)-[:HAS_ANNOTATION]->(a:Annotation:Next {label: 'next', type: 'next'})
  ON CREATE SET a.uuid = randomUUID()

MERGE (a)-[:REFERS_TO]->(c2)

RETURN c1.label AS department, c2.label AS nextDepartment
ORDER BY i;

// NEXT Kanten zwischen Regesta Nodes
MATCH (v:Collection:Volume)
CALL (v) {
  MATCH (r:Regesta)-[:PART_OF]->(v)
  WHERE r.regestennummernorm IS NOT NULL

  WITH r
  ORDER BY toFloat(r.regestennummernorm)

  WITH collect(r) AS regesta
  UNWIND range(0, size(regesta) - 2) AS i

  WITH regesta[i] AS currentRegesta, regesta[i + 1] AS nextRegesta

  MERGE
    (currentRegesta)-[:HAS_ANNOTATION]->
    (a:Annotation:Next {label: 'next', type: 'next'})-[:REFERS_TO]->
    (nextRegesta)
    ON CREATE SET a.uuid = randomUUID()
} IN TRANSACTIONS OF 1 ROW;


