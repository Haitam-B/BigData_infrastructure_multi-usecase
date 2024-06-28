FROM docker.elastic.co/elasticsearch/elasticsearch:7.10.2

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
