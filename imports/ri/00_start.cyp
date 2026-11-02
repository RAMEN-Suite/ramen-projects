// VERSION INFO
// neo4j 5.26 with the apoc plugin required. The neo4j-atag plugin is required to clean the text nodes and create annotations from it. Everything else works without it.

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


// RI Goes Graph 2
// GLOBAL
CREATE FULLTEXT INDEX combined_search IF NOT EXISTS FOR (n:Regesta|Text|Entity) ON EACH [n.label, n.text];

// FILTER
CREATE FULLTEXT INDEX department_search IF NOT EXISTS FOR (n:Department) ON EACH [n.label];
CREATE FULLTEXT INDEX volume_search IF NOT EXISTS FOR (n:Volume) ON EACH [n.label];
CREATE FULLTEXT INDEX person_search IF NOT EXISTS FOR (n:Person) ON EACH [n.label];
CREATE FULLTEXT INDEX place_search IF NOT EXISTS FOR (n:Place) ON EACH [n.label];
CREATE FULLTEXT INDEX thing_search IF NOT EXISTS FOR (n:Thing) ON EACH [n.label];
CREATE FULLTEXT INDEX entity_search IF NOT EXISTS FOR (n:Entity) ON EACH [n.label];

// TEXT FILTER
CREATE FULLTEXT INDEX annotations_search IF NOT EXISTS FOR (n:Annotation) ON EACH [n.text];
CREATE FULLTEXT INDEX archivalHistory_search IF NOT EXISTS FOR (n:ArchivalHistory) ON EACH [n.text];
CREATE FULLTEXT INDEX chancellor_search IF NOT EXISTS FOR (n:Chancellor) ON EACH [n.text];
CREATE FULLTEXT INDEX clerk_search IF NOT EXISTS FOR (n:Clerk) ON EACH [n.text];
CREATE FULLTEXT INDEX commentary_search IF NOT EXISTS FOR (n:Commentary) ON EACH [n.text];
CREATE FULLTEXT INDEX date_search IF NOT EXISTS FOR (n:Date) ON EACH [n.text];
CREATE FULLTEXT INDEX footnotes_search IF NOT EXISTS FOR (n:Footnotes) ON EACH [n.text];
CREATE FULLTEXT INDEX identifier_search IF NOT EXISTS FOR (n:Identifier) ON EACH [n.text];
CREATE FULLTEXT INDEX incipit_search IF NOT EXISTS FOR (n:Incipit) ON EACH [n.text];
CREATE FULLTEXT INDEX literature_search IF NOT EXISTS FOR (n:Literature) ON EACH [n.text];
CREATE FULLTEXT INDEX originalDate_search IF NOT EXISTS FOR (n:OriginalDate) ON EACH [n.text];
CREATE FULLTEXT INDEX placeOfIssue_search IF NOT EXISTS FOR (n:PlaceOfIssue) ON EACH [n.text];
CREATE FULLTEXT INDEX recipient_search IF NOT EXISTS FOR (n:Recipient) ON EACH [n.text];
CREATE FULLTEXT INDEX summary_search IF NOT EXISTS FOR (n:Summary) ON EACH [n.text];
CREATE FULLTEXT INDEX title_search IF NOT EXISTS FOR (n:Title) ON EACH [n.text];
CREATE FULLTEXT INDEX versoNote_search IF NOT EXISTS FOR (n:VersoNote) ON EACH [n.text];
CREATE FULLTEXT INDEX witnesses_search IF NOT EXISTS FOR (n:Witnesses) ON EACH [n.text];
