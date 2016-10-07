
all: all_lego

## ----------------------------------------
## GAFS
## ----------------------------------------

## TODO: use config
GAFS = fb sgd zfin mgi rgd pombase wb

all_lego: $(patsubst %, rdf/%-lego.rdf, $(GAFS))

# TODO: uniprot
gaf/%.gaf.gz: 
	mkdir -p gaf && wget http://geneontology.org/gene-associations/gene_association.$*.gz -O $@.tmp && mv $@.tmp $@ 
.PRECIOUS: gaf/%.gaf.gz

## ----------------------------------------
## LEGO-RDF
## ----------------------------------------

ONT = rdf/go-lego-merged.owl
rdf/%-lego.rdf: gaf/%.gaf.gz $(ONT) 
	mkdir -p rdf && minerva-cli.sh $(ONT)  --gaf $< --gaf-lego-individuals --skip-merge -o $@.tmp && mv $@.tmp $@

$(ONT): 
	OWLTOOLS_MEMORY=12G owltools http://purl.obolibrary.org/obo/go/extensions/go-lego.owl --merge-imports-closure -o $@
.PRECIOUS: ontology/go-lego-merged.owl

## TODO: only include production models in production builds
noctua-models:
	git clone https://github.com/geneontology/noctua-models.git && cp noctua-models/models/* rdf/

## ----------------------------------------
## LOADING BLAZEGRAPH
## ----------------------------------------
BGVERSION = 2.1.4
BGJAR = jars/blazegraph-jar-$(BGVERSION).jar

$(BGJAR):
	mkdir -p jars && mvn -DbgVersion=$(BGVERSION) package
.PRECIOUS: $(BGJAR)

BG = java -XX:+UseG1GC -Xmx12G -cp $(BGJAR) com.bigdata.rdf.store.DataLoader -defaultGraph http://geneontology.org/rdf/ conf/blazegraph.properties
load-blazegraph: $(BGJAR)
	$(BG) rdf

rmcat:
	rm rdf/catalog-v001.xml

rdf/%-bg-load: rdf/%.rdf
	$(BG) $<

bg-start:
	java -server -Xmx8g -Dbigdata.propertyFile=conf/blazegraph.properties -jar $(BGJAR)

## ----------------------------------------
## SciGraph
## ----------------------------------------

# TODO: robust configuration
SCIGRAPH= $(HOME)/repos/SciGraph/
load-scigraph:
	java -Xmx8G -classpath $(SCIGRAPH)/SciGraph-core/target/scigraph-core-1.5-SNAPSHOT-jar-with-dependencies.jar edu.sdsc.scigraph.owlapi.loader.BatchOwlLoader -c conf/scigraph-load-go.yaml 
