#!/bin/bash
# 
# Global Settings
# account="488599217855"
region="us-east-1"
#
# Instance settings
image_id="ami-b70554c8"
#ssh_key_name="AdithyaBase"
instance_type="t2.micro"
subnet_id="subnet-de0385f2"
count=1
keypair1="AdithyaBase"
keypair2="AdithyaBase"
keypair3="AdithyaBase"
wait_seconds="5"

######################################### SECURITY GROUPS####################################################################
read -p "Does security group for bastion instance already exist? y/n: "  Answer
if [[ $Answer = "n" ]]; then
  #aws ec2 delete-security-group --group-name sg1 --region us-east-1
  aws ec2 create-security-group --group-name sg1 --description "Security group for bastion" --region us-east-1
  sgid1name=$(aws ec2 describe-security-groups --group-name sg1 --region us-east-1 | jq -r '.[][] | .GroupId')
  aws ec2 authorize-security-group-ingress --group-id $sgid1name --protocol tcp --port 22 --cidr 0.0.0.0/0 --region us-east-1
fi
read -p "Does security group for the autoscale group instances already exist? y/n: "  Answer
if [[ $Answer = "n" ]]; then
  #aws ec2 delete-security-group --group-name sg2 --region us-east-1
  aws ec2 create-security-group --group-name sg2 --description "Security group for ec2 1" --region us-east-1
  sgid2name=$(aws ec2 describe-security-groups --group-name sg2 --region us-east-1 | jq -r '.[][] | .GroupId')
  aws ec2 authorize-security-group-ingress --group-id $sgid2name --protocol tcp --port 22 --source-group $sgid1name --region us-east-1
  aws ec2 authorize-security-group-ingress --group-id $sgid2name --protocol tcp --port 22 --source-group $sgid2name --region us-east-1
fi

security_group1=$sgid1name
security_group2=$sgid2name

##########################################CREATING INSTANCES##################################################################
printf "Creating Instances........................................ \n"
read -p "Does bastion instance already exist? y/n: "  Answer
if [[ $Answer = "n" ]]; then
  id=$(aws ec2 run-instances --iam-instance-profile Name=FullAccess --image-id ami-b70554c8 --count 1 --instance-type t2.micro --key-name  $keypair1 --subnet-id $subnet_id --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=shell1_ec2_Adithya}]" --region us-east-1 --security-group-ids $security_group1 --query 'Instances[*].InstanceId')
#aws ec2 terminate-instances --instance-ids $id
  printf " Instance was created. Instance ID is $id "
  sleep 5m
fi


read -p "Does instance 1 of the autoscale group already exist? y/n: "  Answer
if [[ $Answer = "n" ]]; then
  id2=$(aws ec2 run-instances --iam-instance-profile Name=FullAccess --image-id ami-b70554c8 --count 1 --instance-type t2.micro --key-name   $keypair2 --subnet-id $subnet_id --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=shell2_ec2_Adithya}]" --region us-east-1 --security-group-ids $security_group2 --query 'Instances[*].InstanceId')
  printf " Instance was created. Instance ID is $id2 \n"
  sleep 5m
fi


read -p "Does instance 2 of the autoscale group already exist? y/n: "  Answer
if [[ $Answer = "n" ]]; then
  id3=$(aws ec2 run-instances --iam-instance-profile Name=FullAccess --image-id ami-b70554c8 --count 1 --instance-type t2.micro --key-name $keypair2 --subnet-id $subnet_id --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=shell3_ec2_Adithya}]" --region us-east-1 --security-group-ids $security_group2 --query 'Instances[*].InstanceId')
  printf " Instance was created. Instance ID is $id3 \n"
  sleep 5m
fi


###########################################CREATING AN AUTOSCALE GROUP#########################################################
printf "Creating Auto Scale Group........................................ \n"
read -p "Does autoscale launch configuration named AdithyaPE already exist? y/n: "  Answer
if [[ $Answer = "n" ]]; then
  aws autoscaling create-launch-configuration --launch-configuration-name AdithyaPE --image-id ami-b70554c8 --instance-type t2.micro --key-name AdithyaBase --region us-east-1 --security-groups sg2
  aws autoscaling describe-launch-configurations --launch configuration-name AdithyaPE --region us-east-1
  sleep 1m
fi

read -p "Does autoscale group already exist? y/n: "  Answer
if [[ $Answer = "n" ]]; then
 aws autoscaling create-auto-scaling-group --auto-scaling-group-name Autoscale_pe --launch-configuration-name AdithyaPE --min-size 0 --max-size 4 --availability-zones us-east-1a --region us-east-1
 sleep 1m
fi

instanceid1=$(aws ec2 describe-instances --region us-east-1 --filters "Name=tag:Name,Values=shell1_ec2_Adithya" | grep InstanceId | grep -E -o "i\-[0-9A-Za-z]+")
instanceid2=$(aws ec2 describe-instances --region us-east-1 --filters "Name=tag:Name,Values=shell2_ec2_Adithya" | grep InstanceId | grep -E -o "i\-[0-9A-Za-z]+")
instanceid3=$(aws ec2 describe-instances --region us-east-1 --filters "Name=tag:Name,Values=shell3_ec2_Adithya" | grep InstanceId | grep -E -o "i\-[0-9A-Za-z]+")

instances=$( echo "$instanceid2 $instanceid3")
read -p "The default desired capacity is 0. Do you want to change it? y/n: " Answer
if [[ $Answer = "n" ]]; then
 aws autoscaling set-desired-capacity --auto-scaling-group-name Autoscale_pe --desired-capacity 0 --region us-east-1
elif [[ $Answer = "y" ]]; then
 read -p " Please change the desired capacity value. It should be between 0-2: " Answer
 aws autoscaling set-desired-capacity --auto-scaling-group-name Autoscale_pe --desired-capacity $Answer --region us-east-1
fi
read -p "Are the instances already part of the Autoscale group? y/n: " Answer
if [[ $Answer = "n" ]]; then
 aws autoscaling attach-instances --instance-ids $instances --auto-scaling-group-name Autoscale_pe --region us-east-1
fi
########################################SSH##################################################################################

printf "Agent forwarding is being enabled............ \n"
eval `ssh-agent -s` 
ssh-add -k AdithyaBase.pem

printf " When SSHing into another instance, please add the flag -A. For instance, ssh -A user@host \n"
read -p "Press any Character to exit: " P



