from kafka import KafkaConsumer
from json import loads, dumps
import requests
import re

consumer = KafkaConsumer(
    'ansible_callback',
    value_deserializer=lambda m: loads(m.decode('utf-8')),
    bootstrap_servers='10.6.6.101:9092'
    )


for each_message in consumer:
    print("hello world")
