from kafka import KafkaConsumer
from json import loads, dumps
import requests
import re

def kafka_cleanup(each_message):
    ansible_host = each_message.value['ansible_host']
    ansible_result = each_message.value['ansible_result']
    ansible_task = each_message.value['ansible_task']
    message = each_message.value['message']
    status = each_message.value['status']
    return(ansible_host, ansible_result, ansible_task, message, status)


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
    ansible_host, ansible_result, ansible_task, message, status = kafka_cleanup(each_message)
    diff = was_diff(ansible_result)
    if diff == True:
        print('ansible_host: ' + ansible_host + '\nansible_result: ' + ansible_result + '\nansible_task: ' + ansible_task + '\nmessage: ' + message + '\nstatus: ' + status)
    print(each_message)
