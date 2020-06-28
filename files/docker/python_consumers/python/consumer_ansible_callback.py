from kafka import KafkaConsumer
from json import loads, dumps
import requests
import re

def kafka_cleanup(each_message):
    # ##########################################################
    # ### each message
    # ########################################################## 
    ansible_message = {}

    # ansible_host
    try:
        ansible_message["ansible_host"] = each_message.value["ansible_host"]
    except KeyError:
        pass

    # ansible_result
    try:
        ansible_message["ansible_result"] = each_message.value["ansible_result"]
    except KeyError:
        pass

    # ansible_task
    try:
        ansible_message["ansible_task"] = each_message.value["ansible_task"]
    except KeyError:
        pass

    # message
    try:
        ansible_message["message"] = each_message.value["message"]
    except KeyError:
        pass

    # status
    try:
        ansible_message["status"] = each_message.value["status"]
    except KeyError:
        pass

    return(ansible_message)


def was_diff(ansible_result):
    diff = False
    match = re.match(r"^TASK.*PRINT.*$", ansible_result)
    if match:
        diff = True
    return(diff)


def send_request(host_name, neighbor, iface):
    try:
        response = requests.post(
            url="http://10.255.127.47/api/v2/job_templates/12/launch/",
            headers={
                "Authorization": "Basic YXV0b21hdGlvbjpqdW5pcGVyMTIz",
                "Content-Type": "application/json; charset=utf-8",
            },
            data=dumps({
                "extra_vars": {
                    "iface": iface,
                    "host_name": host_name,
                    "neighbor": neighbor
                }
            })
        )
        print('Response HTTP Status Code: {status_code}'.format(
            status_code=response.status_code))
        print('Response HTTP Response Body: {content}'.format(
            content=response.content))
    except requests.exceptions.RequestException:
        print('HTTP Request failed')


consumer = KafkaConsumer(
    'ansible_callback',
    value_deserializer=lambda m: loads(m.decode('utf-8')),
    bootstrap_servers='10.6.6.101:9092'
    )


for each_message in consumer:
    ansible_message = kafka_cleanup(each_message)

    # ansible_task
    if ansible_message["ansible_result"]:
        result = loads(ansible_message["ansible_result"])
        print(result["changed"])
        # if result["changed"] == True:
        #     print("RESULT GOES HERE")
