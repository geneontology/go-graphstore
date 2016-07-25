
all: all_lego

## TODO: use config
GAFS = fb sgd zfin mgi rgd pombase wormbase

all_lego: $(patsubst %, rdf/%-lego.rdf, $(GAFS))

# TODO: uniprot
gaf/%.gaf.gz: 
	mkdir -p gaf && wget http://geneontology.org/gene-associations/gene_association.$*.gz -O $@.tmp && mv $@.tmp $@ 
.PRECIOUS: gaf/%.gaf.gz

ONT = rdf/go-lego-merged.owl
rdf/%-lego.rdf: gaf/%.gaf.gz $(ONT) 
	mkdir -p rdf && minerva-cli.sh $(ONT)  --gaf $< --gaf-lego-individuals --skip-merge -o $@.tmp && mv $@.tmp $@

$(ONT): 
	OWLTOOLS_MEMORY=12G owltools http://purl.obolibrary.org/obo/go/extensions/go-lego.owl --merge-imports-closure -o $@
.PRECIOUS: ontology/go-lego-merged.owl

## LOADING
BGJAR = jars/blazegraph.jar

$(BGJAR):
	mkdir -p jars && cd jars && curl -O http://tenet.dl.sourceforge.net/project/bigdata/bigdata/2.1.1/blazegraph.jar
.PRECIOUS: $(BGJAR)

BG = java -XX:+UseG1GC -Xmx12G -cp $(BGJAR) com.bigdata.rdf.store.DataLoader -defaultGraph http://geneontology.org/rdf/ conf/blazegraph.properties
load-blazegraph: $(BGJAR)
	$(BG) rdf

rdf/%-bg-load: rdf/%.rdf
	$(BG) $<

bg-start:
	java -server -Xmx8g -Dbigdata.propertyFile=conf/blazegraph.properties -jar $(BGJAR)
