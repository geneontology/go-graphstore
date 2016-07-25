This repository contains code and configuration for building the GO
graphstore, as well as documentation on how to query it.

# Building the graph store

See the [Makefile](Makefile) for details.

For now this must be constructed yourself but in future we will host
the RDF, the `blazegraph.jnl` file, and provide a query endpoint.

This prototype uses blazegraph. We are also investigating RDFox and
Neo4j; for the latter we will use the SciGraph RDF to Neo mappings.

# Querying the graph store

Here we describe the modeling used and how to query the database. See also the [sparql](sparql) directory.

The contents of the store can be broken down into:

 * the ontology (both GO and other ontologies)
 * functional annotations: descriptions of gene products using GO
 * other support information, e.g. orthology/trees

The store has two different ways of modeling functional annotations
superimposed. A __simple__ model that allows for basic gene
associations and a richer more expressive __lego__ model. For more on
lego, see http://noctua.berkeleybop.org/

## Prefixes used in this document

See [sparql/lego.prefixes](sparql/lego.prefixes)

## Ontology

## Functional Annotation: Simple

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
  
