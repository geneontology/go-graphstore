## Example Queries

### Find terms by GO ID


### Find ancestors of the node 'nucleus'

    prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    SELECT ?ancestor
    WHERE {
      ?s rdfs:label "nucleus"@en ;
         rdfs:subClassOf+ ?ancestor .
    }

### Find 'subClassOf' descendants of the node 'nucleus'

	prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
	SELECT ?descendants
	WHERE {
		?nucleus rdfs:label "nucleus"@en .
	    ?descendants rdfs:subClassOf+ ?nucleus .  
	}

#### For all 'partOf' descendants of 'nucleus' (that is, all entities that ultimately are 'partOf' nucleus) that are not reasoned

	prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
	prefix part_of: <http://purl.obolibrary.org/obo/BFO_0000050_SOME>

	SELECT DISTINCT ?desc
	WHERE {
		?nucleus rdfs:label "nucleus"@en .
		?desc part_of: ?nucleus .
	}

This query uses the inferred part_of relationship. For reference, the real
triples look like:

	:descendent rdfs:subClassOf [ rdf:type owl:Restriction ;
								  owl:onProperty :part_of ;
								  owl:someValuesFrom :nucleus .] .

The inferencer creates a relationship in the "inferred" graph.

### Find relationships that are either inferred or asserted

	SELECT *
	WHERE {
	  GRAPH <http://geneontology.org/rdf/inferred/> {
	    <http://purl.obolibrary.org/obo/GO_0009987> ?p ?o .
	  }
	}

The named graph `<http://geneontology.org/rdf/inferred/>` is where the inferred
relationships from a reasoner go, and you can use the `GRAPH` keyword to just
select elements in a named graph.

To select just _asserted_ (and not inferred) relationships in the ontology,
use the named graph
`<http://geneontology.org/rdf/>` in the `GRAPH` keyword:

	SELECT *
	WHERE {
	  GRAPH <http://geneontology.org/rdf/> {
		<http://purl.obolibrary.org/obo/GO_0009987> ?p ?o .
	  }
	}


### Terms by alternate IDs

	prefix oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>
	prefix xsd: <http://www.w3.org/2001/XMLSchema#>

	SELECT ?s
	WHERE {
		?s oboInOwl:hasAlternativeId "GO:0050875"^^xsd:string
	}

This yields <http://purl.obolibrary.org/obo/GO_0009987> as 0050875 is listed
as an alternate ID for GO:0009987 (cellular process).

### Obsolete Terms

	PREFIX owl: <http://www.w3.org/2002/07/owl#>
	PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

	SELECT *
	WHERE {
	  ?s owl:deprecated "true"^^xsd:boolean .
	}

This finds any term that is obsolete matching on the data property owl:deprecated
being "true".
