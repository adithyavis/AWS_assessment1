#!/bin/bash

readFile=$(<ids.txt)
ids=($readFile)

sg1=${ids[0]}
sg2=${ids[1]}
instance1=${ids[2]}
instance2=${ids[3]}
instance3=${ids[4]}
launchconfig=${ids[5]}
asgroup=${ids[6]}

aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $asgroup --force-delete --region us-east-1
aws autoscaling delete-launch-configuration --launch-configuration-name $launchconfig --region us-east-1
aws ec2 terminate-instances --instance-ids $instance1 --region us-east-1
aws ec2 terminate-instances --instance-ids $instance2 --region us-east-1
aws ec2 terminate-instances --instance-ids $instance3 --region us-east-1
aws ec2 revoke-security-group-ingress --group-id $sg2 --protocol tcp --port 22 --source-group $sg1 --region us-east-1
aws ec2 revoke-security-group-ingress --group-id $sg2 --protocol tcp --port 22 --source-group $sg2 --region us-east-1
aws ec2 delete-security-group --group-id $sg1 --region us-east-1
aws ec2 delete-security-group --group-id $sg2 --region us-east-1






