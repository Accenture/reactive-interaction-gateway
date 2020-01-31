FROM ubuntu:18.04
COPY run6/loader.py loader.py
COPY run6/start_loader.sh start_loader.sh
COPY wait.sh wait.sh
COPY load.py load.py
RUN apt-get update -y
RUN apt-get install librdkafka-dev python3 python3-pip curl -y
RUN pip3 install --upgrade pip
RUN pip3 install confluent-kafka
CMD [ "sh", "start_loader.sh" ]