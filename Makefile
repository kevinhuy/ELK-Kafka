SHELL := /usr/bin/env bash
.DEFAULT_GAOL := help
.PHONY: clean clean_images build build_logstash build_elasticsearch build_kibana logs run run_logstash run_elasticsearch run_kibana rm shell

LOGSTASH_CONTAINER_IMAGE = packetferret/elk-logstash
LOGSTASH_CONTAINER_TAG = 0.0.1
LOGSTASH_CONTAINER_PORT = 5514
LOGSTASH_CONTAINER_HTTP_API = 9600
LOGSTASH_CONTAINER_NAME = elk-logstash
LOGSTASH_CONFIG_FILE_SRC = $(shell pwd)/files/docker/logstash/config/logstash.yml
LOGSTASH_CONFIG_FILE_DST = /usr/share/logstash/config/logstash.yml
LOGSTASH_PIPELINE_FILE_SRC = $(shell pwd)/files/docker/logstash/config/juniper.conf
LOGSTASH_PIPELINE_FILE_DST =  /usr/share/logstash/pipeline/juniper.conf

ELASTICSEARCH_CONTAINER_IMAGE = packetferret/elk-elasticsearch
ELASTICSEARCH_CONTAINER_TAG = 0.0.1
ELASTICSEARCH_CONTAINER_PORT_HTTP = 9200
ELASTICSEARCH_CONTAINER_PORT = 9300
ELASTICSEARCH_CONTAINER_NAME = elk-elasticsearch
ELASTICSEARCH_VOLUME_PATH_HOST = elasticsearch
ELASTICSEARCH_VOLUME_PATH_CONTAINER = /usr/share/elasticsearch/data
ELASTICSEARCH_CONFIG_FILE_SRC = $(shell pwd)/files/docker/elasticsearch/config/elasticsearch.yml
ELASTICSEARCH_CONFIG_FILE_DST = /usr/share/elasticsearch/config/elasticsearch.yml
# ELASTICSEARCH_DEPLOYMENT_TYPE = single-node

KIBANA_CONTAINER_IMAGE = packetferret/elk-kibana
KIBANA_CONTAINER_TAG = 0.0.1
KIBANA_CONTAINER_PORT = 5601
KIBANA_CONTAINER_NAME = elk-kibana

help:
	@echo ''
	@echo 'Makefile will help us build with the following commands'
	@echo '		make clean			cleans all containers'
	@echo '		make build			build all containers'
	@echo '		make build-logstash		build logstash container image'
	@echo '		make build-elasticsearch	build elasticsearch container image'
	@echo '		make build-kibana		build kibana container image'
	@echo '		make build-kafka		build kafaka container image'
	@echo '		make logs			tap into the logs of a container'
	@echo '		make run			run our containers'
	@echo '		make rm				simply remove the containers, not the container image'

clean:
	docker stop \
		$(LOGSTASH_CONTAINER_NAME)\
		$(ELASTICSEARCH_CONTAINER_NAME)\
		$(KIBANA_CONTAINER_NAME);
	docker rm \
		$(LOGSTASH_CONTAINER_NAME)\
		$(ELASTICSEARCH_CONTAINER_NAME)\
		$(KIBANA_CONTAINER_NAME);

clean_images:
	docker rmi \
		$(LOGSTASH_CONTAINER_IMAGE):$(LOGSTASH_CONTAINER_TAG) \
		$(ELASTICSEARCH_CONTAINER_IMAGE):$(ELASTICSEARCH_CONTAINER_TAG)\
		$(KIBANA_CONTAINER_IMAGE):$(KIBANA_CONTAINER_TAG)

build: build_logstash build_elasticsearch build_kibana

build_logstash:
	docker build \
	-t $(LOGSTASH_CONTAINER_IMAGE):$(LOGSTASH_CONTAINER_TAG) \
	files/docker/logstash/

build_elasticsearch:
	docker build \
	-t $(ELASTICSEARCH_CONTAINER_IMAGE):$(ELASTICSEARCH_CONTAINER_TAG) \
	files/docker/elasticsearch/

build_kibana:
	docker build \
	-t $(KIBANA_CONTAINER_IMAGE):$(KIBANA_CONTAINER_TAG) \
	files/docker/kibana/

# build-kafka:

# logs:

run: build run_logstash run_elasticsearch run_kibana

run_logstash:
	docker run \
	-it \
	-d \
	-v $(LOGSTASH_CONFIG_FILE_SRC):$(LOGSTASH_CONFIG_FILE_DST) \
	-v $(LOGSTASH_PIPELINE_FILE_SRC):$(LOGSTASH_PIPELINE_FILE_DST) \
	-p $(LOGSTASH_CONTAINER_PORT):$(LOGSTASH_CONTAINER_PORT)/udp \
	-p $(LOGSTASH_CONTAINER_HTTP_API):$(LOGSTASH_CONTAINER_HTTP_API) \
	--name $(LOGSTASH_CONTAINER_NAME) \
	$(LOGSTASH_CONTAINER_IMAGE):$(LOGSTASH_CONTAINER_TAG)

run_elasticsearch:
	docker run \
	-d \
	-v $(ELASTICSEARCH_CONFIG_FILE_SRC):$(ELASTICSEARCH_CONFIG_FILE_DST) \
	-v $(ELASTICSEARCH_VOLUME_PATH_HOST):$(ELASTICSEARCH_VOLUME_PATH_CONTAINER) \
	-p $(ELASTICSEARCH_CONTAINER_PORT_HTTP):$(ELASTICSEARCH_CONTAINER_PORT_HTTP) \
	-p $(ELASTICSEARCH_CONTAINER_PORT):$(ELASTICSEARCH_CONTAINER_PORT) \
	--name $(ELASTICSEARCH_CONTAINER_NAME) \
	$(ELASTICSEARCH_CONTAINER_IMAGE):$(ELASTICSEARCH_CONTAINER_TAG)

run_kibana:
	docker run \
	-d \
	--link $(ELASTICSEARCH_CONTAINER_NAME):elasticsearch \
	-p $(KIBANA_CONTAINER_PORT):$(KIBANA_CONTAINER_PORT) \
	--name $(KIBANA_CONTAINER_NAME) \
	$(KIBANA_CONTAINER_IMAGE):$(KIBANA_CONTAINER_TAG)

# rm: 