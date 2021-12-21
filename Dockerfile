FROM eclipse-temurin:11.0.12_7-jdk  as jre-build
#FROM eclipse-temurin:11.0.13_8-jre as jre-build
#FROM eclipse-temurin:8u312-b07-jre as jre-build
ENV JAVA_HOME /opt/java/openjdk
# Create a custom Java runtime
#RUN $JAVA_HOME/bin/jlink \
#         --add-modules java.base \
#         --strip-debug \
#         --no-man-pages \
#         --no-header-files \
#         --compress=2 \
#         --output /javaruntime

# Define your base image
FROM debian:buster-slim
ENV JAVA_HOME /opt/java/openjdk
ENV PATH "${JAVA_HOME}/bin:${PATH}"
#COPY --from=jre-build /javaruntime $JAVA_HOME
COPY --from=jre-build $JAVA_HOME $JAVA_HOME


EXPOSE 9200 9300
#https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.16.2-linux-x86_64.tar.gz
ENV ES_VERSION 7.16.2
ENV DOWNLOAD_URL https://artifacts.elastic.co/downloads/elasticsearch/
ENV ES_TARBAL ${DOWNLOAD_URL}elasticsearch-${ES_VERSION}-linux-x86_64.tar.gz
ENV SHA ${ES_TARBAL}.sha512
RUN echo $SHA
 
# Install Elasticsearch.
RUN apt-get update && apt-get install --no-install-recommends -y libdigest-sha-perl wget curl ca-certificates util-linux gnupg openssl uuid-runtime &&\
  set -ex; \
     \
     curl -o /usr/local/bin/su-exec.c https://raw.githubusercontent.com/ncopa/su-exec/master/su-exec.c; \
     \
     fetch_deps='gcc libc-dev'; \
     apt-get update; \
     apt-get install -y --no-install-recommends $fetch_deps; \
     rm -rf /var/lib/apt/lists/*; \
     gcc -Wall \
         /usr/local/bin/su-exec.c -o/usr/local/bin/su-exec; \
     chown root:root /usr/local/bin/su-exec; \
     chmod 0755 /usr/local/bin/su-exec; \
     rm /usr/local/bin/su-exec.c; \
     \
     apt-get purge -y --auto-remove $fetch_deps 

RUN cd /tmp &&\
  wget -q ${ES_TARBAL} &&\
  wget -q ${SHA} &&\
  shasum -a 512 -c elasticsearch-${ES_VERSION}-linux-x86_64.tar.gz.sha512 &&\
  echo "===> Install Elasticsearch..." && ls -ltrha &&\
  tar -xf elasticsearch-$ES_VERSION-linux-x86_64.tar.gz &&\
  mv /tmp/elasticsearch-$ES_VERSION /elasticsearch &&  rm -rf /tmp/elas*


RUN useradd elasticsearch --no-create-home -G 0 -d /elasticsearch -r -U \
  && mkdir -p /elasticsearch/config/scripts /elasticsearch/plugins /data \
  && chown -R elasticsearch:elasticsearch /elasticsearch /data 

RUN ls -ltrha /opt/java/* && echo $PATH ;echo $JAVA_HOME && java -version

ENV PATH /elasticsearch/bin:$PATH
ENV env int
WORKDIR /elasticsearch

# Copy configuration
COPY config /elasticsearch/config
# use es6 config remove on 7
#RUN mv config/elasticsearch6.yml config/elasticsearch.yml
# Copy run script
COPY run.sh /

# Set environment variables defaults
ENV ES_JAVA_OPTS "-Xms512m -Xmx512m"
ENV CLUSTER_NAME es-hetarchief
ENV NODE_MASTER true
ENV NODE_DATA true
ENV NODE_INGEST true
ENV HTTP_ENABLE true
ENV NETWORK_HOST _site_
ENV HTTP_CORS_ENABLE true
ENV HTTP_CORS_ALLOW_ORIGIN *
ENV NUMBER_OF_MASTERS 1
ENV MAX_LOCAL_STORAGE_NODES 1
ENV SHARD_ALLOCATION_AWARENESS ""
ENV SHARD_ALLOCATION_AWARENESS_ATTR ""
ENV MEMORY_LOCK true
ENV REPO_LOCATIONS ""
ENV DISCOVERY_SERVICE "localhost"
ENV env prd
# Volume for Elasticsearch data
VOLUME ["/data"]
# Override config, otherwise plug-in install will fail
ADD config /elasticsearch/config
RUN mv config/elasticsearch.yml config/elasticsearch.yml

# Set environment
ENV DISCOVERY_SERVICE elasticsearch-discovery

# Kubernetes requires swap is turned off, so memory lock is redundant
ENV MEMORY_LOCK false
USER elasticsearch
CMD ["/bin/bash", "/run.sh"]
