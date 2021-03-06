#!/bin/bash

#swarm master

# CPU = $1
# MEMORY = $2+"m"
FUNCTION_NAME=$1
UUID=$2
MEMORY=$3"m"
#echo $FUNCTION_NAME
HOST_IP=$(ip addr | grep 'eth0' | tail -n1 | awk '{print $2}' | cut -f1 -d'/')
MASTER=$HOST_IP":5001"

KEY=$(cat setup.config | awk '{split($0,a,"="); if(a[1]=="KEY") print a[2]}')

echo $KEY

echo "Exceuting docker swarm"

#create container
#CONT_ID=$(sudo docker -H $MASTER create -t -v /home/ubuntu:/home/code -m 256m ub-python 2>&1)
CONT_ID=$(sudo docker -H $MASTER create -t -v /home/ubuntu:/home/code -m $MEMORY ub-python 2>&1)
 #|| echo "Exception occured")
echo $CONT_ID
OUT=$(echo $CONT_ID | awk '{print $2}')

if [ "$OUT" == "" ]; then
#find container node
CONT_NODE=$(sudo docker -H $MASTER inspect --format='{{json .Node.IP}}' $CONT_ID | awk '{print substr($0,2,(length($0)-2))}')

#copy function
#codePath="/home/ubuntu/"+$FUNCTION_NAME 

scp -i $KEY /home/ubuntu/$FUNCTION_NAME ubuntu@$CONT_NODE:/home/ubuntu

#start the container
sudo docker -H $MASTER start $CONT_ID

#execute function
sudo docker -H $MASTER exec $CONT_ID apt-get install -y python
echo "::::::Begining Code Execution:::::::"
#sleeping to check the cluster management
sleep 10
OUT=sudo docker -H $MASTER exec $CONT_ID timeout 60 python /home/code/$FUNCTION_NAME > ./log/$FUNCTION_NAME"_"$UUID".log"
echo $OUT
echo "::::::Log file copying to Master::::::"

#scp -i /home/ubuntu/my-key.pem ubuntu@$CONT_NODE:/home/ubuntu/Lambda-on-OpenStack/LambdaService/EventListener/$FUNCTION_NAME"_"$UUID".log" /home/ubuntu/

#scp -i /home/ubuntu/my-key.pem ubuntu@$CONT_NODE:/home/ubuntu/Lambda-on-OpenStack/LambdaService/EventListener/FunctionLogs/$FUNCTION_NAME"_"$UUID".log" /home/ubuntu/

echo "::::::Execution ends::::::"

#stop container
sudo docker -H $MASTER stop $CONT_ID

#remove container
sudo docker -H $MASTER rm -f $CONT_ID

else

echo "ERROR:::"$CONT_ID;

fi
