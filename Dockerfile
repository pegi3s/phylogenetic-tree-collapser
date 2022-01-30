FROM pegi3s/docker:20.04

RUN apt-get update -y && \
	apt-get install -y python3 openjdk-8-jdk wget && \
	rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

ADD scripts /opt/tree-collapser
ADD data /opt/tree-collapser/data

RUN chmod 777 /opt/tree-collapser/*

ENV PATH="/opt/tree-collapser:${PATH}"

ARG PTC_VERSION
ENV PTC_VERSION=${PTC_VERSION}

ARG PTC_JAR_VERSION
ENV PTC_JAR_VERSION=${PTC_JAR_VERSION}

RUN wget -O /opt/tree-collapser/treecollapse-${PTC_JAR_VERSION}-jar-with-dependencies.jar https://maven.sing-group.org/repository/maven-releases/org/sing_group/treecollapse/${PTC_JAR_VERSION}/treecollapse-${PTC_JAR_VERSION}-jar-with-dependencies.jar

ENV DOCKER_PEGI3S_BIOPYTHON_UTILITIES_VERSION="1.78_0.2.0"
ENV COLLAPSER_JAR_PATH="/opt/tree-collapser/treecollapse-${PTC_JAR_VERSION}-jar-with-dependencies.jar"
ENV SCRIPT_PATH_GET_TAXONOMY="/opt/tree-collapser/get_taxonomy.sh"
ENV SCRIPT_PATH_FLATTEN_TAXONOMY="/opt/tree-collapser/flatten_taxonomy_using_stop_terms.sh"
ENV PATH_PTC_CACHE="/ptc-cache"
