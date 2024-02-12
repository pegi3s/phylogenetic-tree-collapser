FROM pegi3s/biopython_utilities:1.78_0.2.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
	apt-get install -y python3 openjdk-8-jdk wget && \
	rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

#
# entrez-direct installation
#

RUN apt-get -qq update && apt-get -y upgrade && \
	apt-get install -y curl libssl-dev build-essential libio-socket-ssl-perl libxml-simple-perl

WORKDIR /opt

RUN sh -c "$(curl -fsSL ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh)" && \
  mv /root/edirect /opt/

ENV PATH="/opt/edirect/:${PATH}"

WORKDIR /

#
# PTC installation from repository files
#

ADD scripts /opt/tree-collapser
ADD data /opt/tree-collapser/data

RUN chmod 777 /opt/tree-collapser/*

ENV PATH="/opt/tree-collapser:${PATH}"

ARG PTC_VERSION
ENV PTC_VERSION=${PTC_VERSION}

ARG PTC_JAR_VERSION
ENV PTC_JAR_VERSION=${PTC_JAR_VERSION}

RUN wget -O /opt/tree-collapser/treecollapse-${PTC_JAR_VERSION}-jar-with-dependencies.jar https://maven.sing-group.org/repository/maven-releases/org/sing_group/treecollapse/${PTC_JAR_VERSION}/treecollapse-${PTC_JAR_VERSION}-jar-with-dependencies.jar

ENV COLLAPSER_JAR_PATH="/opt/tree-collapser/treecollapse-${PTC_JAR_VERSION}-jar-with-dependencies.jar"
ENV SCRIPT_PATH_GET_TAXONOMY="/opt/tree-collapser/get_taxonomy.sh"
ENV SCRIPT_PATH_FLATTEN_TAXONOMY="/opt/tree-collapser/flatten_taxonomy_using_stop_terms.sh"
ENV PATH_PTC_CACHE="/ptc-cache"
