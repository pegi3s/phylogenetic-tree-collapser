FROM pegi3s/docker:20.04

RUN apt-get update -y && \
	apt-get install -y python3 openjdk-8-jdk wget && \
	rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

ADD scripts /opt/tree-collapser
ADD data /opt/tree-collapser/data

RUN chmod 777 /opt/tree-collapser/*

ENV PATH="/opt/tree-collapser:${PATH}"

RUN wget -O /opt/tree-collapser/treecollapse-0.0.1-SNAPSHOT-jar-with-dependencies.jar https://maven.sing-group.org/repository/maven-snapshots/org/sing_group/treecollapse/0.0.1-SNAPSHOT/treecollapse-0.0.1-20211104.100201-1-jar-with-dependencies.jar

ENV DOCKER_PEGI3S_BIOPYTHON_UTILITIES_VERSION="1.78_0.2.0"
ENV COLLAPSER_JAR_PATH="/opt/tree-collapser/treecollapse-0.0.1-SNAPSHOT-jar-with-dependencies.jar"
ENV SCRIPT_PATH_GET_TAXONOMY="/opt/tree-collapser/get_taxonomy.sh"
ENV SCRIPT_PATH_FLATTEN_TAXONOMY="/opt/tree-collapser/flatten_taxonomy_using_stop_terms.sh"

ARG PTC_VERSION
ENV PTC_VERSION=${PTC_VERSION}
