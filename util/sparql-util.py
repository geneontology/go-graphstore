#!/usr/bin/env python3

import argparse
from SPARQLWrapper import SPARQLWrapper2, JSON
from json import dumps

def main():

    parser = argparse.ArgumentParser(description='LEGO'
                                                 'Helper utils for LEGO',
                                     formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument('-i', '--input', type=str, required=False,
                        help='Input metadata file')
    args = parser.parse_args()
    f = open("sparql/lego.prefixes", 'r')
    prefix_block = f.read()
    f.close()
    f = open(args.input, 'r')
    query = f.read()
    run_query(prefix_block + query)



def run_query(q):
    sparql = SPARQLWrapper2("http://localhost:9999/blazegraph/sparql")
    print(q)
    sparql.setQuery(q)
    #sparql.setReturnFormat(JSON)
    print("ISUPDATE="+str(sparql.isSparqlUpdateRequest()))
    sparql.method = 'POST';  ## Required for SPARQL-UPDATE
    ret = sparql.query()
    if sparql.isSparqlUpdateRequest() :
        return
    print(ret.variables)  # this is an array consisting of "subj" and "prop"
    for binding in ret.bindings :
        # each binding is a dictionary. Let us just print the results
        #print "%s: %s (of type %s)" % ("s",binding[u"subj"].value,binding[u"subj"].type)
        #print "%s: %s (of type %s)" % ("p",binding[u"prop"].value,binding[u"prop"].type)
        print("## RESULT")
        for (k,v) in binding.items():
            print(k+" = "+str(v.value))
        #print(dumps(binding, sort_keys=True, indent=4, separators=(',', ': ')))
    return ret.bindings
    
    

    
if __name__ == "__main__":
    main()    
