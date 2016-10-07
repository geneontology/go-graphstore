
all: all_lego

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

ONT = rdf/go-lego-merged.owl
rdf/%-lego.ttl: gaf/%.gaf.gz $(ONT) 
	mkdir -p rdf && minerva-cli.sh $(ONT) --gaf $< --gaf-lego-individuals --skip-merge --format turtle -o $@.tmp && mv $@.tmp $@

$(ONT): 
	OWLTOOLS_MEMORY=12G owltools http://purl.obolibrary.org/obo/go/extensions/go-lego.owl --merge-imports-closure -o $@
.PRECIOUS: ontology/go-lego-merged.owl

## TODO: only include production models in production builds
noctua-models:
	git clone https://github.com/geneontology/noctua-models.git && cp noctua-models/models/* rdf/

## ----------------------------------------
## LOADING BLAZEGRAPH
## ----------------------------------------

BGJAR = jars/blazegraph.jar

$(BGJAR):
	mkdir -p jars && cd jars && curl -O http://tenet.dl.sourceforge.net/project/bigdata/bigdata/2.1.1/blazegraph.jar
.PRECIOUS: $(BGJAR)

BG = java -server -XX:+UseG1GC -Xmx12G -cp $(BGJAR) com.bigdata.rdf.store.DataLoader
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
	export JAVA_OPTS="-Xmx32G" && mkdir -p tmp && mv rdf/go-lego-merged.owl tmp/ && rdfox-cli --ontology=tmp/go-lego-merged.owl --data=rdf --threads=24 --reason --export=rdfox.ttl --inferred-only && mv tmp/go-lego-merged.owl rdf/
