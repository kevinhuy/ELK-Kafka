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
LOGSTASH_PIPELINE_FILE_SRC = $(shell pwd)/files/docker/logstash/config/pipeline.conf
LOGSTASH_PIPELINE_FILE_DST =  /usr/share/logstash/pipeline/pipeline.conf

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

KAFKA_CONTAINER_IMAGE = packetferret/elk-kafka
KAFKA_CONTAINER_TAG = 0.0.1
KAFKA_CONTAINER_PORT = 9092
KAFKA_CONTAINER_NAME = elk-kafka
KAFKA_CREATE_TOPICS = "juniper:1:1,ansible_callback:1:1"
KAFKA_ZOOKEEPER_CONNECT = 10.6.6.101:2181
KAFKA_ADVERTISED_HOST_NAME = 10.6.6.101

ZOOKEEPER_CONTAINER_IMAGE = packetferret/elk-zookeeper
ZOOKEEPER_CONTAINER_TAG = 0.0.1
ZOOKEEPER_CONTAINER_PORT = 2181
ZOOKEEPER_CONTAINER_NAME = elk-zookeeper

KAFKA_CONSUMER_IMAGE = packetferret/elk-kafka-consumer
KAFKA_CONSUMER_TAG = 0.0.1
KAFKA_CONSUMER_NAME_ISIS_DOWN = elk-kafaka-isis-down
KAFKA_CONSUMER_NAME_ISIS_UP = elk-kafaka-isis-up
KAFKA_CONSUMER_NAME_ISIS_BGP = elk-kafaka-bgp-down
KAFKA_CONSUMER_NAME_ANSIBLE_CALLBACK = elk-kafaka-ansible-callback
KAFKA_CONSUMER_PYTHON_SCRIPTS_SRC = $(shell pwd)/files/docker/python_consumers/python
KAFKA_CONSUMER_PYTHON_SCRIPTS_DST = /home/python
KAFKA_CONSUMER_SCRIPT_ISIS_DOWN = consumer_isis_down.py
KAFKA_CONSUMER_SCRIPT_ISIS_UP = consumer_isis_up.py
KAFKA_CONSUMER_SCRIPT_ISIS_BGP = consumer_bgp_down.py
KAFKA_CONSUMER_SCRIPT_ANSIBLE_CALLBACK = consumer_ansible_callback.py


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
		$(KIBANA_CONTAINER_NAME)\
		$(ZOOKEEPER_CONTAINER_NAME)\
		$(KAFKA_CONTAINER_NAME)\
		$(KAFKA_CONSUMER_NAME_ANSIBLE_CALLBACK);
	docker rm \
		$(LOGSTASH_CONTAINER_NAME)\
		$(ELASTICSEARCH_CONTAINER_NAME)\
		$(KIBANA_CONTAINER_NAME)\
		$(ZOOKEEPER_CONTAINER_NAME)\
		$(KAFKA_CONTAINER_NAME)\
		$(KAFKA_CONSUMER_NAME_ANSIBLE_CALLBACK);

clean_images:
	docker rmi \
		$(LOGSTASH_CONTAINER_IMAGE):$(LOGSTASH_CONTAINER_TAG) \
		$(ELASTICSEARCH_CONTAINER_IMAGE):$(ELASTICSEARCH_CONTAINER_TAG)\
		$(KIBANA_CONTAINER_IMAGE):$(KIBANA_CONTAINER_TAG)\
		$(KAFKA_CONTAINER_IMAGE):$(KAFKA_CONTAINER_TAG)\
		$(KAFKA_CONSUMER_IMAGE):$(KAFKA_CONSUMER_TAG)\
		$(ZOOKEEPER_CONTAINER_IMAGE):$(ZOOKEEPER_CONTAINER_TAG)

build: build_logstash build_elasticsearch build_kibana build_zookeeper build_kafka

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

build_zookeeper:
	docker build \
	-t $(ZOOKEEPER_CONTAINER_IMAGE):$(ZOOKEEPER_CONTAINER_TAG) \
	files/docker/zookeeper/

build_kafka:
	docker build \
	-t $(KAFKA_CONTAINER_IMAGE):$(KAFKA_CONTAINER_TAG) \
	files/docker/kafka/

build_consumer:
	docker build \
	-t $(KAFKA_CONSUMER_IMAGE):$(KAFKA_CONSUMER_TAG) \
	files/docker/python_consumers/


# logs:

run: build run_logstash run_elasticsearch run_kibana run_zookeeper run_kafka run_consumer_ansible

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

run_zookeeper:
	docker run \
	-d \
	-p $(ZOOKEEPER_CONTAINER_PORT):$(ZOOKEEPER_CONTAINER_PORT) \
	--name $(ZOOKEEPER_CONTAINER_NAME) \
	$(ZOOKEEPER_CONTAINER_IMAGE):$(ZOOKEEPER_CONTAINER_TAG)

run_kafka:
	docker run \
	-d \
	-p $(KAFKA_CONTAINER_PORT):$(KAFKA_CONTAINER_PORT) \
	--name $(KAFKA_CONTAINER_NAME) \
	--env KAFKA_CREATE_TOPICS=$(KAFKA_CREATE_TOPICS) \
	--env KAFKA_ZOOKEEPER_CONNECT=$(KAFKA_ZOOKEEPER_CONNECT) \
	--env KAFKA_ADVERTISED_HOST_NAME=$(KAFKA_ADVERTISED_HOST_NAME) \
	$(KAFKA_CONTAINER_IMAGE):$(KAFKA_CONTAINER_TAG)

run_consumer_isis_down:
	docker run \
	-d \
	-v $(KAFKA_CONSUMER_PYTHON_SCRIPTS_SRC):$(KAFKA_CONSUMER_PYTHON_SCRIPTS_DST) \
	--name $(KAFKA_CONSUMER_NAME_ISIS_DOWN) \
	$(KAFKA_CONSUMER_IMAGE):$(KAFKA_CONSUMER_TAG) \
	python3 $(KAFKA_CONSUMER_SCRIPT_ISIS_DOWN)

run_consumer_isis_up:
	docker run \
	-d \
	-v $(KAFKA_CONSUMER_PYTHON_SCRIPTS_SRC):$(KAFKA_CONSUMER_PYTHON_SCRIPTS_DST) \
	--name $(KAFKA_CONSUMER_NAME_ISIS_UP) \
	$(KAFKA_CONSUMER_IMAGE):$(KAFKA_CONSUMER_TAG) \
	python3 $(KAFKA_CONSUMER_SCRIPT_ISIS_UP)

run_consumer_bgp_down:
	docker run \
	-d \
	-v $(KAFKA_CONSUMER_PYTHON_SCRIPTS_SRC):$(KAFKA_CONSUMER_PYTHON_SCRIPTS_DST) \
	--name $(KAFKA_CONSUMER_NAME_BGP_DOWN) \
	$(KAFKA_CONSUMER_IMAGE):$(KAFKA_CONSUMER_TAG) \
	python3 $(KAFKA_CONSUMER_SCRIPT_BGP_DOWN)

run_consumer_ansible:
	docker run \
	-d \
	-v $(KAFKA_CONSUMER_PYTHON_SCRIPTS_SRC):$(KAFKA_CONSUMER_PYTHON_SCRIPTS_DST) \
	--name $(KAFKA_CONSUMER_NAME_ISIS_DOWN) \
	$(KAFKA_CONSUMER_IMAGE):$(KAFKA_CONSUMER_TAG) \
	python3 $(KAFKA_CONSUMER_SCRIPT_ANSIBLE_CALLBACK)
