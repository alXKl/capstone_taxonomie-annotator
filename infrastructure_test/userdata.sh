#!/bin/bash

cd /home/ec2-user
aws s3 cp s3://cap-backend-src-test/backend.zip backend.zip
unzip backend.zip
pip3 install -r requirements.txt
# python3 main.py