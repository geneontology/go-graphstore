
all: all_lego noctua-models

## ----------------------------------------
## GAFS
## ----------------------------------------

## TODO: use config
GAFS = fb sgd zfin mgi rgd pombase wb

all_lego: $(patsubst %, rdf/%-lego.ttl, $(GAFS))

# TODO: uniprot
gaf/%.gaf.gz: 
	mkdir -p gaf && wget http://geneontology.org/gene-associations/gene_association.$*.gz -O $@.tmp && mv $@.tmp $@ 
.PRECIOUS: gaf/%.gaf.gz

## ----------------------------------------
## LEGO-RDF
## ----------------------------------------

ONT = rdf/go-graphstore-merged.ttl
rdf/%-lego.ttl: gaf/%.gaf.gz $(ONT) 
	mkdir -p rdf && MINERVA_CLI_MEMORY=32G minerva-cli.sh $(ONT) --gaf $< --gaf-lego-individuals --skip-merge --format turtle -o $@.tmp && mv $@.tmp $@

$(ONT): 
	mkdir -p rdf && OWLTOOLS_MEMORY=12G owltools go-graphstore.owl --merge-imports-closure -o -f turtle $@
.PRECIOUS: rdf/go-graphstore-merged.ttl

## TODO: only include production models in production builds
noctua-models:
	git clone https://github.com/geneontology/noctua-models.git && cp noctua-models/models/* rdf/

data-files = $(shell ls rdf | grep -v go-graphstore-merged.ttl)

add-defined-by: all_lego noctua-models $(data-files)

.PHONY: add-defined-by $(data-files)

$(data-files):
	arq --query=sparql/link-individual-to-model.rq --data=rdf/$@ --results=turtle >rdf/$(basename $@).definedby.ttl

## ----------------------------------------
## LOADING BLAZEGRAPH
## ----------------------------------------
BGVERSION = 2.1.4
BGJAR = jars/blazegraph-jar-$(BGVERSION).jar

$(BGJAR):
	mkdir -p jars && mvn -DbgVersion=$(BGVERSION) package
.PRECIOUS: $(BGJAR)

BG = java -server -XX:+UseG1GC -Xmx32G -cp $(BGJAR) com.bigdata.rdf.store.DataLoader
load-blazegraph: $(BGJAR)
	$(BG) -defaultGraph http://geneontology.org/rdf/ conf/blazegraph.properties rdf

load-inferences: rdfox.ttl
	$(BG) -defaultGraph http://geneontology.org/rdf/inferred/ conf/blazegraph.properties $<

rmcat:
	rm rdf/catalog-v001.xml

rdf/%-bg-load: rdf/%.rdf
	$(BG) -defaultGraph http://geneontology.org/rdf/ conf/blazegraph.properties $<

bg-start:
	java -server -Xmx8g -Dbigdata.propertyFile=conf/blazegraph.properties -jar $(BGJAR)

## ----------------------------------------
## SciGraph
## ----------------------------------------

# TODO: robust configuration
SCIGRAPH= $(HOME)/repos/SciGraph/
load-scigraph:
	java -Xmx8G -classpath $(SCIGRAPH)/SciGraph-core/target/scigraph-core-1.5-SNAPSHOT-jar-with-dependencies.jar edu.sdsc.scigraph.owlapi.loader.BatchOwlLoader -c conf/scigraph-load-go.yaml 

## ----------------------------------------
## RDFox
## ----------------------------------------

# See https://github.com/balhoff/rdfox-cli
# RDFox can only read turtle data files; avoid loading the ontology as data.
rdfox.ttl:
	export JAVA_OPTS="-Xmx64G" && rdfox-cli --ontology=$(ONT) --rules=rules.dlog --data=rdf --threads=24 --reason --export=rdfox.ttl --inferred-only --excluded-properties=exclude.txt
