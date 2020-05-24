from kafka import KafkaConsumer
from json import loads
import requests
import re

def kafka_cleanup(each_message):
    host_ip = each_message.value['host']
    host_name = each_message.value['hostname']
    msg = each_message.value['router_message']
    return(host_ip, host_name, msg)


def syslog_cleanup(msg):
    match = re.match(r"^\[(?P<junos_string>.*)]", msg)
    if match:
        junos_string = match.groupdict(['junos_string'])
        for k,v in junos_string.items():
            msg = v.split(" ")
            neighbor = msg[2]
            neighbor = neighbor.split("=")
            neighbor = neighbor[1].replace('"','')
            iface = msg[3]
            iface = iface.split("=")
            iface = iface[1].replace('"','')
        return(neighbor, iface)


consumer = KafkaConsumer(
    'isis_down',
    value_deserializer=lambda m: loads(m.decode('utf-8')),
    bootstrap_servers='10.6.6.46:9092'
    )


for each_message in consumer:
    host_ip, host_name, msg = kafka_cleanup(each_message)
    neighbor, iface = syslog_cleanup(msg)
    print('host_ip: ' + str(host_ip))
    print('host_name: ' + str(host_name))
    print('msg: ' + str(msg))
    print('neighbor: ' + str(neighbor))
    print('iface: ' + str(iface))
