import locale
import os
import uuid

from confluent_kafka import Producer
from confluent_kafka.admin import AdminClient, NewTopic

a = AdminClient({"bootstrap.servers": os.getenv("KAFKA_HOST", "localhost:9092")})

def delete_topic():
    for _, f in a.delete_topics(["rig"]).items():
        while not f.done():
            print("", end="")
        print("Topic deleted...")

def recreate_topic():
    for _, f in a.create_topics([NewTopic("rig", 8, replication_factor=1)]).items():
        while not f.done():
            print("", end="")
        print("Topic recreated...")


def clear_topic():
    delete_topic()
    recreate_topic()

p = Producer({"bootstrap.servers": os.getenv("KAFKA_HOST", "localhost:9092"), "message.max.bytes": 2048})

# This is exactly 1 kB or 1000 bytes
payload = """
{"specversion": "0.2", "type": "???", "id": "###", "data": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. 
Dui vivamus arcu felis bibendum ut tristique et. 
Quam nulla porttitor massa id neque aliquam vestibulum morbi. 
Vestibulum sed arcu non odio euismod lacinia at quis. 
Ac auctor augue mauris augue neque. 
Purus gravida quis blandit turpis cursus in hac habitasse platea. 
Vulputate eu scelerisque fes imperdiet proin. 
Varius morbi enim nunc faucibus a pellentesque. 
Nec sagittis aliquam aliquam malesuada bibendum arcu. 
Ornare aenean euismod elementum nisi quis eleifend quam adipiscing. 
Amet massa vitae tortor condimentum lacinia quis vel eros.
Nulla aliquet enim tortor at auctor urna nunc id.proin.
Varius morbi enim nunc faucibus a pellentesque.
Nec sagittis aliquam malesuada bibendum arcu
Diam ut venenatis tellus in metus vulputate", "source": "tutorial"}
"""

def produce(p, topic, payload, etype):
    p.produce(topic, payload.replace("???", etype).replace("###", str(uuid.uuid1())).encode("utf-8"))

def print_progress(i, times = 1000):
    num = locale.format("%d", ((i + 1) * times), grouping=True)
    print(f"Loaded: {num}")