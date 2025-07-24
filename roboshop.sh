#!/bin/bash
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0ed01617e03501426"
INSTNACES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z06642261B4AEFFCIQJUH"
DOMAIN_NAME="prasannadevops.online"
for instance in ${INSTNACES[@]}
do 
aws ec2 run-instances \
    --image-id ami-09c813fb71547fc4f \
    --count 1 \
    --instance-type t2.micro \
    --security-group-ids sg-0ed01617e03501426 \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name, Value="$instance"}]'

done