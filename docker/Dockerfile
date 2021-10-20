ARG minerva_base_image=openjdk:8-jre

FROM maven:3.6.3-openjdk-8 AS builder

COPY ./pom.xml ./pom.xml
RUN mvn package 

FROM ${minerva_base_image}

WORKDIR /app

ADD ./ ./

ARG uid=1000
ARG gid=1000

ENV MEM="2G"

RUN echo '#!/bin/bash\n\
set -x\n\
java -server -Djetty.port=8899 -Xmx$MEM -Djetty.overrideWebXml=./conf/readonly_cors.xml -Dbigdata.propertyFile=./conf/blazegraph.properties -cp jars/blazegraph-jar.jar:jars/jetty-servlets.jar com.bigdata.rdf.sail.webapp.StandaloneNanoSparqlServer \
' > run.sh

RUN groupadd -g ${gid} gunicorn \
    && useradd -u ${uid} -g ${gid} -c 'Gunicorn User' --no-create-home gunicorn \
    && chown -R ${uid}:${gid} /app \
    && chmod +x /app/run.sh 

COPY --chown=${uid}:${gid} --from=builder /jars/*.jar  ./jars/

EXPOSE 8899 
USER gunicorn
CMD ["./run.sh"]
