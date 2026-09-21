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
CREATE (r:Collection:Regesta {
  uuid:                 randomUUID(),
  label:
                        coalesce(nullif(trim(line.`title`), ''), '-') +
                        ' - ' +
                        coalesce(nullif(trim(line.`identifier`), ''), '-') +
                        ' ' +
                        coalesce(nullif(trim(line.`date_string`), ''), '-') +
                        ', ' +
                        coalesce(nullif(trim(line.`locality_string`), ''), '-'),
  regid:                line.persistent_identifier,
  origPlaceOfIssue:     line.locality_string,
  startDate:            line.start_date,
  endDate:              line.end_date,
  externalLinks:        line.external_links,
  archivalHistory:      line.archival_history,
  exchangeIdentifier:   line.exchange_identifier,
  urn:                  line.urn,
  pid:                  line.pid,
  uid:                  line.uid,
  sorting:              line.sorting,
  bandpk:               line.bandpk,
  laufendenummer:       toInteger(line.laufendenummer),
  regestennummernorm:   line.regestennummernorm,
  identifier:           line.identifier,
  date:                 line.date_string
})

WITH r, line,
     CASE WHEN line.`title`            IS NOT NULL THEN {l:'title',           lbl:['Title'],           t:line.`title`}            END AS d0,
     CASE WHEN line.`identifier`       IS NOT NULL THEN {l:'identifier',      lbl:['Identifier'],      t:line.`identifier`}       END AS d1,
     CASE WHEN line.`date_string`      IS NOT NULL THEN {l:'date',            lbl:['Date'],            t:line.`date_string`}      END AS d2,
     CASE WHEN line.`locality_string`  IS NOT NULL THEN {l:'placeOfIssue',    lbl:['PlaceOfIssue'],    t:line.`locality_string`}  END AS d3,
     CASE WHEN line.`summary`          IS NOT NULL THEN {l:'summary',         lbl:['Summary'],         t:line.`summary`}          END AS d4,
     CASE WHEN line.`original_date`    IS NOT NULL THEN {l:'originalDate',    lbl:['OriginalDate'],    t:line.`original_date`}    END AS d5,
     CASE WHEN line.`verso_note`       IS NOT NULL THEN {l:'versoNote',       lbl:['VersoNote'],       t:line.`verso_note`}       END AS d6,
     CASE WHEN line.`witnesses`        IS NOT NULL THEN {l:'witnesses',       lbl:['Witnesses'],       t:line.`witnesses`}        END AS d7,
     CASE WHEN line.`incipit`          IS NOT NULL THEN {l:'incipit',         lbl:['Incipit'],         t:line.`incipit`}          END AS d8,
     CASE WHEN line.`clerk`            IS NOT NULL THEN {l:'clerk',           lbl:['Clerk'],           t:line.`clerk`}            END AS d9,
     CASE WHEN line.`recipient`        IS NOT NULL THEN {l:'recipient',       lbl:['Recipient'],       t:line.`recipient`}        END AS d10,
     CASE WHEN line.`chancellor`       IS NOT NULL THEN {l:'chancellor',      lbl:['Chancellor'],      t:line.`chancellor`}       END AS d11,
     CASE WHEN line.`signature`        IS NOT NULL THEN {l:'signature',       lbl:['Signature'],       t:line.`signature`}        END AS d12,
     CASE WHEN line.`signature_addition` IS NOT NULL THEN {l:'signatureAddition', lbl:['SignatureAddition'], t:line.`signature_addition`} END AS d13,
     CASE WHEN line.`archival_history` IS NOT NULL THEN {l:'archivalHistory', lbl:['ArchivalHistory'], t:line.`archival_history`} END AS d14,
     CASE WHEN line.`literature`       IS NOT NULL THEN {l:'literature',      lbl:['Literature'],      t:line.`literature`}       END AS d15,
     CASE WHEN line.`commentary`       IS NOT NULL THEN {l:'commentary',      lbl:['Commentary'],      t:line.`commentary`}       END AS d16,
     CASE WHEN line.`annotations`      IS NOT NULL THEN {l:'annotations',     lbl:['Annotations'],     t:line.`annotations`}      END AS d17,
     CASE WHEN line.`footnotes`        IS NOT NULL THEN {l:'footnotes',       lbl:['Footnotes'],       t:line.`footnotes`}        END AS d18

WITH r, [x IN [d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,d11,d12,d13,d14,d15,d16,d17,d18] WHERE x IS NOT NULL] AS defs

CALL {
WITH r, defs
UNWIND range(0, size(defs)-1) AS i
WITH r, defs[i] AS def, i

// hochgestellte zeichen umklammern
WITH r, def, i,
     apoc.text.replace(
     def.t,
     '<sup>(.*?)</sup>',
     '<sup>[$1]</sup>'
     ) AS textWithSuperscript

// Nach jedem Listenelement einen Zeilenumbruch einfügen
WITH r, def, i,
     apoc.text.replace(
     textWithSuperscript,
     '</li>',
     '</li>\n'
     ) AS formatedListsText

// html Kommentare entfernen
WITH r, def, i,
     apoc.text.replace(
     formatedListsText,
     '(?s)<!--.*?(-->|$)',
     ''
     ) AS rmHtmlCommentText

// kaputte span elemente entfernen
WITH r, def, i,
     apoc.text.replace(
     rmHtmlCommentText,
     '</</span>',
     '</span>'
     ) AS text

CREATE (c:Content:Text { uuid: randomUUID(), label: def.l, text: text })
CREATE (c)-[:PART_OF]->(r)
WITH c, def
CALL apoc.create.addLabels(c, def.lbl) YIELD node
RETURN collect(node) AS nodes
}

WITH nodes
UNWIND range(0, size(nodes)-2) AS j
WITH nodes[j] AS a, nodes[j+1] AS b
CREATE (a)-[:HAS_ANNOTATION]->(:Annotation:Next { uuid: randomUUID(), label: 'next', type: 'next' })-[:REFERS_TO]->(b)

} IN TRANSACTIONS OF 100 ROWS;


// Regestennummer einzeln erstellen
MATCH (reg:Regesta)
UNWIND apoc.text.regexGroups(reg.identifier, '.* n\. (\\S+)$') AS n
SET reg.regestaNumber = n[1];

// External Links erstellen
MATCH (reg:Regesta) WHERE reg.externalLinks CONTAINS 'link'
WITH reg
CALL (reg) {
UNWIND apoc.text.regexGroups(reg.externalLinks,
'<link (\\S*?)( - \\S*?)>(.*?)</link>') AS link
MERGE (ref:Annotation {url:link[1], type:"ri:externalLink"})
  ON CREATE SET ref:RegestaAnnotation, ref.url_title=link[3]
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
WHERE reg.startDate IS NOT NULL
AND NOT reg.startDate =~ '^\\d{4}-\\d{2}-\\d{2}$'
SET reg.startDateWrong = reg.startDate,
reg.startDate = '2021-01-01';

// Falsch formatierte endDate-Werte abfangen
MATCH (reg:Regesta)
WHERE reg.endDate IS NOT NULL
AND NOT reg.endDate =~ '^\\d{4}-\\d{2}-\\d{2}$'
SET reg.endDateWrong = reg.endDate,
reg.endDate = '2021-01-01';

// Falsche startDate-Werte finden und ersetzen
MATCH (reg:Regesta)
WHERE reg.startDate IS NOT NULL
AND reg.startDate =~ '^\\d{4}-\\d{2}-\\d{2}$'

WITH reg,
toInteger(substring(reg.startDate, 0, 4)) AS year,
toInteger(substring(reg.startDate, 5, 2)) AS month,
toInteger(substring(reg.startDate, 8, 2)) AS day

WITH reg, year, month, day,
CASE
WHEN month IN [1, 3, 5, 7, 8, 10, 12] THEN 31
WHEN month IN [4, 6, 9, 11] THEN 30
WHEN month = 2 AND
(year % 400 = 0 OR (year % 4 = 0 AND year % 100 <> 0))
THEN 29
WHEN month = 2 THEN 28
ELSE 0
END AS maxDay

WHERE month < 1
OR month > 12
OR day < 1
OR day > maxDay

SET reg.startDateWrong = reg.startDate,
reg.startDate = '2021-01-01';

MATCH (reg:Regesta)
WHERE reg.endDate IS NOT NULL
AND reg.endDate =~ '^\\d{4}-\\d{2}-\\d{2}$'

WITH reg,
toInteger(substring(reg.endDate, 0, 4)) AS year,
toInteger(substring(reg.endDate, 5, 2)) AS month,
toInteger(substring(reg.endDate, 8, 2)) AS day

WITH reg, year, month, day,
CASE
WHEN month IN [1, 3, 5, 7, 8, 10, 12] THEN 31
WHEN month IN [4, 6, 9, 11] THEN 30
WHEN month = 2 AND
(year % 400 = 0 OR (year % 4 = 0 AND year % 100 <> 0))
THEN 29
WHEN month = 2 THEN 28
ELSE 0
END AS maxDay

WHERE month < 1
OR month > 12
OR day < 1
OR day > maxDay

SET reg.endDateWrong = reg.endDate,
reg.endDate = '2021-01-01';



// Datum als Neo4j-Datum ergänzen
// Datum als Neo4j-Datum ergänzen
MATCH (n:Regesta)
WITH n
CALL (n) {
SET n.isoStartDate =
CASE
WHEN n.startDate IS NOT NULL
THEN date(n.startDate)
ELSE NULL
END,
n.isoEndDate =
CASE
WHEN n.endDate IS NOT NULL
THEN date(n.endDate)
ELSE NULL
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
UNWIND apoc.text.regexGroups(r.archivalHistory, "<link (http.*?=)(.+?)>(.+?)<\\/link>") AS link
MERGE (ref:Annotation {url:link[1]+link[2], type: 'ri:literature'})
ON CREATE SET
ref:RegestaAnnotation,
ref.uuid = randomUUID(),
ref.url_label=link[3],
ref.url_title=link[2]
MERGE (r)-[:HAS_ANNOTATION]->(ref)
} IN TRANSACTIONS OF 1000 ROWS;

