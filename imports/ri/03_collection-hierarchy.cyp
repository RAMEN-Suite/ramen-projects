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


// Registerstufen anlegen
MATCH (child:Entity)-[:HAS_ANNOTATION]->(:Annotation {type:'ri:isSubOf'})-[:REFERS_TO]->(parent:Entity)
MERGE (child)-[:IS_SUB_OF]->(parent);

MATCH (n1:Entity)
SET n1.pathLength = 'zero';
MATCH (n1:Entity)
  WHERE NOT (n1)-[:IS_SUB_OF]->(:Entity)
SET n1.pathLength = '0', n1.origLabel = n1.label;
MATCH p=(n1:Entity{pathLength:'0'})<-[r:IS_SUB_OF*..8]-(n2)
  WHERE n2.pathLength = 'zero'
SET n2.pathLength = length(p);

Match (e0:Entity)<-[:IS_SUB_OF]-(e1:Entity)
SET e1.label = e0.origLabel + ' // ' + e1.origLabel;
Match (e0:Entity {pathLength:'0'})<-[:IS_SUB_OF]-(e1:Entity)<-[:IS_SUB_OF]-(e2:Entity)
SET e2.label = e0.origLabel + ' // ' + e1.origLabel + ' // ' + e2.origLabel;
Match (e0:Entity {pathLength:'0'})<-[:IS_SUB_OF]-(e1:Entity)<-[:IS_SUB_OF]-(e2:Entity)<-[:IS_SUB_OF]-(e3:Entity)
SET e3.label = e0.origLabel + ' // ' + e1.origLabel + ' // ' + e2.origLabel + ' // ' + e3.origLabel;
Match (e0:Entity {pathLength:'0'})<-[:IS_SUB_OF]-(e1:Entity)<-[:IS_SUB_OF]-(e2:Entity)<-[:IS_SUB_OF]-(e3:Entity)<-[:IS_SUB_OF]-(e4:Entity)
SET e4.label = e0.origLabel + ' // ' + e1.origLabel + ' // ' + e2.origLabel + ' // ' + e3.origLabel + ' // ' + e4.origLabel;
Match (e0:Entity {pathLength:'0'})<-[:IS_SUB_OF]-(e1:Entity)<-[:IS_SUB_OF]-(e2:Entity)<-[:IS_SUB_OF]-(e3:Entity)<-[:IS_SUB_OF]-(e4:Entity)<-[:IS_SUB_OF]-(e5:Entity)
SET e5.label = e0.origLabel + ' // ' + e1.origLabel + ' // ' + e2.origLabel + ' // ' + e3.origLabel + ' // ' + e4.origLabel + ' // ' + e5.origLabel;
Match (e0:Entity {pathLength:'0'})<-[:IS_SUB_OF]-(e1:Entity)<-[:IS_SUB_OF]-(e2:Entity)<-[:IS_SUB_OF]-(e3:Entity)<-[:IS_SUB_OF]-(e4:Entity)<-[:IS_SUB_OF]-(e5:Entity)<-[:IS_SUB_OF]-(e6:Entity)
SET e6.label = e0.origLabel + ' // ' + e1.origLabel + ' // ' + e2.origLabel + ' // ' + e3.origLabel + ' // ' + e4.origLabel + ' // ' + e5.origLabel + ' // ' + e6.origLabel;

MATCH (child:Entity)-[r:IS_SUB_OF]->(parent:Entity)
DETACH DELETE r;

//RI I DATENMODELL STIMMT NICHT ÜBEREIN
MATCH (r:Regesta) WITH r, r.identifier AS identifier
  WHERE identifier STARTS WITH "RI I n." OR identifier STARTS WITH "RI I,"
WITH
  r,
  "RI01 - Karolinger 751-918 (926/962)" AS department,
  CASE
    WHEN identifier STARTS WITH "RI I n." THEN "1 - Karolinger 751-918 (924)"
    WHEN identifier STARTS WITH "RI I,2" THEN "2 - Karl der Kahle 840 (823)-877, Lfg. 1-2: 840 (823)-869"
    WHEN identifier STARTS WITH "RI I,3" THEN "3 - Die Karolinger im Regnum Italiae 840-962 & Die burgundischen Regna: Niederburgund 855-940er Jahre"
    WHEN identifier STARTS WITH "RI I,4" THEN "4 - Papstregesten 800-911"
    ELSE "no volume"
    END AS volume
SET r.department = department
SET	r.volume = coalesce(r.volume, [])
SET	r.volume = CASE WHEN NOT volume IN r.volume THEN r.volume + volume ELSE r.volume END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);


//RI II DATENMODELL STIMMT NICHT ÜBEREIN
MATCH (r:Regesta) WITH r, r.identifier AS identifier
  WHERE identifier STARTS WITH "RI II,"
WITH
  r,
  "RI02 - Sächsisches Haus (919-1024)" AS department,
  CASE
    WHEN identifier STARTS WITH "RI II,5" THEN "5 - Papstregesten"
    ELSE "1-4 - Heinrich I., Otto I., Otto II., Otto III., Heinrich II."
    END AS volume
SET r.department = department
SET	r.volume = coalesce(r.volume, [])
SET	r.volume = CASE WHEN NOT volume IN r.volume THEN r.volume + volume ELSE r.volume END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);


//RI III
MATCH (r:Regesta) WITH r, r.identifier AS identifier
  WHERE identifier STARTS WITH "RI III,"
WITH
  r,
  "RI03 - Salisches Haus (1024-1125)" AS department,
  CASE
    WHEN identifier STARTS WITH "RI III,5" THEN "5 - Papstregesten 1024-1058"
    ELSE split(split(identifier, ' n. ')[0], 'RI III,')[1]
    END AS volume
SET r.department = department
SET	r.volume = coalesce(r.volume, [])
SET	r.volume = CASE WHEN NOT volume IN r.volume THEN r.volume + volume ELSE r.volume END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);


//RI IV
MATCH (r:Regesta) WITH r, r.identifier AS identifier
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
SET	r.volume = coalesce(r.volume, [])
SET	r.volume = CASE WHEN NOT volume IN r.volume THEN r.volume + volume ELSE r.volume END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);


//RI V
MATCH (r:Regesta) WITH r, r.identifier AS identifier
  WHERE identifier STARTS WITH "RI V,"
WITH
  r,
  "RI05 - Jüngere Staufer (1198-1272)" AS department,
  CASE
    WHEN identifier STARTS WITH "RI V,1," THEN "1 - Staufer, Kaiser und Könige"
    WHEN identifier STARTS WITH "RI V,2," THEN "2 - Staufer, Päpste und Reichssachen"
    WHEN identifier STARTS WITH "RI V,4,6" THEN "4,6 - Staufer, Nachträge und Ergänzungen"
    WHEN identifier STARTS WITH "RI V,4,1" THEN "4,1 - Staufer, Nachträge zu Friedrich II. und Konrad IV."
    ELSE split(split(identifier, ' n. ')[0], 'RI V,')[1]
    END AS volume
SET r.department = department
SET	r.volume = coalesce(r.volume, [])
SET	r.volume = CASE WHEN NOT volume IN r.volume THEN r.volume + volume ELSE r.volume END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);


//RI VI
MATCH (r:Regesta) WITH r, r.identifier AS identifier
  WHERE identifier STARTS WITH "RI VI,"
WITH
  r,
  "RI06 - Rudolf I. - Heinrich VII. (1273-1313)" AS department,
  CASE
    WHEN identifier STARTS WITH "RI VI,4," THEN "4 - Heinrich VII. 1288/1308-1313"
    WHEN identifier STARTS WITH "RI VI,1" THEN "1 - Rudolf I. 1273-1291"
    WHEN identifier STARTS WITH "RI VI,2" THEN "2 - Adolf von Nassau 1291-1298"
    ELSE split(split(identifier, ' n. ')[0], 'RI V,')[1]
    END AS volume
SET r.department = department
SET	r.volume = coalesce(r.volume, [])
SET	r.volume = CASE WHEN NOT volume IN r.volume THEN r.volume + volume ELSE r.volume END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);
MATCH (r:Regesta)
  WHERE r.identifier starts with "[RIplus] Regg. Heinrich VII. n. "
WITH r, r.identifier as identifier,
     "RI06 - Rudolf I. - Heinrich VII. (1273-1313)" AS department,
     "[RIplus] Regg. Heinrich VII." AS volume
MATCH (c1:Collection {type: "department", label: department})
SET r.department = department
SET	r.volume = coalesce(r.volume, [])
SET	r.volume = CASE WHEN NOT volume IN r.volume THEN r.volume + volume ELSE r.volume END
WITH r, volume, department, c1
//MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})
MERGE (c2)-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);



// [Regesta Habsburgica 3]
MATCH (r:Regesta) WITH r, r.identifier AS identifier
  WHERE identifier STARTS WITH "[Regesta Habsburgica 3]"
WITH
  r,
  "Regesta Habsburgica 3" AS department,
  CASE
    WHEN identifier STARTS WITH "[Regesta Habsburgica 3]" THEN "Friedrich der Schöne"
    ELSE split(split(identifier, ' n. ')[0], '[Regesta Habsburgica 3]')[1]
    END AS volume
SET r.department = department
SET	r.volume = coalesce(r.volume, [])
SET	r.volume = CASE WHEN NOT volume IN r.volume THEN r.volume + volume ELSE r.volume END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);


//RI VII Department
MATCH (r:Regesta) WITH r, r.identifier AS identifier
  WHERE identifier STARTS WITH "[RI VII]"
WITH r,
     "RI07" AS department,
     split(split(identifier, ' n. ')[0], ' H. ')[1] AS volume
SET r.department = department
SET	r.volume = coalesce(r.volume, [])
SET	r.volume = CASE WHEN NOT volume IN r.volume THEN r.volume + volume ELSE r.volume END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)

MERGE (r)-[:PART_OF]->(c2);



//RI VIII Department

MATCH (r:Regesta) WITH r, r.identifier AS identifier
  WHERE identifier STARTS WITH "RI VIII"
WITH
  r,
  "RI08" AS department,
  "1" AS volume
SET r.department = department
SET	r.volume = coalesce(r.volume, [])
SET	r.volume = CASE WHEN NOT volume IN r.volume THEN r.volume + volume ELSE r.volume END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)

MERGE (r)-[:PART_OF]->(c2);

//Regg. Pfalzgrafen 2 Department
MATCH (r:Regesta) WITH r, r.identifier AS identifier
  WHERE identifier STARTS WITH "[Regg. Pfalzgrafen 2]"
WITH
  r,
  "Pfalzgrafen 2" AS department,
  "1" AS volume
SET r.department = department
SET	r.volume = coalesce(r.volume, [])
SET	r.volume = CASE WHEN NOT volume IN r.volume THEN r.volume + volume ELSE r.volume END
MERGE (c1:Collection {type: "department", label: department})

MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)

MERGE (r)-[:PART_OF]->(c2);

//RI XI Department
MATCH (r:Regesta) WITH r, r.identifier AS identifier
  WHERE identifier STARTS WITH "RI XI,"
WITH
  r,
  "RI11" AS department,
  "1" AS volume
SET r.department = department
SET	r.volume = coalesce(r.volume, [])
SET	r.volume = CASE WHEN NOT volume IN r.volume THEN r.volume + volume ELSE r.volume END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);

MATCH (r:Regesta) WITH r, r.identifier AS identifier
  WHERE identifier STARTS WITH "RI XI Neubearb"
WITH
  r,
  "RI11" AS department,
  split(split(identifier, ' n. ')[0], 'RI XI ')[1] AS volume
SET r.department = department
SET	r.volume = coalesce(r.volume, [])
SET	r.volume = CASE WHEN NOT volume IN r.volume THEN r.volume + volume ELSE r.volume END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);


//RI XII Department
MATCH (r:Regesta) WITH r, r.identifier AS identifier
  WHERE identifier STARTS WITH "RI XII "
WITH
  r,
  "RI12" AS department,
  "1" AS volume
SET r.department = department
SET	r.volume = coalesce(r.volume, [])
SET	r.volume = CASE WHEN NOT volume IN r.volume THEN r.volume + volume ELSE r.volume END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);



//RI XIII
MATCH (r:Regesta) WITH r, r.identifier AS identifier
  WHERE identifier STARTS WITH "[RI XIII] "
WITH
  r,
  "RI13" AS department,
  CASE
    WHEN identifier STARTS WITH "[RI XIII] H." THEN split(split(identifier, ' n. ')[0], ' H. ')[1]
    ELSE split(split(identifier, ' n. ')[0], '[RI XIII] ')[1]
    END AS volume
SET r.department = department
SET	r.volume = coalesce(r.volume, [])
SET	r.volume = CASE WHEN NOT volume IN r.volume THEN r.volume + volume ELSE r.volume END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);
MATCH (r:Regesta) WITH r, r.identifier AS identifier
  WHERE identifier STARTS WITH "Chmel"
WITH
  r,
  "RI13" AS department,
  "Chmel" AS volume
SET r.department = department
SET	r.volume = coalesce(r.volume, [])
SET	r.volume = CASE WHEN NOT volume IN r.volume THEN r.volume + volume ELSE r.volume END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);



//RI XIV
MATCH (r:Regesta) WITH r, r.identifier AS identifier
  WHERE identifier STARTS WITH "RI XIV,"
WITH
  r,
  "RI14" AS department,
  "Maximilian I." AS volume
SET r.department = department
SET	r.volume = coalesce(r.volume, [])
SET	r.volume = CASE WHEN NOT volume IN r.volume THEN r.volume + volume ELSE r.volume END
MERGE (c1:Collection {type: "department", label: department})
MERGE (c2:Collection {type: "volume", label: volume})-[:PART_OF]->(c1)
MERGE (r)-[:PART_OF]->(c2);


// Collections uuids geben
MATCH (n:Collection)
  WHERE n.uuid IS NULL
SET n.uuid = randomUUID();

// numberOfChilds wird ermittelt
MATCH (n:Entity)
OPTIONAL MATCH (n)<-[:REFERS_TO]-(:Annotation {type: "ri:isSubOf"})<-[:HAS_ANNOTATION]-(sub:Entity)
WITH n, COLLECT(sub) AS directChildren
CALL {
WITH n
MATCH (n)<-[:REFERS_TO]-(:Annotation {type: "ri:isSubOf"})<-[:HAS_ANNOTATION]-(sub:Entity)
CALL apoc.path.subgraphNodes(sub, {
  relationshipFilter: "HAS_ANNOTATION>|<REFERS_TO",
  minLevel: 1
}) YIELD node
RETURN COUNT(DISTINCT node) AS totalSubEntities
}
SET n.numberOfChilds = totalSubEntities;

// Creates the labelNorm Annotation on all Entities. Here all HTML-Tags are removed.
MATCH (n:Entity) WHERE n.labelNorm IS NULL SET n.labelNorm = apoc.text.replace(n.label, '<(?:"[^"]*"[\'"]*|\'[^\']*\'[\'"]*|[^\'">])+>', '')  RETURN COUNT(n);

WITH [
       {from:'?', to:'Stufe_unclear'},
       {from:'Null', to:'Stufe_unclear'},
       {from:'IndexEvent', to:'Event'},
       {from:'Rolle', to:'Role'},
       {from:'Person und b', to:'Person'},
       {from:'Person, <i>vgl. auch</i>', to:'Person'},
       {from:'Ort und 4 (vgl. Nachtrag Lief. III und IV)', to:'Place'},
       {from:'Ort und b', to:'Place'},
       {from:'Ort(vgl. Nachtrag Lief. IV)', to:'Place'},
       {from:'Ort. ─ Abt:', to:'Place'},
       {from:'Ort. ─ Edle:', to:'Place'},
       {from:'Ort°', to:'Place'},
       {from:'Xref//*', to:'Xref'}
     ] AS renames

UNWIND renames AS m
MATCH (n:Entity)
  WHERE m.from IN labels(n)
CALL apoc.create.addLabels(n, [m.to]) YIELD node
CALL apoc.create.removeLabels(node, [m.from]) YIELD node as node2
RETURN count(*) AS changed;

MATCH (n:Entity)
UNWIND labels(n) AS lbl
WITH n, lbl
  WHERE lbl STARTS WITH 'Xref//'

CALL apoc.create.addLabels(n, ['Xref']) YIELD node
CALL apoc.create.removeLabels(node, [lbl]) YIELD node AS node2

RETURN count(*) AS changed;


// Jede Entity mit Regesta verbinden
CALL apoc.periodic.iterate(
'MATCH (n:Entity) RETURN n',
'
  // 1) Alle Entity/Annotation-Knoten im selben Cluster holen (beide Richtungen!)
  CALL apoc.path.subgraphNodes(n, {
    relationshipFilter: "REFERS_TO|HAS_ANNOTATION",
    labelFilter: "+Entity|Annotation",
    minLevel: 0,
    maxLevel: 10,
    bfs: true,
    uniqueness: "NODE_GLOBAL"
  }) YIELD node
  RETURN n, collect(DISTINCT node) AS cluster

  CALL {
    WITH cluster
    UNWIND cluster AS x

    OPTIONAL MATCH (r)<-[:REFERS_TO]-(:Annotation)<-[:HAS_ANNOTATION]-(x)
    WHERE r:Regesta OR (r:Collection AND toLower(coalesce(r.type,"")) = "regesta")

    RETURN apoc.coll.toSet(collect(DISTINCT r)) AS regestaCols
  }

  UNWIND regestaCols AS rc
     // 3) Existierende APPEARS_IN Annotation prüfen
  OPTIONAL MATCH (rc)<-[:REFERS_TO]-(existing:Annotation {type:"ri:appearsIn"})<-[:HAS_ANNOTATION]-(n)
  WITH n, rc, existing
  WHERE existing IS NULL

  // 4) Neue Annotation anlegen
  CREATE (a:Annotation {
    type: "ri:appearsIn",
    uuid: randomUUID()
  })

  MERGE (rc)<-[:REFERS_TO]-(a)
  MERGE (n)-[:HAS_ANNOTATION]->(a)
',
{batchSize: 200, parallel: false}
);

MATCH (n:Entity) WHERE n.htmlLabel IS NULL
SET n.htmlLabel = n.label
SET n.label = apoc.text.replace(n.label, '<(?:"[^"]*"[\'"]*|\'[^\']*\'[\'"]*|[^\'">])+>', '')
RETURN COUNT(n);

MATCH (c1:Collection {type: "department"})<-[r:PART_OF]-(c2:Collection {type: "volume"})
SET c1:Department, c2:Volume;

MATCH (n:Entity)
CALL {
WITH n
UNWIND keys(n) AS key
WITH n, key
  WHERE key <> 'uuid' AND key <> 'numberOfChilds' AND key <> 'label' AND key <> 'pathLength' AND NOT key STARTS WITH '_'

CREATE (a:Annotation {
  uuid: randomUUID(),
  type: key,
  value: n[key]
})
MERGE (n)-[:HAS_ANNOTATION]->(a)
REMOVE n[key]
}
IN TRANSACTIONS OF 1000 ROWS;

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

MATCH (c1:Collection {
type: 'department',
label: departmentLabels[i]
})

MATCH (c2:Collection {
type: 'department',
label: departmentLabels[i + 1]
})

MERGE (c1)-[:HAS_ANNOTATION]->(
a:Annotation:Next {
label: 'next',
type: 'next'
}
)
ON CREATE SET a.uuid = randomUUID()

MERGE (a)-[:REFERS_TO]->(c2)

RETURN
c1.label AS department,
c2.label AS nextDepartment
ORDER BY i;


// NEXT Kanten zwischen Regesta Nodes
MATCH (r:Regesta)-[:PART_OF]->(v:Collection:Volume)
WHERE r.regestennummernorm IS NOT NULL
WITH v, r
ORDER BY v, toFloat(r.regestennummernorm)
WITH v, collect(r) AS regesta
UNWIND range(0, size(regesta) - 2) AS i
WITH regesta[i] AS currentRegesta, regesta[i + 1] AS nextRegesta
MERGE (currentRegesta)-[:HAS_ANNOTATION]->(a:Annotation:Next { label: 'next', type: 'next' })-[:REFERS_TO]->(nextRegesta)
ON CREATE SET a.uuid = randomUUID();