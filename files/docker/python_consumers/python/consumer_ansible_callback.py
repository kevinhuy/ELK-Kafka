from kafka import KafkaConsumer
from json import loads, dumps
import requests
import re


def kafka_cleanup(each_message):
    device_message = {}
    try:
        device_message["message"] = each_message.value["message"]
    except KeyError:
        pass

    try:
        device_message["ansible_playbook"] = each_message.value["ansible_playbook"]
    except KeyError:
        pass

    try:
        device_message["ansible_task"] = each_message.value["ansible_task"]
    except KeyError:
        pass

    try:
        device_message["ansible_host"] = each_message.value["ansible_host"]
    except KeyError:
        pass

    try:
        device_message["ansible_result"] = each_message.value["ansible_result"]
        try:
            device_message["ansible_result"] = loads(device_message["ansible_result"])
        except KeyError:
            pass
    except KeyError:
        pass

    return device_message


consumer = KafkaConsumer(
    'ansible_callback',
    value_deserializer=lambda m: loads(m.decode('utf-8')),
    bootstrap_servers='10.6.6.101:9092'
    )


for each_message in consumer:
    device_message = kafka_cleanup(each_message)
    try:
        if device_message["message"] != 'ansible skipped':
            if device_message["message"] == 'ansible stats':
                ansible_result = device_message["ansible_result"]
                for each in ansible_result.items():
                    playbook_result = {}
                    playbook_result["hostname"] = each[0]
                    playbook_result["report"] = each[1]
                    print(playbook_result)
                    if playbook_result["report"]["report"]["changed"] > 0:
                        print('SOMETHING CHANGED')

    except KeyError:
        pass
