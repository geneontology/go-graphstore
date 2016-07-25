This repository contains code and configuration for building the GO
graphstore, as well as documentation on how to query it.

IN PROGRESS

# Building the graph store

See the [Makefile](Makefile) for details.

For now this must be constructed yourself but in future we will host
the RDF, the `blazegraph.jnl` file, and provide a query endpoint.

This prototype uses blazegraph. We are also investigating RDFox and
Neo4j; for the latter we will use the SciGraph RDF to Neo mappings.

The procedure places all triples to be loaded into the `rdf/` directory:

 * ontology: go-lego.owl (imports other ontologies)
 * GAFs translated to LEGO using OWLTools/Minerva
 * Native LEGO models

After this various transformations take place (TODO)

 * [sparql/delete-NamedIndividual-ul.rq](sparql/delete-NamedIndividual-ul.rq) - clogs querying
 * [sparql/insert-oban-mf.rq](sparql/insert-oban-mf.rq) - adds derived simple representation
 * todo - bp, cc 

# Querying the graph store

Here we describe the modeling used and how to query the database. See also the [sparql](sparql) directory.

The contents of the store can be broken down into:

 * the ontology (both GO and other ontologies)
 * functional annotations: descriptions of gene products using GO
 * other support information, e.g. orthology/trees

The store has two different ways of modeling functional annotations
superimposed. A __simple__ model that allows for basic gene
associations and a richer more expressive __lego__ model. For more on
lego, see [Noctua](http://noctua.berkeleybop.org/)

## Prefixes used in this document

See [sparql/lego.prefixes](sparql/lego.prefixes)

## Ontology

We use the standard OWL to RDF mapping.

Note this results in a pattern that is complex to query for
existential restrictions. We may consider superimposing simple
instance-level relationships over this.

## Functional Annotation: Simple

We use the OBAN association model. Simple triples with a reification like pattern.

TODO - document

## Functional Annotation: LEGO

### Core Annoton

The core unit is an annoton. It describes how any specific __molecular entity__ (e.g. a gene product or protein complex) 

    ?functionInstance a ?functionClass ;
                        occurs_in: ?locationInstance ;
                        part_of: ?processInstance ;
                        enabled_by: ?molecularInstance .
    
    ?locationInstance a ?locationClass .
    ?processInstance a ?processClass .
    ?molecularInstance a ?molecularClass .

TODO: causal relations

## Functional Annotation: Evidence

The evidence model is the same regardless of whether simple or lego annotations are used. For now, see:

https://github.com/geneontology/minerva/blob/master/specs/owl-model.md

## Functional Annotation: Molecular Entities

See [Noctua Entity Ontology](https://github.com/geneontology/neo)

## Metadata

 * users
 * GO REFs
 * ...

## Transformations

We can do a variety of transformations in SPARUL

TODO: document reasoning strategy

## Validation

 * TODO: sparql-checks, SHACL, taxon constraints, ...

### Transforming lego to simple

 * [sparql/insert-oban-mf.rq](sparql/insert-oban-mf.rq)

### Golr export

TODO: We can eventually move the GO golr export to this framework
(currently requires in-memory loading). One possibility is to take the
RDF load into SciGraph and use the golr exporter there. Or we can
explore use of SPARQL.
